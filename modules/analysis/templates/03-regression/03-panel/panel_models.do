* Paper Analysis 4SS - 03 regression / 03 panel models executable Stata template.
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
global ID "pid"
global TIME "year"
global CLUSTER "region"
global ABSORB "$ID $TIME"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/panel_models.log", replace text

use "${DATA}", clear

xtset $ID $TIME

* 经典 FE/RE 仅用于 Hausman 诊断，不进入结果表；hausman 不接受聚类 VCE，故此处用默认 VCE
estimates clear
qui xtreg $Y $X $C i.$TIME, fe
est store fe_diag
qui xtreg $Y $X $C i.$TIME, re
est store re_diag
hausman fe_diag re_diag, sigmamore
local hm_chi2 = r(chi2)
local hm_df = r(df)
local hm_p = r(p)

* 高维固定效应：个体 FE 与双向 FE（reghdfe）
estimates clear
qui reghdfe $Y $X $C, absorb($ID) vce(cluster $CLUSTER)
est store hdfe_fe
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store hdfe_twfe

* 动态面板：xtabond2 两步系统 GMM（AR/Hansen 检验值由 e() 直接返回，无需 estadd）
qui xtabond2 $Y L.$Y $X $C i.$TIME, gmm(L.$Y, lag(2 4) collapse) iv($X $C) robust twostep
est store dyn_gmm

esttab hdfe_fe hdfe_twfe dyn_gmm using "${OUT_ROOT}/tables/tableA-panel-models.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within ar1p ar2p hansenp, fmt(0 3 3 3 3 3) labels("观测值" "R²" "Within R²" "AR(1) p" "AR(2) p" "Hansen p")) ///
    addnotes("注：动态面板列的 AR(1)/AR(2)/Hansen 检验 p 值由 xtabond2 的 e(ar1p)/e(ar2p)/e(hansenp) 直接输出。") ///
    replace

file open fp using "${OUT_ROOT}/reports/panel-diagnostics.md", write replace
file write fp "# Panel Diagnostics" _n _n
file write fp "已运行 xtreg FE/RE 与 Hausman 诊断；结果表列使用 reghdfe 个体 FE / 双向 FE；动态面板使用 xtabond2 两步系统 GMM。" _n
file write fp "Hausman 检验：chi2(`hm_df') = `hm_chi2'，p = `hm_p'。" _n
file close fp

capture log close _all
