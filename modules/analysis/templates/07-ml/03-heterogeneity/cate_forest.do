*==============================================================================
* 07-ml / 03-heterogeneity：处理效应异质性（T-learner + GATES + BLP）
*------------------------------------------------------------------------------
* 对应 .py：cate_forest.py。Stata 侧用 lasso linear 作为结果模型的学习器，
* 不提供随机森林/causal forest（Stata 无官方实现，grf 只在 R 侧）。
*
* 用法：
*   set PROJECT_ROOT <工作根>           // 或交给 statamcp 注入
*   do cate_forest.do
*
* 输出（统一契约）：
*   ${OUT_ROOT}/tables/ml-cate.csv              个体层面 CATE（样本外折）
*   ${OUT_ROOT}/tables/ml-overlap.csv           重叠诊断
*   ${OUT_ROOT}/tables/ml-gates.csv             GATES 分组平均效应
*   ${OUT_ROOT}/tables/ml-blp-test.csv          BLP 异质性检验
*   ${OUT_ROOT}/figures/ml-overlap.png          倾向得分分布
*   ${OUT_ROOT}/reports/ml-run-03-heterogeneity-<date>.md
*==============================================================================

version 16
clear all
set more off
set varabbrev off

*------------------------------------------------------------------------------
* 0. 路径与参数
*------------------------------------------------------------------------------
* 工作根：优先 PROJECT_ROOT（环境变量或调用前 set），否则沿用 cwd（statamcp 会把 cwd 设为项目根）
local project_root : env PROJECT_ROOT
if "`project_root'" == "" local project_root "${PROJECT_ROOT}"
if "`project_root'" != "" {
    capture cd "`project_root'"
    if _rc di as txt "提示：cd `project_root' 失败（rc=`=_rc'），沿用当前目录。"
}
global PROJECT_ROOT "`c(pwd)'"

global OUT_ROOT  "${PROJECT_ROOT}/paper-workspace/04-analysis"
global DATA      "${OUT_ROOT}/data/analysis-data.dta"
global DICT      "${OUT_ROOT}/data/variable-dictionary.csv"
global Y         "outcome"
global X         "treatment"
global CONTROLS  "x2 x3 x4 x5 x6 x7 x8 x9 x10"
global ID        "pid"
global SEED      20261024
global CV_FOLDS  5
global GATES_K   5
global HALF_SPLIT 1

capture confirm file "${DATA}"
if _rc {
    di as error "找不到分析数据：${DATA}（先跑 01/02 的数据准备，或改 global DATA）"
    exit 601
}

local today : display %tdCY-N-D date("`c(current_date)'", "DMY")
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/cate_forest.log", replace text

di "--> 03-heterogeneity：数据 ${DATA}；种子 ${SEED}；GATES 组数 ${GATES_K}"

*------------------------------------------------------------------------------
* 1. 读数据与变量角色（以变量表为准，缺失则退回 global）
*------------------------------------------------------------------------------
use "${DATA}", clear

capture confirm variable ${Y}
if _rc {
    di as error "因变量 ${Y} 不在数据里（看 ${DICT} 的 outcome 角色）。"
    exit 111
}
capture confirm variable ${X}
if _rc {
    di as error "处理变量 ${X} 不在数据里（看 ${DICT} 的 treat 角色）。"
    exit 111
}

local controls "${CONTROLS}"
local n_ctrl : word count `controls'
if `n_ctrl' == 0 {
    di as error "阻断：03-heterogeneity 没有协变量，异质性无处安放（补 control 角色）。"
    exit 111
}

capture confirm variable ${ID}
if _rc {
    local have_id 0
    di as txt "提示：没有 ID 变量 ${ID}，折分改用行号。"
}
else local have_id 1

*------------------------------------------------------------------------------
* 2. 折分：按 ${ID} 分组切两半，一半拟合、一半评估
*------------------------------------------------------------------------------
if `have_id' == 1 {
    egen long _uid = group(${ID})
}
else {
    gen long _uid = _n
}
gen byte _half = mod(_uid, 2)

quietly count if _half == 0
local n_fit = r(N)
quietly count if _half == 1
local n_eval = r(N)
if `n_fit' < 50 | `n_eval' < 50 {
    di as error "阻断：折分后样本太小（拟合 `n_fit'，评估 `n_eval'）。"
    exit 111
}
local split_note "按 ${ID} 取模二分组切分"

*------------------------------------------------------------------------------
* 3. T-learner：处理组与控制组各一个结果模型，样本外预测相减得 CATE
*------------------------------------------------------------------------------
capture quietly lasso linear ${Y} `controls' if _half == 0 & ${X} == 1, ///
    selection(cv) folds(${CV_FOLDS}) rseed(${SEED}) nolog
local rc1 = _rc
capture quietly lasso linear ${Y} `controls' if _half == 0 & ${X} == 0, ///
    selection(cv) folds(${CV_FOLDS}) rseed(${SEED}) nolog
local rc0 = _rc
if `rc1' != 0 | `rc0' != 0 {
    di as error "阻断：T-learner 的 lasso linear 报错（rc=`rc1'/`rc0'，检查 lassopack/elasticnet）。"
    file open fblk using "${OUT_ROOT}/reports/ml-blocked-03-heterogeneity-`today'.md", write replace
    file write fblk "# ML 执行阻断：03-heterogeneity" _n _n
    file write fblk "- T-learner 的 lasso linear 报错 rc=`rc1'/`rc0'，检查 lassopack/elasticnet。" _n
    file close fblk
    capture log close _all
    exit 0
}

* 两个模型分别拟合、对全样本预测，CATE = mu1 - mu0
capture drop _mu1 _mu0
quietly lasso linear ${Y} `controls' if _half == 0 & ${X} == 1, ///
    selection(cv) folds(${CV_FOLDS}) rseed(${SEED}) nolog
quietly predict double _mu1, xb
quietly lasso linear ${Y} `controls' if _half == 0 & ${X} == 0, ///
    selection(cv) folds(${CV_FOLDS}) rseed(${SEED}) nolog
quietly predict double _mu0, xb

gen double _cate = _mu1 - _mu0
capture drop _mu1 _mu0

* 倾向得分：在拟合折拟合、全样本预测（必须落在 preserve 之前，否则拟合行已被 keep 掉）
capture quietly logit ${X} `controls' if _half == 0
local rc_ps = _rc
if `rc_ps' != 0 {
    di as txt "提示：倾向得分模型 logit 报 rc=`rc_ps'，重叠诊断降级为 CATE 描述统计。"
    local ps_note "倾向得分模型不可用（logit rc=`rc_ps'）"
}
else {
    quietly predict double _ps, pr
    quietly summarize _ps, detail
    local ps_min = r(min)
    local ps_max = r(max)
    * 贴边比例：e<0.05 或 e>0.95
    quietly count if _half == 1 & (_ps < 0.05 | _ps > 0.95)
    local n_edge = r(N)
    quietly count if _half == 1 & !missing(_ps)
    local n_ps = r(N)
    local edge_share = `n_edge' / `n_ps'
    * 判别力：处理变量对倾向得分的 ROC 面积（roctab 比 lroc 宽松，不依赖估计命令）
    capture quietly roctab ${X} _ps if _half == 1, nograph
    if _rc == 0 {
        local ps_auc = r(area)
        local auc_note "`=strtrim(strofreal(`ps_auc', "%9.3f"))'"
    }
    else {
        local auc_note "不可估计（roctab rc=`=_rc'）"
    }
    local ps_note "倾向得分 AUC=`auc_note'；贴边比例（e<0.05 或 e>0.95）=`=strtrim(strofreal(`edge_share', "%9.3f"))'；e 范围 `=strtrim(strofreal(`ps_min', "%9.3f"))'–`=strtrim(strofreal(`ps_max', "%9.3f"))'"
}

preserve
keep if _half == 1
keep if !missing(_cate)
local n_eval2 = _N


* GATES：按 CATE 分位分组，组内处理效应
quietly summarize _cate, detail
local cate_mean = r(mean)
local cate_sd = r(sd)
local cate_min = r(min)
local cate_max = r(max)

xtile _grp = _cate, nq(${GATES_K})
* GATES：y 对「组虚拟×处理」与「组虚拟」回归，组平均效应取交互项
tab _grp, gen(_d)
local n_gates = ${GATES_K}
forvalues g = 1/`n_gates' {
    quietly gen double _tg`g' = _d`g' * ${X}
}
local gates_rhs "_tg1"
forvalues g = 2/`n_gates' {
    local gates_rhs "`gates_rhs' _tg`g' _d`g'"
}
quietly regress ${Y} `gates_rhs', vce(robust)
local dfe = e(df_r)

file open fgate using "${OUT_ROOT}/tables/ml-gates.csv", write replace
file write fgate "GATES 组,组平均处理效应,标准误,t 值,p 值,组样本,CATE 均值" _n
forvalues g = 1/`n_gates' {
    quietly count if _grp == `g'
    local n_g = r(N)
    if `n_g' < 10 {
        file write fgate "第 `g' 组（CATE 分位 `g'/${GATES_K}）,,,,,`n_g'," _n
        continue
    }
    local b_g = _b[_tg`g']
    local se_g = _se[_tg`g']
    local t_g = `b_g' / `se_g'
    local p_g = 2 * ttail(`dfe', abs(`t_g'))
    quietly summarize _cate if _grp == `g'
    local m_g = r(mean)
    file write fgate "第 `g' 组（CATE 分位 `g'/${GATES_K}）,`=strtrim(strofreal(`b_g', "%9.3f"))',`=strtrim(strofreal(`se_g', "%9.3f"))',`=strtrim(strofreal(`t_g', "%9.3f"))',`=strtrim(strofreal(`p_g', "%9.3f"))',`n_g',`=strtrim(strofreal(`m_g', "%9.3f"))'" _n
}
file close fgate

* BLP：y = a + b*t + c*(s - mean(s)) + d*t*(s - mean(s))，d 显著说明 CATE 排序有样本外解释力
gen double _c = _cate - `cate_mean'
gen double _ts = ${X} * _c
quietly regress ${Y} ${X} _c _ts, vce(robust)
local b_ts = _b[_ts]
local se_ts = _se[_ts]
local p_ts = 2 * ttail(e(df_r), abs(`b_ts' / `se_ts'))
local b_t = _b[${X}]
local se_t = _se[${X}]
local p_t = 2 * ttail(e(df_r), abs(`b_t' / `se_t'))

file open fblp using "${OUT_ROOT}/tables/ml-blp-test.csv", write replace
file write fblp "项,系数,标准误,p 值,解读" _n
file write fblp "处理×CATE（异质性信号）,`=strtrim(strofreal(`b_ts', "%9.3f"))',`=strtrim(strofreal(`se_ts', "%9.3f"))',`=strtrim(strofreal(`p_ts', "%9.3f"))',显著为正说明 CATE 排序在样本外仍有解释力；不显著则不得声称异质性" _n
file write fblp "处理项（ATE 基准）,`=strtrim(strofreal(`b_t', "%9.3f"))',`=strtrim(strofreal(`se_t', "%9.3f"))',`=strtrim(strofreal(`p_t', "%9.3f"))',可与 GATES 加权平均对照" _n
file close fblp

* 个体 CATE 明细
file open fcate using "${OUT_ROOT}/tables/ml-cate.csv", write replace
if `have_id' == 1 {
    file write fcate "${ID},treatment,outcome,cate" _n
}
else {
    file write fcate "unit_index,treatment,outcome,cate" _n
}
local obs = _N
forvalues i = 1/`obs' {
    local id_i = ${ID}[`i']
    local t_i = ${X}[`i']
    local y_i = ${Y}[`i']
    local c_i = _cate[`i']
    local s_y = strtrim(strofreal(`y_i', "%12.4f"))
    local s_c = strtrim(strofreal(`c_i', "%9.4f"))
    if `have_id' == 1 {
        file write fcate "`id_i',`t_i',`s_y',`s_c'" _n
    }
    else {
        file write fcate "`i',`t_i',`s_y',`s_c'" _n
    }
}
file close fcate

* 重叠诊断表
file open fov using "${OUT_ROOT}/tables/ml-overlap.csv", write replace
file write fov "指标,值,解读" _n
file write fov "CATE 均值,`=strtrim(strofreal(`cate_mean', "%9.3f"))',样本外折的平均处理效应近似" _n
file write fov "CATE 标准差,`=strtrim(strofreal(`cate_sd', "%9.3f"))',异质性的原始尺度" _n
file write fov "CATE 最小值／最大值,`=strtrim(strofreal(`cate_min', "%9.3f"))' / `=strtrim(strofreal(`cate_max', "%9.3f"))',极值常来自外推，需对照重叠诊断阅读" _n
if `rc_ps' == 0 {
    file write fov "倾向得分 AUC,`auc_note',接近 1 说明处理组与对照组可比性差" _n
    file write fov "贴边比例（e<0.05 或 e>0.95）,`=strtrim(strofreal(`edge_share', "%9.3f"))',超过 0.10 时个体层面的 CATE 不可用于政策建议" _n
}
else {
    file write fov "倾向得分,不可估计,`ps_note'" _n
}
file close fov
restore

*------------------------------------------------------------------------------
* 4. 报告
*------------------------------------------------------------------------------
file open frep using "${OUT_ROOT}/reports/ml-run-03-heterogeneity-`today'.md", write replace
file write frep "# ML 执行摘要：03-heterogeneity" _n _n
file write frep "## 运行口径" _n _n
file write frep "数据 ${DATA}；种子 ${SEED}；折分方式＝`split_note'；GATES 组数 ${GATES_K}；协变量 `n_ctrl' 个；拟合折 `n_fit'，样本外折 `n_eval'。" _n _n
file write frep "- 学习器：lasso linear（Stata 侧无 causal forest；与 .py 的 HistGB/T-learner 口径不同，结论方向应一致、数字不必相同）。" _n _n
file write frep "## CATE" _n _n
file write frep "- 表：tables/ml-cate.csv" _n
file write frep "- 摘要：均值 `=strtrim(strofreal(`cate_mean', "%9.3f"))'，标准差 `=strtrim(strofreal(`cate_sd', "%9.3f"))'，范围 `=strtrim(strofreal(`cate_min', "%9.3f"))'–`=strtrim(strofreal(`cate_max', "%9.3f"))'。" _n _n
file write frep "## GATES" _n _n
file write frep "- 表：tables/ml-gates.csv（${GATES_K} 组）" _n _n
file write frep "## BLP" _n _n
file write frep "- 表：tables/ml-blp-test.csv" _n
file write frep "- 摘要：处理×CATE 系数 `=strtrim(strofreal(`b_ts', "%9.3f"))'（p=`=strtrim(strofreal(`p_ts', "%9.3f"))'）。" _n _n
file write frep "## 重叠诊断" _n _n
file write frep "- 表：tables/ml-overlap.csv" _n
file write frep "- `ps_note'。" _n _n
file write frep "## 可声称边界" _n _n
file write frep "可声称：不同特征群体的平均效应存在差异（GATES），且该差异在样本外可复现（BLP 显著）。不可声称：某个个体的效应等于其 CATE；重叠不足时不可给出个体政策建议（C29、C30）。" _n
file close frep

di "--> 完成：报告见 ${OUT_ROOT}/reports/ml-run-03-heterogeneity-`today'.md"

capture log close _all
