* Paper Analysis 4SS - 03 regression / 01 main models executable Stata template.

version 16
clear all
set more off

local project_root : env PROJECT_ROOT
if "`project_root'" != "" & fileexists("`project_root'") cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global DATA "${OUT_ROOT}/data/analysis-data.dta"
global Y "outcome"
global X "treatment"
global C "age gender education income"
global C2 ""
global ID "pid"
global TIME "year"
global ABSORB "$ID $TIME"
global CLUSTER "region"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/main_models.log", replace text

use "${DATA}", clear

di "--> 估计表1：描述统计"
estpost summarize $Y $X $C, detail
esttab using "${OUT_ROOT}/tables/table1-descriptives.csv", ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") nogaps compress substitute("=" "") replace

di "--> 估计表2：主回归阶梯（reghdfe）"
estimates clear
qui reghdfe $Y $X, absorb($ABSORB) vce(cluster $CLUSTER)
est store m1
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store m2
qui reghdfe $Y $X $C $C2, absorb($ABSORB) vce(cluster $CLUSTER)
est store m3
* 对照列：普通组内未聚类标准误（不写 vce 选项）
qui reghdfe $Y $X $C $C2, absorb($ABSORB) resid
est store m4_unclustered
* 残差正态性诊断（reghdfe 需 resid 选项才生成残差变量）
swilk `e(resid)'
drop `e(resid)'

esttab m1 m2 m3 m4_unclustered using "${OUT_ROOT}/tables/table2-main-regression.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_a r2_within, fmt(0 3 3 3) labels("观测值" "R²" "调整 R²" "Within R²")) ///
    addnotes("注：*** p<0.001，** p<0.01，* p<0.05；括号内为 t 值；标准误按 $CLUSTER 聚类；末列为普通组内未聚类对照。") replace
esttab m1 m2 m3 m4_unclustered using "${OUT_ROOT}/tables/table2-main-regression.tex", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label booktabs nogaps substitute("=" "") ///
    stats(N r2 r2_a r2_within, fmt(0 3 3 3) labels("观测值" "R²" "调整 R²" "Within R²")) replace

file open fm using "${OUT_ROOT}/reports/main-models-results.md", write replace
file write fm "# Main Models Results" _n _n
file write fm "已运行 reghdfe 高维固定效应主回归阶梯：m1/m2/m3 与未聚类对照列 m4；表格见 table2-main-regression.csv。" _n
file close fm

capture log close _all
