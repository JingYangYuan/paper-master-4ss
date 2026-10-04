#!/usr/bin/env python3
"""Nonlinear models and marginal effects.

Python 不实现 Tobit、Heckman/样本选择、面板选择模型（statsmodels 与主流库无维护实现），
故本脚本不包含这些块；相应方法仅由 Stata/R 模板提供。
"""

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


def _diag(p, df, models, roles, y_bin, y_ord, y_multi, y_count, y_prop, y_dur, event):
    import numpy as np

    rows = [["诊断项", "logit", "probit", "ordered logit", "ordered probit", "multinomial", "poisson", "nbreg"]]

    def aic_bic(m):
        inner = getattr(m, "inner", m)
        ll = getattr(inner, "llf", None)
        k = len(common._model_params(m))
        n = common.model_n(m)
        try:
            n = float(n)
        except Exception:
            n = float("nan")
        if ll is None or not np.isfinite(float(ll)):
            return ".", "."
        return f"{-2 * float(ll) + 2 * k:9.3f}", f"{-2 * float(ll) + k * np.log(n):9.3f}" if np.isfinite(n) and n > 0 else "."

    aics, bics = [], []
    for m in models:
        a, b = aic_bic(m)
        aics.append(a)
        bics.append(b)
    rows.append(["AIC"] + aics)
    rows.append(["BIC"] + bics)

    def _pred(m):
        inner = getattr(m, "inner", m)
        for call in (lambda: inner.predict(),
                     lambda: inner.predict(inner.model.exog),
                     lambda: inner.predict(exog=inner.model.exog)):
            try:
                return np.asarray(call(), dtype=float)
            except Exception:
                continue
        return None

    def class_rate(m, y):
        pr = _pred(m)
        if pr is None:
            return "."
        return f"{np.mean((pr >= 0.5) == (y > 0.5)):9.4f}"

    y_bin_values = df[y_bin].to_numpy(dtype=float)
    rows.append(["分类正确率", class_rate(models[0], y_bin_values), class_rate(models[1], y_bin_values), "", "", "", "", ""])

    def auc(m, y):
        pr = _pred(m)
        if pr is None:
            return "."
        r = pr.argsort().argsort() + 1
        n1 = int((y > 0.5).sum())
        n0 = len(y) - n1
        if n1 == 0 or n0 == 0:
            return "."
        return f"{(r[y > 0.5].sum() - n1 * (n1 + 1) / 2) / (n1 * n0):9.4f}"

    rows.append(["AUC", auc(models[0], y_bin_values), "", "", "", "", "", ""])
    rows.append(["注：Python 侧用 statsmodels OrderedModel/MNLogit/NegativeBinomial/GLM 与 lifelines。分类正确率与 AUC 仅对二元模型适用。",
                 "", "", "", "", "", "", ""])
    import csv as _csv

    out_path = p["tables"] / "table3e-nonlinear-diagnostics.csv"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8-sig") as fh:
        _csv.writer(fh).writerows(rows)


def main() -> int:
    parser = common.add_common_args(argparse.ArgumentParser(description=__doc__))
    args = parser.parse_args()
    p = common.paths(args.out_root)
    data_path = Path(args.data) if args.data else p["data"] / "analysis-data.csv"
    df = common.load_data(data_path)
    roles = common.infer_roles(df, args.dict_path or p["data"] / "variable-dictionary.csv")

    y_bin = roles.outcome_bin or roles.y
    y_ord = roles.outcome_ord or roles.y
    y_multi = roles.outcome_multi or roles.y
    y_count = roles.outcome_count or roles.y
    y_prop = roles.prop_outcome or roles.y
    y_dur = roles.duration or roles.y

    # 表3：二元与计数的边际效应
    mods3 = {
        "Logit AME": common.run_logit(df, y_bin, roles.x, roles.controls, roles.fe, roles.cluster),
        "Probit AME": common.run_probit(df, y_bin, roles.x, roles.controls, roles.fe, roles.cluster),
        "Poisson ME": common.run_poisson(df, y_count, roles.x, roles.controls, roles.fe),
    }
    common.export_marginal_effects(mods3, p["tables"] / "table3-nonlinear-marginal-effects.csv")

    # 表3b：有序与多分类
    mods3b = {
        "Ordered logit": common.run_ologit(df, y_ord, roles.x, roles.controls, roles.cluster),
        "Ordered probit": common.run_oprobit(df, y_ord, roles.x, roles.controls, roles.cluster),
        "Multinomial logit": common.run_mlogit(df, y_multi, roles.x, roles.controls, roles.cluster),
    }
    common.export_regression_table(mods3b, p["tables"] / "table3b-ordered-multinomial.csv",
                                   roles.controls, [], roles.cluster, "Table 3b Ordered Multinomial")

    # 表3c：删失与样本选择 —— Python 不实现
    common.write_csv(p["tables"] / "table3c-censored-selection.csv", [
        {"项目": "Tobit / Heckman / IV-Tobit / 内生处理回归",
         "状态": "Python 生态无维护实现（statsmodels 与主流库均缺失），故本语种不提供；请使用 Stata 或 R 模板。"},
    ])

    # 表3d：计数、比例与持续时间
    mods3d = {
        "Negative binomial": common.run_nbreg(df, y_count, roles.x, roles.controls, roles.cluster),
        "Fractional logit": common.run_fracreg(df, y_prop, roles.x, roles.controls, roles.cluster),
        "Duration (lifelines)": common.run_duration(df, y_dur, roles.x, roles.controls, roles.event_flag),
    }
    common.export_regression_table(mods3d, p["tables"] / "table3d-count-fractional-duration.csv",
                                   roles.controls, [], roles.cluster, "Table 3d Count Fractional Duration")

    # 表3e：诊断
    _diag(p, df, list(mods3.values()) + list(mods3b.values()) + [mods3d["Negative binomial"]],
          roles, y_bin, y_ord, y_multi, y_count, y_prop, y_dur, roles.event_flag)

    common.export_model_summary(p["reports"] / "nonlinear-models-results.md",
                                {**mods3, **mods3b, **mods3d}, "Nonlinear Models Results")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
