* Paper Analysis 4SS - 03 regression / 06 robustness executable Stata template.
* 按 analysis-execution-plan 保留需要的块并删除不适用的方法块；本模板不做运行时条件跳过。
* psacalc 的选项是 rmax()（不是 r2max()）；子命令为 delta/beta。
* ritest 的 _b[...] 语法与 rwolf/wyoung 的选项以 help 为准。

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
global CLUSTER "region"
global ABSORB "$ID $TIME"
global POST_PERIOD "2019"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/robustness.log", replace text

use "${DATA}", clear

di "--> 表A：基准与替代口径稳健性"
estimates clear
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store base_cluster
qui reghdfe $Y $X $C, absorb($ABSORB) vce(robust)
est store base_robust
* 无固定效应对照列
qui reghdfe $Y $X $C, vce(cluster $CLUSTER)
est store no_fe
qui reghdfe $Y $X, absorb($ABSORB) vce(cluster $CLUSTER)
est store no_controls
qui reghdfe $Y $X $C if !missing($Y, $X), absorb($ABSORB) vce(cluster $CLUSTER)
est store complete_case

esttab base_cluster base_robust no_fe no_controls complete_case using "${OUT_ROOT}/tables/tableA-robustness.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：只声称本表真实运行的稳健性模型；未配置替代变量/样本/安慰剂见不可声称清单。") replace

di "--> 表A-inference：推断稳健性（wild cluster bootstrap、随机化推断、多重检验校正）"
estimates clear
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
boottest $X, cluster($CLUSTER) reps(999) nograph
* ritest 的语法是 ritest <聚类/置换变量> <统计量>；此处按 $CLUSTER 聚类做随机化推断。
ritest $CLUSTER _b[$X], reps(1000) cluster($CLUSTER): reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
* rwolf 的语法是 rwolf <因变量列表>, indepvar($X) ...；reghdfe 无法作为 method() 传入，故用默认 regress。
* 多重检验族为控制变量集合上的 X 系数。
rwolf $Y, indepvar($X) controls($C) reps(500) cluster($CLUSTER) vce(cluster $CLUSTER)
* wyoung 语法 1：把待同时检验的结果变量列在命令前，cmd() 中用 OUTCOMEVAR 占位。
wyoung $Y age education income, cmd(reghdfe OUTCOMEVAR $X $C, absorb($ABSORB) vce(cluster $CLUSTER)) familyp($X) bootstraps(500) cluster($CLUSTER)

file open fi using "${OUT_ROOT}/tables/tableA-robustness-inference.csv", write replace
file write fi "方法,内容" _n
file write fi "Wild cluster bootstrap (boottest),见日志：聚类 bootstrap 下的 p 值与置信区间（reps=999）" _n
file write fi "随机化推断 (ritest),见日志：随机置换下的 p 值（reps=1000，按 $CLUSTER 聚类）" _n
file write fi "Romano-Wolf 多重检验校正 (rwolf),见日志：逐步降序降幂 p 值（reps=500）" _n
file write fi "Westfall-Young 多重检验校正 (wyoung),见日志：bootstrap 校正 p 值（bootstraps=500）" _n
file close fi

di "--> 表A-sensitivity：未观测混淆敏感性（Oster、sensemakr、konfound）"
estimates clear
qui regress $Y $X $C
est store sens_base
* psacalc 的选项是 rmax()，不是 r2max()；rmax 必须大于受控 R²。
psacalc delta $X, rmax(0.5)
psacalc beta $X, delta(1)
* sensemakr 的 varlist 是「因变量 + 回归量」，最少 2 个变量。
sensemakr $Y $X $C, treat($X) benchmark($C) q(1) kd(1)
* konfound 需要内存中最近一次 regress/logit 估计；选项为 sig() 与 indx()（RIR 默认，IT 为 ITCV）。
konfound $X, sig(.05) indx(RIR)
konfound $X, sig(.05) indx(IT)

file open fs using "${OUT_ROOT}/tables/tableA-robustness-sensitivity.csv", write replace
file write fs "方法,内容" _n
file write fs "Oster delta (psacalc),见日志：使系数为零所需的未观测混淆强度比例（rmax=0.5 与 mcontrols 口径）" _n
file write fs "Oster beta (psacalc),见日志：delta=1 下稳健的系数界" _n
file write fs "sensemakr,见日志：RV（robustness value）与基准协变量强度下的界" _n
file write fs "konfound,见日志：使结论翻转所需替换案例比例（Impact / RIR / ITCV）" _n
file write fs "注,Python 与 R 生态对 Oster 的 psacalc 无等价实现，本表仅 Stata 与 R 提供" _n
file close fs

di "--> 表A-alternatives：替代样本窗口、替代标准误、替代估计量与替代缩尾"
estimates clear
qui reghdfe $Y $X $C if $TIME >= $POST_PERIOD, absorb($ABSORB) vce(cluster $CLUSTER)
est store alt_window
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $ID)
est store alt_cluster_id
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER $TIME)
est store alt_twoway
qui rreg $Y $X $C
est store alt_rreg
qui qreg2 $Y $X $C, cluster($CLUSTER) quantile(0.5)
est store alt_qreg50
* 替代缩尾比例：在 preserve/restore 内对 $Y 做 0.5/99.5 缩尾后重估
preserve
qui winsor2 $Y, cuts(0.5 99.5) replace
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store alt_winsor
restore
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store alt_base

esttab alt_base alt_window alt_cluster_id alt_twoway alt_rreg alt_qreg50 alt_winsor ///
    using "${OUT_ROOT}/tables/tableA-robustness-alternatives.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：列依次为基准、替代样本窗口（$TIME >= $POST_PERIOD）、替代聚类（$ID）、双向聚类（$CLUSTER $TIME）、稳健回归 rreg、中位数回归 qreg2、替代缩尾（0.5/99.5）。") replace

file open fc using "${OUT_ROOT}/reports/cannot-claim-list.md", write replace
file write fc "# Cannot Claim List" _n _n
file write fc "未在本脚本中成功运行的替代变量、替代样本、安慰剂和敏感性分析，不得写入结果结论。本脚本已运行：聚类/稳健标准误、无固定效应、无控制变量、完全案例、替代样本窗口、替代聚类层级、双向聚类、rreg、中位数回归、替代缩尾比例，以及 wild cluster bootstrap、ritest、rwolf、wyoung、psacalc、sensemakr、konfound。" _n
file close fc

capture log close _all
