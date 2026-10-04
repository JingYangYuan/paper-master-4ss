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
global ID "pid"
global TIME "year"
global ABSORB "$ID $TIME"
global CLUSTER "region"
global MECH "mediator"
global MODERATOR "moderator"
global RISKVAR "riskvar"
global PROVINCE "province"
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

capture which reghdfe
if _rc {
    capture ssc install reghdfe
    capture which reghdfe
    if _rc {
        file open fg using "${RUN_LOG}", write append
        file write fg "| `c(current_date)' | 03-regression/05-mechanism-heterogeneity | blocked | - | 缺少 reghdfe，无法执行高维固定效应估计。 |" _n
        file close fg
        exit 2
    }
}

capture confirm file "${DATA}"
if _rc exit 2
use "${DATA}", clear

* ---- 机制检验：江艇（2022）两步法 ----
* 第一步：X -> Y 基准因果效应（不放入机制变量）
local stored_mech ""
capture noisily reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store mech_step1
    local stored_mech "`stored_mech' mech_step1"
}
* 第二步：X -> M_k 直接赋能检验（多机制渠道用空格分隔写入 $MECH）
foreach m of global MECH {
    capture noisily reghdfe `m' $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
    if !_rc {
        estimates store mech_`m'
        local stored_mech "`stored_mech' mech_`m'"
    }
}

* ---- 调节效应：四列递进规范（含仅交乘项中心化）----
capture drop JC c_X c_MOD c_JC
gen double JC = $X * $MODERATOR
quietly summarize $X, meanonly
gen double c_X = $X - r(mean)
quietly summarize $MODERATOR, meanonly
gen double c_MOD = $MODERATOR - r(mean)
gen double c_JC = c_X * c_MOD

local stored_mod ""
capture noisily reghdfe $Y $X JC $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store mod_omitted
    local stored_mod "`stored_mod' mod_omitted"
}
capture noisily reghdfe $Y $X $MODERATOR JC $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store mod_corrected
    local stored_mod "`stored_mod' mod_corrected"
}
capture noisily reghdfe $Y $X $MODERATOR c_JC $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store mod_centered
    local stored_mod "`stored_mod' mod_centered"
    margins, dydx($X) at($MODERATOR = (0(1)5))
    marginsplot, name(margins_interact, replace)
    capture graph export "${OUT_ROOT}/figures/marginal-effects.png", replace width(1600)
}
capture noisily reghdfe $Y c_X c_MOD c_JC $C, absorb($ABSORB) vce(cluster $CLUSTER)
if !_rc {
    estimates store mod_full
    local stored_mod "`stored_mod' mod_full"
}
* 双口径对照列：普通组内未聚类标准误（不写 vce 选项）
capture noisily reghdfe $Y $X $MODERATOR c_JC $C, absorb($ABSORB)
if !_rc {
    estimates store mod_centered_unclustered
    local stored_mod "`stored_mod' mod_centered_unclustered"
}

local stored_all "`stored_mech' `stored_mod'"
if "`stored_all'" != "" {
    capture esttab `stored_all' using "${OUT_ROOT}/tables/table3-mechanism-mediation-moderation.csv", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
        stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
        addnotes("注：mech_step1 为第一步 X→Y 基准效应，mech_* 为第二步 X→M 机制检验（江艇两步法，不将机制变量放入 Y 方程）；mod_* 为调节效应四列递进规范与双口径标准误对照。") ///
        replace
}
capture confirm file "${OUT_ROOT}/tables/table3-mechanism-mediation-moderation.csv"
local mech_ok = !_rc

* ---- 异质性检验：分组 + 风控门槛 + 区域区位 ----
local stored ""

* (a) 既有分组变量
capture confirm variable $GROUP
if !_rc {
    capture levelsof $GROUP, local(groups)
    capture confirm string variable $GROUP
    local group_is_string = !_rc
    foreach g of local groups {
        if `group_is_string' {
            capture noisily reghdfe $Y $X $C if $GROUP == "`g'", absorb($ABSORB) vce(cluster $CLUSTER)
        }
        else {
            capture noisily reghdfe $Y $X $C if $GROUP == `g', absorb($ABSORB) vce(cluster $CLUSTER)
        }
        if !_rc {
            local clean_g = strtoname("`g'")
            estimates store het_`clean_g'
            local stored "`stored' het_`clean_g'"
        }
    }
}

* (b) 风控门槛：按 $RISKVAR 全样本中位数分高风险组/低风险组
capture confirm variable $RISKVAR
if !_rc {
    quietly summarize $RISKVAR, detail
    local rmed = r(p50)
    capture drop high_risk
    gen byte high_risk = $RISKVAR > `rmed'
    foreach g in 0 1 {
        capture noisily reghdfe $Y $X $C if high_risk == `g', absorb($ABSORB) vce(cluster $CLUSTER)
        if !_rc {
            estimates store het_risk_`g'
            local stored "`stored' het_risk_`g'"
        }
    }
}

* (c) 区域区位：东部/中部/西部三分法与沿海（东部）/内陆二分法（国家统计局三大地带）
* 地级市→省份映射属项目清洗层（如 city_province_map.dta），模板在 province 字段就绪后归类
capture confirm variable $PROVINCE
if !_rc {
    capture confirm string variable $PROVINCE
    if !_rc {
        capture drop _belt
        gen byte _belt = .
        replace _belt = 1 if inlist($PROVINCE, "北京", "天津", "河北", "辽宁", "上海", "江苏", "浙江", "福建", "山东", "广东", "海南")
        replace _belt = 2 if inlist($PROVINCE, "山西", "吉林", "黑龙江", "安徽", "江西", "河南", "湖北", "湖南")
        replace _belt = 3 if inlist($PROVINCE, "内蒙古", "广西", "重庆", "四川", "贵州", "云南", "西藏", "陕西", "甘肃", "青海", "宁夏", "新疆")
    }
    else {
        capture drop _belt
        gen byte _belt = .
        replace _belt = 1 if inlist($PROVINCE, 11, 12, 13, 21, 31, 32, 33, 35, 37, 44, 46)
        replace _belt = 2 if inlist($PROVINCE, 14, 22, 23, 34, 36, 41, 42, 43)
        replace _belt = 3 if inlist($PROVINCE, 15, 45, 50, 51, 52, 53, 54, 61, 62, 63, 64, 65)
    }
    foreach b in 1 2 3 {
        capture noisily reghdfe $Y $X $C if _belt == `b', absorb($ABSORB) vce(cluster $CLUSTER)
        if !_rc {
            estimates store het_belt_`b'
            local stored "`stored' het_belt_`b'"
        }
    }
    capture drop _coast
    gen byte _coast = (_belt == 1)
    foreach b in 1 0 {
        capture noisily reghdfe $Y $X $C if _coast == `b', absorb($ABSORB) vce(cluster $CLUSTER)
        if !_rc {
            estimates store het_coast_`b'
            local stored "`stored' het_coast_`b'"
        }
    }
}

if "`stored'" != "" {
    capture esttab `stored' using "${OUT_ROOT}/tables/table4-heterogeneity-threshold-nonlinear.csv", ///
        b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
        stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) replace
}
capture confirm file "${OUT_ROOT}/tables/table4-heterogeneity-threshold-nonlinear.csv"
local het_ok = !_rc

file open flog using "${RUN_LOG}", write append
if `mech_ok' | `het_ok' {
    file write flog "| `c(current_date)' | 03-regression/05-mechanism-heterogeneity | ok | table3-mechanism-mediation-moderation.csv<br>table4-heterogeneity-threshold-nonlinear.csv | 已运行江艇两步法机制检验、四列调节效应规范与多维异质性模型；缺失产物不得声称。 |" _n
}
else {
    file write flog "| `c(current_date)' | 03-regression/05-mechanism-heterogeneity | blocked | - | 未生成可导出表格；请检查 MECH/MODERATOR/RISKVAR/PROVINCE/GROUP 角色、reghdfe 依赖和样本条件。 |" _n
}
file close flog
if !(`mech_ok' | `het_ok') exit 2