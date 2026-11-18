* Paper Analysis 4SS - 07 ml / 01 supervised Stata template.
* 对应 Python 基准：templates\07-ml\01-supervised\supervised_ml.py（任务 ID、输出表名、CSV 列名、报告命名逐字对齐）。
* 任务：regularized（正则化筛变量）/ predict-regression（连续因变量样本外预测）/
*       predict-binary（二分类样本外性能，非二分类时写阻断）/ structure（PCA 与 K-means）。
* 纪律：只报实际跑出的数；跑不动就写阻断，不写占位结果（见 _shared/TEMPLATE-CONTRACT.md 与 phases/07-ml-and-causal-ml.md §6）。
*
* 本机/本版本不可用块与替代路径：
*   - 随机森林、梯度提升（HistGB）在 Stata 16 基础版无内置命令（rforest / cforest 属社区包，不保证已装）。
*     predict-regression 的候选模型改为「基准 OLS / Lasso / 弹性网」，置换重要性也基于这三个线性模型计算；
*     与 .py 的 HistGB 口径不同，报告与正文必须写明。需要树模型请走 07-ml 的 .R 模板（ranger/gbm）、
*     或 03-regression 的交互项与样条路径。
*   - 折分按个体（$ID）分组，不按行随机切；测试集只评估一次。

version 16
clear all
set more off

local project_root : env PROJECT_ROOT
if "`project_root'" == "" local project_root "${PROJECT_ROOT}"
if "`project_root'" != "" {
    capture cd "`project_root'"
    if _rc di as txt "提示：cd `project_root' 失败（rc=`=_rc'），沿用当前目录。"
}
global PROJECT_ROOT "`c(pwd)'"

global OUT_ROOT "paper-workspace/04-analysis"
global DATA "${OUT_ROOT}/data/analysis-data.dta"
global Y "outcome"
global BIN_Y "outcome_bin"
global X "treatment"
global C "x2 x3 x4 x5 x6 x7 x8 x9 x10"
global HET "x1"
global MODERATOR ""
global FE ""
global CLUSTER "pid"
global ID "pid"
global TIME "year"
global SEED "20261024"
global TEST_SIZE "0.3"
global CV_FOLDS "5"
global KMAX "5"
global NCOMP "5"
global NREP "5"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/data"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/supervised_ml.log", replace text

use "${DATA}", clear

local today : di %tdCCYY-NN-DD daily("`c(current_date)'", "DMY")
global FEATURES "$X $C $HET $MODERATOR"

capture program drop _mlfmt3
program define _mlfmt3, rclass
    version 16
    args value
    return local s = strtrim(strofreal((`value'), "%12.3f"))
end
capture program drop _mlfmt0
program define _mlfmt0, rclass
    version 16
    args value
    return local s = strtrim(strofreal((`value'), "%12.0f"))
end

* AUC 用秩公式算，不依赖 e()：lasso logit 之后 `lroc' 会报 r(301)，
* 而 `.do' 一旦中断，尚未 close 的 CSV 写缓存会整段丢掉（空表却看不出错）。
capture program drop _mlauc
program define _mlauc, rclass
    version 16
    args prob dep
    qui egen double _rk = rank(`prob') if !missing(`prob', `dep')
    qui count if `dep' == 1 & !missing(_rk)
    local n1 = r(N)
    qui count if !missing(_rk)
    local n0 = r(N) - `n1'
    if `n1' == 0 | `n0' == 0 {
        return scalar auc = .
        qui drop _rk
        exit
    }
    qui summarize _rk if `dep' == 1 & !missing(_rk), meanonly
    return scalar auc = (r(mean) - (`n1' + 1) / 2) / `n0'
    qui drop _rk
end

*------------------------------------------------------------------------------
* Mata 辅助函数（先定义，供后面的置换重要性与 profile 计算调用）
*   sil_mean(X, g)：平均轮廓系数；D 的第 i 行必须是行向量（转置不可省）。
*   _ml_permute(vname, maskname)：只在 mask==1 的观测之间打乱单个变量。
*------------------------------------------------------------------------------
capture mata: mata drop sil_mean()
capture mata: mata drop _ml_permute()
mata:
real scalar sil_mean(real matrix X, real colvector g)
{
    real scalar n, K, j, i, mx
    real colvector a, b, s, Sown, nown
    real matrix D, B, M, S, nj, U
    n = rows(X)
    K = rows(uniqrows(g))
    D = J(n, n, 0)
    for (i=1; i<=n; i++) D[i, ] = sqrt(rowsum((X :- X[i, .]):^2))'
    B = J(n, K, 0)
    for (j=1; j<=K; j++) B[., j] = (g :== uniqrows(g)[j])
    nj = colsum(B)
    S = D * B
    U = J(n, 1, 1) * nj
    M = S :/ U
    Sown = rowsum(S :* B)
    nown = rowsum(U :* B)
    a = Sown :/ (nown :- 1)
    b = rowmin(M :+ (B :* 1e300))
    s = J(n, 1, 0)
    for (i=1; i<=n; i++) {
        mx = max((a[i], b[i]))
        if (mx > 0 & a[i] < . & b[i] < .) s[i] = (b[i] - a[i]) / mx
    }
    return(mean(s))
}

void _ml_permute(string scalar vname, string scalar maskname)
{
    real colvector V, msk, idx
    V = st_data(., vname)
    msk = st_data(., maskname)
    idx = selectindex(msk :== 1)
    if (rows(idx) > 1) {
        V[idx] = jumble(V[idx])
        st_store(., vname, V)
    }
}
end

*------------------------------------------------------------------------------
* 预处理：按 ID 分组切分训练/测试集（同一个体不跨折），种子口径同 .py
*------------------------------------------------------------------------------
di "--> 预处理：按 $ID 分组切分，测试集比例 $TEST_SIZE"
set seed $SEED
qui bysort $ID: egen double _rgrp = min(cond(_n==1, runiform(), .))
qui gen byte _test = (_rgrp < $TEST_SIZE)
qui count if _test == 0
local n_train = r(N)
qui count if _test == 1
local n_test = r(N)
local split_note "按 $ID 分组切分（同 .py 的 GroupShuffleSplit）"
local kfeat = wordcount("$FEATURES")
di "训练样本 `n_train'，测试样本 `n_test'，候选特征 `kfeat' 个"

*------------------------------------------------------------------------------
* 任务 regularized：弹性网（含 Lasso 端点），CV 选 alpha 与 lambda
*------------------------------------------------------------------------------
di "--> 任务 regularized：弹性网（含 Lasso 端点）"
estimates clear
capture noisily elasticnet linear $Y $FEATURES, alpha(0.1 0.5 0.9 1) folds($CV_FOLDS) rseed($SEED) nolog
local en_rc = _rc

local reg_summary ""
if `en_rc' == 0 {
    local reg_kind "弹性网（含 Lasso 端点）"
    local en_lambda = e(lambda_cv)
    local en_alpha = e(alpha_sel)
    local en_knz = e(k_nonzero_cv)
    local en_n = e(N)
    matrix b_en = e(b)
    _mlfmt3 `en_lambda'
    local en_lambda_s = r(s)
    _mlfmt3 `en_alpha'
    local en_alpha_s = r(s)
    _mlfmt0 `kfeat'
    local kfeat_s = r(s)
    _mlfmt0 `en_knz'
    local en_knz_s = r(s)
    _mlfmt0 `en_n'
    local en_n_s = r(s)

    local n_sel 0
    file open fsel using "${OUT_ROOT}/tables/ml-selected-variables.csv", write replace
    file write fsel "variable,coefficient,selected,model" _n
    foreach v of global FEATURES {
        local j = colnumb(b_en, "`v'")
        local coef 0
        local pick "否"
        if `j' != . {
            local coef = b_en[1, `j']
            if abs(`coef') > 1e-8 {
                local pick "是"
                local n_sel = `n_sel' + 1
            }
        }
        _mlfmt3 `coef'
        local coefs = r(s)
        file write fsel "`v',`coefs',`pick',`reg_kind'" _n
    }
    file close fsel

    file open fpath using "${OUT_ROOT}/tables/ml-regularization-path.csv", write replace
    file write fpath "模型,惩罚参数,l1_ratio,候选特征数,选中特征数,样本量" _n
    file write fpath "`reg_kind',`en_lambda_s',`en_alpha_s',`kfeat_s',`en_knz_s',`en_n_s'" _n
    file close fpath

    local reg_summary "`reg_kind'，候选 `kfeat' 个特征，选中 `n_sel' 个；lambda=`en_lambda_s'，alpha=`en_alpha_s'。"
    di "`reg_summary'"
}
else {
    di as error "elasticnet 不可用（rc=`en_rc'），regularized 任务阻断"
    local reg_summary "阻断：elasticnet 报 rc=`en_rc'。本机/本版本不可用时改用 lasso linear（同口径的 Lasso 端点）+ 第三方向量；或走 07-ml 的 .R 模板（glmnet）。"
    file open fblk0 using "${OUT_ROOT}/reports/ml-blocked-01-supervised-`today'.md", write replace
    file write fblk0 "# ML 执行阻断：01-supervised" _n _n
    file write fblk0 "## regularized" _n _n
    file write fblk0 "- `reg_summary'" _n
    file close fblk0
}

*------------------------------------------------------------------------------
* 任务 predict-regression：基准 OLS / Lasso / 弹性网，报样本外指标与训练集 R2
*------------------------------------------------------------------------------
di "--> 任务 predict-regression：基准 OLS / Lasso / 弹性网"
qui summarize $Y if _test == 1
local sst_oos = r(Var) * (`n_test' - 1)
qui summarize $Y if _test == 0
local sst_tr = r(Var) * (`n_train' - 1)

_mlfmt0 `n_train'
local n_train_s = r(s)
_mlfmt0 `n_test'
local n_test_s = r(s)

file open fperf using "${OUT_ROOT}/tables/ml-model-performance.csv", write replace
file write fperf "任务,模型,样本外AUC,样本外Brier,样本外准确率,训练集准确率,训练样本,测试样本,样本外 RMSE,样本外 MAE,样本外 R2,训练集 R2" _n

local best_name ""
local best_rmse .
local perf_rows 0

* --- 基准 OLS
capture noisily qui regress $Y $FEATURES if _test == 0
if _rc == 0 {
    local mname "基准 OLS"
    local fitted 1
    capture drop _ph _pht
    qui predict double _ph if _test == 1
    qui predict double _pht if _test == 0
    local perf_ok 1
}
else local perf_ok 0

if `perf_ok' == 1 {
    qui count if _test == 1 & !missing(_ph)
    local np = r(N)
    if `np' < `n_test' {
        di as error "`mname' 样本外预测缺观测，跳过"
        local perf_ok 0
    }
}

if `perf_ok' == 1 {
    qui gen double _errsq = ($Y - _ph)^2 if _test == 1
    qui gen double _absq = abs($Y - _ph) if _test == 1
    qui summarize _errsq if _test == 1, meanonly
    local sse_oos = r(sum)
    qui summarize _absq if _test == 1, meanonly
    local mae_oos = r(sum) / `n_test'
    qui gen double _etr2 = ($Y - _pht)^2 if _test == 0
    qui summarize _etr2 if _test == 0, meanonly
    local sse_tr = r(sum)
    local rmse_oos = sqrt(`sse_oos' / `n_test')
    local r2_oos = 1 - `sse_oos' / `sst_oos'
    local r2_tr = 1 - `sse_tr' / `sst_tr'
    drop _errsq _absq _etr2
    _mlfmt3 `rmse_oos'
    local f1 = r(s)
    _mlfmt3 `mae_oos'
    local f2 = r(s)
    _mlfmt3 `r2_oos'
    local f3 = r(s)
    _mlfmt3 `r2_tr'
    local f4 = r(s)
    file write fperf "predict-regression,`mname',,,,,`n_train_s',`n_test_s',`f1',`f2',`f3',`f4'" _n
    local perf_rows = `perf_rows' + 1
    local best_name "`mname'"
    local best_rmse = `rmse_oos'
}

* --- Lasso（CV 选 lambda）
foreach cand in lasso enet {
    if "`cand'" == "lasso" {
        local mname "Lasso（CV 选 lambda）"
        capture noisily qui lasso linear $Y $FEATURES if _test == 0, selection(cv) folds($CV_FOLDS) rseed($SEED) nolog
    }
    else {
        local mname "弹性网（CV 选 alpha 与 lambda）"
        capture noisily qui elasticnet linear $Y $FEATURES if _test == 0, alpha(0.1 0.5 0.9 1) folds($CV_FOLDS) rseed($SEED) nolog
    }
    if _rc != 0 {
        di as error "`mname' 估计失败（rc=`=_rc'），跳过该候选模型"
        continue
    }
    capture drop _ph _pht
    * 样本外 predict 常返回 rc=601（e(sample) 不含测试观测）；只要预测值齐备即可用
    capture predict double _ph if _test == 1, xb
    capture predict double _pht if _test == 0, xb
    qui count if _test == 1 & !missing(_ph)
    local np = r(N)
    if `np' < `n_test' {
        di as error "`mname' 样本外预测缺观测（`np'/`n_test'），跳过该候选模型"
        continue
    }
    qui gen double _errsq = ($Y - _ph)^2 if _test == 1
    qui gen double _absq = abs($Y - _ph) if _test == 1
    qui summarize _errsq if _test == 1, meanonly
    local sse_oos = r(sum)
    qui summarize _absq if _test == 1, meanonly
    local mae_oos = r(sum) / `n_test'
    qui gen double _etr2 = ($Y - _pht)^2 if _test == 0
    qui summarize _etr2 if _test == 0, meanonly
    local sse_tr = r(sum)
    local rmse_oos = sqrt(`sse_oos' / `n_test')
    local r2_oos = 1 - `sse_oos' / `sst_oos'
    local r2_tr = 1 - `sse_tr' / `sst_tr'
    drop _errsq _absq _etr2
    _mlfmt3 `rmse_oos'
    local f1 = r(s)
    _mlfmt3 `mae_oos'
    local f2 = r(s)
    _mlfmt3 `r2_oos'
    local f3 = r(s)
    _mlfmt3 `r2_tr'
    local f4 = r(s)
    file write fperf "predict-regression,`mname',,,,,`n_train_s',`n_test_s',`f1',`f2',`f3',`f4'" _n
    local perf_rows = `perf_rows' + 1
    if `rmse_oos' < `best_rmse' {
        local best_rmse = `rmse_oos'
        local best_name "`mname'"
    }
}
file close fperf
di "样本外 RMSE 最小者：`best_name'（RMSE=`=strtrim(strofreal(`best_rmse', "%12.3f"))'），共 `perf_rows' 个候选模型"

*------------------------------------------------------------------------------
* 置换重要性：被解释模型＝样本外 RMSE 最小者，5 次重复，指标 delta R2（同 .py 的 scoring=None）
*------------------------------------------------------------------------------
di "--> 置换重要性：被解释模型＝`best_name'"
local imp_ok 1
capture drop _pref
if "`best_name'" == "基准 OLS" {
    capture noisily qui regress $Y $FEATURES if _test == 0
}
else if "`best_name'" == "Lasso（CV 选 lambda）" {
    capture noisily qui lasso linear $Y $FEATURES if _test == 0, selection(cv) folds($CV_FOLDS) rseed($SEED) nolog
}
else {
    capture noisily qui elasticnet linear $Y $FEATURES if _test == 0, alpha(0.1 0.5 0.9 1) folds($CV_FOLDS) rseed($SEED) nolog
}
if _rc != 0 {
    local imp_ok 0
}
if "`best_name'" == "" {
    local imp_ok 0
}

if `imp_ok' == 1 {
    capture predict double _pref if _test == 1, xb
    qui count if _test == 1 & !missing(_pref)
    if r(N) < `n_test' {
        local imp_ok 0
    }
}

if `imp_ok' == 1 {
    qui gen double _ersq = ($Y - _pref)^2 if _test == 1
    qui summarize _ersq if _test == 1, meanonly
    local r2_base = 1 - r(sum) / `sst_oos'
    drop _ersq

    local impv ""
    local impm ""
    local impsd ""
    local nimp 0
    foreach v of global FEATURES {
        qui gen double _orig = `v' if _test == 1
        local sum_imp 0
        local sumsq_imp 0
        forvalues r = 1/$NREP {
            mata: _ml_permute("`v'", "_test")
            capture drop _pp
            capture predict double _pp if _test == 1, xb
            qui gen double _ep2 = ($Y - _pp)^2 if _test == 1
            qui summarize _ep2 if _test == 1, meanonly
            local r2_perm = 1 - r(sum) / `sst_oos'
            local d = `r2_base' - `r2_perm'
            local sum_imp = `sum_imp' + `d'
            local sumsq_imp = `sumsq_imp' + `d' * `d'
            drop _ep2 _pp
            qui replace `v' = _orig if _test == 1
        }
        local mean_imp = `sum_imp' / $NREP
        local sd_imp = sqrt((`sumsq_imp' - $NREP * `mean_imp'^2) / ($NREP - 1))
        drop _orig
        local nimp = `nimp' + 1
        local impv "`impv' `v'"
        local impm "`impm' `mean_imp'"
        local impsd "`impsd' `sd_imp'"
    }

    * 按置换重要性降序输出（同 .py 的 imp.sort(key=-重要性)）
    file open fimp using "${OUT_ROOT}/tables/ml-variable-importance.csv", write replace
    file write fimp "variable,置换重要性均值,标准差" _n
    local left_v "`impv'"
    local left_m "`impm'"
    local left_s "`impsd'"
    forvalues step = 1/`nimp' {
        local kk = wordcount("`left_m'")
        local argmax 1
        local vmax : word 1 of `left_m'
        forvalues j = 2/`kk' {
            local vj : word `j' of `left_m'
            if `vj' > `vmax' {
                local vmax = `vj'
                local argmax `j'
            }
        }
        local vout : word `argmax' of `left_v'
        local mout : word `argmax' of `left_m'
        local sout : word `argmax' of `left_s'
        _mlfmt3 `mout'
        local ms = r(s)
        _mlfmt3 `sout'
        local ss = r(s)
        file write fimp "`vout',`ms',`ss'" _n
        local nv ""
        local nm ""
        local ns ""
        forvalues j = 1/`kk' {
            if `j' != `argmax' {
                local aj : word `j' of `left_v'
                local bj : word `j' of `left_m'
                local cj : word `j' of `left_s'
                local nv "`nv' `aj'"
                local nm "`nm' `bj'"
                local ns "`ns' `cj'"
            }
        }
        local left_v "`nv'"
        local left_m "`nm'"
        local left_s "`ns'"
    }
    file close fimp
    di "置换重要性已写入 tables/ml-variable-importance.csv（指标＝delta R2，5 次重复）"
}
else {
    di as error "置换重要性阻断：未得到可用的样本外预测模型"
    file open fblk1 using "${OUT_ROOT}/reports/ml-blocked-01-supervised-`today'.md", write replace
    file write fblk1 "# ML 执行阻断：01-supervised" _n _n
    file write fblk1 "## predict-regression / ml-variable-importance.csv" _n _n
    file write fblk1 "- 阻断：未得到可用的样本外预测模型（`best_name'），置换重要性无法计算。" _n
    file write fblk1 "- 处置：检查 $Y 与 $FEATURES 的缺失、共线，或换用其他候选模型。" _n
    file close fblk1
}

*------------------------------------------------------------------------------
* 任务 predict-binary：$Y 必须是二分类，否则照 .py 口径写阻断
*------------------------------------------------------------------------------
local by "$Y"
capture confirm variable $BIN_Y
if _rc == 0 local by "$BIN_Y"
di "--> 任务 predict-binary：核对 `by' 的取值个数"
qui levelsof `by', local(ylv)
local ky = wordcount("`ylv'")
local bin_summary ""
if `ky' > 2 {
    local bin_reason "RuntimeError: predict-binary: 因变量 `by' 取值 `ky' 类，不是二分类任务"
    di as error "`bin_reason'"
    local bin_summary "阻断：`bin_reason'"
    file open fblk2 using "${OUT_ROOT}/reports/ml-blocked-01-supervised-`today'.md", write replace
    file write fblk2 "# ML 执行阻断：01-supervised" _n _n
    file write fblk2 "## predict-binary" _n _n
    file write fblk2 "- 阻断：`bin_reason'" _n
    file write fblk2 "- 处置：二分类任务须给出 0/1 因变量（字典里 role=outcome_bin 的列，对应 $BIN_Y），或改走 03-regression 的 logit 路径。" _n
    file write fblk2 "- 影响：ml-model-performance.csv 保留连续因变量口径（本脚本先写连续口径，再在此处阻断，故不被覆盖）；ml-calibration.csv 不产出。" _n
    file close fblk2
}
else {
    di "--> 二分类任务：基准 Logit 与 Lasso logit"
    file open fperfbin using "${OUT_ROOT}/tables/ml-model-performance.csv", write append
    file open fcal using "${OUT_ROOT}/tables/ml-calibration.csv", write replace
    file write fcal "任务,模型,分箱,平均预测概率,实际正例比例" _n
    local bin_n 0

    capture noisily qui logit `by' $FEATURES if _test == 0
    if _rc == 0 {
        capture drop _pb _pbt
        capture predict double _pb if _test == 1, pr
        capture predict double _pbt if _test == 0, pr
        qui count if _test == 1 & !missing(_pb)
        if r(N) == `n_test' {
            _mlauc _pb `by'
            local auc = r(auc)
            qui gen double _brier = (`by' - _pb)^2 if _test == 1
            qui summarize _brier if _test == 1, meanonly
            local brier = r(mean)
            qui gen byte _hit = ((`by' == 1) == (_pb >= 0.5)) if _test == 1
            qui summarize _hit if _test == 1, meanonly
            local acc = r(mean)
            qui gen byte _hitt = ((`by' == 1) == (_pbt >= 0.5)) if _test == 0
            qui summarize _hitt if _test == 0, meanonly
            local acctr = r(mean)
            _mlfmt3 `auc'
            local a1 = r(s)
            _mlfmt3 `brier'
            local a2 = r(s)
            _mlfmt3 `acc'
            local a3 = r(s)
            _mlfmt3 `acctr'
            local a4 = r(s)
            file write fperfbin "predict-binary,基准 Logit（MLE）,`a1',`a2',`a3',`a4',`n_train_s',`n_test_s',,,," _n
            local bin_n = `bin_n' + 1
            capture drop _pbin
            qui xtile _pbin = _pb if _test == 1, nq(10)
            qui levelsof _pbin if _test == 1, local(bins)
            foreach b of local bins {
                qui summarize _pb if _test == 1 & _pbin == `b', meanonly
                local mp = r(mean)
                qui summarize `by' if _test == 1 & _pbin == `b', meanonly
                local fp = r(mean)
                _mlfmt3 `mp'
                local c1 = r(s)
                _mlfmt3 `fp'
                local c2 = r(s)
                file write fcal "predict-binary,基准 Logit（MLE）,`b',`c1',`c2'" _n
            }
            drop _brier _hit _hitt _pbin
        }
    }
    else di as error "基准 Logit 估计失败（rc=`=_rc'）"

    capture noisily qui lasso logit `by' $FEATURES if _test == 0, selection(cv) folds($CV_FOLDS) rseed($SEED) nolog
    if _rc == 0 {
        capture drop _pb2 _pb2t
        capture predict double _pb2 if _test == 1, pr
        capture predict double _pb2t if _test == 0, pr
        qui count if _test == 1 & !missing(_pb2)
        if r(N) == `n_test' {
            _mlauc _pb2 `by'
            local auc2 = r(auc)
            qui gen double _brier2 = (`by' - _pb2)^2 if _test == 1
            qui summarize _brier2 if _test == 1, meanonly
            local brier2 = r(mean)
            qui gen byte _hit2 = ((`by' == 1) == (_pb2 >= 0.5)) if _test == 1
            qui summarize _hit2 if _test == 1, meanonly
            local acc2 = r(mean)
            qui gen byte _hit2t = ((`by' == 1) == (_pb2t >= 0.5)) if _test == 0
            qui summarize _hit2t if _test == 0, meanonly
            local acc2t = r(mean)
            _mlfmt3 `auc2'
            local a1 = r(s)
            _mlfmt3 `brier2'
            local a2 = r(s)
            _mlfmt3 `acc2'
            local a3 = r(s)
            _mlfmt3 `acc2t'
            local a4 = r(s)
            file write fperfbin "predict-binary,Lasso logit（CV 选 lambda）,`a1',`a2',`a3',`a4',`n_train_s',`n_test_s',,,," _n
            local bin_n = `bin_n' + 1
            drop _brier2 _hit2 _hit2t
        }
    }
    else di as error "lasso logit 不可用（rc=`=_rc'），二分类只报基准 Logit"

    file close fperfbin
    file close fcal
    local bin_summary "二分类任务已执行：`bin_n' 个候选模型；样本外 AUC／Brier／准确率见 tables/ml-model-performance.csv，校准见 tables/ml-calibration.csv。"
}

*------------------------------------------------------------------------------
* 任务 structure：PCA 与 K-means（K=2..$KMAX，轮廓系数取最大）
*------------------------------------------------------------------------------
di "--> 任务 structure：PCA 与 K-means"
local sfeat "$C $X"
local ksfeat = wordcount("`sfeat'")
local zlist ""
foreach v of local sfeat {
    qui egen double _zb_`v' = std(`v')
    local zlist "`zlist' _zb_`v'"
}
local pca_summary ""
local clus_summary ""

if `ksfeat' >= 2 {
    * 在标准化变量上做 PCA，等价于 .py 的 StandardScaler + PCA（相关阵 PCA）
    qui pca `zlist'
    matrix Ev = e(Ev)
    local ncomp = min($NCOMP, `ksfeat')
    local cum 0
    file open fpca using "${OUT_ROOT}/tables/ml-structure-pca.csv", write replace
    file write fpca "主成分,解释方差比例,累计解释方差" _n
    forvalues i = 1/`ncomp' {
        local ratio = Ev[1, `i'] / `ksfeat'
        local cum = `cum' + `ratio'
        _mlfmt3 `ratio'
        local r1 = r(s)
        _mlfmt3 `cum'
        local r2 = r(s)
        file write fpca "PC`i',`r1',`r2'" _n
        if `i' == 1 {
            local pc1 = `ratio'
        }
        if `i' == 2 {
            local pc2 = `ratio'
        }
    }
    file close fpca
    if `ncomp' >= 2 {
        local pcsum = `pc1' + `pc2'
    }
    else local pcsum = `pc1'
    local pca_summary "PCA 前两主成分累计解释 `=strtrim(strofreal(`pcsum', "%12.3f"))'；明细 tables/ml-structure-pca.csv。"

    file open fclu using "${OUT_ROOT}/tables/ml-structure-cluster.csv", write replace
    file write fclu "解数K,组内平方和,轮廓系数,最小组占比" _n
    local best_k 0
    local best_sil -2
    forvalues k = 2/$KMAX {
        capture drop _km`k'
        capture drop _gc`k'
        capture drop _wss
        capture drop _mw_*
        capture drop _dw_*
        capture noisily qui cluster kmeans `zlist', k(`k') name(km`k') start(krandom($SEED)) generate(_km`k')
        if _rc != 0 {
            di as error "K=`k' 聚类失败（rc=`=_rc'），跳过"
            continue
        }
        foreach v of local zlist {
            qui bysort _km`k': egen double _mw_`v' = mean(`v')
            qui gen double _dw_`v' = (`v' - _mw_`v')^2
        }
        qui egen double _wss = rowtotal(_dw_*)
        qui summarize _wss, meanonly
        local wss = r(sum)
        qui egen double _gc`k' = count(_km`k'), by(_km`k')
        qui summarize _gc`k', meanonly
        local minshare = r(min) / r(N)
        drop _gc`k'
        mata: st_numscalar("_sil`k'", sil_mean(st_data(., "`zlist'"), st_data(., "_km`k'")))
        local sil = _sil`k'
        _mlfmt3 `wss'
        local w1 = r(s)
        _mlfmt3 `sil'
        local w2 = r(s)
        _mlfmt3 `minshare'
        local w3 = r(s)
        file write fclu "`k',`w1',`w2',`w3'" _n
        if `sil' > `best_sil' {
            local best_sil = `sil'
            local best_k = `k'
        }
    }
    file close fclu
    local clus_summary "K 解按轮廓系数选 `best_k'（轮廓系数 `=strtrim(strofreal(`best_sil', "%12.3f"))'）；明细 tables/ml-structure-cluster.csv。"
}
else {
    local pca_summary "阻断：structure 候选特征少于 2 个（同 .py 的 RuntimeError: structure: 候选特征少于 2 个，无法降维或聚类）。"
    local clus_summary "阻断：同上，K-means 不执行。"
    di as error "`pca_summary'"
    file open fblk3 using "${OUT_ROOT}/reports/ml-blocked-01-supervised-`today'.md", write replace
    file write fblk3 "# ML 执行阻断：01-supervised" _n _n
    file write fblk3 "## structure" _n _n
    file write fblk3 "- `pca_summary'" _n
    file close fblk3
}
di "`pca_summary'"
di "`clus_summary'"

*------------------------------------------------------------------------------
* 报告：reports/ml-run-01-supervised-<date>.md（章节与 .py 的 sections 一致）
*------------------------------------------------------------------------------
file open frep using "${OUT_ROOT}/reports/ml-run-01-supervised-`today'.md", write replace
file write frep "# ML 执行摘要：01-supervised" _n _n
file write frep "## 运行口径" _n _n
file write frep "数据 $DATA；种子 $SEED；测试集比例 $TEST_SIZE；折分方式＝`split_note'；训练样本 `n_train'，测试样本 `n_test'；候选特征 `kfeat' 个。" _n _n
file write frep "## regularized" _n _n
file write frep "- 表：tables/ml-selected-variables.csv, tables/ml-regularization-path.csv" _n
file write frep "- 摘要：`reg_summary'" _n _n
file write frep "## predict-regression" _n _n
file write frep "- 表：tables/ml-model-performance.csv, tables/ml-variable-importance.csv" _n
file write frep "- 摘要：候选模型 `perf_rows' 个（基准 OLS / Lasso / 弹性网）；样本外 RMSE 最小者为 `best_name'。" _n
file write frep "- 注意：随机森林与梯度提升（HistGB）在 Stata 16 基础版无内置命令（本机/本版本不可用），此处候选模型与置换重要性口径与 .py 不同；置换重要性衡量模型依赖，不是因果贡献，对外声称请按 C30 写边界。" _n _n
file write frep "## predict-binary" _n _n
file write frep "- `bin_summary'" _n _n
file write frep "## structure" _n _n
file write frep "- 表：tables/ml-structure-pca.csv, tables/ml-structure-cluster.csv" _n
file write frep "- `pca_summary'" _n
file write frep "- `clus_summary'" _n _n
file write frep "## 可声称边界" _n _n
file write frep "预测性能支持对样本外预测能力的陈述；变量重要性与选中变量清单不支持因果解释。因果结论须走 02-causal-ml 并满足其识别假设（C30）。" _n
file close frep

di "--> 完成：报告见 ${OUT_ROOT}/reports/ml-run-01-supervised-`today'.md"

capture log close _all
