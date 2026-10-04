#!/usr/bin/env python3
"""Causal identification: IV, event study, CS-DID, RD, PSM/IPW, SCM."""

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

    # 表A1：主结果
    mods = {
        "IV/2SLS": common.run_iv(df, roles),
        "DID/TWFE": common.run_twfe_did(df, roles),
    }
    common.export_regression_table(mods, p["tables"] / "tableA1-causal-robustness.csv",
                                   roles.controls, roles.fe, roles.cluster, "Table A1 Causal Robustness")

    # 表A1a：IV 诊断
    iv = mods["IV/2SLS"]
    diag = getattr(iv, "_pa_first_stage", None)
    rows = [{"诊断项": "第一阶段", "内容": "见 reports/causal-results.md 的 first stage 摘要" if diag is not None else "linearmodels 未返回第一阶段对象"}]
    try:
        fs = getattr(getattr(iv, "first_stage", None), "diagnostics", None)
        if fs is not None:
            rows.append({"诊断项": "Weak instruments / Wu-Hausman", "内容": str(fs)})
    except Exception:
        pass
    common.write_csv(p["tables"] / "tableA1a-iv-diagnostics.csv", rows)

    # 表A1b：事件研究
    es = None
    try:
        es = common.run_event_study_py(df, roles)
        common.export_regression_table({"Sun-Abraham event study": es},
                                       p["tables"] / "tableA1b-did-event-study.csv", [], [], roles.id,
                                       "Table A1b DID Event Study")
    except Exception as exc:
        common.write_csv(p["tables"] / "tableA1b-did-event-study.csv",
                         [{"项目": "事件研究", "状态": f"未运行：{exc}"}])

    # 表A1c：CS-DID
    cs = None
    try:
        cs = common.run_cs_did_py(df, roles)
        common.write_markdown(p["reports"] / "did-diagnostics.md", "DID Diagnostics",
                              {"Callaway-Sant'Anna": str(cs)})
    except Exception as exc:
        common.write_markdown(p["reports"] / "did-diagnostics.md", "DID Diagnostics",
                              {"Callaway-Sant'Anna": f"未运行：{exc}"})
    common.write_csv(p["tables"] / "tableA1c-did-diagnostics.csv", [
        {"项目": "CS-DID 组-时 ATT", "内容": "见 reports/did-diagnostics.md"},
        {"项目": "Bacon 分解 / honestdid", "内容": "Python 生态无等价实现；请使用 Stata 模板的 bacondecomp 与 honestdid。"},
    ])

    # 表A1d：RDD
    try:
        rd = common.run_rd_py(df, roles, cutoff=roles.cutoff)
        common.write_markdown(p["reports"] / "rd-bandwidths.md", "RD Bandwidth Sensitivity",
                              {"主估计": str(rd)})
        common.write_csv(p["tables"] / "tableA1d-rd.csv", [
            {"项目": "RDD 主估计", "内容": f"coef={rd.coef.iloc[0, 0]:.3f}" if hasattr(rd, "coef") else str(rd)},
        ])
    except Exception as exc:
        common.write_csv(p["tables"] / "tableA1d-rd.csv", [{"项目": "RDD", "状态": f"未运行：{exc}"}])

    # 表A1e：匹配与加权
    psm = ipw = None
    try:
        psm = common.run_psm_py(df, roles)
    except Exception:
        pass
    try:
        ipw = common.run_ipw_py(df, roles)
    except Exception:
        pass
    mods_a1e = {}
    if ipw is not None:
        mods_a1e["IPW"] = ipw
    if mods_a1e:
        common.export_regression_table(mods_a1e, p["tables"] / "tableA1e-matching.csv",
                                       [], [], roles.cluster, "Table A1e Matching")
    bal = [{"方法": "PSM 最近邻", "ATT": f"{psm['att']:.3f}" if psm else "未运行",
            "n_treated": psm["n_treated"] if psm else "",
            "n_control_matched": psm["n_control_matched"] if psm else ""}]
    common.write_csv(p["tables"] / "matching-balance.csv", bal)

    # 表A1f：合成控制
    try:
        scm = common.run_scm_py(df, roles)
        common.write_csv(p["tables"] / "tableA1f-scm.csv", [
            {"项目": "合成控制 RMSPE", "内容": str(scm.get("loss"))},
        ])
    except Exception as exc:
        common.write_csv(p["tables"] / "tableA1f-scm.csv", [{"项目": "合成控制", "状态": f"未运行：{exc}"}])

    common.export_model_summary(p["reports"] / "causal-results.md",
                                {k: v for k, v in {**mods, "EventStudy": es}.items() if v is not None},
                                "Causal Results")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
