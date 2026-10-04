* Paper Analysis 4SS - 03 regression / 02 nonlinear models executable Stata template.
* 按 analysis-execution-plan 保留需要的块并删除不适用的方法块；本模板不做运行时条件跳过。
* 有序/多分类的类别号（-predict(outcome(#))- 与 -base()-）由改写者按 -tab <因变量>- 的实际取值替换，模板默认使用第一个实有类别与第 2 类展示类别。
* stset 会改写数据状态，故生存分析块放在文件末尾，其后不再使用原始样本口径。

version 16
clear all
set more off

local project_root : env PROJECT_ROOT
if "`project_root'" != "" & fileexists("`project_root'") cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global DATA "${OUT_ROOT}/data/analysis-data.dta"
global Y "outcome"
global BIN_Y "outcome_bin"
global X "treatment"
global C "age gender education income"
global FE "i.year i.region"
global CLUSTER "region"
global ORD_Y "outcome_ord"
global MULTI_Y "outcome_multi"
global MULTI_BASE "1"
global CENS_Y "duration"
global CENS_LOWER "0"
global COUNT_Y "outcome_count"
global PROP_Y "prop_outcome"
global DUR_Y "duration"
global DUR_FAIL "event"
global SEL_D "treated"
global SEL_Z "sel_z"
global ENDOG "endog_x"
global IV "instrument_z"
global TREAT "treated"
global TREAT_IV "treat_iv"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/nonlinear_models.log", replace text

use "${DATA}", clear

di "--> 估计表3：二元与计数模型的平均边际效应"
estimates clear
qui logit $BIN_Y $X $C $FE, vce(cluster $CLUSTER)
est store logit1
margins, dydx($X $C) post
est store ame_logit

qui probit $BIN_Y $X $C $FE, vce(cluster $CLUSTER)
est store probit1
margins, dydx($X $C) post
est store ame_probit

qui poisson $COUNT_Y $X $C $FE, vce(cluster $CLUSTER)
est store poisson1
margins, dydx($X $C) post
est store ame_poisson

esttab ame_logit ame_probit ame_poisson using "${OUT_ROOT}/tables/table3-nonlinear-marginal-effects.csv", ///
    b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：非线性模型必须报告边际效应或预测概率；括号内为 z 值。") replace

di "--> 估计表3b：有序 logit/probit 与多分类 logit"
estimates clear
qui ologit $ORD_Y $X $C $FE, vce(cluster $CLUSTER)
est store ologit1
margins, dydx($X $C) predict(outcome(1)) post
est store ame_ologit_c1
qui oprobit $ORD_Y $X $C $FE, vce(cluster $CLUSTER)
est store oprobit1
margins, dydx($X $C) predict(outcome(1)) post
est store ame_oprobit_c1
qui mlogit $MULTI_Y $X $C $FE, base($MULTI_BASE) vce(cluster $CLUSTER)
est store mlogit1
margins, dydx($X) predict(outcome(2)) post
est store ame_mlogit_c2
margins, rrr

esttab ame_ologit_c1 ame_oprobit_c1 ame_mlogit_c2 using "${OUT_ROOT}/tables/table3b-ordered-multinomial.csv", ///
    b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：有序模型报告指定类别（默认第 1 类，按 tab 实际取值替换）的边际效应；多分类模型基准类别为 $MULTI_BASE，报告第 2 类的预测概率边际效应；括号内为 z 值。") ///
    replace

di "--> 估计表3c：删失与样本选择模型"
estimates clear
qui tobit $CENS_Y $X $C $FE, ll($CENS_LOWER) vce(cluster $CLUSTER)
est store tobit1
* 注意：tobit 的 margins 必须用 predict(ystar(#,.)) 双参数形式；单参数 ystar(0) 报 invalid syntax (r198)。
margins, dydx($X $C) predict(ystar($CENS_LOWER,.)) post
est store ame_tobit
qui heckman $CENS_Y $X $C, select($SEL_D = $X $C $SEL_Z) twostep
est store heckman1
qui ivtobit $CENS_Y $X ($ENDOG = $IV), ll($CENS_LOWER)
est store ivtobit1
qui etregress $CENS_Y $X $C, treat($TREAT = $X $C $SEL_Z) vce(cluster $CLUSTER)
est store etregress1

esttab ame_tobit heckman1 ivtobit1 etregress1 using "${OUT_ROOT}/tables/table3c-censored-selection.csv", ///
    b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：第 1 列为 Tobit 在左删失点上的边际效应 predict(ystar($CENS_LOWER))；第 2-4 列为 Heckman 两步法、IV-Tobit 与内生处理回归的系数；括号内为 z 值；Heckman 的选择方程为 $SEL_D = $X $C $SEL_Z。") ///
    replace

di "--> 估计表3d：计数、比例与持续时间模型"
estimates clear
qui poisson $COUNT_Y $X $C $FE, vce(cluster $CLUSTER)
scalar ll_pois = e(ll)
qui nbreg $COUNT_Y $X $C $FE, vce(cluster $CLUSTER)
est store nbreg1
scalar ll_nb = e(ll)
scalar nb_alpha = e(alpha)
scalar nb_lr = 2*(ll_nb - ll_pois)
scalar nb_lrp = chi2tail(1, nb_lr)/2
qui fracreg logit $PROP_Y $X $C, vce(cluster $CLUSTER)
est store fracreg1

stset $DUR_Y, failure($DUR_FAIL)
qui streg $X $C, distribution(weibull) vce(cluster $CLUSTER)
est store weibull1
qui stcox $X $C, vce(cluster $CLUSTER)
est store cox1
stset, clear

esttab nbreg1 fracreg1 weibull1 cox1 using "${OUT_ROOT}/tables/table3d-count-fractional-duration.csv", ///
    b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：第 1 列为负二项回归（过度离散 alpha = `=string(nb_alpha,"%9.3f")'，alpha=0 的 LR 检验 p = `=string(nb_lrp,"%9.3f")'）；第 2 列为比例因变量的 fractional logit；第 3 列 Weibull 报告系数，第 4 列 Cox 报告风险比 exp(b)；括号内为 z 值。") ///
    replace

di "--> 表3e：非线性模型诊断"
file open fq using "${OUT_ROOT}/tables/table3e-nonlinear-diagnostics.csv", write replace
file write fq "诊断项,logit,probit,ologit,oprobit,mlogit,poisson,nbreg" _n

qui logit $BIN_Y $X $C $FE, vce(cluster $CLUSTER)
qui linktest
scalar lt_logit = 2*normal(-abs(r(t)))
qui estat classification
scalar cc_logit = r(P_corr)
qui lroc
scalar auc_logit = r(area)
qui estat gof
scalar gof_logit = r(p)
qui estat ic
scalar aic_logit = r(S)[1,5]
scalar bic_logit = r(S)[1,6]

qui probit $BIN_Y $X $C $FE, vce(cluster $CLUSTER)
qui linktest
scalar lt_probit = 2*normal(-abs(r(t)))
qui estat classification
scalar cc_probit = r(P_corr)
qui estat gof
scalar gof_probit = r(p)
qui estat ic
scalar aic_probit = r(S)[1,5]
scalar bic_probit = r(S)[1,6]

* linktest 不适用于 mlogit/ologit/oprobit 与计数模型（官方限制），相关单元格留空
qui ologit $ORD_Y $X $C $FE, vce(cluster $CLUSTER)
qui estat ic
scalar aic_ologit = r(S)[1,5]
scalar bic_ologit = r(S)[1,6]

qui oprobit $ORD_Y $X $C $FE, vce(cluster $CLUSTER)
qui estat ic
scalar aic_oprobit = r(S)[1,5]
scalar bic_oprobit = r(S)[1,6]

qui mlogit $MULTI_Y $X $C $FE, base($MULTI_BASE) vce(cluster $CLUSTER)
qui estat ic
scalar aic_mlogit = r(S)[1,5]
scalar bic_mlogit = r(S)[1,6]

qui poisson $COUNT_Y $X $C $FE, vce(cluster $CLUSTER)
qui estat gof
scalar gof_pois = r(p)
qui estat ic
scalar aic_pois = r(S)[1,5]
scalar bic_pois = r(S)[1,6]

qui nbreg $COUNT_Y $X $C $FE, vce(cluster $CLUSTER)
qui estat ic
scalar aic_nb = r(S)[1,5]
scalar bic_nb = r(S)[1,6]

file write fq "linktest _hatsq p（模型设定）," %9.4f (lt_logit) "," %9.4f (lt_probit) ",,,,," _n
file write fq "分类正确率（estat classification）," %9.4f (cc_logit) "," %9.4f (cc_probit) ",,,,," _n
file write fq "AUC（lroc）," %9.4f (auc_logit) ",,,,,," _n
file write fq "拟合优度检验 p（estat gof）," %9.4f (gof_logit) "," %9.4f (gof_probit) ",,," %9.4f (gof_pois) "," _n
file write fq "AIC（estat ic）," %9.3f (aic_logit) "," %9.3f (aic_probit) "," %9.3f (aic_ologit) "," %9.3f (aic_oprobit) "," %9.3f (aic_mlogit) "," %9.3f (aic_pois) "," %9.3f (aic_nb) _n
file write fq "BIC（estat ic）," %9.3f (bic_logit) "," %9.3f (bic_probit) "," %9.3f (bic_ologit) "," %9.3f (bic_oprobit) "," %9.3f (bic_mlogit) "," %9.3f (bic_pois) "," %9.3f (bic_nb) _n
file write fq "过度离散 alpha（nbreg）,,,,,,," %9.4f (nb_alpha) _n
file write fq "过度离散 LR 检验 p（nbreg）,,,,,,," %9.4f (nb_lrp) _n
file close fq

capture log close _all
