* Paper Analysis 4SS - 03 regression / 03 panel models executable Stata template.
* 按 analysis-execution-plan 保留需要的块并删除不适用的方法块；本模板不做运行时条件跳过。
* hausman 不接受聚类 VCE，故 FE/RE 诊断列不带 vce(cluster)；xttest0 必须在 xtreg, re 之后调用。
* 动态面板的 AR/Hansen 检验 p 值由 xtabond2 的 e(ar1p)/e(ar2p)/e(hansenp) 直接返回，不得用 estadd 覆盖。
* bacondecomp 需要至少 2 个处理时点组。

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
global BIN_Y "outcome_bin"
global COUNT_Y "outcome_count"
global ENDOG "endog_x"
global IV "instrument_z"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/panel_models.log", replace text

use "${DATA}", clear

xtset $ID $TIME

di "--> 表A0：面板设定选择检验（混合 OLS / FE / RE）"
* 经典 FE/RE 仅用于 Hausman 与 xttest0 诊断，不进入结果表；hausman 不接受聚类 VCE，故此处用默认 VCE
estimates clear
qui xtreg $Y $X $C i.$TIME, fe
est store fe_diag
qui xtreg $Y $X $C i.$TIME, re
est store re_diag
* xttest0 必须在最近一次 xtreg, re 之后调用
xttest0
local bp_chibar2 = r(chibar2)
local bp_p = r(p)
hausman fe_diag re_diag, sigmamore
local hm_chi2 = r(chi2)
local hm_df = r(df)
local hm_p = r(p)
qui xtreg $Y $X $C i.$TIME, fe
local fe_F = e(F)
local fe_Fp = e(p)

file open fa using "${OUT_ROOT}/tables/tableA0-panel-selection.csv", write replace
file write fa "检验,统计量,自由度,p 值,结论口径" _n
file write fa "Breusch-Pagan LM（xttest0：混合 OLS vs RE）," %9.3f (`bp_chibar2') ",1," %9.4f (`bp_p') ",p<0.05 拒绝混合 OLS" _n
file write fa "Hausman（FE vs RE）," %9.3f (`hm_chi2') "," %3.0f (`hm_df') "," %9.4f (`hm_p') ",p<0.05 选择 FE" _n
file write fa "FE 联合显著性 F 检验," %9.3f (`fe_F') ",," %9.4f (`fe_Fp') ",p<0.05 固定效应联合显著" _n
file close fa

di "--> 表A：高维固定效应主结果（reghdfe）"
estimates clear
qui reghdfe $Y $X $C, absorb($ID) vce(cluster $CLUSTER)
est store hdfe_fe
qui reghdfe $Y $X $C, absorb($ABSORB) vce(cluster $CLUSTER)
est store hdfe_twfe

esttab hdfe_fe hdfe_twfe using "${OUT_ROOT}/tables/tableA-panel-models.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_within, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：FE 列为个体固定效应，TWFE 列为个体+年份双向固定效应；标准误按 $CLUSTER 聚类；括号内为 t 值。") replace

di "--> 表A2：动态面板（系统/差分 GMM、偏差校正 LSDV、xtdpdgmm、xtbcfe）"
* 注：短 T 面板下 `collapse` 会使工具数少于回归量（r481 Equation not identified），故此处不 collapse。
* 若 T 较大，可加回 collapse 以降弱工具数。
estimates clear
qui xtabond2 $Y L.$Y $X $C i.$TIME, gmm(L.$Y, lag(2 3)) iv($X $C) robust twostep
est store dyn_gmm
qui xtabond2 $Y L.$Y $X $C i.$TIME, gmm(L.$Y, lag(2 3)) iv($X $C) robust noleveleq twostep
est store diff_gmm
qui xtdpdgmm $Y L.$Y $X $C, gmm(L.$Y, lag(2 3)) iv($X $C) twostep vce(robust)
est store xtdpdgmm_sys
qui xtlsdvc $Y $X $C, initial(ah) bias(2)
est store xtlsdvc1
* xtbcfe 是偏差校正固定效应（Bias-Corrected FE），不是动态面板；选项为 lags()/bciters()，且不接受时间序列算子。
qui xtbcfe $Y $X $C, lags(1) bciters(50)
est store xtbcfe1

esttab dyn_gmm diff_gmm xtdpdgmm_sys xtlsdvc1 xtbcfe1 using "${OUT_ROOT}/tables/tableA2-panel-dynamic.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N ar1p ar2p hansenp, fmt(0 3 3 3) labels("观测值" "AR(1) p" "AR(2) p" "Hansen p")) ///
    addnotes("注：动态面板列均含滞后因变量 L.$Y。AR(1)/AR(2)/Hansen 检验 p 值来自 xtabond2 的 e(ar1p)/e(ar2p)/e(hansenp)；xtlsdvc 为偏差校正 LSDV。AR(2) p>0.05 且 Hansen p>0.05 才支持矩条件有效。") ///
    replace

di "--> 表A3：长面板（N 小 T 大）估计与面板诊断"
estimates clear
qui xtscc $Y $X $C, fe lag(2)
est store xtscc_dk
qui xtpcse $Y $X $C
est store xtpcse1
qui xtgls $Y $X $C, panels(hetero)
est store xtgls1

esttab xtscc_dk xtpcse1 xtgls1 using "${OUT_ROOT}/tables/tableA3-panel-longN.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2 r2_w, fmt(0 3 3) labels("观测值" "R²" "Within R²")) ///
    addnotes("注：xtscc 为 Driscoll-Kraay 标准误固定效应；xtpcse 为面板校正标准误；xtgls 允许面板异方差。后续行为面板诊断检验结果。") ///
    replace

* 面板诊断检验（rclass 检验，不进入 esttab，追加到表A3 的诊断行）
* 注：xttest3 需要内存中有最近一次的 xtreg 估计，故先重跑 xtreg, fe 再调用。
* 注：xtcdf/xtcd2/xthst 返回矩阵（r(CD)/r(p)/r(delta_p)），不是标量 r(p)。
qui xtreg $Y $X $C, fe
xttest3
local het_p = r(p)
xtserial $Y $X $C
local ws_p = r(p)
xtcdf $Y
matrix CD_cdf = r(CD)
matrix p_cdf = r(p)
local cdf_p = p_cdf[1,1]
xtcd2 $Y
matrix p_cd2 = r(p)
local cd2_p = p_cd2[1,1]
xthst $Y $X $C
matrix p_hst = r(delta_p)
local hst_p = p_hst[1,1]

file open fl using "${OUT_ROOT}/tables/tableA3-panel-longN.csv", write append
file write fl "面板诊断,,,,,,," _n
file write fl "Wooldridge 面板自相关检验 p（xtserial）," %9.4f (`ws_p') ",,,,,," _n
file write fl "组间异方差 LR 检验 p（xttest3）," %9.4f (`het_p') ",,,,,," _n
file write fl "Pesaran CD 截面相关检验 p（xtcdf）," %9.4f (`cdf_p') ",,,,,," _n
file write fl "弱截面相关检验 p（xtcd2）," %9.4f (`cd2_p') ",,,,,," _n
file write fl "斜率同质性检验 p（xthst）," %9.4f (`hst_p') ",,,,,," _n
file close fl

di "--> 表A4：面板 IV 与面板非线性模型"
estimates clear
* 注：xtlogit/xtpoisson 的 fe 不允许 vce(cluster)（面板非线性 FE 用条件似然，标准误另行设定），
* 故 FE 列不加 vce 选项；RE 列才允许 vce(cluster)。
* 注：面板计数模型此处用 xtpoisson（FE/RE）。xtnbreg 的 RE 估计在 T 很短的窄面板上不收敛
* （实测 158 秒未返回），T 足够长的项目可把下面两行替换为 xtnbreg $COUNT_Y $X $C, re。
qui xtivreg $Y $C ($ENDOG = $IV), fe vce(cluster $ID)
est store xtiv_fe
qui xtivreg $Y $C ($ENDOG = $IV), re vce(cluster $ID)
est store xtiv_re
qui xtlogit $BIN_Y $X $C $FE, fe
est store xtlogit_fe
qui xtprobit $BIN_Y $X $C, re vce(cluster $ID)
est store xtprobit_re
qui xtpoisson $COUNT_Y $X $C, fe
est store xtpoisson_fe
qui xtpoisson $COUNT_Y $X $C, re vce(cluster $ID)
est store xtpoisson_re

esttab xtiv_fe xtiv_re xtlogit_fe xtprobit_re xtpoisson_fe xtpoisson_re using "${OUT_ROOT}/tables/tableA4-panel-iv-nonlinear.csv", ///
    b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：前两列为面板 IV（FE/RE，内生变量 $ENDOG 由 $IV 工具化）；后四列为面板 logit/probit/poisson/nbreg；标准误按 $ID 聚类；括号内为 z 值。") ///
    replace

file open fp using "${OUT_ROOT}/reports/panel-diagnostics.md", write replace
file write fp "# Panel Diagnostics" _n _n
file write fp "已运行 xtreg FE/RE、xttest0 与 Hausman 诊断；结果表列使用 reghdfe 个体 FE / 双向 FE；动态面板使用 xtabond2 两步系统/差分 GMM、xtdpdgmm 与 xtbcfe；长面板使用 xtscc/xtpcse/xtgls 并附 xtserial/xttest3/xtcdf/xtcd2/xthst 诊断。" _n
file write fp "Hausman 检验：chi2(`hm_df') = `hm_chi2'，p = `hm_p'。" _n
file write fp "Breusch-Pagan LM（xttest0）：chibar2 = `bp_chibar2'，p = `bp_p'。" _n
file close fp

capture log close _all
