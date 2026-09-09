* Paper Analysis 4SS - 06 export and quality gates.

version 16
clear all

local project_root : env PROJECT_ROOT
if "`project_root'" != "" cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"

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

file open fq using "${OUT_ROOT}/reports/analysis-quality-gates-`c(current_date)'.md", write replace
file write fq "# Analysis Quality Gates" _n _n
foreach f in "data/analysis-data.csv" "data/variable-dictionary.csv" "tables/sample-flow.csv" "tables/table1-descriptives.csv" "tables/table2-main-regression.csv" {
    capture confirm file "${OUT_ROOT}/`f'"
    if _rc file write fq "- 缺失：`f'" _n
    else file write fq "- 通过：`f'" _n
}
file write fq _n "只有 run-log 记录为 ok 且产物存在的结果可以进入论文结论。" _n
file close fq

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 06-export | ok | analysis-quality-gates | 已执行质量门控。 |" _n
file close flog
