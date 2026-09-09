* Paper Analysis 4SS - 03 regression / 04 causal models executable Stata template.

version 16
clear all
set more off

local project_root : env PROJECT_ROOT
if "`project_root'" != "" cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global DATA "${OUT_ROOT}/data/analysis-data.dta"
global Y "outcome"
global X "treatment"
global C "age gender education income"
global FE "i.year i.region"
global CLUSTER "region"
global ID "pid"
global TIME "year"
global TREAT "treated"
global POST "post"
global GVAR "first_treat_year"
global EVENT "rel_year"
global ENDOG "endog_x"
global IV "instrument_z"
global RUNNING "running_score"
global CUTOFF "0"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"
capture confirm file "${RUN_LOG}"
if _rc {
    file open flog using "${RUN_LOG}", write replace
    file write flog "# Analysis Run Log" _n _n
    file write flog "| Date | Step | Status | Outputs | Note |" _n
    file write flog "|---|---|---|---|---|" _n
    file close flog
}
capture confirm file "${DATA}"
if _rc exit 2
use "${DATA}", clear

local stored_causal ""
capture noisily regress $ENDOG $IV $C $FE, vce(cluster $CLUSTER)
if !_rc {
    estimates store first_stage
    local stored_causal "`stored_causal' first_stage"
}
capture noisily ivregress 2sls $Y $C $FE ($ENDOG = $IV), vce(cluster $CLUSTER)
if !_rc {
    estimates store iv_2sls
    local stored_causal "`stored_causal' iv_2sls"
}

capture gen _did = $TREAT * $POST
capture noisily regress $Y _did $TREAT $POST $C, vce(cluster $CLUSTER)
if !_rc {
    estimates store did_2x2
    local stored_causal "`stored_causal' did_2x2"
}
capture noisily xtset $ID $TIME
capture noisily reghdfe $Y _did $C, absorb($ID $TIME) vce(cluster $CLUSTER)
if !_rc {
    estimates store did_twfe
    local stored_causal "`stored_causal' did_twfe"
}

capture noisily csdid $Y $C, ivar($ID) time($TIME) gvar($GVAR) method(dripw) cluster($CLUSTER)
if !_rc estimates store csdid_model

capture noisily rdrobust $Y $RUNNING, c($CUTOFF) covs($C)
capture noisily rddensity $RUNNING, c($CUTOFF)

capture noisily psmatch2 $TREAT $C, outcome($Y) neighbor(1) common
capture pstest $C, both

if "`stored_causal'" != "" {
    capture esttab `stored_causal' using "${OUT_ROOT}/tables/tableA1-causal-robustness.csv", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps ///
        stats(N r2, fmt(0 3) labels("观测值" "R²")) ///
        addnotes("注：IV/DID/RDD/PSM 等仅在变量和命令可用时运行；未运行项见 run-log。") replace
}

capture confirm file "${OUT_ROOT}/tables/tableA1-causal-robustness.csv"
local causal_table_ok = !_rc

file open fr using "${OUT_ROOT}/reports/causal-results.md", write replace
file write fr "# Causal Results" _n _n
if `causal_table_ok' {
    file write fr "已尝试运行 IV/2SLS、DID/TWFE、多期 DID、RDD 和 PSM。可声称内容以成功生成的表格和 run-log 为准。" _n
}
else {
    file write fr "因果识别模型未生成可导出表格；请检查 instrument/endog/treatment/post/id/time/running 等角色、依赖命令和样本条件。" _n
}
file close fr

file open flog using "${RUN_LOG}", write append
if `causal_table_ok' {
    file write flog "| `c(current_date)' | 03-regression/04-causal | ok | tableA1-causal-robustness.csv<br>causal-results.md | 已运行可用因果识别模型。 |" _n
}
else {
    file write flog "| `c(current_date)' | 03-regression/04-causal | blocked | causal-results.md | IV/DID/RDD/PSM 均未生成可导出表格；不得声称因果识别结果。 |" _n
}
file close flog
if !`causal_table_ok' exit 2
