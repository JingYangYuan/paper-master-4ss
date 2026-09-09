* Paper Analysis 4SS - 05 mixed methods joint display.

version 16
clear all

local project_root : env PROJECT_ROOT
if "`project_root'" != "" cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"
capture confirm file "${RUN_LOG}"
if _rc {
    file open flog using "${RUN_LOG}", write replace
    file write flog "# Analysis Run Log" _n _n
    file write flog "| Date | Step | Status | Outputs | Note |" _n
    file write flog "|---|---|---|---|---|" _n
    file close flog
}

capture confirm file "${OUT_ROOT}/tables/table2-main-regression.csv"
if _rc {
    file open flog using "${RUN_LOG}", write append
    file write flog "| `c(current_date)' | 05-mixed | blocked | - | 缺少 table2-main-regression.csv。 |" _n
    file close flog
    exit 2
}

file open fj using "${OUT_ROOT}/tables/mixed-joint-display.csv", write replace
file write fj "quant_finding,qual_theme,integration,claim_status" _n
file write fj "tables/table2-main-regression.csv,需读取 coded-excerpts,待基于真实系数方向和编码摘录撰写整合解释,pending-review" _n
file close fj

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 05-mixed | ok | mixed-joint-display.csv | 已基于真实定量表创建 joint display 入口。 |" _n
file close flog
