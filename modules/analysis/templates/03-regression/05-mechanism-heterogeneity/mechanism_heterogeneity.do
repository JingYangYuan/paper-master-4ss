* Paper Analysis 4SS - 03 regression / 05 mechanism and heterogeneity executable Stata template.

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
global MEDIATOR "mediator"
global MODERATOR "moderator"
global GROUP "group"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
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

local stored_mech ""
capture noisily regress $Y $X $C $FE, vce(cluster $CLUSTER)
if !_rc {
    estimates store total
    local stored_mech "`stored_mech' total"
}
capture noisily regress $MEDIATOR $X $C $FE, vce(cluster $CLUSTER)
if !_rc {
    estimates store path_a
    local stored_mech "`stored_mech' path_a"
}
capture noisily regress $Y $X $MEDIATOR $C $FE, vce(cluster $CLUSTER)
if !_rc {
    estimates store path_b
    local stored_mech "`stored_mech' path_b"
}
capture noisily regress $Y c.$X##c.$MODERATOR $C $FE, vce(cluster $CLUSTER)
if !_rc {
    estimates store moderation
    local stored_mech "`stored_mech' moderation"
    margins, dydx($X) at($MODERATOR = (0(1)5))
    marginsplot, name(margins_interact, replace)
    capture graph export "${OUT_ROOT}/figures/marginal-effects.png", replace width(1600)
}

if "`stored_mech'" != "" {
    capture esttab `stored_mech' using "${OUT_ROOT}/tables/table3-mechanism-mediation-moderation.csv", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps ///
        stats(N r2, fmt(0 3) labels("观测值" "R²")) replace
}
capture confirm file "${OUT_ROOT}/tables/table3-mechanism-mediation-moderation.csv"
local mech_ok = !_rc

capture noisily levelsof $GROUP, local(groups)
local stored ""
capture confirm string variable $GROUP
local group_is_string = !_rc
foreach g of local groups {
    if `group_is_string' {
        capture noisily regress $Y $X $C $FE if $GROUP == "`g'", vce(cluster $CLUSTER)
    }
    else {
        capture noisily regress $Y $X $C $FE if $GROUP == `g', vce(cluster $CLUSTER)
    }
    if !_rc {
        local clean_g = strtoname("`g'")
        estimates store het_`clean_g'
        local stored "`stored' het_`clean_g'"
    }
}
if "`stored'" != "" {
    capture esttab `stored' using "${OUT_ROOT}/tables/table4-heterogeneity-threshold-nonlinear.csv", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps replace
}
capture confirm file "${OUT_ROOT}/tables/table4-heterogeneity-threshold-nonlinear.csv"
local het_ok = !_rc

file open flog using "${RUN_LOG}", write append
if `mech_ok' | `het_ok' {
    file write flog "| `c(current_date)' | 03-regression/05-mechanism-heterogeneity | ok | table3-mechanism-mediation-moderation.csv<br>table4-heterogeneity-threshold-nonlinear.csv | 已运行机制、调节和异质性候选模型；缺失产物不得声称。 |" _n
}
else {
    file write flog "| `c(current_date)' | 03-regression/05-mechanism-heterogeneity | blocked | - | 机制、调节和异质性模型均未生成可导出表格；请检查 mediator/moderator/group 角色和样本条件。 |" _n
}
file close flog
if !(`mech_ok' | `het_ok') exit 2
