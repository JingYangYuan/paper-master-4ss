#!/usr/bin/env python3
"""Run descriptives, baseline OLS, fixed effects, and diagnostics."""

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
    data_path = Path(args.data) if args.data else p["data"] / "analysis-data.csv"
    if not data_path.exists():
        common.log_run(args, "03-regression/01-main-models", "blocked", [], f"缺少数据：{data_path}")
        return 2
    df = common.load_data(data_path)
    roles = common.infer_roles(df, args.dict_path or p["data"] / "variable-dictionary.csv")
    table1 = common.describe_data(df, [roles.y, roles.x, *roles.controls], args.out_root)
    models = {
        "(1)": common.run_ols(df, roles.y, roles.x, [], [], roles.cluster),
        "(2)": common.run_ols(df, roles.y, roles.x, roles.controls, [], roles.cluster),
        "(3)": common.run_ols(df, roles.y, roles.x, roles.controls, roles.fe, roles.cluster),
    }
    table2 = common.export_regression_table(models, p["tables"] / "table2-main-regression.csv", roles.controls, roles.fe, roles.cluster, "Table 2 Main Regression")
    summary = common.export_model_summary(p["reports"] / "main-models-results.md", models, "Main Models Results")
    decision = common.write_markdown(
        p["reports"] / f"model-decision-{date.today().isoformat()}.md",
        "Model Decision",
        {"主模型": "逐步 OLS：M1 仅 X，M2 加控制变量，M3 加固定效应。", "标准误": f"cluster={roles.cluster or 'HC1'}", "变量角色": str(roles)},
    )
    common.log_run(args, "03-regression/01-main-models", "ok", [table1, table2, summary, decision], "已真实估计主回归。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
