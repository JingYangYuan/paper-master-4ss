# Template Contract

## 通用规则

- 所有模板使用泛化变量名和 `variable-dictionary.csv` 的 `display_name`，不得固化具体项目变量。
- 所有模板默认输出到 `paper-workspace/04-analysis/`。
- 所有模板必须记录 run-log：命令、输入、输出、状态、阻断原因。
- 未执行成功时，不得声称得到统计结论、质性主题或混合方法整合结论；模板不能只写空表冒充分析结果。

## 必备输出

| 流程 | 必备输出 |
|---|---|
| `02-clean-describe` | `data/analysis-data.csv`, `data/variable-dictionary.csv`, `tables/sample-flow.csv`, `tables/table1-descriptives.csv`, `reports/cleaning-report-[date].md` |
| `03-regression/00-plan-dispatch` | `reports/regression-dispatch.json`, `reports/regression-dispatch.csv`, `reports/model-decision-[date].md` |
| `03-regression/01-main-models` | `tables/table2-main-regression.csv`, `reports/main-models-results-[date].md` |
| `03-regression/02-nonlinear` | `tables/table3-nonlinear-marginal-effects.csv`, non-linear marginal effect notes |
| `03-regression/03-panel` | `tables/tableA-panel-models.csv`, panel diagnostic notes |
| `03-regression/04-causal` | `tables/tableA1-causal-robustness.csv`, event/RDD/matching notes |
| `03-regression/05-mechanism-heterogeneity` | `tables/table3-mechanism-mediation-moderation.csv`, `tables/table4-heterogeneity-threshold-nonlinear.csv` |
| `03-regression/06-robustness` | `tables/tableA-robustness.csv`,不可声称内容清单 |
| `03-regression/07-regression-export` | `reports/script-index.md`, `reports/regression-results-[date].md`, 缺失产物报告 |
| `04-qual` | 匿名化文本、分段数据、编码本、信度报告 |
| `05-mixed` | `tables/joint-display-[slug]-[date].csv`, `qual/coded-data/code-to-variable-map-[slug]-[date].csv` |
| `06-export` | `reports/script-index.md`, `reports/results-brief.md`, 质量门控清单 |

## 回归宽表

回归 CSV 必须使用论文宽表结构：表题行、模型编号行、因变量行、系数行、t/z 行、固定效应行、观测值行和中文注释行。标准误、聚类、权重和参考组写入表注。
