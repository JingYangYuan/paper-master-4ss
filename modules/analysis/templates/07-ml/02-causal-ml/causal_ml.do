* Paper Analysis 4SS - 07 ml / 02 causal-ml Stata template.
* 对应 Python 基准：templates/07-ml/02-causal-ml/causal_ml.py（任务 ID、输出表名、CSV 列名、报告命名逐字对齐）。
* 任务：pds-controls（双重选择控制集）/ dml-plr（部分线性模型的交叉拟合）/ iv-lasso（Lasso 挑工具变量后 2SLS）。
* 只报实际跑出的数；跑不动就写阻断，不写占位结果（见 TEMPLATE-CONTRACT 与 phases/07-ml-and-causal-ml.md §6）。
* 与 .py 的口径差异（报告里必须写明）：
*   - Stata 无 HistGB，DML 的 nuisance 学习器固定为 lasso（CV 定惩罚），不对应 --learner histgb。
*   - 交叉拟合按 $ID 分组分折（同一个体不跨折），不按行随机切分。
*   - pds-controls 走「两方程各自 lasso linear + 并集」手写路径，不等价于 pdslasso 的 post-double-selection 推断，
*     报告的摘要行已注明；装了 pdslasso 也仍走此路径，避免两套推断口径混用。

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
global X "treatment"
global C "x2 x3 x4 x5 x6 x7 x8 x9 x10"
global IVCAND ""
global CLUSTER "pid"
global ID "pid"
global TIME "year"
global SEED "20261024"
global CV_FOLDS "5"
global DML_FOLDS "5"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/data"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/causal_ml.log", replace text

use "${DATA}", clear

local today : di %tdCCYY-NN-DD daily("`c(current_date)'", "DMY")
local controls "$C"
local n_ctrl = wordcount("`controls'")
local cluster_note "$CLUSTER"

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

*------------------------------------------------------------------------------
* 取「e(b) 里非零系数的候选变量名」：用 Stata 的 colnumb 逐名查，不依赖 Mata
*------------------------------------------------------------------------------
capture program drop _ml_sel
program define _ml_sel, rclass
    version 16
    args bname cands
    tempname b
    matrix `b' = `bname'
    local out ""
    foreach v of local cands {
        capture local j = colnumb(`b', "`v'")
        if _rc == 0 {
            if `j' < . {
                local cf = `b'[1, `j']
                if abs(`cf') > 1e-8 local out "`out' `v'"
            }
        }
    }
    return local sel = strtrim("`out'")
end

*------------------------------------------------------------------------------
* 主表 ml-causal-estimates.csv：本模板先写表头，后续各任务按行追加
*------------------------------------------------------------------------------
local fmain "${OUT_ROOT}/tables/ml-causal-estimates.csv"
file open fmain using "`fmain'", write replace
file write fmain "任务,模型,处理变量系数,标准误,观测值,备注,t 值,p 值,控制变量数,聚类层级,第一阶段 F,选中工具变量数" _n
file close fmain

local pds_summary ""
local dml_summary ""
local iv_summary ""

*------------------------------------------------------------------------------
* 任务 pds-controls
*------------------------------------------------------------------------------
di "--> 任务 pds-controls：双重选择控制集"
if `n_ctrl' == 0 {
    local pds_summary "阻断：pds-controls 没有候选控制变量（变量发现包的 control 角色为空）。"
    di as error "`pds_summary'"
    file open fblk using "${OUT_ROOT}/reports/ml-blocked-02-causal-ml-`today'.md", write replace
    file write fblk "# ML 执行阻断：02-causal-ml" _n _n
    file write fblk "## pds-controls" _n _n
    file write fblk "- `pds_summary'" _n
    file close fblk
}
else {
    capture quietly lasso linear $Y `controls', selection(cv) folds($CV_FOLDS) rseed($SEED) nolog
    local rc_y = _rc
    if `rc_y' != 0 {
        local pds_summary "阻断：Y 方程的 lasso linear 报 rc=`rc_y'（检查 lassopack/elasticnet 是否可用）。"
        di as error "`pds_summary'"
        file open fblk using "${OUT_ROOT}/reports/ml-blocked-02-causal-ml-`today'.md", write replace
        file write fblk "# ML 执行阻断：02-causal-ml" _n _n
        file write fblk "## pds-controls" _n _n
        file write fblk "- `pds_summary'" _n
        file close fblk
    }
    else {
        matrix b_pdsy = e(b)
        local a_y = e(alpha)
        _ml_sel b_pdsy "`controls'"
        local sel_y "`r(sel)'"

        capture quietly lasso linear $X `controls', selection(cv) folds($CV_FOLDS) rseed($SEED) nolog
        local rc_x = _rc
        if `rc_x' != 0 {
            local sel_x ""
            local a_x .
        }
        else {
            matrix b_pdsx = e(b)
            local a_x = e(alpha)
            _ml_sel b_pdsx "`controls'"
            local sel_x "`r(sel)'"
        }
        local n_sel_y = wordcount("`sel_y'")
        local n_sel_x = wordcount("`sel_x'")
        local union : list sel_y | sel_x
        local n_union = wordcount("`union'")

        * 逐变量标记：Y 方程选中、X 方程选中、是否进并集
        file open fsel using "${OUT_ROOT}/tables/ml-pds-selected-variables-pds-controls.csv", write replace
        file open fselm using "${OUT_ROOT}/tables/ml-pds-selected-variables.csv", write replace
        file write fsel "variable,selected_by,pred_X,in_union" _n
        file write fselm "任务,variable,selected_by,pred_X,in_union" _n
        foreach v of local controls {
            local tag_y ""
            local tag_x ""
            local tag_u "否"
            local t1 : list v in sel_y
            if `t1' local tag_y "Y 方程"
            local t2 : list v in sel_x
            if `t2' local tag_x "是"
            local t3 : list v in union
            if `t3' local tag_u "是"
            file write fsel "`v',`tag_y',`tag_x',`tag_u'" _n
            file write fselm "pds-controls,`v',`tag_y',`tag_x',`tag_u'" _n
        }
        file close fsel
        file close fselm

        file open ftask using "${OUT_ROOT}/tables/ml-causal-estimates-pds-controls.csv", write replace
        file write ftask "模型,处理变量系数,标准误,t 值,p 值,控制变量数,观测值,聚类层级" _n
        quietly regress $Y $X `controls', vce(cluster $CLUSTER)
        local b_all = _b[$X]
        local se_all = _se[$X]
        local n_all = e(N)
        local t_all = `b_all' / `se_all'
        local p_all = 2 * ttail(e(df_r), abs(`t_all'))
        _mlfmt3 `b_all'
        local s_b "`r(s)'"
        _mlfmt3 `se_all'
        local s_se "`r(s)'"
        _mlfmt3 `t_all'
        local s_t "`r(s)'"
        _mlfmt3 `p_all'
        local s_p "`r(s)'"
        _mlfmt0 `n_all'
        local s_n "`r(s)'"
        file write ftask "基准：全部候选控制变量,`s_b',`s_se',`s_t',`s_p',`n_ctrl',`s_n',`cluster_note'" _n

        file open fm using "`fmain'", write append
        file write fm "pds-controls,基准：全部候选控制变量,`s_b',`s_se',`s_n',,`s_t',`s_p',`n_ctrl',`cluster_note',," _n

        if `n_union' == 0 {
            local pds_summary "双重选择后并集为空，PDS 行不估计；候选控制 `n_ctrl' 个（C28 要求写清正交化对象）。"
            di as error "`pds_summary'"
        }
        else {
            quietly regress $Y $X `union', vce(cluster $CLUSTER)
            local b_u = _b[$X]
            local se_u = _se[$X]
            local n_u = e(N)
            local t_u = `b_u' / `se_u'
            local p_u = 2 * ttail(e(df_r), abs(`t_u'))
            _mlfmt3 `b_u'
            local s_bu "`r(s)'"
            _mlfmt3 `se_u'
            local s_seu "`r(s)'"
            _mlfmt3 `t_u'
            local s_tu "`r(s)'"
            _mlfmt3 `p_u'
            local s_pu "`r(s)'"
            _mlfmt0 `n_u'
            local s_nu "`r(s)'"
            file write ftask "PDS：并集控制集,`s_bu',`s_seu',`s_tu',`s_pu',`n_union',`s_nu',`cluster_note'" _n
            file write fm "pds-controls,PDS：并集控制集,`s_bu',`s_seu',`s_nu',,`s_tu',`s_pu',`n_union',`cluster_note',," _n
            local pds_summary "候选控制 `n_ctrl' 个；Y 方程选中 `n_sel_y' 个；X 方程选中 `n_sel_x' 个；并集 `n_union' 个；alpha_Y=`=strtrim(strofreal(`a_y', "%12.4g"))'，alpha_X=`=strtrim(strofreal(`a_x', "%12.4g"))'。"
        }
        file close fm
        file close ftask
        di "`pds_summary'"
    }
}

*------------------------------------------------------------------------------
* 任务 dml-plr：按 $ID 分折交叉拟合，残差对残差，报折间波动
*------------------------------------------------------------------------------
di "--> 任务 dml-plr：部分线性模型的交叉拟合"
if `n_ctrl' == 0 {
    local dml_summary "阻断：dml-plr 没有候选控制变量。"
    di as error "`dml_summary'"
}
else {
    preserve
    quietly {
        egen long _uid = group($ID)
        gen byte _fold = mod(_uid, $DML_FOLDS) + 1
        gen double _ry = .
        gen double _rd = .
    }

    local fold_fail 0
    local fold_min 0
    local fold_max 0
    local have_fold 0
    file open ffold using "${OUT_ROOT}/tables/ml-crossfit-folds.csv", write replace
    file write ffold "任务,折,折系数,折样本" _n

    forvalues k = 1/$DML_FOLDS {
        quietly count if _fold == `k'
        if r(N) == 0 continue
        capture quietly lasso linear $Y `controls' if _fold != `k', selection(cv) folds($CV_FOLDS) rseed($SEED) nolog
        if _rc != 0 {
            local fold_fail = 1
            continue
        }
        quietly predict double _pyhat if _fold == `k', xb
        quietly replace _ry = $Y - _pyhat if _fold == `k'
        quietly drop _pyhat
        capture quietly lasso linear $X `controls' if _fold != `k', selection(cv) folds($CV_FOLDS) rseed($SEED) nolog
        if _rc != 0 {
            local fold_fail = 1
            continue
        }
        quietly predict double _pdhat if _fold == `k', xb
        quietly replace _rd = $X - _pdhat if _fold == `k'
        quietly drop _pdhat

        quietly count if _fold == `k' & !missing(_ry, _rd)
        local nk = r(N)
        if `nk' < 10 continue
        quietly regress _ry _rd if _fold == `k', vce(robust)
        local bk = _b[_rd]
        if `have_fold' == 0 {
            local fold_min = `bk'
            local fold_max = `bk'
            local have_fold 1
        }
        else {
            if `bk' < `fold_min' local fold_min = `bk'
            if `bk' > `fold_max' local fold_max = `bk'
        }
        _mlfmt3 `bk'
        local s_bk "`r(s)'"
        _mlfmt0 `nk'
        local s_nk "`r(s)'"
        file write ffold "dml-plr,`k',`s_bk',`s_nk'" _n
    }
    file close ffold

    if `fold_fail' == 1 {
        local dml_summary "阻断：交叉拟合的 lasso linear 报错，DML 点估计不报（检查 lassopack/elasticnet）。"
        di as error "`dml_summary'"
        restore
    }
    else {
        quietly regress _ry _rd, vce(robust)
        local theta = _b[_rd]
        local se_theta = _se[_rd]
        local n_dml = e(N)
        _mlfmt3 `theta'
        local s_theta "`r(s)'"
        _mlfmt3 `se_theta'
        local s_se_theta "`r(s)'"
        _mlfmt0 `n_dml'
        local s_n_dml "`r(s)'"

        file open fdml using "${OUT_ROOT}/tables/ml-causal-estimates-dml-plr.csv", write replace
        file write fdml "模型,处理变量系数,标准误,观测值,备注" _n
        file write fdml "DML-PLR（lasso，$DML_FOLDS 折交叉拟合）,`s_theta',`s_se_theta',`s_n_dml',Neyman 正交 + 交叉拟合；标准误 HC1" _n
        file close fdml
        restore

        quietly regress $Y $X `controls', vce(cluster $CLUSTER)
        local b_base = _b[$X]
        local se_base = _se[$X]
        local n_base = e(N)
        _mlfmt3 `b_base'
        local s_base "`r(s)'"
        _mlfmt3 `se_base'
        local s_se_base "`r(s)'"
        _mlfmt0 `n_base'
        local s_n_base "`r(s)'"
        file open fm using "`fmain'", write append
        file write fm "dml-plr,基准 OLS（全部控制）,`s_base',`s_se_base',`s_n_base',控制变量 `n_ctrl' 个,,,`n_ctrl',`cluster_note',," _n
        file write fm "dml-plr,DML-PLR（lasso，$DML_FOLDS 折交叉拟合）,`s_theta',`s_se_theta',`s_n_dml',Neyman 正交 + 交叉拟合；折间系数 `=strtrim(strofreal(`fold_min', "%12.3f"))'–`=strtrim(strofreal(`fold_max', "%12.3f"))',,,`n_ctrl',HC1,," _n
        file close fm
        local dml_summary "DML 点估计 `=strtrim(strofreal(`theta', "%12.3f"))'（HC1 标准误 `=strtrim(strofreal(`se_theta', "%12.3f"))'），基准 OLS `=strtrim(strofreal(`b_base', "%12.3f"))'；折间系数范围 `=strtrim(strofreal(`fold_min', "%12.3f"))'–`=strtrim(strofreal(`fold_max', "%12.3f"))'。"
        di "`dml_summary'"
    }
}

*------------------------------------------------------------------------------
* 任务 iv-lasso：Lasso 从工具变量候选中筛，再 2SLS
*------------------------------------------------------------------------------
di "--> 任务 iv-lasso：Lasso 挑工具变量后 2SLS"
if "$IVCAND" == "" {
    local iv_summary "阻断：iv-lasso 未指定工具变量候选（global IVCAND 为空）。这是模板占位，不是分析结论（C28）。"
    di as error "`iv_summary'"
}
else {
    capture quietly lasso linear $X $IVCAND `controls', selection(cv) folds($CV_FOLDS) rseed($SEED) nolog
    local rc_iv = _rc
    if `rc_iv' != 0 {
        local iv_summary "阻断：iv-lasso 的 lasso linear 报 rc=`rc_iv'（检查 lassopack/elasticnet）。"
        di as error "`iv_summary'"
    }
    else {
        matrix b_iv = e(b)
        _ml_sel b_iv "$IVCAND"
        local sel_iv "`r(sel)'"
        local n_sel_iv = wordcount("`sel_iv'")
        if `n_sel_iv' == 0 {
            local iv_summary "Lasso 未从工具变量候选中选出任何变量，2SLS 不估计；候选 `=wordcount("$IVCAND")' 个。"
            di as error "`iv_summary'"
        }
        else {
            capture quietly ivregress 2sls $Y `controls' ($X = `sel_iv'), vce(cluster $CLUSTER)
            local rc_2sls = _rc
            if `rc_2sls' != 0 {
                local iv_summary "阻断：ivregress 2sls 报 rc=`rc_2sls'（弱工具或共线，先看第一阶段）。"
                di as error "`iv_summary'"
            }
            else {
                local b_iv = _b[$X]
                local se_iv = _se[$X]
                local n_iv = e(N)
                quietly regress $X `sel_iv' `controls', vce(cluster $CLUSTER)
                quietly test `sel_iv'
                local f_first = r(F)
                _mlfmt3 `b_iv'
                local s_biv "`r(s)'"
                _mlfmt3 `se_iv'
                local s_seiv "`r(s)'"
                _mlfmt3 `f_first'
                local s_f "`r(s)'"
                _mlfmt0 `n_iv'
                local s_niv "`r(s)'"

                file open fiv using "${OUT_ROOT}/tables/ml-causal-estimates-iv-lasso.csv", write replace
                file write fiv "模型,处理变量系数,标准误,观测值,第一阶段 F,选中工具变量数" _n
                file write fiv "2SLS（Lasso 挑 IV）,`s_biv',`s_seiv',`s_niv',`s_f',`n_sel_iv'" _n
                file close fiv

                file open fm using "`fmain'", write append
                file write fm "iv-lasso,2SLS（Lasso 挑 IV）,`s_biv',`s_seiv',`s_niv',选中工具变量：`sel_iv',,,`n_ctrl',`cluster_note',`s_f',`n_sel_iv'" _n
                file close fm
                local iv_summary "2SLS 系数 `=strtrim(strofreal(`b_iv', "%12.3f"))'（聚类稳健标准误 `=strtrim(strofreal(`se_iv', "%12.3f"))'），第一阶段聚类稳健 F=`=strtrim(strofreal(`f_first', "%12.1f"))'，选中工具变量 `n_sel_iv' 个：`sel_iv'。"
                di "`iv_summary'"
            }
        }
    }
}

*------------------------------------------------------------------------------
* 报告：reports/ml-run-02-causal-ml-<date>.md
*------------------------------------------------------------------------------
file open frep using "${OUT_ROOT}/reports/ml-run-02-causal-ml-`today'.md", write replace
file write frep "# ML 执行摘要：02-causal-ml" _n _n
file write frep "## 运行口径" _n _n
file write frep "数据 $DATA；种子 $SEED；交叉拟合折数 $DML_FOLDS（按 $ID 分组分配）；nuisance 学习器 lasso（Stata 无 HistGB，与 .py 的 --learner histgb 口径不同）；聚类变量 $CLUSTER。" _n _n
file write frep "## pds-controls" _n _n
file write frep "- 表：tables/ml-causal-estimates.csv（任务级副本 tables/ml-causal-estimates-pds-controls.csv）、tables/ml-pds-selected-variables.csv（任务级副本 tables/ml-pds-selected-variables-pds-controls.csv）" _n
file write frep "- 摘要：`pds_summary'" _n _n
file write frep "## dml-plr" _n _n
file write frep "- 表：tables/ml-causal-estimates.csv（任务级副本 tables/ml-causal-estimates-dml-plr.csv）、tables/ml-crossfit-folds.csv" _n
file write frep "- 摘要：`dml_summary'" _n
file write frep "- 注意：两列差异若无机制解释，不得写成「ML 校正了内生性」（C30）。" _n _n
file write frep "## iv-lasso" _n _n
file write frep "- 表：tables/ml-causal-estimates-iv-lasso.csv" _n
file write frep "- 摘要：`iv_summary'" _n _n
file write frep "## 识别前提" _n _n
file write frep "PDS 与 DML 都只在给定识别假设下成立：控制集须满足条件外生性，DML 只处理高维控制带来的正则化偏误，不解决遗漏变量。IV 结论依赖工具变量外生性与第一阶段强度。" _n
file close frep

di "--> 完成：报告见 ${OUT_ROOT}/reports/ml-run-02-causal-ml-`today'.md"

capture log close _all

