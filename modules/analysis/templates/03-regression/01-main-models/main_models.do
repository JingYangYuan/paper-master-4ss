* Paper Analysis 4SS - 03 regression / 01 main models executable Stata template.

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
global ABSORB "region year"
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
if _rc {
    file open flog using "${RUN_LOG}", write append
    file write flog "| `c(current_date)' | 03-regression/01-main-models | blocked | - | 缺少 ${DATA}。 |" _n
    file close flog
    exit 2
}

use "${DATA}", clear

estpost summarize $Y $X $C, detail
esttab using "${OUT_ROOT}/tables/table1-descriptives.csv", ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") replace

regress $Y $X, vce(cluster $CLUSTER)
estimates store m1
regress $Y $X $C, vce(cluster $CLUSTER)
estimates store m2
regress $Y $X $C $FE, vce(cluster $CLUSTER)
estimates store m3

quietly regress $Y $X $C $FE
capture estat vif
capture estat hettest, iid
capture estat imtest, white
capture predict _resid_ols, residuals
capture swilk _resid_ols
capture drop _resid_ols

capture which reghdfe
if !_rc {
    capture noisily reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
    if !_rc estimates store hdfe1
}

esttab m1 m2 m3 using "${OUT_ROOT}/tables/table2-main-regression.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps ///
    stats(N r2 r2_a, fmt(0 3 3) labels("观测值" "R²" "调整 R²")) ///
    addnotes("注：*** p<0.001，** p<0.01，* p<0.05；括号内为 t 值；标准误按 $CLUSTER 聚类。") replace

esttab m1 m2 m3 using "${OUT_ROOT}/tables/table2-main-regression.tex", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label booktabs nogaps ///
    stats(N r2 r2_a, fmt(0 3 3) labels("观测值" "R²" "调整 R²")) replace

file open fm using "${OUT_ROOT}/reports/main-models-results.md", write replace
file write fm "# Main Models Results" _n _n
file write fm "已运行 Stata OLS 主回归：m1/m2/m3；表格见 table2-main-regression.csv。" _n
file close fm

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 03-regression/01-main-models | ok | table1-descriptives.csv<br>table2-main-regression.csv<br>main-models-results.md | 已真实估计主回归。 |" _n
file close flog
