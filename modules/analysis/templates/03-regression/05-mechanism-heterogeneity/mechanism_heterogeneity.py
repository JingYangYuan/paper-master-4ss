#!/usr/bin/env python3
"""Mechanism (Jiang Ting two-step), mediation robustness, moderation, group difference and threshold grid."""

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

    # 表3：机制（江艇两步法）与调节；列序与 Stata 完全一致
    mech = common.run_mediation(df, roles)
    mods: dict = {"mech_step1": mech["total"], "mech_m1": mech["path_a"]}
    if "mediator2" in df.columns:
        mods["mech_m2"] = common.run_ols(df, "mediator2", roles.x, roles.controls, roles.fe, roles.cluster)
    mods["mod_omitted"] = common.run_interaction(df, roles)
    df["_cX"] = df[roles.x] - df[roles.x].mean()
    if roles.moderator:
        df["_cMOD"] = df[roles.moderator] - df[roles.moderator].mean()
        df["_cJC"] = df["_cX"] * df["_cMOD"]
        mods["mod_corrected"] = common.run_ols(df, roles.y, roles.moderator, [roles.x, "_cJC", *roles.controls], roles.fe, roles.cluster)
        mods["mod_centered"] = common.run_ols(df, roles.y, "_cJC", [roles.x, roles.moderator, *roles.controls], roles.fe, roles.cluster)
    common.export_regression_table(mods, p["tables"] / "table3-mechanism-mediation-moderation.csv",
                                   roles.controls, roles.fe, roles.cluster, "Table 3 Mechanism Mediation Moderation")

    # 表3s：中介稳健性（间接效应仅作补充证据）
    ind = mech["indirect_boot"]
    total_x = common._model_params(mech["total"]).get(roles.x, float("nan"))
    path_a_x = common._model_params(mech["path_a"]).get(roles.x, float("nan"))
    common.write_csv(p["tables"] / "table3s-mediation-robustness.csv", [
        {"方法": "江艇两步法 第一步 X→Y", "内容": f"系数 {total_x:.3f}", "说明": "主识别口径"},
        {"方法": "江艇两步法 第二步 X→M", "内容": f"系数 {path_a_x:.3f}", "说明": "主识别口径"},
        {"方法": "间接效应 bootstrap（补充证据）",
         "内容": f"点估计 {ind['estimate']:.4f}，95% CI [{ind['ci_low']:.4f}, {ind['ci_high']:.4f}]，reps={ind['reps']}",
         "说明": "间接效应为补充证据，主识别为江艇两步法；不得据此声称因果中介"},
    ])

    # 表4：异质性分组
    if roles.heterogeneity:
        groups = sorted(df[roles.heterogeneity].dropna().unique())
        hmods = {}
        for g in groups:
            sub = df[df[roles.heterogeneity] == g]
            if len(sub) > len(roles.controls) + 8:
                hmods[f"{roles.heterogeneity}={g}"] = common.run_ols(sub, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)
        if hmods:
            common.export_regression_table(hmods, p["tables"] / "table4-heterogeneity-threshold-nonlinear.csv",
                                           roles.controls, roles.fe, roles.cluster, "Table 4 Heterogeneity")

    # 表4b：组间系数差异（交互项 + Wald 检验）
    if roles.heterogeneity:
        d = df.copy()
        d["_g1"] = (d[roles.heterogeneity] == d[roles.heterogeneity].max()).astype(int)
        d["_xg"] = d[roles.x] * d["_g1"]
        gd = common.run_ols(d, roles.y, "_xg", [roles.x, "_g1", *roles.controls], roles.fe, roles.cluster)
        common.export_regression_table({"Group interaction": gd}, p["tables"] / "table4b-group-difference.csv",
                                       roles.controls, roles.fe, roles.cluster, "Table 4b Group Difference")
        params = common._model_params(gd)
        pvals = getattr(gd, "pvalues", None)
        wald_p = float(pvals["_xg"]) if pvals is not None and "_xg" in pvals else float("nan")
        rows = [{"交互项 _xg 系数": f"{params.get('_xg', float('nan')):.4f}", "p 值": f"{wald_p:.4f}"}]
        common.write_csv(p["tables"] / "table4b-group-difference-wald.csv", rows)

    # 表4c：门槛网格
    risk = "riskvar" if "riskvar" in df.columns else None
    if risk:
        thr_mods = {}
        for q in (0.2, 0.4, 0.6, 0.8):
            thr = df[risk].quantile(q)
            lo = df[df[risk] <= thr]
            hi = df[df[risk] > thr]
            if len(lo) > len(roles.controls) + 8:
                thr_mods[f"p{int(q * 100)}_low"] = common.run_ols(lo, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)
            if len(hi) > len(roles.controls) + 8:
                thr_mods[f"p{int(q * 100)}_high"] = common.run_ols(hi, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)
        if thr_mods:
            common.export_regression_table(thr_mods, p["tables"] / "table4c-threshold-grid.csv",
                                           roles.controls, roles.fe, roles.cluster, "Table 4c Threshold Grid")

    common.export_model_summary(p["reports"] / "mechanism-results.md", mods, "Mechanism Results")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
