# Template Contract

## 通用规则

- 所有模板使用泛化变量名和 `variable-dictionary.csv` 的 `display_name`，不得固化具体项目变量。
- 所有模板默认输出到 `paper-workspace/04-analysis/`。
- 模板输出控制台日志：Stata 用 `log using "${OUT_ROOT}/reports/<子流程名>.log", replace text`；R/Python 由调用方重定向 stdout/stderr。markdown `run-log-[date].md` 由 agent 记录执行命令、退出码、stdout/stderr 路径、产物和失败信号。
- 模板不做运行时条件跳过：不适用的模型块在改写脚本时删除；变量、依赖或数据结构不满足时直接报错，不用 `capture` 静默跳过。
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

## 回归宽表

回归 CSV 必须使用论文宽表结构：表题行、模型编号行、因变量行、系数行、t/z 行、固定效应行、观测值行和中文注释行。标准误、聚类、权重和参考组写入表注。
