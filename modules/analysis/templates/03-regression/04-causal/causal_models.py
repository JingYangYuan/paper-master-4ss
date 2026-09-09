#!/usr/bin/env python3
"""Run configured causal identification strategies."""

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
        common.log_run(args, "03-regression/04-causal", "blocked", [], f"缺少数据：{data_path}")
        return 2
    df = common.load_data(data_path)
    roles = common.infer_roles(df, args.dict_path or p["data"] / "variable-dictionary.csv")
    models = {}
    blockers = []
    for name, fn in [("IV/2SLS", common.run_iv_2sls), ("DID/TWFE", common.run_twfe_did), ("RDD", common.run_parametric_rdd), ("IPW", common.run_ipw_ate)]:
        try:
            models[name] = fn(df, roles)
        except Exception as exc:
            blockers.append(f"{name}: {exc}")
    if not models:
        report = common.write_markdown(p["reports"] / "causal-blockers.md", "Causal Blockers", {"阻断": "\n".join(blockers)})
        common.log_run(args, "03-regression/04-causal", "blocked", [report], "没有可执行的识别策略。")
        return 2
    table = common.export_regression_table(models, p["tables"] / "tableA1-causal-robustness.csv", roles.controls, roles.fe, roles.cluster, "Table A1 Causal Robustness")
    summary = common.export_model_summary(p["reports"] / "causal-results.md", models, "Causal Results")
    balance = common.write_csv(p["tables"] / "matching-balance.csv", [{"method": "IPW/PSM/CEM", "status": "若 IPW 成功，权重回归已纳入 tableA1；PSM/CEM 需按项目依赖扩展。"}])
    common.log_run(args, "03-regression/04-causal", "ok", [table, summary, balance], "已运行可配置的 IV/DID/RDD/IPW。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
