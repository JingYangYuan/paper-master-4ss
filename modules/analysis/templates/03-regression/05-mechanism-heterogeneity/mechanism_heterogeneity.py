#!/usr/bin/env python3
"""Run mediation, mechanism, moderation, and heterogeneity tests."""

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
    mech_models = {}
    mech_models.update({f"mediation_{k}": v for k, v in common.run_mediation_baron_kenny(df, roles).items()})
    mech_models["moderation_interaction"] = common.run_interaction(df, roles)
    het_models = {}
    het_models.update(common.run_group_models(df, roles))
    if mech_models:
        common.export_regression_table(mech_models, p["tables"] / "table3-mechanism-mediation-moderation.csv", roles.controls, roles.fe, roles.cluster, "Table 3 Mechanism Mediation Moderation")
        common.export_model_summary(p["reports"] / "mechanism-results.md", mech_models, "Mechanism Results")
    if het_models:
        common.export_regression_table(het_models, p["tables"] / "table4-heterogeneity-threshold-nonlinear.csv", roles.controls, roles.fe, roles.cluster, "Table 4 Heterogeneity Threshold Nonlinear")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
