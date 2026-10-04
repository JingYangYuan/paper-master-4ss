#!/usr/bin/env python3
"""Spatial models: weights, Moran's I, spatial cross-section and panel, effects."""

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

    if not roles.lat or not roles.lon:
        raise ValueError("spatial 子流程需要 lat/lon 变量角色")

    # 表S1：权重矩阵与全局 Moran's I
    mo = common.run_moran_py(df, roles)
    unit = "pid" if "pid" in df.columns else roles.id
    n_units = int(df[unit].nunique())
    neigh = mo["weights"].s0 / n_units if n_units else float("nan")
    common.write_csv(p["tables"] / "tableS1-spatial-weights.csv", [
        {"项目": "权重矩阵类型", "内容": "K 近邻（libpysal KNN, k=5）+ 行标准化"},
        {"项目": "空间单元数", "内容": str(n_units)},
        {"项目": "平均邻居数", "内容": f"{neigh:.2f}"},
        {"项目": "全局 Moran's I", "内容": f"{mo['I']:.4f}"},
        {"项目": "Moran's I p 值", "内容": f"{mo['p']:.4f}"},
        {"项目": "坐标系统", "内容": "平面坐标（不依赖 geopandas/sf；如需地理坐标请改用公里距离阈值）"},
    ])

    # 表S2：截面空间回归
    rows = []
    for m in ("lag", "error"):
        try:
            res = common.run_spatial_py(df, roles, model=m)
            beta = res["coef"]
            rows.append({"模型": "SAR (lag)" if m == "lag" else "SEM (error)",
                         "系数": ", ".join(f"{b:.4f}" for b in beta),
                         "N": str(res["n"])})
        except Exception as exc:
            rows.append({"模型": m, "状态": f"未运行：{exc}"})
    common.write_csv(p["tables"] / "tableS2-spatial-cross-section.csv", rows)

    # 表S3：面板空间回归
    try:
        pan = common.run_spatial_panel_py(df, roles, model="lag")
        common.write_csv(p["tables"] / "tableS3-spatial-panel.csv", [
            {"模型": "Panel FE SAR", "系数": ", ".join(f"{b:.4f}" for b in pan["coef"]), "N": str(pan["n"])},
        ])
    except Exception as exc:
        common.write_csv(p["tables"] / "tableS3-spatial-panel.csv", [{"模型": "Panel FE SAR", "状态": f"未运行：{exc}"}])

    # 表S3b：效应分解
    common.write_csv(p["tables"] / "tableS3b-spatial-effects.csv", [
        {"效应": "直接效应", "内容": "spreg 的 betas 首项为核心解释变量系数；直接/间接分解见 Stata 模板的 margins predict(direct/indirect/total)。"},
        {"效应": "间接效应（空间溢出）", "内容": "Python 侧不提供 rho 的非线性效应分解等价实现，请使用 Stata 模板。"},
        {"效应": "总效应", "内容": "见 Stata 模板 tableS3b-spatial-effects.csv。"},
    ])

    # 空间诊断报告
    common.write_markdown(p["reports"] / "spatial-diagnostics.md", "Spatial Diagnostics", {
        "权重矩阵来源": "K 近邻（k=5）由坐标 lat/lon 直接构造（libpysal KNN），行标准化；不依赖 geopandas/sf。",
        "坐标单位": "按平面坐标处理。若原始为经纬度，应改用公里距离阈值构造邻接。",
        "Moran's I 结论": f"全局 Moran's I = {mo['I']:.4f}，p = {mo['p']:.4f}。p<0.05 表示存在显著空间自相关，应使用空间回归而非普通 OLS。",
        "直接/间接/总效应解释": "直接效应为本单元 X 变动对本单元 Y 的影响；间接效应（空间溢出）为经权重矩阵传导到其他单元的影响；总效应为两者之和。三者含空间滞后反馈项，不等同于非空间模型系数。",
        "Python 生态差异": "Python 侧的效应分解以 spreg 的系数口径为主；rho 的非线性分解与 stata 的 margins predict(direct/indirect/total) 不完全等价，表注必须标明所用软件。",
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
