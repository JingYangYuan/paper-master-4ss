* Paper Analysis 4SS - 03 regression / 04 causal models executable Stata template.
* 按 analysis-execution-plan 保留需要的块并删除不适用的方法块；本模板不做运行时条件跳过。
* ivreghdfe 的回归量不得含与吸收的个体固定效应共线的时不变控制变量；如报 rc=504，删除或替换该控制变量后重跑。
* 恰好识别时删除表A1a 的 estat overid 行（报 invalid subcommand）。
* 表A1c 的 bacondecomp 需要至少 2 个处理时点组，否则报 r(3301)。
* 表A1f 的 synth/sdid/scpi 要求单一处理单元且处理前后都有足够期数；不满足时按项目数据结构删除该块。
* csdid 的 cluster() 不得等于 ivar()。

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
global CLUSTER "region"
global ID "pid"
global TIME "year"
global ABSORB "$ID $TIME"
global TREAT "treated"
global POST "post"
global POST_PERIOD "2019"
global GVAR "first_treat_year"
global GVARM "first_treat_year_miss"
global NEVER "never_treated"
global TREAT_V "treated"
global DID_D "treated"
global EVENT "rel_year"
global ES_L "L1_es"
global ES_F "F0_es F1_es"
global ENDOG "endog_x"
global IV "instrument_z"
global IV2 "instrument_z2"
global IVX "instrument_z instrument_z2"
global RUNNING "running_score"
global CUTOFF "0"
global SCM_UNIT "pid"
global SCM_TREATED "1"
global SCM_PERIOD "2019"
global SCM_PRED "outcome(2016) outcome(2017) outcome(2018)"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/causal_models.log", replace text

use "${DATA}", clear

di "--> 表A1：IV/2SLS、DID 主结果"
estimates clear
* 第一阶段：IV -> 内生变量（高维吸收）
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

esttab first_stage iv_2sls did_2x2 did_twfe using "${OUT_ROOT}/tables/tableA1-causal-robustness.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：first_stage 为第一阶段；iv_2sls 为高维吸收 2SLS；did_2x2 为 2×2 DID；did_twfe 为双向固定效应 DID。Kleibergen-Paap rk Wald F = `kp'；Cragg-Donald F = `cdf'；不可识别检验 p = `idp'。") replace

di "--> 表A1a：IV 诊断（第一阶段、弱工具、过度识别、内生性）"
estimates clear
* estat firststage / estat endogenous / estat overid 只对官方 ivregress 有效，ivreg2 会报 r(321)。
* estat overid 还需要非稳健 VCE 且模型过度识别，故此处用双工具 $IV $IV2 与无 vce 的 ivregress 跑过度识别检验。
qui ivregress 2sls $Y $C ($ENDOG = $IV), vce(cluster $CLUSTER)
est store iv_ivregress
estat firststage
estat endogenous
qui ivregress 2sls $Y $C ($ENDOG = $IV $IV2)
estat overid
* weakiv 与 estat overid 都需要过度识别模型，故诊断列统一使用扩展工具集 $IVX。
qui ivreg2 $Y $C ($ENDOG = $IVX), cluster($CLUSTER) first
est store iv_ivreg2
local kp2 = e(widstat)
local cdf2 = e(cdf)
local idp2 = e(idp)
qui ivreghdfe $Y $C ($ENDOG = $IV), absorb($ABSORB) vce(cluster $CLUSTER) liml first
est store iv_liml
qui ivregress gmm $Y $C ($ENDOG = $IV), vce(cluster $CLUSTER)
est store iv_gmm
* weakiv 必须直接跟在过度识别的 ivreg2 之后调用（不可传 est store 的名称，否则报 unsupported estimator）。
weakiv
boottest $ENDOG, cluster($CLUSTER) reps(999) nograph

esttab iv_ivreg2 iv_liml iv_gmm using "${OUT_ROOT}/tables/tableA1a-iv-diagnostics.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2, fmt(0 3) labels("观测值" "R²")) ///
    addnotes("注：iv_ivreg2 为 ivreg2/2SLS，iv_liml 为 LIML（弱工具时更稳健），iv_gmm 为 GMM。Kleibergen-Paap rk Wald F = `kp2'；Cragg-Donald F = `cdf2'；不可识别检验 p = `idp2'。第一阶段 F、内生性与过度识别检验、weakiv 弱工具稳健推断与 boottest wild cluster bootstrap 见日志。") replace

di "--> 表A1b：事件研究（多种异质性稳健估计量）"
estimates clear
qui csdid $Y $C, ivar($ID) time($TIME) gvar($GVAR) method(dripw) cluster($CLUSTER) agg(event)
est store es_csdid
qui did_imputation $Y $ID $TIME $GVARM, horizons(0/5) pretrend(5) minn(0) autosample
est store es_didimp
qui eventstudyinteract $Y $ES_L $ES_F, vce(cluster $ID) absorb($ID $TIME) cohort($GVAR) control_cohort($NEVER)
est store es_esi
qui did2s $Y, first_stage($ID $TIME) second_stage($ES_L $ES_F) treatment($TREAT_V) cluster($ID)
est store es_did2s
qui stackedev $Y $ES_L $ES_F, cohort($GVAR) time($TIME) never_treat($NEVER) unit_fe($ID) clust_unit($ID)
est store es_stacked
qui jwdid $Y, ivar($ID) time($TIME) gvar($GVAR)
est store es_jwdid
* did_multiplegt / did_multiplegt_dyn 仅在处理变量存在稳定切换组时可用，按项目数据结构保留或删除

esttab es_csdid es_didimp es_esi es_did2s es_stacked es_jwdid using "${OUT_ROOT}/tables/tableA1b-did-event-study.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：列依次为 csdid（DRIPW 事件研究聚合）、did_imputation（Borusyak 等）、eventstudyinteract（Sun-Abraham）、did2s（Gardner 两阶段）、stackedev（堆叠 DID）、jwdid（Wooldridge）。事前系数联合不显著支持平行趋势。") replace

di "--> 表A1c：DID 诊断与平行趋势敏感性"
* 事件研究命令（如 stackedev）会改写数据集为堆叠格式，故此处重新载入原始分析数据。
use "${DATA}", clear
* bacondecomp 需要 xtset 面板设定，且需要 ≥2 个处理时点组
xtset $ID $TIME
bacondecomp $Y $DID_D, ddetail
* honestdid 需要 e(b)/e(V) 里同时含事前与事后事件系数，故对事件研究回归调用；
* 亦可用 csdid 的 agg(event)，但需其系数个数满足 numpreperiods+numpostperiods。
qui csdid $Y $C, ivar($ID) time($TIME) gvar($GVAR) method(dripw) cluster($CLUSTER) agg(event)
use "${DATA}", clear
qui reghdfe $Y Dm4 Dm3 Dm2 Dp0 Dp1 Dp2 Dp3 $C, absorb($ABSORB) vce(cluster $CLUSTER)
honestdid, numpreperiods(3) numpostperiods(4) mvec(0(0.5)2)

file open fd using "${OUT_ROOT}/tables/tableA1c-did-diagnostics.csv", write replace
file write fd "检验,统计量/结论" _n
file write fd "Bacon 分解 (bacondecomp),见日志：处理组/时点的 2×2 DID 权重与分解" _n
file write fd "平行趋势敏感性 (honestdid),见日志：相对幅度 M 取值 0 至 2 的稳健置信区间" _n
file close fd

di "--> 表A1：2×2 双重稳健 DID（drdid）"
preserve
keep if inlist($TIME, `= $POST_PERIOD - 1', $POST_PERIOD)
qui drdid $Y $C, ivar($ID) time($TIME) treatment($TREAT_V) cluster($CLUSTER)
est store drdid_2x2
restore

di "--> 表A1d：断点回归（主估计、带宽敏感性、安慰剂断点）"
estimates clear
qui rdrobust $Y $RUNNING, c($CUTOFF) covs($C)
est store rd_main
foreach b in 0.5 1 1.5 2 {
    qui rdrobust $Y $RUNNING, c($CUTOFF) h(`b')
    est store rd_h`=subinstr("`b'",".","_",.)'
}
foreach pc in -1 -0.5 0.5 1 {
    local nm = subinstr("`pc'","-","m",1)
    local nm = subinstr("`nm'",".","_",.)
    qui rdrobust $Y $RUNNING, c(`pc')
    est store rd_placebo_`nm'
}
rddensity $RUNNING, c($CUTOFF)

esttab rd_main rd_h0_5 rd_h1 rd_h1_5 rd_h2 rd_placebo_m1 rd_placebo_m0_5 rd_placebo_0_5 rd_placebo_1 ///
    using "${OUT_ROOT}/tables/tableA1d-rd.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：第 1 列为主估计（协变量 $C，默认带宽）；第 2-5 列为带宽 0.5/1/1.5/2 敏感性；第 6-9 列为安慰剂断点 -1/-0.5/0.5/1。rddensity 的操纵检验见日志。") replace

di "--> 表A1e：匹配与加权（PSM、CEM、熵平衡、IPW/AIPW）"
estimates clear
qui psmatch2 $TREAT_V $C, outcome($Y) neighbor(1) common
est store psm_nn
pstest $C, both
qui cem $C, treatment($TREAT_V)
qui ebalance $TREAT_V $C, targets(2)
qui teffects ipw ($Y) ($TREAT_V $C), atet
est store teffects_ipw
qui teffects aipw ($Y $C) ($TREAT_V $C), atet
est store teffects_aipw
qui kmatch ps $TREAT_V $C (($Y)), att
est store kmatch_ps

esttab teffects_ipw teffects_aipw using "${OUT_ROOT}/tables/tableA1e-matching.csv", ///
    b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：IPW 与 AIPW 的 ATET 估计。psmatch2 最近邻匹配与 kmatch 核匹配的 ATT 见日志；pstest/cem/ebalance 的平衡性见 matching-balance.csv。") replace

file open fb using "${OUT_ROOT}/tables/matching-balance.csv", write replace
file write fb "方法,平衡性/共同支撑来源" _n
file write fb "PSM 最近邻匹配,pstest 输出的标准化偏差与 t 检验（见日志）" _n
file write fb "CEM 粗化精确匹配,cem 输出的多元不平衡测度 L1（见日志）" _n
file write fb "熵平衡,ebalance 输出的约束满足与权重（见日志）" _n
file write fb "IPW/AIPW,teffects 的重叠与平衡诊断（见日志）" _n
file close fb

di "--> 表A1f：合成控制（synth、sdid）"
* synth 与 sdid 都要求 tsset 面板；sdid 的 vce(placebo)/vce(jackknife) 要求对照单元数多于处理单元数，
* 且 method(synth) 在本机报 r(3000)（nothing found where subexp expected），故此处用 method(sc)。
estimates clear
tsset $SCM_UNIT $TIME
qui synth $Y $SCM_PRED, trunit($SCM_TREATED) trperiod($SCM_PERIOD) figure
graph export "${OUT_ROOT}/figures/scm-${Y}.png", replace width(1600)
qui sdid $Y $SCM_UNIT $TIME $TREAT_V, vce(placebo) method(sc)
est store sdid1

esttab sdid1 using "${OUT_ROOT}/tables/tableA1f-scm.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：sdid 列为合成 DID（method(sc) 与 placebo 标准误）。synth 的处理单元-合成对照拟合与处理期效应见日志与 figures/scm-${Y}.png。") replace

file open fr using "${OUT_ROOT}/reports/causal-results.md", write replace
file write fr "# Causal Results" _n _n
file write fr "已运行 IV/2SLS/LIML/GMM、IV 诊断、2×2 与 TWFE DID、2×2 双重稳健 DID、事件研究（csdid/did_imputation/eventstudyinteract/did2s/stackedev/jwdid）、Bacon 分解与 honestdid 平行趋势敏感性、RDD（带宽与安慰剂断点）、PSM/CEM/熵平衡/IPW/AIPW 与合成控制。可声称内容以生成的表格和 .log 为准。" _n
file close fr

capture log close _all
