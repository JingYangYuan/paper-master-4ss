# Template Contract

## 通用规则

- 所有模板使用泛化变量名和 `variable-dictionary.csv` 的 `display_name`，不得固化具体项目变量。
- 所有模板默认输出到 `paper-workspace/04-analysis/`。
- 模板输出控制台日志：Stata 用 `log using "${OUT_ROOT}/reports/<子流程名>.log", replace text`；R/Python 由调用方重定向 stdout/stderr。markdown `run-log-[date].md` 由 agent 记录执行命令、退出码、stdout/stderr 路径、产物和失败信号。
- 模板不做运行时条件跳过：不适用的模型块在改写脚本时删除；变量、依赖或数据结构不满足时直接报错，不用 `capture` 静默跳过。
- 输入 CSV 一律按 UTF-8 读，并容忍 BOM：Excel 和 `pandas.to_csv(encoding="utf-8-sig")` 导出的首列名会带 `\ufeff`，Stata 读进来就是 `пpid`，角色推断和按名取列全部落空且不报错。Stata 导入后先跑一遍变量名清洗（去掉非 `[0-9A-Za-z_]` 字符），Python 用 `encoding="utf-8-sig"`，R 用 `read.csv(..., fileEncoding="UTF-8-BOM")` 后再 `clean_names_safe()`。
- Stata 模板的 `project_root` 守卫必须直接 `cd "`project_root'"`，不得写成 `& fileexists("`project_root'")`：`fileexists()` 对目录恒返回 0，该写法永不切换目录，`/e do` 批量模式下会静默落到 Stata 安装目录。
- 未执行成功时，不得声称得到统计结论、质性主题或混合方法整合结论；模板不能只写空表冒充分析结果。

## 必备输出

| 流程 | 必备输出 |
|---|---|
| `02-clean-describe` | `data/analysis-data.csv`, `data/variable-dictionary.csv`, `tables/sample-flow.csv`, `tables/table1-descriptives.csv`, `reports/cleaning-report-[date].md` |
| `03-regression/00-plan-dispatch` | `reports/regression-dispatch.json`, `reports/regression-dispatch.csv`, `reports/model-decision-[date].md` |
| `03-regression/01-main-models` | `tables/table2-main-regression.csv`, `reports/main-models-results-[date].md` |
| `03-regression/02-nonlinear` | `tables/table3-nonlinear-marginal-effects.csv`, `tables/table3b-ordered-multinomial.csv`, `tables/table3c-censored-selection.csv`, `tables/table3d-count-fractional-duration.csv`, `tables/table3e-nonlinear-diagnostics.csv` |
| `03-regression/03-panel` | `tables/tableA0-panel-selection.csv`, `tables/tableA-panel-models.csv`, `tables/tableA2-panel-dynamic.csv`, `tables/tableA3-panel-longN.csv`, `tables/tableA4-panel-iv-nonlinear.csv` |
| `03-regression/04-causal` | `tables/tableA1-causal-robustness.csv`, `tables/tableA1a-iv-diagnostics.csv`, `tables/tableA1b-did-event-study.csv`, `tables/tableA1c-did-diagnostics.csv`, `tables/tableA1d-rd.csv`, `tables/tableA1e-matching.csv`, `tables/tableA1f-scm.csv` |
| `03-regression/05-mechanism-heterogeneity` | `tables/table3-mechanism-mediation-moderation.csv`, `tables/table3s-mediation-robustness.csv`, `tables/table4-heterogeneity-threshold-nonlinear.csv`, `tables/table4b-group-difference.csv`, `tables/table4c-threshold-grid.csv` |
| `03-regression/06-robustness` | `tables/tableA-robustness.csv`, `tables/tableA-robustness-inference.csv`, `tables/tableA-robustness-sensitivity.csv`, `tables/tableA-robustness-alternatives.csv` |
| `03-regression/07-regression-export` | `reports/script-index.md`, `reports/regression-results-[date].md`, 缺失产物报告 |
| `03-regression/08-spatial` | `tables/tableS1-spatial-weights.csv`, `tables/tableS2-spatial-cross-section.csv`, `tables/tableS3-spatial-panel.csv`, `reports/spatial-diagnostics.md` |
| `04-qual` | 匿名化文本、分段数据、编码本、信度报告 |
| `05-mixed` | `tables/joint-display-[slug]-[date].csv`, `qual/coded-data/code-to-variable-map-[slug]-[date].csv` |
| `06-export` | `reports/script-index.md`, `reports/results-brief.md`, 质量门控清单 |
| `07-ml/01-supervised` | `tables/ml-selected-variables.csv`, `tables/ml-regularization-path.csv`, `tables/ml-model-performance.csv`, `tables/ml-calibration.csv`, `tables/ml-variable-importance.csv`, `tables/ml-structure-pca.csv`, `tables/ml-structure-cluster.csv`, `reports/ml-run-01-supervised-[date].md` |
| `07-ml/02-causal-ml` | `tables/ml-causal-estimates.csv`, `tables/ml-pds-selected-variables.csv`, `tables/ml-crossfit-folds.csv`, `reports/ml-run-02-causal-ml-[date].md` |
| `07-ml/03-heterogeneity` | `tables/ml-cate.csv`, `tables/ml-overlap.csv`, `tables/ml-gates.csv`, `tables/ml-blp-test.csv`, `reports/ml-run-03-heterogeneity-[date].md` |
| `07-ml/04-ml-export` | `tables/ml-wide-table.csv`, `tables/ml-run-manifest.csv`, `reports/ml-methods-note-[date].md`, `reports/ml-run-04-ml-export-[date].md` |

## 回归宽表

回归 CSV 必须使用论文宽表结构：表题行、模型编号行、因变量行、系数行、t/z 行、固定效应行、观测值行和中文注释行。标准误、聚类、权重和参考组写入表注。

## ML 表的额外要求

- 每张 ml 表都要带 `随机种子` 与 `折数` 列（或以注释行写明），面板数据额外写 `折分单位`（个体/组/时间）。缺这三项的样本外指标不得进正文。
- 训练集指标与样本外指标必须同表并报；只报其中一个即视为未完成。
- 超参搜索空间与选中参数写入 `reports/ml-run-<子流程>-<date>.md`，成本（候选模型数、实际拟合次数、耗时）一并记入。
- 同名表由多个 `--tasks` 写入时，先落任务级副本 `tables/<表名>-<任务>.csv`，再合并成主表 `tables/<表名>.csv`（首列 `任务`）。后跑的任务不得静默覆盖前一个任务的结果。Stata 侧直接写主表、不写任务级副本，列序与 Python／R 主表一致（`ml-model-performance.csv` 12 列、`ml-calibration.csv` 5 列）。
- `04-ml-export` 只读 CSV，只有 `.py` 与 `.R` 两个实现；Stata 侧没有 `.do`，导出直接用任一种。
- `tables/ml-run-manifest.csv` 列出应产出的表与实际状态（已产出／未产出+原因）。`04-ml-export` 生成 `ml-wide-table.csv` 时跳过未产出表，并在方法说明里写明跳过原因。
- `tables/ml-wide-table.csv` 三语言同列：`子流程`、`任务`、`方法或组`、`指标`、`数值`、`样本量`、`来源表`、`备注`。一行一个指标，数值原样搬运，不四舍五入美化，不补造缺失项。
- 依赖缺失、样本不足、变量角色缺失均写 `reports/ml-blocked-<子流程>-<date>.md` 后退出，不得降级到简单模型冒充。
