* Paper Analysis 4SS - 05 mixed methods joint display.

version 16
clear all

local project_root : env PROJECT_ROOT
if "`project_root'" != "" & fileexists("`project_root'") cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/mixed_methods.log", replace text

confirm file "${OUT_ROOT}/tables/table2-main-regression.csv"

file open fj using "${OUT_ROOT}/tables/mixed-joint-display.csv", write replace
file write fj "quant_finding,qual_theme,integration,claim_status" _n
file write fj "tables/table2-main-regression.csv,需读取 coded-excerpts,待基于真实系数方向和编码摘录撰写整合解释,pending-review" _n
file close fj

di "--> 已基于真实定量表创建 joint display 入口"

capture log close _all
