#!/usr/bin/env python3
"""Aggregate ML subflow outputs into one wide table, a methods-note draft and a not-run list.

本子流程只读表、不重算模型：
  - 宽表把 01/02/03 三家的结果压成同构长表，供 06-export 直接取用；
  - 方法说明草稿把折分方案、超级参数、样本外指标、可声称边界一次写清（C30、C31）；
  - 未执行清单记录哪张表没产出、为什么没产出，保证正文不出现"跑过"的假象。

纪律：表缺就是缺，清单里写原因，不补造数字；列名认不出的表进"未映射"清单交人工，不硬猜。
"""

from __future__ import annotations

import argparse
import csv
import sys
from datetime import date
from pathlib import Path


def _load_common():
    for parent in Path(__file__).resolve().parents:
        shared = parent / "_shared"
        if shared.exists():
            sys.path.insert(0, str(shared))
            import python_common  # type: ignore

            return python_common
    raise RuntimeError("Cannot locate templates/_shared/python_common.py")


common = _load_common()

# 每张表：子流程、方法列（用于宽表"方法或组"）、指标列、样本量列、缺失含义
TABLE_SPEC = {
    "ml-regularization-path.csv": ("01-supervised", "模型", ["惩罚参数", "l1_ratio", "候选特征数", "选中特征数"], "样本量"),
    "ml-model-performance.csv": ("01-supervised", "模型", ["样本外 RMSE", "样本外 MAE", "样本外 R2", "训练集 R2"], "测试样本"),
    "ml-variable-importance.csv": ("01-supervised", "variable", ["置换重要性均值", "标准差"], ""),
    "ml-structure-pca.csv": ("01-supervised", "主成分", ["解释方差比例", "累计解释方差"], ""),
    "ml-structure-cluster.csv": ("01-supervised", "解数K", ["组内平方和", "轮廓系数", "最小组占比"], ""),
    "ml-causal-estimates.csv": ("02-causal-ml", "模型", ["处理变量系数", "标准误", "第一阶段 F", "选中工具变量数"], "观测值"),
    "ml-selected-variables.csv": ("01-supervised", "variable", ["coefficient"], ""),
    "ml-calibration.csv": ("01-supervised", "模型", ["平均预测概率", "实际正例比例"], ""),
    "ml-crossfit-folds.csv": ("02-causal-ml", "折", ["折系数"], "折样本"),
    "ml-gates.csv": ("03-heterogeneity", "GATES 组", ["组平均处理效应", "标准误", "p 值", "CATE 均值"], "组样本"),
    "ml-blp-test.csv": ("03-heterogeneity", "项", ["系数", "标准误", "p 值"], ""),
    "ml-overlap.csv": ("03-heterogeneity", "指标", ["值"], ""),
}

EXPECTED = {
    "01-supervised": ["ml-regularization-path.csv", "ml-model-performance.csv",
                      "ml-variable-importance.csv", "ml-calibration.csv", "ml-selected-variables.csv",
                      "ml-structure-pca.csv", "ml-structure-cluster.csv"],
    "02-causal-ml": ["ml-causal-estimates.csv", "ml-pds-selected-variables.csv", "ml-crossfit-folds.csv"],
    "03-heterogeneity": ["ml-cate.csv", "ml-gates.csv", "ml-blp-test.csv", "ml-overlap.csv"],
}

# 已识别但不进宽表：清单类表没有可比数值指标，硬挤进去只会把“选中了哪个”挤成伪数字
NO_WIDE = {
    "ml-pds-selected-variables.csv": "选中控制变量清单，无数值指标，不进宽表（见 tables 原表）。",
}

BLOCK_HINTS = {
    "ml-calibration.csv": "分类任务未执行或因变量非二元；校准曲线属于二分类专属产出。",
    "ml-crossfit-folds.csv": "DML 未执行（缺处理变量／控制变量或样本不足）。",
    "ml-causal-estimates.csv": "02-causal-ml 未产出任何因果 ML 估计。",
    "ml-gates.csv": "03-heterogeneity 未执行（缺处理变量或异质性变量）。",
    "ml-overlap.csv": "重叠诊断未执行，此时不得给出个体层面的政策建议（C29）。",
    "ml-cate.csv": "CATE 未估计，异质性结论无依据（C29）。",
    "ml-pds-selected-variables.csv": "PDS 未执行（缺处理变量或候选控制变量）。",
}


def _read_table(path: Path):
    import pandas as pd

    try:
        return pd.read_csv(path, encoding="utf-8-sig")
    except Exception:  # noqa: BLE001  某些导出是制表符或 GBK
        try:
            return pd.read_csv(path, encoding="utf-8-sig", sep="\t")
        except Exception:  # noqa: BLE001
            return pd.read_csv(path, encoding="gbk", on_bad_lines="skip")


def _is_num(value) -> bool:
    try:
        float(str(value).replace(",", "").replace("%", ""))
        return True
    except (TypeError, ValueError):
        return False


def _fmt(value) -> str:
    """计数类指标不显示小数，参数类保留四位。"""
    num = float(str(value).replace(",", "").replace("%", ""))
    if abs(num - round(num)) < 1e-9 and abs(num) < 1e7:
        return str(int(round(num)))
    return f"{num:.4f}"


def _task_of(name: str, df) -> str:
    """宽表的任务列：主表带“任务”列则直取，否则从 `<表名>-<任务>.csv` 后缀解析。"""
    if "任务" in df.columns:
        return str(df["任务"].iloc[0]) if len(df) else ""
    stem = name[: -len(".csv")]
    for base in TABLE_SPEC:
        prefix = base[: -len(".csv")] + "-"
        if stem.startswith(prefix):
            return stem[len(prefix):]
    return ""


def run(args) -> int:
    out = common.paths(args.out_root)
    tables_dir = out["tables"]
    if not tables_dir.exists():
        msg = f"没有找到表目录：{tables_dir}；先跑 01/02/03 三个子流程"
        common.write_markdown(out["reports"] / f"ml-blocked-04-ml-export-{date.today()}.md",
                              "ML 执行阻断：04-ml-export", {"阻断原因": msg})
        print(msg, file=sys.stderr)
        return 1

    wide_rows: list[dict] = []
    manifest: list[dict] = []
    unmapped: list[str] = []

    for subflow, files in EXPECTED.items():
        for name in files:
            path = tables_dir / name
            if not path.exists():
                manifest.append({
                    "子流程": subflow, "表": name, "状态": "未产出", "行数": 0,
                    "阻断说明": BLOCK_HINTS.get(name, "上游脚本未生成该表。"),
                })
                continue
            df = _read_table(path)
            manifest.append({"子流程": subflow, "表": name, "状态": "已产出", "行数": len(df),
                             "阻断说明": ""})
            spec = TABLE_SPEC.get(name)
            if name in NO_WIDE:
                manifest[-1]["阻断说明"] = NO_WIDE[name]
                continue
            if name == "ml-cate.csv":
                numeric = _read_table(path)["cate"].map(
                    lambda v: float(str(v).replace(",", "")) if _is_num(v) else None).dropna()
                if len(numeric):
                    for label, value in [("CATE 均值", numeric.mean()), ("CATE 标准差", numeric.std()),
                                         ("CATE P10", numeric.quantile(0.10)), ("CATE P90", numeric.quantile(0.90))]:
                        wide_rows.append({"子流程": "03-heterogeneity", "任务": "cate_forest",
                                          "方法或组": label, "指标": "cate", "数值": _fmt(value),
                                          "样本量": len(numeric), "来源表": name, "备注": "个体 CATE 分布摘要"})
                continue
            if spec is None:
                unmapped.append(f"{name}（{len(df)} 行，列：{', '.join(map(str, df.columns))}）")
                continue
            sub, key_col, metric_cols, n_col = spec
            if key_col not in df.columns:
                unmapped.append(f"{name}（找不到方法列 {key_col}）")
                continue
            task_of = _task_of(name, df)
            has_task_col = "任务" in df.columns
            for _, row in df.iterrows():
                label = str(row.get(key_col, "")).strip()
                row_task = str(row.get("任务", "")).strip() if has_task_col else task_of
                for metric in metric_cols:
                    if metric not in df.columns:
                        continue
                    value = row.get(metric)
                    if not _is_num(value) or str(value).strip() in {"", "nan"}:
                        continue
                    wide_rows.append({
                        "子流程": sub, "任务": row_task, "方法或组": label, "指标": metric,
                        "数值": _fmt(value),
                        "样本量": row.get(n_col, "") if n_col else "",
                        "来源表": name,
                        "备注": str(row.get("备注", "")).strip()[:60],
                    })

    if not wide_rows:
        msg = "所有候选表都没有可识别的数值列，宽表为空；请人工核对表头（见未映射清单）。"
        common.write_markdown(out["reports"] / f"ml-blocked-04-ml-export-{date.today()}.md",
                              "ML 执行阻断：04-ml-export", {"阻断原因": msg, "未映射表": "；".join(unmapped)})
        print(msg, file=sys.stderr)
        return 1

    common.write_csv(tables_dir / "ml-wide-table.csv", wide_rows, list(wide_rows[0].keys()))
    common.write_csv(tables_dir / "ml-run-manifest.csv", manifest, list(manifest[0].keys()))

    done = [m for m in manifest if m["状态"] == "已产出"]
    missing = [m for m in manifest if m["状态"] == "未产出"]

    # 未执行清单：表格契约要求落盘，否则正文里“没跑哪几张表”无从核对
    not_run = tables_dir / "ml-not-run-list.csv"
    with open(not_run, "w", encoding="utf-8-sig", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["子流程", "表", "阻断说明"])
        for item in missing:
            writer.writerow([item["子流程"], item["表"], item["阻断说明"]])

    # 方法说明草稿：给正文"研究设计—模型—稳健性"三段直接可抄的骨架
    note_path = out["reports"] / "ml-methods-note.md"
    sections = {
        "任务定义与进入理由": (
            "说明本文为何需要 ML：预测／分类本身是研究目的，或经典方法在高维非线性下失效，"
            "或在识别框架内部用 ML 补薄弱环节（挑控制变量、挑工具变量、估异质性）。"
            "只写实际执行过的任务，理由见 references/ml-causal-ml-methods.md §2、§10（C24）。"
        ),
        "折分与防泄漏": (
            f"训练／验证／测试的划分方式与随机种子记录在 reports 下的执行摘要中（种子口径见 scripts 参数）。"
            "所有预处理（标准化、插补、编码、特征选择）只在训练折内拟合，测试集只用一次（C26）。"
        ),
        "模型与超级参数": "；".join(dict.fromkeys(
            r["方法或组"] for r in wide_rows
            if r["来源表"] in {"ml-regularization-path.csv", "ml-model-performance.csv"}))
            or "未执行监督学习任务。",
        "样本外表现": "见 tables/ml-model-performance.csv；报告 RMSE／MAE／R² 时同时给出训练集与测试集，"
                     "差距过大说明过拟合（C27）。",
        "因果 ML 口径": "PDS／DML 的估计值须与基准 OLS 并表，正交化对象与交叉拟合折数写清；"
                      "折间系数波动过大时不得当作稳健结论（C28）。",
        "异质性与重叠": "GATES 报分位组平均效应，BLP 报异质性信号检验；重叠不足时只能报组间差异，"
                     "不得给个体政策建议（C29）。",
        "可声称边界": "预测精度不等于因果效应；ML 校正了正则化偏误，不解决遗漏变量与识别假设（C30）。",
        "未执行与阻断": "；".join(f"{m['表']}：{m['阻断说明']}" for m in missing) or "无。",
        "引用与依据": "方法依据见 references/ml-causal-ml-methods.md：§3 目标差异与纪律、§4 特征工程与元指标、"
                    "§10 因果 ML、§11 异质性与政策靶向。",
    }
    common.write_markdown(note_path, "ML 方法说明草稿", sections)

    summary = {
        "运行口径": f"只读 {tables_dir}；已产出表 {len(done)} 张，缺失 {len(missing)} 张。",
        "宽表": f"tables/ml-wide-table.csv（{len(wide_rows)} 行长表）。",
        "清单": "tables/ml-run-manifest.csv。",
        "方法说明": "reports/ml-methods-note.md（草稿，进 06-export 前人工核对口径）。",
        "缺失与阻断": "；".join(f"{m['表']}（{m['阻断说明']}）" for m in missing) or "无。",
        "未映射表": "；".join(unmapped) if unmapped else "无。",
        "不得声称": "缺失的表对应的结论一律不得写入正文；宽表里的数字只能原样引用，不做四舍五入美化。",
    }
    common.write_markdown(out["reports"] / f"ml-run-04-ml-export-{date.today()}.md",
                          "ML 执行摘要：04-ml-export", summary)
    print(f"[07-ml/04-ml-export] 完成：宽表 {len(wide_rows)} 行；缺失 {len(missing)} 张；未映射 {len(unmapped)} 张")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="ML export aggregator (paper-analysis-4ss / 07-ml)")
    common.add_common_args(parser)
    args = parser.parse_args()
    return run(args)


if __name__ == "__main__":
    raise SystemExit(main())
