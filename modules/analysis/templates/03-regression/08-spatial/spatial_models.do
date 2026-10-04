* Paper Analysis 4SS - 03 regression / 08 spatial models executable Stata template.
* 按 analysis-execution-plan 保留需要的块并删除不适用的方法块；本模板不做运行时条件跳过。
* 空间子流程依赖 Stata 15+ 官方 sp* 命令（spset/spmatrix/spregress/spxtregress）与 xsmle（SSC），无需额外安装。
* spset 要求空间截面数据（ID 唯一）；面板数据必须先 collapse 到截面再 spset，或直接沿用 xtset 面板配合 Wmat。
* 全局 Moran's I 与 spatreg 使用 spatgsa/spatwmat，其中 spatwmat 用坐标与 band() 直接构造权重矩阵。

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
global SLAT "lat"
global SLON "lon"
global SWEIGHT "Wm"
global SBAND "0 0.5"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/spatial_models.log", replace text

use "${DATA}", clear

di "--> 表S1：空间权重矩阵与全局 Moran's I"
* spset 要求空间单元 ID 在数据中唯一，故先聚合到个体层面的截面数据。
preserve
collapse (mean) $Y $X $C $SLAT $SLON, by($ID)
spset $ID, coord($SLAT $SLON) coordsys(planar)
spmatrix create idistance $SWEIGHT, replace
spmatrix summarize $SWEIGHT
* spmatrix export 写出的文件是 spmat 格式，不能再用 use 打开；
* spatwmat 需要自行用坐标与 band() 构造标准权重矩阵。
spatwmat, name($SWEIGHT) xcoord($SLAT) ycoord($SLON) band($SBAND) standardize eigenval(SWEIGEN)
spatgsa $Y $X $C, weights($SWEIGHT) moran
* 全局 Moran's I 统计量与 p 值（spatgsa 结果写入日志）
qui spatgsa $Y, weights($SWEIGHT) moran
local mi_moran = r(moran)
local mi_p = r(p_moran)
* 基准 OLS（空间回归的对照）
qui regress $Y $X $C
est store ols_base
* 空间自相关诊断：OLS 残差的 Moran's I
qui regress $Y $X $C
predict double _resid_ols, resid

file open f1 using "${OUT_ROOT}/tables/tableS1-spatial-weights.csv", write replace
file write f1 "项目,内容" _n
file write f1 "权重矩阵类型,反距离（spmatrix create idistance $SWEIGHT）" _n
file write f1 "备用权重矩阵,距离带 band($SBAND) + 行标准化（spatwmat standardize）" _n
file write f1 "坐标系统,平面坐标 coordsys(planar)，坐标变量 $SLAT $SLON" _n
file write f1 "全局 Moran's I（$Y）," %9.4f (`mi_moran') _n
file write f1 "全局 Moran's I p 值（$Y）," %9.4f (`mi_p') _n
file write f1 "说明,权重矩阵类型、行标准化方式、稀疏度与全局 Moran's I 必须一并报告" _n
file close f1

di "--> 表S2：截面空间回归与效应分解"
qui spregress $Y $X $C, gs2sls dvarlag($SWEIGHT)
est store sar_gs2sls
qui spregress $Y $X $C, gs2sls dvarlag($SWEIGHT) ivarlag($SWEIGHT: $X)
est store sdm_gs2sls
qui spregress $Y $X $C, ml dvarlag($SWEIGHT)
est store sar_ml
estat impact
qui spatreg $Y $X $C, weights($SWEIGHT) eigenval(SWEIGEN) model(error) nolog
est store spatreg_error
restore

esttab ols_base sar_gs2sls sdm_gs2sls sar_ml spatreg_error using "${OUT_ROOT}/tables/tableS2-spatial-cross-section.csv", ///
    b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N r2, fmt(0 3) labels("观测值" "R²")) ///
    addnotes("注：截面空间回归。ols_base 为无空间项 OLS；sar_gs2sls/sar_ml 为 SAR（广义空间两阶段最小二乘/极大似然）；sdm_gs2sls 为 SDM（含 X 的空间滞后）；spatreg_error 为 spatreg 的空间误差模型。estat impact 的直接/间接/总效应分解见 tableS3b-spatial-effects.csv 与日志。") ///
    replace

di "--> 表S3：面板空间回归与效应分解"
use "${DATA}", clear
xtset $ID $TIME
* 面板空间回归需要 Wmat 矩阵，由截面坐标构造。
preserve
collapse (mean) $SLAT $SLON, by($ID)
spatwmat, name($SWEIGHT) xcoord($SLAT) ycoord($SLON) band($SBAND) standardize eigenval(SWEIGEN)
restore
estimates clear
qui xsmle $Y $X $C, wmat($SWEIGHT) model(sdm) fe type(ind) nolog
est store sdm_fe
qui xsmle $Y $X $C, wmat($SWEIGHT) model(sar) fe type(ind) nolog
est store sar_fe
qui xsmle $Y $X $C, wmat($SWEIGHT) model(sdm) re type(ind) nolog
est store sdm_re

esttab sdm_fe sar_fe sdm_re using "${OUT_ROOT}/tables/tableS3-spatial-panel.csv", ///
    b(3) z(3) star(* 0.05 ** 0.01 *** 0.001) label nogaps compress substitute("=" "") ///
    stats(N, fmt(0) labels("观测值")) ///
    addnotes("注：面板空间回归（xsmle）。sdm_fe/sar_fe 为个体固定效应下的 SDM/SAR；sdm_re 为随机效应 SDM。效应分解见 tableS3b-spatial-effects.csv。") ///
    replace

di "--> 表S3b：直接、间接与总效应分解"
estimates clear
qui xsmle $Y $X $C, wmat($SWEIGHT) model(sdm) fe type(ind) nolog
* xsmle 的效应分解用 margins predict(direct|indirect|total) 提取。
qui margins, dydx($X) predict(direct) noestimcheck nochainrule force
matrix P_direct = r(b)
matrix V_direct = r(V)
qui margins, dydx($X) predict(indirect) noestimcheck nochainrule force
matrix P_indirect = r(b)
matrix V_indirect = r(V)
qui margins, dydx($X) predict(total) noestimcheck nochainrule force
matrix P_total = r(b)
matrix V_total = r(V)

scalar d_b = P_direct[1,1]
scalar d_se = sqrt(V_direct[1,1])
scalar i_b = P_indirect[1,1]
scalar i_se = sqrt(V_indirect[1,1])
scalar t_b = P_total[1,1]
scalar t_se = sqrt(V_total[1,1])

file open f3b using "${OUT_ROOT}/tables/tableS3b-spatial-effects.csv", write replace
file write f3b "效应,系数,标准误,z 值" _n
file write f3b "直接效应（Direct）," %9.4f (d_b) "," %9.4f (d_se) "," %9.4f (d_b/d_se) _n
file write f3b "间接效应（Indirect）," %9.4f (i_b) "," %9.4f (i_se) "," %9.4f (i_b/i_se) _n
file write f3b "总效应（Total）," %9.4f (t_b) "," %9.4f (t_se) "," %9.4f (t_b/t_se) _n
file close f3b

file open fmd using "${OUT_ROOT}/reports/spatial-diagnostics.md", write replace
file write fmd "# Spatial Diagnostics" _n _n
file write fmd "## 权重矩阵来源" _n _n
file write fmd "反距离矩阵由 spmatrix create idistance $SWEIGHT 生成；距离带矩阵由 spatwmat 以坐标 $SLAT/$SLON 与 band($SBAND) 生成并做行标准化。" _n _n
file write fmd "## 坐标单位" _n _n
file write fmd "坐标 $SLAT/$SLON 按 coordsys(planar) 处理（平面坐标，非经纬度）。若使用经纬度，应改为 coordsys(geographic) 或先把距离换算为公里。" _n _n
file write fmd "## Moran's I 结论" _n _n
file write fmd "全局 Moran's I（$Y）= `mi_moran'，p = `mi_p'。p<0.05 表示存在显著空间自相关，应改用空间回归而非普通 OLS。" _n _n
file write fmd "## 直接/间接/总效应解释" _n _n
file write fmd "直接效应是本单元 X 变动对本单元 Y 的影响；间接效应（空间溢出）是本单元 X 变动通过权重矩阵传导到其他单元 Y 的影响；总效应为两者之和。三者均含 X 的空间滞后反馈项，不能等同于非空间模型的系数。" _n
file write fmd "## 截面与面板口径" _n _n
file write fmd "表S2 使用个体层面截面数据（spset + spregress）；表S3 使用原始面板（xtset + xsmle）。两者权重矩阵均由个体坐标构造，故可直接比较截面与面板的空间依赖强度。" _n
file close fmd

capture log close _all
