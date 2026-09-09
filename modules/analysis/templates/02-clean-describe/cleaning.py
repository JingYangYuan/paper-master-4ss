#!/usr/bin/env python3
"""Read, clean, describe, and save analysis data."""

from __future__ import annotations

import argparse
import sys
from datetime import date
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
    if not args.data or not Path(args.data).exists():
        report = common.write_markdown(p["reports"] / f"cleaning-report-{date.today().isoformat()}.md", "Cleaning Report", {"阻断": "缺少 --data 或数据文件不存在。"})
        common.log_run(args, "02-clean-describe", "blocked", [report], "缺少可执行数据输入。")
        return 2
    raw = common.load_data(args.data)
    cleaned = common.clean_data(raw)
    roles = common.infer_roles(cleaned, args.dict_path)
    dict_path = common.write_variable_dictionary(cleaned, roles, args.data, args.out_root)
    sample, sample_flow = common.sample_flow(cleaned, roles, args.out_root)
    data_path = common.save_analysis_data(sample, args.out_root)
    table1 = common.describe_data(sample, [roles.y, roles.x, *roles.controls], args.out_root)
    corr = common.correlation_table(sample, [roles.y, roles.x, *roles.controls], args.out_root)
    figs = common.basic_figures(sample, roles, args.out_root)
    report = common.write_markdown(
        p["reports"] / f"cleaning-report-{date.today().isoformat()}.md",
        "Cleaning Report",
        {
            "数据输入": str(args.data),
            "样本": f"raw N={len(raw)}; analysis N={len(sample)}",
            "变量角色": str(roles),
            "清洗规则": "列名标准化、特殊缺失码转 NA、数值变量 1%/99% 缩尾、去重、删除 Y/X/control 缺失。",
        },
    )
    outputs = [data_path, dict_path, sample_flow, table1, report, *(x for x in [corr] if x), *figs]
    common.log_run(args, "02-clean-describe", "ok", outputs, "已真实读取、清洗并生成描述统计。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
