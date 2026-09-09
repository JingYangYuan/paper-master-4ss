#!/usr/bin/env python3
"""Run explicitly configured robustness checks."""

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
        common.log_run(args, "03-regression/06-robustness", "blocked", [], f"缺少数据：{data_path}")
        return 2
    df = common.load_data(data_path)
    roles = common.infer_roles(df, args.dict_path or p["data"] / "variable-dictionary.csv")
    models = common.run_robustness(df, roles)
    table = common.export_regression_table(models, p["tables"] / "tableA-robustness.csv", roles.controls, roles.fe, roles.cluster, "Table A Robustness")
    cannot = common.write_markdown(p["reports"] / "cannot-claim-list.md", "Cannot Claim List", {"不可声称": "未在本脚本中成功运行的替代变量、替代样本、安慰剂和敏感性分析，不得写入结论。"})
    common.log_run(args, "03-regression/06-robustness", "ok", [table, cannot], "已真实运行基线稳健性变体。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
