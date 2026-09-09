* Paper Analysis 4SS - 03 regression / 06 robustness executable Stata template.

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

regress $Y $X $C $FE, vce(cluster $CLUSTER)
estimates store base_cluster
regress $Y $X $C $FE, vce(robust)
estimates store base_robust
regress $Y $X $C, vce(cluster $CLUSTER)
estimates store no_fe
regress $Y $X $FE, vce(cluster $CLUSTER)
estimates store no_controls

capture noisily regress $Y $X $C $FE if !missing($Y, $X), vce(cluster $CLUSTER)
if !_rc estimates store complete_case

esttab base_cluster base_robust no_fe no_controls complete_case using "${OUT_ROOT}/tables/tableA-robustness.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps ///
    stats(N r2, fmt(0 3) labels("观测值" "R²")) ///
    addnotes("注：只声称本表真实运行的稳健性模型；未配置替代变量/样本/安慰剂见不可声称清单。") replace

file open fc using "${OUT_ROOT}/reports/cannot-claim-list.md", write replace
file write fc "# Cannot Claim List" _n _n
file write fc "未在本脚本中成功运行的替代变量、替代样本、安慰剂和敏感性分析，不得写入结果结论。" _n
file close fc

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 03-regression/06-robustness | ok | tableA-robustness.csv<br>cannot-claim-list.md | 已运行稳健性变体。 |" _n
file close flog
