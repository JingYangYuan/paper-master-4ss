# Python 运行环境与依赖安装

本文件供 `modules/analysis/` 在选择 Python 环境、配置镜像源、安装依赖或排查运行故障时按需读取。

---

## 1. 安装运行时

```bash
# macOS
brew install python@3.12

# Ubuntu / Debian
sudo apt-get install -y python3.12 python3.12-venv

# Windows
# 从 https://www.python.org/downloads/ 下载安装包
```

推荐使用虚拟环境隔离项目依赖：

```bash
# 标准 venv
python3 -m venv .venv
source .venv/bin/activate     # macOS/Linux
.venv\Scripts\activate        # Windows

# conda
conda create -n paper-analysis python=3.12
conda activate paper-analysis
```

---

## 2. PyPI 镜像源

```bash
# 方式一：临时指定
pip install pandas statsmodels -i https://pypi.tuna.tsinghua.edu.cn/simple

# 方式二：持久配置 (~/.pip/pip.conf 或 %APPDATA%/pip/pip.ini)
# [global]
# index-url = https://pypi.tuna.tsinghua.edu.cn/simple
# trusted-host = pypi.tuna.tsinghua.edu.cn

# 方式三：pip config 命令
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

国内常用 PyPI 镜像：

| 镜像 | URL |
|------|-----|
| 清华 TUNA | `https://pypi.tuna.tsinghua.edu.cn/simple` |
| 阿里云 | `https://mirrors.aliyun.com/pypi/simple/` |
| 中科大 USTC | `https://pypi.mirrors.ustc.edu.cn/simple/` |
| 官方 | `https://pypi.org/simple/` |

---

## 3. 关键依赖安装

```bash
pip install pandas numpy scipy statsmodels matplotlib seaborn  # 核心
pip install linearmodels                                       # IV + 面板
pip install scikit-learn                                       # ML + 倾向得分
pip install jupyterlab                                         # 交互探索（可选）
```

---

## 4. 验收命令

```bash
python3 --version

python3 -c "
import importlib, sys
missing = []
for pkg in ['pandas','numpy','scipy','statsmodels']:
    try:
        importlib.import_module(pkg)
        print(f'{pkg} OK')
    except ImportError:
        print(f'{pkg} MISSING')
        missing.append(pkg)
if missing:
    sys.exit(1)
"
```

---

## 5. 执行入口

```bash
python3 "script.py"
```

若无 `python3`，按本文件 §1 安装；依赖缺失时创建 venv 并用 `pip` 安装。

---

## 6. 适用场景与常用包

**适用场景**：批量文本、自动化清洗、基础回归、面板模型、预测建模、LLM 辅助编码。

| 领域 | 包 |
|------|----|
| 清洗 | `pandas`、`numpy` |
| 回归 | `statsmodels` |
| 面板/IV | `linearmodels` |
| ML | `scikit-learn` |
| 因果 ML | `doubleml`、`econml` |
| RDD | `rdrobust` |
| 图形 | `matplotlib`、`seaborn`、`scipy` |
| 文本 | `re`、`jieba` |

---

## 7. 绘图关键规则

- **中文字体**：`plt.rcParams["font.sans-serif"] = ["PingFang SC", "Heiti SC", "SimHei", "Microsoft YaHei"]`；`axes.unicode_minus = False`
- **后端**：headless/服务器环境必须 `matplotlib.use("Agg")`
- **颜色**：用十六进制如 `#666666`，不用 CSS 名称如 `grey40`
- **双格式导出**：`fig.savefig(...)` 同时存 PDF（排版）+ PNG（预览）
- **公式模型预测**：使用 `C()` 编码（如 `"y ~ x + C(gender)"`），避免在公式中写 dummy 列名

绘图函数（模板已内置）：`save_plot_pair()`、`theme_paper()`、`plot_distribution()`、`plot_group_mean()`、`plot_coef()`、`plot_marginal()`、`plot_diagnostics()`。详见 [python-analysis-template.py](../templates/python-analysis-template.py)。

---

## 8. 故障排除

| 问题 | 处理 |
|------|------|
| `pip install` 超时 | 切换国内镜像源（见 §2） |
| `statsmodels` 导入报错 | 检查 numpy/scipy 版本兼容性，重建 venv |
| `linearmodels` 安装失败 | 需要 C 编译器；macOS 先 `xcode-select --install` |
| 中文图乱码 | 检查 `font.sans-serif` 配置；确认系统有中文字体 |
| 虚拟环境 Python 版本不对 | `python3.12 -m venv .venv` 指定版本 |

---

## 9. 其他语言

- R 环境：[r-ecosystem-setup.md](r-ecosystem-setup.md)
- Stata 环境：[stata-ecosystem-setup.md](stata-ecosystem-setup.md)
