#!/usr/bin/env python3
"""Read analysis-execution-plan and create regression dispatch files."""

from __future__ import annotations

import argparse
import csv
import re
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

TASK_RULES = {
    "main": ["Y", "X", "control", "fe", "cluster", "weight", "主回归", "描述统计"],
    "nonlinear": ["nonlinear", "logit", "probit", "poisson", "tobit", "heckman", "有序", "多分类"],
    "panel": ["id", "time", "panel", "FE", "RE", "Hausman", "面板"],
    "causal": ["instrument", "treatment", "post", "running", "cutoff", "IV", "DID", "RDD", "PSM", "CEM", "IPW", "SCM"],
    "mechanism_heterogeneity": ["mediator", "mechanism", "moderator", "heterogeneity", "threshold", "中介", "机制", "调节", "异质性", "门槛", "交互", "分组"],
    "robustness": ["robustness", "placebo", "sensitivity", "替代变量", "替代样本", "替代模型", "稳健性", "安慰剂"],
}


def infer_tasks(text: str) -> list[dict[str, str]]:
    rows = []
    for task, needles in TASK_RULES.items():
        matched = sorted({n for n in needles if re.search(re.escape(n), text, flags=re.IGNORECASE)})
        rows.append(
            {
                "task": task,
                "run": "yes" if matched else "blocked",
                "evidence": "; ".join(matched) if matched else "analysis-execution-plan 未发现触发角色",
                "blocker": "" if matched else "缺少变量角色或设计信号；回流变量发现/清洗复核",
            }
        )
    return rows


def main() -> int:
    parser = common.add_common_args(argparse.ArgumentParser(description=__doc__))
    args = parser.parse_args()
    p = common.paths(args.out_root)
    today = date.today().isoformat()
    plan = Path(args.plan) if args.plan else common.find_latest_report(args.out_root, "analysis-execution-plan")
    plan_text = plan.read_text(encoding="utf-8", errors="ignore") if plan and plan.exists() else ""
    dict_path = Path(args.dict_path) if args.dict_path else p["data"] / "variable-dictionary.csv"
    dict_rows = common.read_csv_dicts(dict_path)
    cleaning = common.find_latest_report(args.out_root, "cleaning-report")
    rows = infer_tasks(plan_text)
    json_path = p["reports"] / "regression-dispatch.json"
    csv_path = p["reports"] / "regression-dispatch.csv"
    decision = p["reports"] / f"model-decision-{today}.md"
    common.write_json(
        json_path,
        {
            "plan": str(plan) if plan else None,
            "variable_dictionary": str(dict_path),
            "variable_count": len(dict_rows),
            "cleaning_report": str(cleaning) if cleaning else None,
            "tasks": rows,
        },
    )
    common.write_csv(csv_path, rows, ["task", "run", "evidence", "blocker"])
    common.write_markdown(
        decision,
        "Model Decision",
        {
            "来源计划": str(plan) if plan else "未找到 analysis-execution-plan-[date].md",
            "变量字典与清洗报告": f"变量字典行数：{len(dict_rows)}\n\n清洗报告：{cleaning or '未找到 cleaning-report-[date].md'}",
            "模型派发": "\n".join(f"- {r['task']}: {r['run']} ({r['evidence']})" for r in rows),
            "阻断": "\n".join(f"- {r['task']}: {r['blocker']}" for r in rows if r["blocker"]) or "无派发阻断。",
        },
    )
    status = "ok" if plan_text else "blocked"
    note = "不运行统计模型，只生成 dispatch。" if plan_text else "缺少 analysis-execution-plan；不得直接建模。"
    common.log_run(args, "03-regression/00-plan-dispatch", status, [json_path, csv_path, decision], note)
    return 0 if plan_text else 2


if __name__ == "__main__":
    raise SystemExit(main())
