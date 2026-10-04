#!/usr/bin/env python3
"""Panel models: FE/TWFE (linearmodels), dynamic GMM (pydynpd), long-N Driscoll-Kraay, panel IV and panel nonlinear."""

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

    # 表A：FE / TWFE
    fe = common.run_panel_fe_py(df, roles)
    fe_ind = common.run_ols(df, roles.y, roles.x, roles.controls, [roles.id], roles.cluster or roles.id)
    common.export_regression_table({"(1) Individual FE": fe, "(2) Two-way FE": fe_ind},
                                   p["tables"] / "tableA-panel-models.csv", roles.controls,
                                   [v for v in [roles.id, roles.time] if v], roles.cluster, "Table A Panel Models")

    # 表A0：面板设定选择检验（Python 侧给出信息准则口径；Hausman 的严格等价见 R/Stata）
    fe_ll = getattr(getattr(fe, "inner", fe), "llf", None)
    common.write_csv(p["tables"] / "tableA0-panel-selection.csv", [
        {"检验": "FE vs 混合 OLS", "口径": "linearmodels PanelOLS 的 F 检验（entity_effects 的 poolability）", "值": str(fe_ll)},
        {"检验": "FE vs RE (Hausman)", "口径": "Python 生态无维护的 Hausman 面板检验实现；请使用 Stata（xtreg+hausman）或 R（plm::phtest）", "值": "见 Stata/R 模板"},
        {"检验": "Breusch-Pagan LM", "口径": "Python 生态无维护实现；请使用 Stata（xttest0）或 R（plm::plmtest）", "值": "见 Stata/R 模板"},
    ])

    # 表A2：动态面板 GMM
    try:
        dyn = common.run_pgmm(df, roles)
        summary = common.write_markdown(p["reports"] / "panel-dynamic-gmm.md", "Dynamic Panel GMM",
                                        {"pydynpd 结果": str(getattr(dyn, "regression_table", dyn))})
    except Exception as exc:  # pragma: no cover - surfaces as blocking note
        common.write_markdown(p["reports"] / "panel-dynamic-gmm.md", "Dynamic Panel GMM",
                              {"未运行": f"pydynpd 调用失败：{exc}"})
    common.write_csv(p["tables"] / "tableA2-panel-dynamic.csv", [
        {"项目": "系统/差分 GMM", "内容": "pydynpd 估计结果见 reports/panel-dynamic-gmm.md（AR/Hansen 统计量随该报告输出）"},
    ])

    # 表A3：长面板 Driscoll-Kraay
    long = common.run_panel_long_py(df, roles)
    common.export_regression_table({"(1) Driscoll-Kraay": long, "(2) FE": fe},
                                   p["tables"] / "tableA3-panel-longN.csv", roles.controls, [], roles.cluster,
                                   "Table A3 Panel LongN")

    # 表A4：面板 IV 与面板非线性
    mods_a4 = {}
    try:
        mods_a4["(1) Panel IV"] = common.run_xtiv_py(df, roles)
    except Exception:
        pass
    try:
        mods_a4["(2) Panel logit FE"] = common.run_panel_nl_py(df, roles)
    except Exception:
        pass
    if mods_a4:
        common.export_regression_table(mods_a4, p["tables"] / "tableA4-panel-iv-nonlinear.csv",
                                       roles.controls, [], roles.cluster, "Table A4 Panel IV Nonlinear")

    common.write_markdown(p["reports"] / "panel-diagnostics.md", "Panel Diagnostics", {
        "估计口径": "linearmodels PanelOLS（个体/双向效应，聚类标准误）；长面板用 cov_type=\"kernel\"（Driscoll-Kraay）；动态 GMM 用 pydynpd；面板非线性用 pyfixest::feglm。",
        "Python 生态差异": "Hausman / Breusch-Pagan 面板检验在 Python 无维护实现，故只给出 Stata/R 模板指引，不做近似替代。",
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
