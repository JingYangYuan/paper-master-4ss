#!/usr/bin/env python3
"""Lightweight index for Paper Analysis 4SS Python templates.

The implementation templates now live under flow/subflow directories. This
file is kept as a migration entrypoint and does not run cleaning, regression,
causal identification, or export logic directly.
"""

from __future__ import annotations

import argparse
from pathlib import Path


TEMPLATES = [
    "01-init/init.py",
    "02-clean-describe/cleaning.py",
    "03-regression/00-plan-dispatch/plan_dispatch.py",
    "03-regression/01-main-models/main_models.py",
    "03-regression/02-nonlinear/nonlinear_models.py",
    "03-regression/03-panel/panel_models.py",
    "03-regression/04-causal/causal_models.py",
    "03-regression/05-mechanism-heterogeneity/mechanism_heterogeneity.py",
    "03-regression/06-robustness/robustness.py",
    "03-regression/07-regression-export/regression_export.py",
    "04-qual/qual_analysis.py",
    "05-mixed/mixed_methods.py",
    "06-export/export_quality.py",
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true", help="List Python flow templates.")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    print("Paper Analysis 4SS Python templates are split by flow/subflow:")
    for item in TEMPLATES:
        print(f"- {root / item}")
    if not args.list:
        print("\nRun a concrete subflow script with --help, then copy/adapt it into paper-workspace/04-analysis/scripts/.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
