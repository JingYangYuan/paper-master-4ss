* Paper Analysis 4SS - 03 regression / 02 nonlinear models executable Stata template.
* 按 analysis-execution-plan 保留需要的块并删除不适用的方法块；本模板不做运行时条件跳过。

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

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/nonlinear_models.log", replace text

use "${DATA}", clear

estimates clear
qui logit $Y $X $C $FE, vce(cluster $CLUSTER)
est store logit1
margins, dydx($X $C) post
est store ame_logit

qui probit $Y $X $C $FE, vce(cluster $CLUSTER)
est store probit1
margins, dydx($X $C) post
est store ame_probit

qui poisson $Y $X $C $FE, vce(cluster $CLUSTER)
est store poisson1
margins, dydx($X $C) post
est store ame_poisson

esttab ame_logit ame_probit ame_poisson using "${OUT_ROOT}/tables/table3-nonlinear-marginal-effects.csv", ///
    b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：非线性模型必须报告边际效应或预测概率；括号内为 z 值。") replace

capture log close _all
