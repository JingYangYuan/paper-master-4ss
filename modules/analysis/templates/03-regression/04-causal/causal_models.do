* Paper Analysis 4SS - 03 regression / 04 causal models executable Stata template.
* 按 analysis-execution-plan 保留需要的块并删除不适用的方法块；本模板不做运行时条件跳过。
* ivreghdfe 的回归量不得含与吸收的个体固定效应共线的时不变控制变量；如报 rc=504，删除或替换该控制变量后重跑。

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

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/causal_models.log", replace text

use "${DATA}", clear

* 第一阶段：IV -> 内生变量（高维吸收）
estimates clear
qui reghdfe $ENDOG $IV $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store first_stage

* 第二阶段：ivreghdfe 高维吸收 2SLS
qui ivreghdfe $Y $C ($ENDOG = $IV), absorb($ABSORB) vce(cluster $CLUSTER) first
est store iv_2sls
local kp = e(widstat)
local cdf = e(cdf)
local idp = e(idp)

gen _did = $TREAT * $POST
qui reghdfe $Y _did $TREAT $POST $C, vce(cluster $CLUSTER)
est store did_2x2
qui reghdfe $Y _did $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store did_twfe

csdid $Y $C, ivar($ID) time($TIME) gvar($GVAR) method(dripw) cluster($CLUSTER)
rdrobust $Y $RUNNING, c($CUTOFF) covs($C)
rddensity $RUNNING, c($CUTOFF)
psmatch2 $TREAT $C, outcome($Y) neighbor(1) common
pstest $C, both

esttab first_stage iv_2sls did_2x2 did_twfe using "${OUT_ROOT}/tables/tableA1-causal-robustness.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2, fmt(0 3) labels("观测值" "R²")) ///
    addnotes("注：IV/DID/RDD/PSM 等仅在变量和命令可用时运行；未运行项见 run-log。 Kleibergen-Paap rk Wald F = `kp'；Cragg-Donald F = `cdf'；不可识别检验 p = `idp'。") replace

file open fr using "${OUT_ROOT}/reports/causal-results.md", write replace
file write fr "# Causal Results" _n _n
file write fr "已运行 IV/2SLS、DID/TWFE、多期 DID、RDD 和 PSM。可声称内容以生成的表格和 .log 为准。" _n
file close fr

capture log close _all
