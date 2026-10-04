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
global CLUSTER "region"
global ID "pid"
global TIME "year"
global ABSORB "$ID $TIME"
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

capture which reghdfe
if _rc {
    capture ssc install reghdfe
    capture which reghdfe
    if _rc {
        file open fg using "${RUN_LOG}", write append
        file write fg "| `c(current_date)' | 03-regression/04-causal | blocked | - | 缺少 reghdfe，无法执行高维吸收估计。 |" _n
        file close fg
        exit 2
    }
}
capture which ivreghdfe
if _rc capture ssc install ivreghdfe
capture which ivreghdfe
local has_ivreghdfe = !_rc

capture confirm file "${DATA}"
if _rc exit 2
use "${DATA}", clear

local stored_causal ""
local ivnote "注：IV/DID/RDD/PSM 等仅在变量和命令可用时运行；未运行项见 run-log。"

* 第一阶段：IV -> 内生变量（高维吸收）
capture noisily reghdfe $ENDOG $IV $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store first_stage
    local stored_causal "`stored_causal' first_stage"
}

* 判定控制变量中哪些在个体维度上时不变：此类变量与被吸收的个体固定效应完全共线，
* 直接列入 ivreghdfe 的回归量会导致估计后 e(b) 含缺失值（estimates post 失败），
* 必须先经 partial() 从回归量中部分化出去。
local c_tv ""
local c_iv ""
capture xtset $ID $TIME
capture confirm variable $ID
local has_panel = !_rc
foreach v of global C {
    capture confirm variable `v'
    if _rc continue
    local tv = 0
    if `has_panel' {
        capture bysort $ID: gen byte _tvprobe = (`v' != `v'[1])
        capture quietly summarize _tvprobe
        if !_rc & r(max) == 0 local tv = 1
        capture drop _tvprobe
    }
    if `tv' {
        local c_tv "`c_tv' `v'"
    }
    else local c_iv "`c_iv' `v'"
}

* 第二阶段：ivreghdfe 高维吸收 2SLS
* ivreghdfe 要求 partial() 列出的变量同时保留在回归量列表中；时不变控制变量
* 与被吸收的个体固定效应共线，只列入回归量会导致估计后 e(b) 含缺失值，必须同时
* 写入 partial() 才会被部分化出去。
if `has_ivreghdfe' {
    if "`c_tv'" != "" {
        capture noisily ivreghdfe $Y $C ($ENDOG = $IV), absorb($ABSORB) partial(`c_tv') vce(cluster $CLUSTER) first
    }
    else {
        capture noisily ivreghdfe $Y $C ($ENDOG = $IV), absorb($ABSORB) vce(cluster $CLUSTER) first
    }
    if !_rc {
        local kp = e(widstat)
        local cdf = e(cdf)
        local idp = e(idp)
        estimates store iv_2sls
        local stored_causal "`stored_causal' iv_2sls"
        local ivnote "`ivnote' Kleibergen-Paap rk Wald F = `kp'；Cragg-Donald F = `cdf'；不可识别检验 p = `idp'。"
    }
}

capture gen _did = $TREAT * $POST
capture noisily reghdfe $Y _did $TREAT $POST $C, vce(cluster $CLUSTER)
if !_rc {
    estimates store did_2x2
    local stored_causal "`stored_causal' did_2x2"
}
capture noisily xtset $ID $TIME
capture noisily reghdfe $Y _did $C, absorb($ABSORB) vce(cluster $CLUSTER)
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
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
        stats(N r2, fmt(0 3) labels("观测值" "R²")) ///
        addnotes("`ivnote'") replace
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
    file write flog "| `c(current_date)' | 03-regression/04-causal | ok | tableA1-causal-robustness.csv<br>causal-results.md | 已运行 reghdfe/ivreghdfe 因果识别候选模型（含弱工具变量与不可识别检验标量）。 |" _n
}
else {
    file write flog "| `c(current_date)' | 03-regression/04-causal | blocked | causal-results.md | IV/DID/RDD/PSM 均未生成可导出表格；不得声称因果识别结果。 |" _n
}
file close flog
if !`causal_table_ok' exit 2