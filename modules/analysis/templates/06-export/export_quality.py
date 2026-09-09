#!/usr/bin/env python3
"""Export the analysis package and enforce quality gates."""

from __future__ import annotations

import argparse
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


def main() -> int:
    parser = common.add_common_args(argparse.ArgumentParser(description=__doc__))
    args = parser.parse_args()
    p = common.paths(args.out_root)
    required = [
        p["data"] / "analysis-data.csv",
        p["data"] / "variable-dictionary.csv",
        p["tables"] / "sample-flow.csv",
        p["tables"] / "table1-descriptives.csv",
        p["tables"] / "table2-main-regression.csv",
        common.run_log_path(args),
    ]
    missing = [str(x) for x in required if not x.exists()]
    report = common.write_markdown(
        p["reports"] / f"analysis-quality-gates-{date.today().isoformat()}.md",
        "Analysis Quality Gates",
        {
            "通过": "所有核心产物存在。" if not missing else "部分产物缺失。",
            "缺失": "\n".join(f"- {x}" for x in missing) or "无",
            "结论边界": "只有 run-log 记录为 ok 且产物存在的结果可以进入论文结论。",
        },
    )
    common.log_run(args, "06-export", "ok" if not missing else "partial", [report], "已执行质量门控。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
