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
global ID "pid"
global TIME "year"
global CLUSTER "region"
global ABSORB "$ID $TIME"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/robustness.log", replace text

use "${DATA}", clear

estimates clear
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store base_cluster
qui reghdfe $Y $X $C, absorb($ABSORB) vce(robust)
est store base_robust
* 无固定效应对照列
qui reghdfe $Y $X $C, vce(cluster $CLUSTER)
est store no_fe
qui reghdfe $Y $X, absorb($ABSORB) vce(cluster $CLUSTER)
est store no_controls
qui reghdfe $Y $X $C if !missing($Y, $X), absorb($ABSORB) vce(cluster $CLUSTER)
est store complete_case

esttab base_cluster base_robust no_fe no_controls complete_case using "${OUT_ROOT}/tables/tableA-robustness.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：只声称本表真实运行的稳健性模型；未配置替代变量/样本/安慰剂见不可声称清单。") replace

file open fc using "${OUT_ROOT}/reports/cannot-claim-list.md", write replace
file write fc "# Cannot Claim List" _n _n
file write fc "未在本脚本中成功运行的替代变量、替代样本、安慰剂和敏感性分析，不得写入结果结论。" _n
file close fc

capture log close _all
