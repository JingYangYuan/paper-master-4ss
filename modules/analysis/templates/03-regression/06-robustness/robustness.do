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
        file write fg "| `c(current_date)' | 03-regression/06-robustness | blocked | - | 缺少 reghdfe，无法执行高维固定效应估计。 |" _n
        file close fg
        exit 2
    }
}

capture confirm file "${DATA}"
if _rc exit 2
use "${DATA}", clear

local stored_rb ""
capture noisily reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store base_cluster
    local stored_rb "`stored_rb' base_cluster"
}
capture noisily reghdfe $Y $X $C, absorb($ABSORB) vce(robust)
if !_rc {
    estimates store base_robust
    local stored_rb "`stored_rb' base_robust"
}
* 无固定效应对照列
capture noisily reghdfe $Y $X $C, vce(cluster $CLUSTER)
if !_rc {
    estimates store no_fe
    local stored_rb "`stored_rb' no_fe"
}
capture noisily reghdfe $Y $X, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store no_controls
    local stored_rb "`stored_rb' no_controls"
}
capture noisily reghdfe $Y $X $C if !missing($Y, $X), absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store complete_case
    local stored_rb "`stored_rb' complete_case"
}

if "`stored_rb'" != "" {
    capture esttab `stored_rb' using "${OUT_ROOT}/tables/tableA-robustness.csv", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
        stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
        addnotes("注：只声称本表真实运行的稳健性模型；未配置替代变量/样本/安慰剂见不可声称清单。") replace
}
capture confirm file "${OUT_ROOT}/tables/tableA-robustness.csv"
local rb_ok = !_rc

file open fc using "${OUT_ROOT}/reports/cannot-claim-list.md", write replace
file write fc "# Cannot Claim List" _n _n
file write fc "未在本脚本中成功运行的替代变量、替代样本、安慰剂和敏感性分析，不得写入结果结论。" _n
file close fc

file open flog using "${RUN_LOG}", write append
if `rb_ok' {
    file write flog "| `c(current_date)' | 03-regression/06-robustness | ok | tableA-robustness.csv<br>cannot-claim-list.md | 已运行 reghdfe 稳健性变体（聚类/稳健/无FE/无控制/完整个案）。 |" _n
}
else {
    file write flog "| `c(current_date)' | 03-regression/06-robustness | blocked | cannot-claim-list.md | 未生成稳健性表；请检查变量角色与 reghdfe 依赖。 |" _n
}
file close flog
if !`rb_ok' exit 2