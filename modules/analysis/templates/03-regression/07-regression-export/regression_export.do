* Paper Analysis 4SS - 03 regression / 07 regression export.
* Aggregates subflow products; does not re-estimate models.

version 16
clear all

local project_root : env PROJECT_ROOT
if "`project_root'" != "" cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"
global RESULTS "${OUT_ROOT}/reports/regression-results-`c(current_date)'.md"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/reports"
capture confirm file "${RUN_LOG}"
if _rc {
    file open flog using "${RUN_LOG}", write replace
    file write flog "# Analysis Run Log" _n _n
    file write flog "| Date | Step | Status | Outputs | Note |" _n
    file write flog "|---|---|---|---|---|" _n
    file close flog
}

file open fs using "${OUT_ROOT}/reports/script-index.md", write replace
file write fs "# Script Index" _n _n
file write fs "| 顺序 | 子流程 |" _n
file write fs "|---|---|" _n
file write fs "| 1 | 00-plan-dispatch |" _n
file write fs "| 2 | 01-main-models |" _n
file write fs "| 3 | 02-nonlinear |" _n
file write fs "| 4 | 03-panel |" _n
file write fs "| 5 | 04-causal |" _n
file write fs "| 6 | 05-mechanism-heterogeneity |" _n
file write fs "| 7 | 06-robustness |" _n
file write fs "| 8 | 07-regression-export |" _n
file close fs

file open fm using "${OUT_ROOT}/reports/missing-regression-products.md", write replace
file write fm "# Missing Regression Products" _n _n
foreach f in "data/analysis-data.csv" "data/variable-dictionary.csv" "tables/sample-flow.csv" "tables/table1-descriptives.csv" "tables/table2-main-regression.csv" "tables/table3-nonlinear-marginal-effects.csv" "tables/table3-mechanism-mediation-moderation.csv" "tables/table4-heterogeneity-threshold-nonlinear.csv" "tables/tableA1-causal-robustness.csv" {
    capture confirm file "${OUT_ROOT}/`f'"
    if _rc file write fm "- `f'" _n
}
file close fm

file open fr using "${RESULTS}", write replace
file write fr "# Regression Results" _n _n
file write fr "本导出脚本不重新估计模型，只汇总真实运行产物。所有可声称内容必须追溯到 ${RUN_LOG}。" _n
file close fr

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 03-regression/07-regression-export | ok | script-index.md<br>${RESULTS} | 未重新估计模型。 |" _n
file close flog
