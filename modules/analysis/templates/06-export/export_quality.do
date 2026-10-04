* Paper Analysis 4SS - 06 export and quality gates.

version 16
clear all

local project_root : env PROJECT_ROOT
if "`project_root'" != "" cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/export_quality.log", replace text

file open fq using "${OUT_ROOT}/reports/analysis-quality-gates-`c(current_date)'.md", write replace
file write fq "# Analysis Quality Gates" _n _n
foreach f in "data/analysis-data.csv" "data/variable-dictionary.csv" "tables/sample-flow.csv" "tables/table1-descriptives.csv" "tables/table2-main-regression.csv" {
    capture confirm file "${OUT_ROOT}/`f'"
    if _rc file write fq "- 缺失：`f'" _n
    else file write fq "- 通过：`f'" _n
}
file write fq _n "只有产物存在且子流程 reports/*.log 无 r(...) 报错的结果可以进入论文结论。" _n
file close fq

capture log close _all
