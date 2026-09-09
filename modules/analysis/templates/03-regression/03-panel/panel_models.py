#!/usr/bin/env python3
"""Run panel fixed-effect style models after id/time roles are confirmed."""

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
        common.log_run(args, "03-regression/03-panel", "blocked", [], f"缺少数据：{data_path}")
        return 2
    df = common.load_data(data_path)
    roles = common.infer_roles(df, args.dict_path or p["data"] / "variable-dictionary.csv")
    if not roles.id or not roles.time or roles.id not in df.columns or roles.time not in df.columns:
        report = common.write_markdown(p["reports"] / "panel-diagnostics.md", "Panel Diagnostics", {"阻断": "缺少 id/time 角色；不得猜测面板结构。"})
        common.log_run(args, "03-regression/03-panel", "blocked", [report], "缺少 id/time。")
        return 2
    model = common.run_panel_fe(df, roles)
    table = common.export_regression_table({"(1) TWFE": model}, p["tables"] / "tableA-panel-models.csv", roles.controls, [roles.id, roles.time], roles.cluster or roles.id, "Table A Panel Models")
    summary = common.export_model_summary(p["reports"] / "panel-diagnostics.md", {"twfe": model}, "Panel Diagnostics")
    common.log_run(args, "03-regression/03-panel", "ok", [table, summary], "已真实估计双向固定效应近似模型。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
