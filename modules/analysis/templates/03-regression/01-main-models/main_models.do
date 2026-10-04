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
global C2 ""
global ID "pid"
global TIME "year"
global ABSORB "$ID $TIME"
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

capture which reghdfe
if _rc {
    capture ssc install reghdfe
    capture which reghdfe
    if _rc {
        file open fg using "${RUN_LOG}", write append
        file write fg "| `c(current_date)' | 03-regression/01-main-models | blocked | - | 缺少 reghdfe，无法执行高维固定效应估计。 |" _n
        file close fg
        exit 2
    }
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
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") nogaps compress substitute("=" "") replace

local stored_main ""
capture noisily reghdfe $Y $X, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store m1
    local stored_main "`stored_main' m1"
}
capture noisily reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store m2
    local stored_main "`stored_main' m2"
}
capture noisily reghdfe $Y $X $C $C2, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store m3
    local stored_main "`stored_main' m3"
    capture estat vif
}
* 对照列：普通组内未聚类标准误（不写 vce 选项）
capture noisily reghdfe $Y $X $C $C2, absorb($ABSORB)
if !_rc {
    estimates store m4_unclustered
    local stored_main "`stored_main' m4_unclustered"
}
capture predict _resid_ols, residuals
capture swilk _resid_ols
capture drop _resid_ols

if "`stored_main'" != "" {
    capture esttab `stored_main' using "${OUT_ROOT}/tables/table2-main-regression.csv", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
        stats(N r2 r2_a r2_within, fmt(0 3 3 3) labels("观测值" "R²" "调整 R²" "Within R²")) ///
        addnotes("注：*** p<0.001，** p<0.01，* p<0.05；括号内为 t 值；标准误按 $CLUSTER 聚类；末列为普通组内未聚类对照。") replace
    capture esttab `stored_main' using "${OUT_ROOT}/tables/table2-main-regression.tex", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label booktabs nogaps substitute("=" "") ///
        stats(N r2 r2_a r2_within, fmt(0 3 3 3) labels("观测值" "R²" "调整 R²" "Within R²")) replace
}
capture confirm file "${OUT_ROOT}/tables/table2-main-regression.csv"
local main_ok = !_rc

file open fm using "${OUT_ROOT}/reports/main-models-results.md", write replace
file write fm "# Main Models Results" _n _n
file write fm "已运行 reghdfe 高维固定效应主回归阶梯：m1/m2/m3 与未聚类对照列 m4；表格见 table2-main-regression.csv。" _n
file close fm

file open flog using "${RUN_LOG}", write append
if `main_ok' {
    file write flog "| `c(current_date)' | 03-regression/01-main-models | ok | table1-descriptives.csv<br>table2-main-regression.csv<br>main-models-results.md | 已运行 reghdfe 高维固定效应主回归阶梯（含未聚类对照列）。 |" _n
}
else {
    file write flog "| `c(current_date)' | 03-regression/01-main-models | blocked | - | 未生成主回归表；请检查 Y/X/C、ABSORB/CLUSTER 角色与 reghdfe 依赖。 |" _n
}
file close flog
if !`main_ok' exit 2