#!/usr/bin/env python3
"""Aggregate real regression products without re-estimating models."""

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

REQUIRED = [
    "data/analysis-data.csv",
    "data/variable-dictionary.csv",
    "tables/sample-flow.csv",
    "tables/table1-descriptives.csv",
    "tables/table2-main-regression.csv",
    "tables/table3-nonlinear-marginal-effects.csv",
    "tables/table3-mechanism-mediation-moderation.csv",
    "tables/table4-heterogeneity-threshold-nonlinear.csv",
    "tables/tableA1-causal-robustness.csv",
]


def main() -> int:
    parser = common.add_common_args(argparse.ArgumentParser(description=__doc__))
    args = parser.parse_args()
    p = common.paths(args.out_root)
    missing = [x for x in REQUIRED if not (p["root"] / x).exists()]
    script_index = common.script_index(args.out_root, [
        "00-plan-dispatch", "01-main-models", "02-nonlinear", "03-panel",
        "04-causal", "05-mechanism-heterogeneity", "06-robustness", "07-regression-export",
    ])
    fig_index = common.write_markdown(p["reports"] / "figure-index.md", "Figure Index", {"图形": "\n".join(str(x.relative_to(p["root"])) for x in p["figures"].glob("*")) or "未发现图形。"})
    missing_report = common.write_markdown(p["reports"] / "missing-regression-products.md", "Missing Regression Products", {"缺失产物": "\n".join(f"- {x}" for x in missing) or "无缺失产物。"})
    results = common.write_markdown(
        p["reports"] / f"regression-results-{date.today().isoformat()}.md",
        "Regression Results",
        {"可声称内容": "只声称 run-log 记录且产物存在的模型结果。", "缺失或阻断": "\n".join(f"- {x}" for x in missing) or "无缺失产物。"},
    )
    common.log_run(args, "03-regression/07-regression-export", "ok" if not missing else "partial", [script_index, fig_index, missing_report, results], "未重新估计模型。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
