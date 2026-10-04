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
    df = common.load_data(data_path)
    roles = common.infer_roles(df, args.dict_path or p["data"] / "variable-dictionary.csv")
    model = common.run_panel_fe(df, roles)
    table = common.export_regression_table({"(1) TWFE": model}, p["tables"] / "tableA-panel-models.csv", roles.controls, [roles.id, roles.time], roles.cluster or roles.id, "Table A Panel Models")
    summary = common.export_model_summary(p["reports"] / "panel-diagnostics.md", {"twfe": model}, "Panel Diagnostics")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
