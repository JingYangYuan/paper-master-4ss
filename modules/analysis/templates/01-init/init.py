#!/usr/bin/env python3
"""Initialize workspace and check executable analysis dependencies."""

from __future__ import annotations

import argparse
import shutil
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
    checks = {
        "python": shutil.which("python3") or sys.executable,
        "Rscript": shutil.which("Rscript") or "not found",
        "statamcp": "verify via stata_session(list) + stata_run_selection('display 1+1')",
    }
    for pkg in ["pandas", "numpy", "statsmodels", "matplotlib"]:
        try:
            __import__(pkg)
            checks[pkg] = "ok"
        except Exception as exc:
            checks[pkg] = f"missing: {exc}"
    report = p["reports"] / f"analysis-init-{date.today().isoformat()}.md"
    common.write_markdown(
        report,
        "Analysis Init",
        {
            "CLI 与依赖检查": "\n".join(f"- {k}: {v}" for k, v in checks.items()),
            "输出目录": "\n".join(f"- {v}" for v in p.values()),
            "下一步": "运行 02-clean-describe 生成 analysis-data、variable-dictionary、sample-flow 和 Table 1。",
        },
    )
    status = "ok" if checks["pandas"] == "ok" and checks["statsmodels"] == "ok" else "blocked"
    common.log_run(args, "01-init", status, [report], "已创建目录并检查 Python/R/Stata 运行环境。")
    return 0 if status == "ok" else 2


if __name__ == "__main__":
    raise SystemExit(main())
