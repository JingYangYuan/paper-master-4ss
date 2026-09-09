#!/usr/bin/env python3
"""Run nonlinear models and export marginal effects/predicted-probability evidence."""

from __future__ import annotations

import argparse
import sys
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
        common.log_run(args, "03-regression/02-nonlinear", "blocked", [], f"缺少数据：{data_path}")
        return 2
    df = common.load_data(data_path)
    roles = common.infer_roles(df, args.dict_path or p["data"] / "variable-dictionary.csv")
    models = {}
    y_values = set(df[roles.y].dropna().unique()) if roles.y in df.columns else set()
    blockers = []
    if y_values and y_values.issubset({0, 1, 0.0, 1.0}):
        for name, fn in [("Logit AME", common.run_logit), ("Probit AME", common.run_probit)]:
            try:
                models[name] = fn(df, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)
            except Exception as exc:
                blockers.append(f"{name}: {exc}")
    try:
        if df[roles.y].dropna().min() >= 0:
            models["Poisson ME"] = common.run_poisson(df, roles.y, roles.x, roles.controls, roles.fe)
    except Exception as exc:
        blockers.append(f"Poisson: {exc}")
    if not models:
        report = common.write_markdown(p["reports"] / "nonlinear-blockers.md", "Nonlinear Blockers", {"阻断": "\n".join(blockers) or "因变量类型不适合已配置的非线性模型。"})
        common.log_run(args, "03-regression/02-nonlinear", "blocked", [report], "未能估计非线性模型。")
        return 2
    table = common.export_marginal_effects(models, p["tables"] / "table3-nonlinear-marginal-effects.csv")
    summary = common.export_model_summary(p["reports"] / "nonlinear-models-results.md", models, "Nonlinear Models Results")
    common.log_run(args, "03-regression/02-nonlinear", "ok", [table, summary], "已真实估计非线性模型，并导出边际效应。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
