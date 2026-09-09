#!/usr/bin/env python3
"""Manage the project-local literature registry used by the lit workflow.

The registry is deliberately CSV and standard-library only: it is easy to
inspect, survives host changes, and is the sole link between a bibliographic
record, its project PDF, parsed Markdown, and reading status.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Iterable


REGISTRY_NAME = "paper-registry.csv"
FIELDS = [
    "paper_id",
    "title",
    "authors",
    "year",
    "source",
    "doi",
    "source_id",
    "abstract",
    "language",
    "citation_key",
    "selection_reason",
    "download_url",
    "download_status",
    "pdf_path",
    "source_pdf_path",
    "pdf_sha256",
    "pdf_bytes",
    "pdf_pages",
    "parse_status",
    "fulltext_path",
    "reading_status",
    "notes",
]
DOWNLOADABLE_STATES = {"pending", "retry", "failed"}


def normalize(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip()).casefold()


def clean_doi(value: str) -> str:
    value = normalize(value)
    return re.sub(r"^(?:https?://)?(?:dx\.)?doi\.org/", "", value).rstrip(".")


def stable_id(title: str, authors: str, year: str, doi: str, source_id: str) -> str:
    if clean_doi(doi):
        identity = f"doi:{clean_doi(doi)}"
    elif normalize(source_id):
        identity = f"source:{normalize(source_id)}"
    else:
        identity = f"citation:{normalize(title)}|{normalize(authors)}|{normalize(year)}"
    return "paper-" + hashlib.sha256(identity.encode("utf-8")).hexdigest()[:12]


def safe_title_filename(title: str) -> str:
    """Keep a readable title while replacing only path-unsafe characters."""
    cleaned = re.sub(r'[\x00-\x1f/\\:*?"<>|]', " ", title)
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" .")
    if not cleaned:
        cleaned = "untitled"
    # Filesystems have component limits. The full, unmodified title remains in CSV.
    return cleaned[:180].rstrip(" .") or "untitled"


def literature_root(workspace: Path) -> Path:
    return workspace.resolve() / "02-literature"


def registry_path(workspace: Path) -> Path:
    return literature_root(workspace) / REGISTRY_NAME


def ensure_layout(workspace: Path) -> Path:
    root = literature_root(workspace)
    for directory in (root, root / "papers", root / "fulltext", root / "plans"):
        directory.mkdir(parents=True, exist_ok=True)
    path = registry_path(workspace)
    if not path.exists():
        write_rows(path, [], FIELDS)
    return path


def read_rows(path: Path) -> tuple[list[dict[str, str]], list[str]]:
    if not path.exists():
        return [], FIELDS.copy()
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        headers = list(reader.fieldnames or [])
        rows = [{key: value or "" for key, value in row.items() if key is not None} for row in reader]
    ordered = FIELDS + [name for name in headers if name not in FIELDS]
    for row in rows:
        for field in ordered:
            row.setdefault(field, "")
    return rows, ordered


def write_rows(path: Path, rows: Iterable[dict[str, str]], headers: list[str] | None = None) -> None:
    headers = headers or FIELDS
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=headers, extrasaction="ignore", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in headers})


def load_registry(workspace: Path) -> tuple[Path, list[dict[str, str]], list[str]]:
    path = ensure_layout(workspace)
    rows, headers = read_rows(path)
    changed = False
    for row in rows:
        for field in FIELDS:
            if field not in headers:
                headers.append(field)
                changed = True
            row.setdefault(field, "")
    if changed:
        write_rows(path, rows, headers)
    return path, rows, headers


def relative_to_literature(path: Path, root: Path) -> str:
    try:
        return str(path.resolve().relative_to(root.resolve()))
    except ValueError as exc:
        raise ValueError(f"路径必须位于项目文献目录内: {path}") from exc


def target_pdf_path(root: Path, rows: list[dict[str, str]], paper_id: str, title: str) -> str:
    filename = safe_title_filename(title) + ".pdf"
    default = Path("papers") / filename
    occupied = {
        Path(row["pdf_path"]).as_posix().casefold()
        for row in rows
        if row.get("paper_id") != paper_id and row.get("pdf_path")
    }
    existing_file = (root / default).exists()
    if default.as_posix().casefold() not in occupied and not existing_file:
        return default.as_posix()
    return (Path("papers") / paper_id / filename).as_posix()


def field_values(args: argparse.Namespace) -> dict[str, str]:
    return {
        "title": args.title or "",
        "authors": args.authors or "",
        "year": args.year or "",
        "source": args.source or "",
        "doi": clean_doi(args.doi or ""),
        "source_id": args.source_id or "",
        "abstract": args.abstract or "",
        "language": args.language or "",
        "citation_key": args.citation_key or "",
        "selection_reason": args.selection_reason or "",
        "download_url": args.download_url or "",
        "source_pdf_path": args.source_pdf_path or "",
        "notes": args.notes or "",
    }


def command_init(args: argparse.Namespace) -> int:
    path = ensure_layout(Path(args.workspace))
    print(path)
    return 0


def command_register(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    path, rows, headers = load_registry(workspace)
    values = field_values(args)
    if not values["title"]:
        raise ValueError("--title 不能为空")
    paper_id = stable_id(
        values["title"], values["authors"], values["year"], values["doi"], values["source_id"]
    )
    existing = next((row for row in rows if row["paper_id"] == paper_id), None)
    created = existing is None
    if existing is None:
        existing = {field: "" for field in headers}
        existing["paper_id"] = paper_id
        existing["parse_status"] = "not_requested"
        existing["reading_status"] = "not_read"
        if values["download_url"]:
            existing["pdf_path"] = target_pdf_path(literature_root(workspace), rows, paper_id, values["title"])
            existing["fulltext_path"] = (Path("fulltext") / paper_id / "document.md").as_posix()
            existing["download_status"] = "pending"
        elif values["source_pdf_path"]:
            existing["download_status"] = "external"
        else:
            existing["download_status"] = "not_requested"
        rows.append(existing)
    for key, value in values.items():
        if value and (created or not existing.get(key)):
            existing[key] = value
    if values["download_url"] and not existing["pdf_path"]:
        existing["pdf_path"] = target_pdf_path(literature_root(workspace), rows, paper_id, values["title"])
        existing["fulltext_path"] = (Path("fulltext") / paper_id / "document.md").as_posix()
        if existing["download_status"] in {"", "not_requested", "external"}:
            existing["download_status"] = "pending"
    write_rows(path, rows, headers)
    print(json.dumps({"paper_id": paper_id, "pdf_path": existing["pdf_path"], "fulltext_path": existing["fulltext_path"]}, ensure_ascii=False))
    return 0


def command_download_plan(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    _, rows, _ = load_registry(workspace)
    output = Path(args.out).resolve()
    selected = [
        row for row in rows
        if row.get("download_url") and row.get("download_status") in DOWNLOADABLE_STATES and row.get("pdf_path")
    ]
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["paper_id", "pdf_path", "download_url"], delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows({key: row.get(key, "") for key in writer.fieldnames} for row in selected)
    print(f"{output}: {len(selected)} 篇待下载")
    return 0


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_pdf(path: Path) -> dict[str, object]:
    result: dict[str, object] = {"path": str(path), "valid": False, "pages": "", "parser": "", "error": ""}
    if not path.is_file() or path.stat().st_size < 32:
        result["error"] = "文件不存在或为空"
        return result
    with path.open("rb") as handle:
        head = handle.read(8)
        handle.seek(max(0, path.stat().st_size - 2048))
        tail = handle.read()
    if not head.startswith(b"%PDF-") or b"%%EOF" not in tail:
        result["error"] = "不是带完整尾标记的 PDF"
        return result
    try:
        from pypdf import PdfReader  # type: ignore
        reader = PdfReader(str(path))
        result.update(valid=True, pages=len(reader.pages), parser="pypdf")
        return result
    except ImportError:
        pass
    except Exception as exc:
        result["error"] = f"pypdf 无法解析: {exc}"
        return result
    for executable, command in (("pdfinfo", ["pdfinfo", str(path)]), ("qpdf", ["qpdf", "--check", str(path)])):
        if not shutil.which(executable):
            continue
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode != 0:
            result["error"] = f"{executable} 校验失败: {(completed.stderr or completed.stdout).strip()[:200]}"
            return result
        pages = ""
        if executable == "pdfinfo":
            match = re.search(r"^Pages:\s*(\d+)", completed.stdout, re.MULTILINE)
            pages = match.group(1) if match else ""
        result.update(valid=True, pages=pages, parser=executable)
        return result
    result["error"] = "需要 pypdf、pdfinfo 或 qpdf 之一来验证 PDF"
    return result


def command_validate_pdf(args: argparse.Namespace) -> int:
    result = validate_pdf(Path(args.path))
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result["valid"] else 1


def find_row(rows: list[dict[str, str]], paper_id: str) -> dict[str, str]:
    row = next((item for item in rows if item["paper_id"] == paper_id), None)
    if row is None:
        raise ValueError(f"未找到 paper_id: {paper_id}")
    return row


def command_mark_download(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    path, rows, headers = load_registry(workspace)
    root = literature_root(workspace)
    row = find_row(rows, args.paper_id)
    pdf = Path(args.pdf_path).resolve()
    result = validate_pdf(pdf)
    if not result["valid"]:
        raise ValueError(f"不能登记为已下载：{result['error']}")
    row.update(
        download_status="downloaded",
        pdf_path=relative_to_literature(pdf, root),
        pdf_sha256=sha256(pdf),
        pdf_bytes=str(pdf.stat().st_size),
        pdf_pages=str(result["pages"]),
        notes=(args.note or row.get("notes", "")),
    )
    if not row.get("fulltext_path"):
        row["fulltext_path"] = (Path("fulltext") / row["paper_id"] / "document.md").as_posix()
    write_rows(path, rows, headers)
    return 0


def command_mark_download_failure(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    path, rows, headers = load_registry(workspace)
    row = find_row(rows, args.paper_id)
    row["download_status"] = args.status
    row["notes"] = args.note or row.get("notes", "")
    write_rows(path, rows, headers)
    return 0


def command_mark_parse(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    path, rows, headers = load_registry(workspace)
    root = literature_root(workspace)
    row = find_row(rows, args.paper_id)
    fulltext = Path(args.fulltext_path).resolve()
    if args.status == "parsed":
        if not fulltext.is_file() or not fulltext.read_text(encoding="utf-8", errors="ignore").strip():
            raise ValueError("不能登记为空或不存在的全文 Markdown")
        row["fulltext_path"] = relative_to_literature(fulltext, root)
    row["parse_status"] = args.status
    row["notes"] = args.note or row.get("notes", "")
    write_rows(path, rows, headers)
    return 0


def command_mark_reading(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    path, rows, headers = load_registry(workspace)
    row = find_row(rows, args.paper_id)
    row["reading_status"] = args.status
    row["notes"] = args.note or row.get("notes", "")
    write_rows(path, rows, headers)
    return 0


def command_check(args: argparse.Namespace) -> int:
    workspace = Path(args.workspace)
    _, rows, _ = load_registry(workspace)
    root = literature_root(workspace)
    issues: list[str] = []
    seen_paths: dict[str, str] = {}
    for row in rows:
        paper_id = row.get("paper_id", "") or "<missing-id>"
        pdf_rel = row.get("pdf_path", "")
        if row.get("download_status") == "downloaded":
            if not pdf_rel or not (root / pdf_rel).is_file():
                issues.append(f"{paper_id}: 已下载但 PDF 路径不存在")
            elif pdf_rel.casefold() in seen_paths:
                issues.append(f"{paper_id}: 与 {seen_paths[pdf_rel.casefold()]} 共用 PDF 路径")
            else:
                seen_paths[pdf_rel.casefold()] = paper_id
        if row.get("parse_status") == "parsed":
            fulltext_rel = row.get("fulltext_path", "")
            if not fulltext_rel or not (root / fulltext_rel).is_file():
                issues.append(f"{paper_id}: 已解析但全文 Markdown 不存在")
    print(json.dumps({"papers": len(rows), "issues": issues}, ensure_ascii=False))
    return 0 if not issues else 1


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description="项目内文献注册、归档与状态管理")
    sub = root.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init")
    init.add_argument("--workspace", required=True)
    init.set_defaults(func=command_init)

    register = sub.add_parser("register")
    register.add_argument("--workspace", required=True)
    register.add_argument("--title", required=True)
    for name in ("authors", "year", "source", "doi", "source-id", "abstract", "language", "citation-key", "selection-reason", "download-url", "source-pdf-path", "notes"):
        register.add_argument(f"--{name}")
    register.set_defaults(func=command_register)

    plan = sub.add_parser("download-plan")
    plan.add_argument("--workspace", required=True)
    plan.add_argument("--out", required=True)
    plan.set_defaults(func=command_download_plan)

    validate = sub.add_parser("validate-pdf")
    validate.add_argument("--path", required=True)
    validate.set_defaults(func=command_validate_pdf)

    downloaded = sub.add_parser("mark-download")
    downloaded.add_argument("--workspace", required=True)
    downloaded.add_argument("--paper-id", required=True)
    downloaded.add_argument("--pdf-path", required=True)
    downloaded.add_argument("--note")
    downloaded.set_defaults(func=command_mark_download)

    failed = sub.add_parser("mark-download-failure")
    failed.add_argument("--workspace", required=True)
    failed.add_argument("--paper-id", required=True)
    failed.add_argument("--status", choices=["retry", "failed", "blocked"], required=True)
    failed.add_argument("--note", required=True)
    failed.set_defaults(func=command_mark_download_failure)

    parsed = sub.add_parser("mark-parse")
    parsed.add_argument("--workspace", required=True)
    parsed.add_argument("--paper-id", required=True)
    parsed.add_argument("--fulltext-path", required=True)
    parsed.add_argument("--status", choices=["parsed", "failed"], required=True)
    parsed.add_argument("--note")
    parsed.set_defaults(func=command_mark_parse)

    reading = sub.add_parser("mark-reading")
    reading.add_argument("--workspace", required=True)
    reading.add_argument("--paper-id", required=True)
    reading.add_argument("--status", choices=["not_read", "read", "needs_evidence"], required=True)
    reading.add_argument("--note")
    reading.set_defaults(func=command_mark_reading)

    check = sub.add_parser("check")
    check.add_argument("--workspace", required=True)
    check.set_defaults(func=command_check)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except (OSError, ValueError) as exc:
        print(f"错误: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
