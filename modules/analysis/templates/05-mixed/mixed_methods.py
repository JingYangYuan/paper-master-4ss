#!/usr/bin/env python3
"""Build a mixed-methods joint display from real quantitative and qualitative products."""

from __future__ import annotations

import argparse
import csv
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


def read_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


def main() -> int:
    parser = common.add_common_args(argparse.ArgumentParser(description=__doc__))
    args = parser.parse_args()
    p = common.paths(args.out_root)
    table2 = p["tables"] / "table2-main-regression.csv"
    coded_files = sorted((p["qual"] / "coded-data").glob("coded-excerpts-*.csv"))
    coded = read_rows(coded_files[-1])
    themes = sorted({r.get("code", "") for r in coded if r.get("code")}) or ["待人工编码主题"]
    rows = []
    for theme in themes:
        rows.append({"quant_finding": str(table2), "qual_theme": theme, "integration": "待基于真实系数方向和编码摘录撰写整合解释", "claim_status": "pending-review"})
    joint = common.write_csv(p["tables"] / "mixed-joint-display.csv", rows)
    report = common.write_markdown(p["reports"] / f"mixed-methods-integration-{date.today().isoformat()}.md", "Mixed Methods Integration", {"joint display": str(joint), "说明": "本脚本只整合真实产物，不生成未经编码支持的主题结论。"})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
