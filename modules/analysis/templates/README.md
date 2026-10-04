# Analysis Templates

本目录按 `modules/analysis/phases/` 的执行流程组织真实可执行的三语言模板。模板是项目脚本的源材料：实际执行时，把相关脚本复制或改写到 `paper-workspace/04-analysis/scripts/`，再用 `python3`、`Rscript` 运行；Stata 统一经 statamcp 的 `stata_run_file` 执行。

## 目录

| 流程 | 目录 | 产物 |
|---|---|---|
| 初始化与路由 | `01-init/` | 目录、候选数据、CLI 检查 |
| 清洗与描述 | `02-clean-describe/` | `analysis-data.*`、`variable-dictionary.csv`、`sample-flow.csv`、`table1-descriptives.csv` |
| 回归与扩展 | `03-regression/` | dispatch、模型决策、主回归、非线性、面板、因果、机制、稳健性、空间权重与空间回归、汇总导出 |
| 质性分析 | `04-qual/` | 匿名化文本、分段数据、编码本、编码表、信度记录 |
| 混合方法 | `05-mixed/` | 读取真实定量表和质性编码表，生成 joint display |
| 导出门控 | `06-export/` | `script-index.md`、结果报告、质量门控清单 |

## 语言覆盖差异

三语言模板对齐到各自生态的**上限**，而不是强行三语言同质。差异如下：

| 方法 | Stata | R | Python |
|---|---|---|---|
| 二元/计数/比例/持续时间/有序/多分类 | 全部 | 全部 | 全部 |
| Tobit、Heckman/样本选择、IV-Tobit、内生处理回归 | 提供 | 提供（`AER::tobit`、`sampleSelection::heckman`） | **不提供** |
| 面板设定选择（Hausman、Breusch-Pagan LM） | 提供（`xtreg`+`hausman`、`xttest0`） | 提供（`plm::phtest`、`plm::plmtest`） | **不提供** |
| 广义有序（`gologit2`/`oglm`）、`xtdcce2`、`xthst` | 提供 | 不提供 | 不提供 |
| 未观测混淆敏感性（Oster `psacalc`、`sensemakr`） | 提供 | 提供（`robomit`、`sensemakr`） | **不提供** |
| 多重检验的 Romano-Wolf / Westfall-Young | 提供（`rwolf`、`wyoung`） | 不提供（用 `p.adjust` 的 Holm/BH） | 不提供（用 `statsmodels` 的 Holm/BH） |
| 面板空间效应分解（`margins predict(direct/indirect/total)`） | 提供 | 不提供等价实现（以 `impacts` 口径为主） | 不提供等价实现 |
| 空间权重构造 | `spmatrix`/`spatwmat` | base R 线性代数（行标准化 K 近邻 W；`spdep` 可用时自动优先使用） | `libpysal`（不依赖 `geopandas`） |
| AME 口径 | `margins` | `marginaleffects::slopes` | `statsmodels.get_margeff`/手写 AME |

**Python 不实现的四项**（Tobit、Heckman/样本选择、面板选择模型、Oster `psacalc` 敏感性分析）仅由 Stata/R 模板提供；Python 模板中**直接删除**对应方法块，**不得**用近似模型冒充。R 与 Stata 的 AME、多重检验校正与空间效应分解口径不同，表注必须写明所用软件与 VCE，**不得**为对齐数值而统一改用非聚类口径。

## 统一接口

Python/R 脚本采用“配置块 + CLI 参数覆盖”：

```bash
python3 templates/02-clean-describe/cleaning.py --data data.csv --out-root paper-workspace/04-analysis
Rscript templates/03-regression/01-main-models/main_models.R --data data.csv --out-root paper-workspace/04-analysis
```

Stata 脚本使用文件顶部宏配置，并保留等价参数说明；生产执行使用 `.do` 文件：

```text
# statamcp —— stata_run_file(
#   file_path="paper-workspace/04-analysis/scripts/03-regression/01-main-models/main_models.do",
#   working_dir=<.do 相对路径基准目录>, timeout=按需)
```

模板输出控制台日志：Stata 用 `log using "${OUT_ROOT}/reports/<子流程名>.log", replace text`；R/Python 由调用方重定向 stdout/stderr。markdown `run-log-[date].md` 由 agent 记录执行命令、退出码、stdout/stderr 路径、产物和失败信号，模板不再写它。

模板不做运行时条件跳过：不适用的模型块在改写脚本时删除；变量、依赖或数据结构不满足时直接报错，不用 `capture`/`tryCatch`/`try-except` 静默跳过。模板只能声称本脚本实际生成的产物。
