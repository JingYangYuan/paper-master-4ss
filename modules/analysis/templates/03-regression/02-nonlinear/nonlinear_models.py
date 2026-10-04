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
    df = common.load_data(data_path)
    roles = common.infer_roles(df, args.dict_path or p["data"] / "variable-dictionary.csv")
    models = {}
    for name, fn in [("Logit AME", common.run_logit), ("Probit AME", common.run_probit)]:
        models[name] = fn(df, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)
    models["Poisson ME"] = common.run_poisson(df, roles.y, roles.x, roles.controls, roles.fe)
    table = common.export_marginal_effects(models, p["tables"] / "table3-nonlinear-marginal-effects.csv")
    summary = common.export_model_summary(p["reports"] / "nonlinear-models-results.md", models, "Nonlinear Models Results")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
