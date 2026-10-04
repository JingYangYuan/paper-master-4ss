* Paper Analysis 4SS - 03 regression / 05 mechanism and heterogeneity executable Stata template.
* 按 analysis-execution-plan 保留需要的块并删除不适用的方法块；本模板不做运行时条件跳过。

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
global ID "pid"
global TIME "year"
global ABSORB "$ID $TIME"
global CLUSTER "region"
global MECH1 "mediator"
global MECH2 "mediator2"
global MODERATOR "moderator"
global RISKVAR "riskvar"
global PROVINCE "province"
global GROUP "group"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/mechanism_heterogeneity.log", replace text

use "${DATA}", clear

di "--> 估计表3：机制检验（江艇两步法）与调节效应"
* ---- 机制检验：江艇（2022）两步法 ----
* 第一步：X -> Y 基准因果效应（不放入机制变量）
estimates clear
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store mech_step1
* 第二步：X -> M_k 直接赋能检验（多机制渠道显式列出）
qui reghdfe $MECH1 $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store mech_m1
qui reghdfe $MECH2 $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store mech_m2

* ---- 调节效应：四列递进规范（含仅交乘项中心化）----
gen double JC = $X * $MODERATOR
quietly summarize $X, meanonly
gen double c_X = $X - r(mean)
quietly summarize $MODERATOR, meanonly
gen double c_MOD = $MODERATOR - r(mean)
gen double c_JC = c_X * c_MOD

qui reghdfe $Y $X JC $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store mod_omitted
qui reghdfe $Y $X $MODERATOR JC $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store mod_corrected
qui reghdfe $Y $X $MODERATOR c_JC $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store mod_centered
margins, dydx($X) at($MODERATOR = (0(1)5))
marginsplot, name(margins_interact, replace)
graph export "${OUT_ROOT}/figures/marginal-effects.png", replace width(1600)
qui reghdfe $Y c_X c_MOD c_JC $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store mod_full
* 双口径对照列：普通组内未聚类标准误（不写 vce 选项）
qui reghdfe $Y $X $MODERATOR c_JC $C, absorb($ABSORB)
est store mod_centered_unclustered

esttab mech_step1 mech_m1 mech_m2 mod_omitted mod_corrected mod_centered mod_full mod_centered_unclustered ///
    using "${OUT_ROOT}/tables/table3-mechanism-mediation-moderation.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：mech_step1 为第一步 X→Y 基准效应，mech_m* 为第二步 X→M 机制检验（江艇两步法，不将机制变量放入 Y 方程）；mod_* 为调节效应四列递进规范与双口径标准误对照。") ///
    replace

* ---- 异质性检验：分组 + 风控门槛 + 区域区位 ----
estimates clear

* (a) 既有分组变量
qui reghdfe $Y $X $C if $GROUP == 0, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_g0
qui reghdfe $Y $X $C if $GROUP == 1, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_g1

* (b) 风控门槛：按 $RISKVAR 全样本中位数分高风险组/低风险组
qui summarize $RISKVAR, detail
gen byte high_risk = $RISKVAR > r(p50)
qui reghdfe $Y $X $C if high_risk == 0, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_risk0
qui reghdfe $Y $X $C if high_risk == 1, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_risk1

* (c) 区域区位：东部/中部/西部三分法与沿海（东部）/内陆二分法（国家统计局三大地带）
* 地级市→省份映射属项目清洗层（如 city_province_map.dta），模板在 province 字段就绪后归类
* inlist() 在字符串参数过多时会报 r(130) expression too long，故用竖线分隔的全名串精确匹配
gen byte _belt = .
replace _belt = 1 if strpos("|北京|天津|河北|辽宁|上海|江苏|浙江|福建|山东|广东|海南|", "|" + $PROVINCE + "|") > 0
replace _belt = 2 if strpos("|山西|吉林|黑龙江|安徽|江西|河南|湖北|湖南|", "|" + $PROVINCE + "|") > 0
replace _belt = 3 if strpos("|内蒙古|广西|重庆|四川|贵州|云南|西藏|陕西|甘肃|青海|宁夏|新疆|", "|" + $PROVINCE + "|") > 0
qui reghdfe $Y $X $C if _belt == 1, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_belt1
qui reghdfe $Y $X $C if _belt == 2, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_belt2
qui reghdfe $Y $X $C if _belt == 3, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_belt3
gen byte _coast = (_belt == 1)
qui reghdfe $Y $X $C if _coast == 1, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_coast1
qui reghdfe $Y $X $C if _coast == 0, absorb($ABSORB) vce(cluster $CLUSTER)
est store het_coast0

esttab het_g0 het_g1 het_risk0 het_risk1 het_belt1 het_belt2 het_belt3 het_coast1 het_coast0 ///
    using "${OUT_ROOT}/tables/table4-heterogeneity-threshold-nonlinear.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) replace

di "--> 表3s：中介效应稳健性（Imai 因果中介、KHB 分解、参数化中介）"
* medeff 的方程顺序必须是中介变量方程在前，否则报 Mediate variable not the dependent variable in equation 1。
medeff (regress $MECH1 $X $C) (regress $Y $MECH1 $X $C), mediate($MECH1) treat($X) sims(1000)
khb regress $Y $X || $MECH1
qui paramed $Y, avar($X) mvar($MECH1) a0(0) a1(1) m(0) yreg(linear) mreg(linear) bootstrap reps(200)

file open f3s using "${OUT_ROOT}/tables/table3s-mediation-robustness.csv", write replace
file write f3s "方法,内容" _n
file write f3s "Imai 因果中介分析 (medeff),见日志：ACME/ACME(平均直接效应)/总效应的点估计与 95% 区间（sims=1000）" _n
file write f3s "KHB 分解 (khb),见日志：总效应/直接效应/间接效应及其占比" _n
file write f3s "参数化中介 (paramed),见日志：自然直接效应/自然间接效应（bootstrap 200 次）" _n
file write f3s "注,主识别为江艇（2022）两步法（table3-mechanism-mediation-moderation.csv 的 mech_* 列）；本表为补充证据" _n
file close f3s

di "--> 表4b：组间系数差异检验"
estimates clear
qui reghdfe $Y $X $C if $GROUP == 0, absorb($ABSORB) vce(cluster $CLUSTER)
est store gd_g0
qui reghdfe $Y $X $C if $GROUP == 1, absorb($ABSORB) vce(cluster $CLUSTER)
est store gd_g1
* 交互项检验是无需外部包的主口径
gen byte _g1 = ($GROUP == 1)
gen double _xg = $X * _g1
qui reghdfe $Y $X _g1 _xg $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store gd_interact
test _xg = 0
local gd_p = r(p)
* bdiff 的选项名以 help bdiff 为准（model() 内写完整回归命令）
bdiff, group($GROUP) model(reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER))

esttab gd_g0 gd_g1 gd_interact using "${OUT_ROOT}/tables/table4b-group-difference.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：前两列为分组回归；第 3 列为全样本交互项模型，_xg 的检验 p = `gd_p'（交互项为零即组间无差异）。bdiff 的 Fisher 置换检验结果见日志。") ///
    replace

di "--> 表4c：门槛回归（候选门槛值网格搜索）"
* xthreg/threshold 不在本机 SSC 可装范围，故用 reghdfe 在候选门槛上做分组估计（无外部依赖）。
preserve
keep if !missing($RISKVAR)
estimates clear
foreach p in 20 40 60 80 {
    qui _pctile $RISKVAR, p(`p')
    local thr = r(r1)
    qui reghdfe $Y $X $C if $RISKVAR <= `thr', absorb($ABSORB) vce(cluster $CLUSTER)
    est store thr`p'_low
    qui reghdfe $Y $X $C if $RISKVAR > `thr', absorb($ABSORB) vce(cluster $CLUSTER)
    est store thr`p'_high
}
esttab thr20_low thr20_high thr40_low thr40_high thr60_low thr60_high thr80_low thr80_high ///
    using "${OUT_ROOT}/tables/table4c-threshold-grid.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：门槛候选为 $RISKVAR 的 20/40/60/80 分位点；每对列为该门槛下的低组与高组回归。门槛值本身见日志 _pctile 输出；改写者按项目改为专有候选门槛列表。") ///
    replace
restore

capture log close _all
