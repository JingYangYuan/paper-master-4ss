#!/usr/bin/env python3
"""Check manuscript citations against write-first and lit-second reference sources."""

from __future__ import annotations

import argparse
import csv
import re
from dataclasses import dataclass
from pathlib import Path


TEXT_SUFFIXES = {".md", ".txt"}
TABLE_SUFFIXES = {".csv", ".tsv"}
# lit 注册表体系下的归档目录：存的是逐篇全文与 PDF 原件，不是题录源。
SKIP_DIR_NAMES = {"papers", "fulltext"}


@dataclass
class Citation:
    key: str
    raw: str
    kind: str


@dataclass
class Reference:
    key: str
    raw: str
    source: str
    priority: int
    aliases: tuple[str, ...] = ()


def normalize_author(author: str) -> str:
    author = re.sub(r"\s+", " ", author.strip())
    author = re.sub(r"[，,。.：:;；]+$", "", author)
    return author.lower()


def make_key(author: str, year: str) -> str:
    return f"{normalize_author(author)}::{year.lower()}"


def clean_chinese_author(author: str) -> str:
    for prefix in ("引用", "根据", "参见", "借鉴"):
        if author.startswith(prefix) and len(author) > len(prefix) + 1:
            return author[len(prefix) :]
    return author


def extract_citations(text: str) -> list[Citation]:
    citations: list[Citation] = []
    patterns = [
        ("zh-narrative", re.compile(r"([\u4e00-\u9fa5]{2,4})（(\d{4}[a-z]?)）")),
        ("zh-parenthetical", re.compile(r"（([\u4e00-\u9fa5]{2,4})，(\d{4}[a-z]?)）")),
        ("en-narrative", re.compile(r"\b([A-Z][A-Za-z-]+)\s+\((\d{4}[a-z]?)\)")),
        ("en-parenthetical", re.compile(r"\(([A-Z][A-Za-z-]+),\s*(\d{4}[a-z]?)\)")),
    ]
    for kind, pattern in patterns:
        for match in pattern.finditer(text):
            author, year = match.group(1), match.group(2)
            if kind.startswith("zh-"):
                author = clean_chinese_author(author)
            citations.append(Citation(make_key(author, year), match.group(0), kind))

    for match in re.finditer(r"\[@([A-Za-z0-9_:-]+)\]", text):
        citations.append(Citation(f"pandoc::{match.group(1).lower()}", match.group(0), "pandoc-key"))

    for match in re.finditer(r"\[\^([^\]]+)\]", text):
        citations.append(Citation(f"footnote::{match.group(1).lower()}", match.group(0), "footnote"))
    return citations


def parse_reference_line(line: str, source: str, priority: int) -> Reference | None:
    stripped = line.strip()
    if len(stripped) < 8:
        return None
    if re.match(r"^#+\s*(参考文献|References)\b", stripped, re.IGNORECASE):
        return None

    zh = re.match(r"^([\u4e00-\u9fa5]{2,12})[，,\.\s]+(\d{4}[a-z]?)", stripped)
    if zh:
        return Reference(make_key(zh.group(1), zh.group(2)), stripped, source, priority)

    en = re.match(r"^([A-Z][A-Za-z-]+)(?:,\s*[A-Z]\.)?.*?(\d{4}[a-z]?)", stripped)
    if en:
        return Reference(make_key(en.group(1), en.group(2)), stripped, source, priority)
    return None


def parse_text_references(path: Path, priority: int) -> list[Reference]:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = path.read_text(encoding="utf-8", errors="ignore")
    refs: list[Reference] = []
    for line in text.splitlines():
        ref = parse_reference_line(line, str(path), priority)
        if ref:
            refs.append(ref)
    return refs


def parse_table_references(path: Path, priority: int) -> list[Reference]:
    delimiter = "\t" if path.suffix.lower() == ".tsv" else ","
    refs: list[Reference] = []
    with path.open(newline="", encoding="utf-8", errors="ignore") as handle:
        reader = csv.DictReader(handle, delimiter=delimiter)
        for row in reader:
            lowered = {k.lower(): v for k, v in row.items() if k}
            author = lowered.get("author") or lowered.get("authors") or lowered.get("作者") or ""
            year = lowered.get("year") or lowered.get("年份") or ""
            title = lowered.get("title") or lowered.get("题名") or lowered.get("标题") or ""
            citation_key = lowered.get("citation_key") or lowered.get("citationkey") or ""
            if author and year:
                raw = "; ".join(part for part in [author, year, title] if part)
                aliases = (f"pandoc::{citation_key.lower()}",) if citation_key else ()
                refs.append(
                    Reference(
                        make_key(author.split(";")[0].split(",")[0], year),
                        raw,
                        str(path),
                        priority,
                        aliases,
                    )
                )
    return refs


def collect_references(paths: list[Path], priority: int) -> list[Reference]:
    refs: list[Reference] = []
    for base in paths:
        if not base.exists():
            continue
        files = [base] if base.is_file() else [p for p in base.rglob("*") if p.is_file()]
        for path in files:
            if base.is_dir() and set(path.relative_to(base).parts[:-1]) & SKIP_DIR_NAMES:
                continue
            suffix = path.suffix.lower()
            if suffix in TEXT_SUFFIXES:
                refs.extend(parse_text_references(path, priority))
            elif suffix in TABLE_SUFFIXES:
                refs.extend(parse_table_references(path, priority))
    return refs


def build_reference_index(refs: list[Reference]) -> dict[str, Reference]:
    index: dict[str, Reference] = {}
    for ref in sorted(refs, key=lambda item: item.priority):
        index.setdefault(ref.key, ref)
        for alias in ref.aliases:
            # citation_key 别名让 [@key] 引用能直接命中 paper-registry.csv 条目。
            index.setdefault(alias, ref)
    return index


def has_required_fields(ref: Reference, style: str) -> list[str]:
    missing: list[str] = []
    raw = ref.raw
    if not re.search(r"\d{4}[a-z]?", raw):
        missing.append("year")
    if len(raw) < 20:
        missing.append("title/source")
    if style == "apa" and "doi" not in raw.lower() and "http" not in raw.lower():
        missing.append("doi/url (if available)")
    return missing


def render_normalized(citations: list[Citation], index: dict[str, Reference], style: str) -> str:
    lines = [
        "# Citation Normalized Report",
        "",
        f"- Target style: `{style}`",
        "- Source priority: write materials first, literature materials second, user files as supplied.",
        "",
        "| Citation | Kind | Matched Reference | Reference Source |",
        "|---|---|---|---|",
    ]
    seen: set[str] = set()
    for citation in citations:
        if citation.raw in seen:
            continue
        seen.add(citation.raw)
        ref = index.get(citation.key)
        lines.append(
            f"| {citation.raw} | {citation.kind} | {ref.raw if ref else 'MISSING'} | {ref.source if ref else 'n/a'} |"
        )
    return "\n".join(lines) + "\n"


def render_gaps(citations: list[Citation], refs: list[Reference], index: dict[str, Reference], style: str) -> str:
    cited_keys = {citation.key for citation in citations}
    lines = ["# Citation Gap Report", ""]

    missing = [citation for citation in citations if citation.key not in index and not citation.key.startswith(("pandoc::", "footnote::"))]
    if missing:
        lines.extend(["## Missing References", ""])
        for citation in missing:
            lines.append(f"- {citation.raw}: 未在 write/lit/user 题录中找到对应条目。")
        lines.append("")

    incomplete: list[str] = []
    for key in cited_keys:
        ref = index.get(key)
        if not ref:
            continue
        missing_fields = has_required_fields(ref, style)
        if missing_fields:
            incomplete.append(f"- {ref.raw}: 缺少 {', '.join(missing_fields)}。来源：{ref.source}")
    if incomplete:
        lines.extend(["## Incomplete Matched References", "", *incomplete, ""])

    orphan_refs = [
        ref
        for ref in refs
        if ref.key not in cited_keys
        and ref.priority <= 2
        and not (set(ref.aliases) & cited_keys)
    ]
    if orphan_refs:
        lines.extend(["## Orphan References", ""])
        for ref in orphan_refs[:100]:
            lines.append(f"- {ref.raw} （来源：{ref.source}）")
        lines.append("")

    pandoc_or_footnotes = [citation for citation in citations if citation.key.startswith(("pandoc::", "footnote::"))]
    unmapped = [c for c in pandoc_or_footnotes if c.key not in index]
    if unmapped:
        lines.extend(["## Needs Manual Mapping", ""])
        for citation in unmapped:
            lines.append(f"- {citation.raw}: 需要 BibTeX/脚注内容或 paper-registry.csv 的 citation_key 进一步映射。")
        lines.append("")

    if len(lines) == 2:
        lines.append("未发现明显引用缺口。")
    lines.append("\n注：本报告不虚构题录字段；缺失信息需要用户、write 材料或 lit 题录补充。")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Check citations with write-first, lit-second priority.")
    parser.add_argument("manuscript", help="Path to manuscript.md")
    parser.add_argument("--write-root", default="paper-workspace/05-writing", help="Write-stage materials root")
    parser.add_argument("--lit-root", default="paper-workspace/02-literature", help="Literature-stage materials root")
    parser.add_argument("--extra-ref", action="append", default=[], help="Additional reference file/folder")
    parser.add_argument("--style", choices=["sociological-research", "gb", "apa"], default="sociological-research")
    parser.add_argument("--out-normalized", default="paper-workspace/06-submission/citation-normalized.md")
    parser.add_argument("--out-gap", default="paper-workspace/06-submission/citation-gap-report.md")
    args = parser.parse_args()

    manuscript = Path(args.manuscript).expanduser().resolve()
    if not manuscript.exists():
        raise SystemExit(f"manuscript not found: {manuscript}")

    text = manuscript.read_text(encoding="utf-8", errors="ignore")
    citations = extract_citations(text)
    refs: list[Reference] = []
    refs.extend(parse_text_references(manuscript, priority=0))
    refs.extend(collect_references([Path(args.write_root)], priority=1))
    refs.extend(collect_references([Path(args.lit_root)], priority=2))
    refs.extend(collect_references([Path(p).expanduser() for p in args.extra_ref], priority=3))
    index = build_reference_index(refs)

    normalized = Path(args.out_normalized).expanduser()
    gap = Path(args.out_gap).expanduser()
    if not normalized.is_absolute():
        normalized = (Path.cwd() / normalized).resolve()
    if not gap.is_absolute():
        gap = (Path.cwd() / gap).resolve()
    normalized.parent.mkdir(parents=True, exist_ok=True)
    gap.parent.mkdir(parents=True, exist_ok=True)

    normalized.write_text(render_normalized(citations, index, args.style), encoding="utf-8")
    gap.write_text(render_gaps(citations, refs, index, args.style), encoding="utf-8")
    print(f"wrote: {normalized}")
    print(f"wrote: {gap}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
