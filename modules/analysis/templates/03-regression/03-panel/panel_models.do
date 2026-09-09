* Paper Analysis 4SS - 03 regression / 03 panel models executable Stata template.

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
global ID "pid"
global TIME "year"
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

capture confirm variable $ID
if _rc {
    file open flog using "${RUN_LOG}", write append
    file write flog "| `c(current_date)' | 03-regression/03-panel | blocked | - | 缺少 ID 变量 $ID。 |" _n
    file close flog
    exit 2
}
capture confirm variable $TIME
if _rc {
    file open flog using "${RUN_LOG}", write append
    file write flog "| `c(current_date)' | 03-regression/03-panel | blocked | - | 缺少 TIME 变量 $TIME。 |" _n
    file close flog
    exit 2
}

xtset $ID $TIME
xtreg $Y $X $C i.$TIME, fe vce(cluster $CLUSTER)
estimates store fe
xtreg $Y $X $C i.$TIME, re vce(cluster $CLUSTER)
estimates store re
capture hausman fe re, sigmamore
capture noisily xtabond $Y L.$Y $X $C, vce(robust)
if !_rc estimates store dyn_gmm

esttab fe re dyn_gmm using "${OUT_ROOT}/tables/tableA-panel-models.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps ///
    stats(N r2_w r2_b r2_o, fmt(0 3 3 3) labels("观测值" "Within R²" "Between R²" "Overall R²")) replace

file open fp using "${OUT_ROOT}/reports/panel-diagnostics.md", write replace
file write fp "# Panel Diagnostics" _n _n
file write fp "已运行 FE/RE、Hausman（若可用）和动态面板候选模型（若可用）。" _n
file close fp

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 03-regression/03-panel | ok | tableA-panel-models.csv<br>panel-diagnostics.md | 已真实运行面板模型。 |" _n
file close flog
