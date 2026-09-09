* Paper Analysis 4SS - 03 regression / 02 nonlinear models executable Stata template.

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
capture confirm file "${DATA}"
if _rc exit 2
use "${DATA}", clear

local stored_ame ""
capture noisily logit $Y $X $C $FE, vce(cluster $CLUSTER)
if !_rc {
    estimates store logit1
    margins, dydx($X $C) post
    estimates store ame_logit
    local stored_ame "`stored_ame' ame_logit"
}

capture noisily probit $Y $X $C $FE, vce(cluster $CLUSTER)
if !_rc {
    estimates store probit1
    margins, dydx($X $C) post
    estimates store ame_probit
    local stored_ame "`stored_ame' ame_probit"
}

capture noisily poisson $Y $X $C $FE, vce(cluster $CLUSTER)
if !_rc {
    estimates store poisson1
    margins, dydx($X $C) post
    estimates store ame_poisson
    local stored_ame "`stored_ame' ame_poisson"
}

if "`stored_ame'" != "" {
    capture esttab `stored_ame' using "${OUT_ROOT}/tables/table3-nonlinear-marginal-effects.csv", ///
        b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps ///
        stats(N, fmt(0) labels("观测值")) ///
        addnotes("注：非线性模型必须报告边际效应或预测概率；括号内为 z 值。") replace
}

capture confirm file "${OUT_ROOT}/tables/table3-nonlinear-marginal-effects.csv"
if _rc {
    file open flog using "${RUN_LOG}", write append
    file write flog "| `c(current_date)' | 03-regression/02-nonlinear | blocked | - | logit/probit/poisson 均未成功；请检查因变量是否为二元/计数变量、是否存在完全预测或模型角色缺失。 |" _n
    file close flog
    exit 2
}

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 03-regression/02-nonlinear | ok | table3-nonlinear-marginal-effects.csv | 已运行 logit/probit/poisson 可用模型并导出 margins。 |" _n
file close flog
