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
global ABSORB "$ID $TIME"
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
        file write fg "| `c(current_date)' | 03-regression/03-panel | blocked | - | 缺少 reghdfe，无法执行高维固定效应估计。 |" _n
        file close fg
        exit 2
    }
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

* 经典 FE/RE 仅用于 Hausman 诊断，不进入结果表
capture noisily xtreg $Y $X $C i.$TIME, fe vce(cluster $CLUSTER)
if !_rc estimates store fe_diag
capture noisily xtreg $Y $X $C i.$TIME, re vce(cluster $CLUSTER)
if !_rc estimates store re_diag
capture hausman fe_diag re_diag, sigmamore
local hm_chi2 = r(chi2)
local hm_df = r(df)
local hm_p = r(p)

* 高维固定效应：个体 FE 与双向 FE（reghdfe）
local stored_panel ""
capture noisily reghdfe $Y $X $C, absorb($ID) vce(cluster $CLUSTER)
if !_rc {
    estimates store hdfe_fe
    local stored_panel "`stored_panel' hdfe_fe"
}
capture noisily reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store hdfe_twfe
    local stored_panel "`stored_panel' hdfe_twfe"
}

* 动态面板：xtabond2 两步系统 GMM（未安装时跳过并记录）
capture which xtabond2
if !_rc {
    capture noisily xtabond2 $Y L.$Y $X $C i.$TIME, gmm(L.$Y, lag(2 4) collapse) iv($X $C) robust twostep
    if !_rc {
        local ar1p = r(ar1p)
        local ar2p = r(ar2p)
        local hansenp = r(hansenp)
        capture estadd scalar ar1p = `ar1p'
        capture estadd scalar ar2p = `ar2p'
        capture estadd scalar hansenp = `hansenp'
        estimates store dyn_gmm
        local stored_panel "`stored_panel' dyn_gmm"
    }
}

if "`stored_panel'" != "" {
    capture esttab `stored_panel' using "${OUT_ROOT}/tables/tableA-panel-models.csv", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
        stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
        addnotes("注：动态面板列另报 AR(1)/AR(2)/Hansen 检验标量（ar1p/ar2p/hansenp），以 estadd 输出为准。") ///
        replace
}
capture confirm file "${OUT_ROOT}/tables/tableA-panel-models.csv"
local panel_ok = !_rc

file open fp using "${OUT_ROOT}/reports/panel-diagnostics.md", write replace
file write fp "# Panel Diagnostics" _n _n
file write fp "已运行 xtreg FE/RE 与 Hausman 诊断；结果表列使用 reghdfe 个体 FE / 双向 FE；动态面板使用 xtabond2 两步系统 GMM（命令缺失时跳过）。" _n
if "`hm_p'" != "" {
    if `hm_p' < . {
        file write fp "Hausman 检验：chi2(`hm_df') = `hm_chi2'，p = `hm_p'。" _n
    }
}
file close fp

file open flog using "${RUN_LOG}", write append
if `panel_ok' {
    file write flog "| `c(current_date)' | 03-regression/03-panel | ok | tableA-panel-models.csv<br>panel-diagnostics.md | 已运行 reghdfe 高维固定效应与 xtabond2 动态面板候选模型。 |" _n
}
else {
    file write flog "| `c(current_date)' | 03-regression/03-panel | blocked | panel-diagnostics.md | 未生成面板结果表；请检查 ID/TIME/CLUSTER 角色、reghdfe 依赖与样本条件。 |" _n
}
file close flog
if !`panel_ok' exit 2
