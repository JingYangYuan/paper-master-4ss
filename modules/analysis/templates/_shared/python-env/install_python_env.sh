#!/usr/bin/env bash
# 按锁文件重建 Paper Analysis 4SS 的 Python 分析环境。
#
# 用法:
#   bash install_python_env.sh [目标目录] [python 解释器]
# 默认:
#   目标目录     <本脚本所在目录>/venv
#   python 解释器 python3.11（模板要求 >= 3.11）
#
# 说明: Python venv 不可重定位（pyvenv.cfg 与 bin/* 内是绝对路径），
#       且含平台相关二进制，因此随包分发的是**锁文件**而不是 venv 快照。

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HERE/venv}"
PYTHON_BIN="${2:-python3.11}"
LOCK="$HERE/requirements-lock.txt"

if [ ! -f "$LOCK" ]; then
  echo "找不到锁文件: $LOCK" >&2
  exit 1
fi

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "找不到 Python 解释器 '$PYTHON_BIN'；请安装 Python >= 3.11 或把它作为第二个参数传入。" >&2
  exit 1
fi

echo "==> 解释器: $("$PYTHON_BIN" -V)  ($("$PYTHON_BIN" -c 'import platform;print(platform.platform(), platform.machine())'))"
echo "==> 目标目录: $TARGET"
echo "==> 锁文件: $LOCK ($(grep -c . "$LOCK") 个包)"

if [ -d "$TARGET" ]; then
  echo "==> 目标目录已存在，先删除"
  rm -rf "$TARGET"
fi

"$PYTHON_BIN" -m venv "$TARGET"
"$TARGET/bin/python" -m pip install --upgrade pip

echo "==> 按锁文件安装（耗时取决于网络；源码包会本地编译）"
"$TARGET/bin/python" -m pip install -r "$LOCK"

echo "==> 验收"
"$TARGET/bin/python" - <<'PY'
import sys
required = [
    "pandas", "numpy", "scipy", "statsmodels", "linearmodels", "pyfixest",
    "differences", "rdrobust", "pysyncon", "spreg", "pydynpd", "lifelines",
    "sklearn", "wildboottest", "esda", "libpysal",
]
missing = []
for name in required:
    try:
        __import__(name)
    except Exception as exc:  # noqa: BLE001
        missing.append(f"{name} ({type(exc).__name__})")
if missing:
    print("验收失败，缺失:", ", ".join(missing), file=sys.stderr)
    sys.exit(1)
print("PY-ENV-OK", sys.version.split()[0])
PY

echo "==> 完成。运行模板示例:"
echo "    $TARGET/bin/python templates/03-regression/08-spatial/spatial_models.py --out-root paper-workspace/04-analysis"
