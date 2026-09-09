#!/usr/bin/env python3
"""Anonymize, segment, and scaffold qualitative coding from real text files."""

from __future__ import annotations

import argparse
import re
import sys
from datetime import date
from pathlib import Path


def _load_common():
    for parent in Path(__file__).resolve().parents:
        if (parent / "_shared").exists():
            sys.path.insert(0, str(parent / "_shared"))
            import python_common  # type: ignore

            return python_common
    raise RuntimeError("Cannot locate templates/_shared/python_common.py")


common = _load_common()


def anonymize(text: str) -> str:
    text = re.sub(r"[\w.+-]+@[\w-]+\.[\w.-]+", "[EMAIL]", text)
    text = re.sub(r"\b1[3-9]\d{9}\b", "[PHONE]", text)
    text = re.sub(r"\b\d{15,18}[0-9Xx]\b", "[ID]", text)
    return text


def main() -> int:
    parser = common.add_common_args(argparse.ArgumentParser(description=__doc__))
    parser.add_argument("--text-dir", default=None, help="Directory of .txt/.md files.")
    args = parser.parse_args()
    p = common.paths(args.out_root)
    text_dir = Path(args.text_dir or args.data or ".")
    files = [x for pat in ("*.txt", "*.md") for x in text_dir.glob(pat)] if text_dir.is_dir() else ([text_dir] if text_dir.exists() else [])
    if not files:
        report = common.write_markdown(p["qual"] / "memos" / f"qual-blockers-{date.today().isoformat()}.md", "Qual Blockers", {"阻断": "缺少可读取的 .txt/.md 文本材料。"})
        common.log_run(args, "04-qual", "blocked", [report], "未发现文本材料。")
        return 2
    coded_rows = []
    for f in files:
        text = anonymize(f.read_text(encoding="utf-8", errors="ignore"))
        anon_path = p["qual"] / "anonymized" / f"{f.stem}-anonymized.txt"
        anon_path.write_text(text, encoding="utf-8")
        parts = [x.strip() for x in re.split(r"\n\s*\n", text) if x.strip()]
        for i, part in enumerate(parts, 1):
            coded_rows.append({"source_id": f.stem, "excerpt_id": i, "anonymized_excerpt": part[:1000], "code": "", "memo": ""})
    codebook = common.write_csv(p["qual"] / "codebooks" / f"codebook-{date.today().isoformat()}.csv", [{"code": "", "definition": "", "inclusion": "", "exclusion": "", "example": ""}])
    coded = common.write_csv(p["qual"] / "coded-data" / f"coded-excerpts-{date.today().isoformat()}.csv", coded_rows)
    reliability = common.write_markdown(p["qual"] / "reliability" / f"reliability-{date.today().isoformat()}.md", "Qualitative Reliability", {"复核": "已完成去标识化和分段；主题、信度和结论需由人工编码或复核后填写。"})
    common.log_run(args, "04-qual", "ok", [codebook, coded, reliability], "已真实去标识化和分段，不伪造主题结论。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
