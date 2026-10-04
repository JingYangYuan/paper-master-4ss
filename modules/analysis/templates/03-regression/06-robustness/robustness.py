#!/usr/bin/env python3
"""Robustness: inference (wild bootstrap, multiplicity) and alternatives."""

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

    # 表A：基准与替代口径
    mods = common.run_robustness(df, roles)
    common.export_regression_table(mods, p["tables"] / "tableA-robustness.csv",
                                   roles.controls, roles.fe, roles.cluster, "Table A Robustness")

    # 表A-inference：wild cluster bootstrap 与多重检验校正
    rows = []
    try:
        wb = common.run_wild_boot_py(df, roles, reps=9999)
        rows.append({"方法": "Wild cluster bootstrap (wildboottest)", "内容": str(getattr(wb, "pvalue", wb))})
    except Exception as exc:
        rows.append({"方法": "Wild cluster bootstrap", "状态": f"未运行：{exc}"})
    try:
        import statsmodels.formula.api as smf

        pvals = []
        names = []
        for v in roles.controls:
            fit = smf.ols(f"{roles.y} ~ {roles.x} + {v}", data=df).fit()
            pvals.append(float(fit.pvalues[roles.x]))
            names.append(v)
        adj = common.run_multiplicity_py(pvals, "holm")
        rows.append({"方法": "多重检验校正（Holm）",
                     "内容": "; ".join(f"{n}: p={pv:.4f} -> adj={a:.4f}" for n, pv, a in zip(names, pvals, adj))})
    except Exception as exc:
        rows.append({"方法": "多重检验校正", "状态": f"未运行：{exc}"})
    common.write_csv(p["tables"] / "tableA-robustness-inference.csv", rows)

    # 表A-sensitivity：Python 不实现 Oster / sensemakr
    common.write_csv(p["tables"] / "tableA-robustness-sensitivity.csv", [
        {"方法": "Oster (psacalc)", "状态": "PyPI 无 sensemakr 等价包；Python 不实现未观测混淆敏感性分析，请使用 Stata 或 R 模板。"},
        {"方法": "sensemakr", "状态": "PyPI 无 sensemakr；Python 不实现，请使用 Stata 或 R 模板。"},
    ])

    # 表A-alternatives：替代样本窗口、聚类层级、缩尾与分位回归
    alt = {"(1) Baseline": common.run_ols(df, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)}
    if roles.time:
        import numpy as np

        med = df[roles.time].median()
        alt["(2) Subsample (recent)"] = common.run_ols(df[df[roles.time] >= med], roles.y, roles.x,
                                                       roles.controls, roles.fe, roles.cluster)
    alt["(3) Cluster by id"] = common.run_ols(df, roles.y, roles.x, roles.controls, roles.fe, roles.id)
    alt["(4) No cluster"] = common.run_ols(df, roles.y, roles.x, roles.controls, roles.fe, None)
    import numpy as np

    d = df.copy()
    lo, hi = np.quantile(d[roles.y].dropna(), [0.005, 0.995])
    d[roles.y] = d[roles.y].clip(lo, hi)
    alt["(5) Winsorised"] = common.run_ols(d, roles.y, roles.x, roles.controls, roles.fe, roles.cluster)
    try:
        import statsmodels.formula.api as smf

        qr = smf.quantreg(f"{roles.y} ~ {roles.x} + {' + '.join(roles.controls)}", data=df).fit(q=0.5)
        alt["(6) Quantile 0.5"] = qr
    except Exception:
        pass
    common.export_regression_table(alt, p["tables"] / "tableA-robustness-alternatives.csv",
                                   roles.controls, roles.fe, roles.cluster, "Table A Robustness Alternatives")

    common.write_markdown(p["reports"] / "cannot-claim-list.md", "Cannot Claim List", {
        "不可声称": "未在本脚本中成功运行的替代变量、替代样本、安慰剂和敏感性分析，不得写入结论。",
        "已运行": "、".join(alt.keys()),
        "Python 生态差异": "Python 不提供 Oster/sensemakr 敏感性分析；多重检验用 statsmodels 的 Holm/BH 校正，不得声称与 Stata 的 Romano-Wolf/Westfall-Young 结果一致。",
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
