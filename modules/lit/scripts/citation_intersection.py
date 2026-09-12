#!/usr/bin/env python3
"""参考文献交集统计：多篇全文 Markdown 的参考文献取交集，按重复度排序。

用途（phase-1-search.md Step 12 参考文献滚雪球）：
  对 paper-registry.csv 中 parse_status=parsed 的条目，从 fulltext/<paper_id>/document.md
  提取参考文献条目，统计每条被多少篇文献共同引用（共引频次），输出高重复度候选清单，
  作为下一轮 CNKI 检索下载的输入。

仅用标准库。用法：
  python3 citation_intersection.py --workspace <paper-workspace> \
    [--min-count 2] [--top 20] [--out <输出.md>] [--tsv <输出.tsv>] [--registry <路径>]
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import unicodedata
from pathlib import Path

REF_HEAD = re.compile(
    r"^#{1,6}\s*(参考文献|引用文献|引注文献|注释与参考文献|主要参考文献|文献|references|reference|bibliography|notes and references)\s*:?\s*$",
    re.IGNORECASE,
)
# 无标题时的兜底标记
REF_MARKER = re.compile(r"^\s*(主要参考文献|参考文献|References)\s*:?\s*$", re.MULTILINE)
ENTRY_NUM = re.compile(r"^\s*(?:[\[（(（]?(\d{1,3})[\]）).]|[〇①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳](\d{0,3}))\s*")
STOP_HEAD = re.compile(
    r"^#{1,6}\s*(附录|致谢|作者贡献|图表目录|索引|appendix|acknowledg|glossary)",
    re.IGNORECASE,
)


def read_registry(workspace: Path, registry: str | None) -> tuple[Path, list[dict[str, str]]]:
    path = Path(registry) if registry else workspace / "02-literature" / "paper-registry.csv"
    if not path.exists():
        raise SystemExit(f"注册表不存在: {path}")
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return path, list(csv.DictReader(handle))


def extract_reference_text(md: str) -> str:
    lines = md.splitlines()
    start = None
    for i, line in enumerate(lines):
        if REF_HEAD.match(line.strip()):
            start = i + 1
            break
    if start is None:
        match = REF_MARKER.search(md)
        if match:
            return md[match.end():]
        # 脚注式兜底：参考文献通常在文末，取尾部 25% 且含编号标记的连续区块
        zone = lines[max(0, int(len(lines) * 0.75)):]
        idx = None
        for j, ln in enumerate(zone):
            if ENTRY_NUM.match(ln.strip()) and len(ln.strip()) >= 15:
                idx = j
                break
        if idx is None:
            return ""
        return "\n".join(zone[idx:])
    out: list[str] = []
    for line in lines[start:]:
        if STOP_HEAD.match(line.strip()):
            break
        if REF_HEAD.match(line.strip()) and out:
            break
        out.append(line)
    return "\n".join(out)


def split_entries(text: str) -> list[str]:
    """把参考文献段落切成单条。优先按 [n]/〇n/①n 编号切分，否则按非空行。"""
    if not text.strip():
        return []
    circ = "\u2460-\u2473\u3251-\u325F\u32B1-\u32BF"
    numbered = re.split(rf"\n(?=\s*(?:[\[（(]\d{{1,3}}[\]）).]|[〇{circ}]))", text)
    entries = [e for e in numbered if e.strip()]
    if len(entries) <= 2 and not ENTRY_NUM.match(text.strip()):
        entries = [ln.strip() for ln in text.splitlines() if ln.strip()]
    if len(entries) <= 2:
        items = re.split(r"\n(?=\s*[-*]\s+)", text)
        if len(items) > len(entries):
            entries = [re.sub(r"^\s*[-*]\s+", "", i).strip() for i in items if i.strip()]
    return [re.sub(r"\s+", " ", e).strip() for e in entries if len(e.strip()) >= 8]


def normalize_entry(entry: str) -> str:
    """规范化条目做交集键：全角→半角、去编号、去空白与标点变体、统一 OCR 断字。"""
    s = unicodedata.normalize("NFKC", entry)
    s = ENTRY_NUM.sub("", s)
    s = re.sub(r"\s+", "", s)
    s = s.replace("[J]", "").replace("[M]", "").replace("[D]", "").replace("[C]", "")
    s = s.replace("[N]", "").replace("[A]", "").replace("[EB/OL]", "")
    s = re.sub(r"[.,;:，。；：（）()“”\"'’‘·—–\-_/\\]", "", s)
    return s.casefold()


def entry_display(entry: str) -> str:
    return re.sub(r"\s+", " ", entry).strip()[:120]


def merge_clusters(table: dict[str, dict]) -> list[dict]:
    """合并 OCR 变体产生的近重复键（difflib 相似度 ≥0.85 的条目归并）。"""
    import difflib
    clusters: list[dict] = []
    for key in sorted(table, key=lambda k: -len(k)):
        item = table[key]
        for c in clusters:
            if difflib.SequenceMatcher(None, key, c["keys"][0]).ratio() >= 0.85:
                c["count"] += item["count"]
                c["papers"] += item["papers"]
                c["keys"].append(key)
                break
        else:
            clusters.append({"count": item["count"], "papers": list(item["papers"]),
                             "display": item["display"], "keys": [key]})
    # 归并后按论文去重
    for c in clusters:
        seen: set[str] = set()
        uniq = []
        for p in c["papers"]:
            if p not in seen:
                seen.add(p)
                uniq.append(p)
        c["papers"] = uniq
    return clusters


def rank_clusters(clusters: list[dict], args: argparse.Namespace) -> list[dict]:
    ranked = sorted(
        (c for c in clusters if c["count"] >= max(1, args.min_count)),
        key=lambda x: (-x["count"], x["display"]),
    )[: args.top]
    return ranked


def main() -> int:
    ap = argparse.ArgumentParser(description="参考文献交集统计（共引频次）")
    ap.add_argument("--workspace", required=True)
    ap.add_argument("--registry")
    ap.add_argument("--min-count", type=int, default=2)
    ap.add_argument("--top", type=int, default=20)
    ap.add_argument("--out")
    ap.add_argument("--tsv")
    args = ap.parse_args()

    workspace = Path(args.workspace)
    reg_path, rows = read_registry(workspace, args.registry)
    root = reg_path.parent

    # key -> {count, papers, display}
    table: dict[str, dict] = {}
    parsed = [r for r in rows if r.get("parse_status") == "parsed" and r.get("fulltext_path")]
    used: list[str] = []
    for row in parsed:
        md_path = root / row["fulltext_path"]
        if not md_path.exists():
            continue
        text = extract_reference_text(md_path.read_text(encoding="utf-8", errors="ignore"))
        entries = split_entries(text)
        used.append(f"{row.get('paper_id')}: {len(entries)} 条")
        seen_in_paper: set[str] = set()
        for e in entries:
            key = normalize_entry(e)
            if len(key) < 10:
                continue
            if key in seen_in_paper:
                continue
            seen_in_paper.add(key)
            item = table.setdefault(key, {"count": 0, "papers": [], "display": entry_display(e)})
            item["count"] += 1
            item["papers"].append(row.get("paper_id", ""))

    ranked = rank_clusters(merge_clusters(table), args)

    tsv_path = Path(args.tsv) if args.tsv else root / "plans" / "citation-intersection.tsv"
    tsv_path.parent.mkdir(parents=True, exist_ok=True)
    with tsv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(["共引频次", "参考文献条目", "引用论文"])
        for item in ranked:
            writer.writerow([item["count"], item["display"], ";".join(item["papers"])])

    out_path = Path(args.out) if args.out else root / "citation-intersection.md"
    lines = [
        "# 参考文献交集（共引频次）",
        "",
        f"- 解析文献数：{len(used)}（{'; '.join(used) or '无'}）",
        f"- 阈值：被 ≥{args.min_count} 篇共同引用，展示前 {args.top} 条",
        f"- 数据文件：{tsv_path}",
        "",
        "| 共引频次 | 参考文献条目 | 引用论文 |",
        "|---|---|---|",
    ]
    lines += [
        f"| {item['count']} | {item['display']} | {', '.join(item['papers'][:6])} |" for item in ranked
    ]
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({
        "papers_parsed": len(used),
        "unique_refs": len(table),
        "ranked": len(ranked),
        "markdown": str(out_path),
        "tsv": str(tsv_path),
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"错误: {exc}", file=sys.stderr)
        raise SystemExit(1)
