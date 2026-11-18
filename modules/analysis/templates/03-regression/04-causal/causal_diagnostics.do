* ============================================================================
* Paper Analysis 4SS — 因果识别诊断钩子（Stata，base Stata + Mata，无第三方包依赖）
*
* 用途：在 03-regression/04-causal 主模板跑完之后，补齐「识别设计」的诊断读数。
* 设计原则：
*   1) 只依赖 base Stata（regress/ivregress/test/file write）与 Mata；
*   2) 缺变量、缺数据、缺包一律写 SKIP 行并继续，不阻断主流程；
*   3) 输出列名与 R/Python 版本严格一致（见同目录 causal_diagnostics.{R,py} 文件头）；
*   4) 需要第三方包才能算的量（Bacon 分解、rdrobust 的 Robust 行、honestdid）只写 SKIP 并说明替代路径。
*
* 调用方式：
*   A. 由 causal_models.do 末尾 `do` 本文件（globals 已就位，直接可用）；
*   B. 独立运行：`do causal_diagnostics.do`（需 cd 到项目根或设 PROJECT_ROOT；数据取 $DATA）。
*
* 可选参数：out() data() y() x() c() iv() endog() cluster() id() time() reps() alpha()
* ============================================================================

version 16
set more off

capture program drop causal_diag
program define causal_diag
    syntax [, OUT(string) DATA(string) Y(string) X(string) C(string) IV(string) ///
              ENDOG(string) CLUSTER(string) ID(string) TIME(string) ///
              REPS(integer 200) ALPHA(real 0.05)]

    * ---- 解析参数：显式参数 > 全局宏 > 默认 ----
    local out  = cond("`out'"!="",  "`out'",  cond("${OUT_ROOT}"!="", "${OUT_ROOT}", "paper-workspace/04-analysis"))
    local data = cond("`data'"!="", "`data'", cond("${DATA}"!="", "${DATA}", "`out'/data/analysis-data.dta"))
    local y    = cond("`y'"!="",    "`y'",    "${Y}")
    local ctrl = cond("`c'"!="",    "`c'",    "${C}")
    local z    = cond("`iv'"!="",   "`iv'",   "${IV}")
    local d    = cond("`endog'"!="", "`endog'", "${ENDOG}")
    local cl   = cond("`cluster'"!="", "`cluster'", "${CLUSTER}")
    local id   = cond("`id'"!="",   "`id'",   "${ID}")
    local tm   = cond("`time'"!="", "`time'", "${TIME}")
    local rv   = "${RUNNING}"
    local cut  = ${CUTOFF}
    if "`cut'" == "" local cut = 0
    local treat = "${TREAT}"

    capture mkdir "`out'"
    capture mkdir "`out'/tables"
    capture mkdir "`out'/reports"
    local skips "`out'/tables/diagnostics-skips.csv"
    file open fs using "`skips'", write replace
    file write fs "block,reason,detail" _n
    file close fs

    * ---- 数据：缺则尝试载入 ----
    capture confirm variable `y'
    if _rc {
        capture confirm file "`data'"
        if _rc == 0 quietly use "`data'", clear
    }
    capture confirm variable `y'
    if _rc {
        di as error "SKIP: 无数据或缺因变量 `y'（数据：`data'）"
        file open fs using "`skips'", write append
        file write fs "all,no_data,`data'" _n
        file close fs
        exit
    }

    quietly count
    local N = r(N)
    local ncl = .
    if "`cl'" != "" {
        capture confirm variable `cl'
        if _rc == 0 {
            quietly levelsof `cl', local(_lv)
            local ncl : word count `_lv'
        }
    }
    local vceopt ""
    capture confirm variable `cl'
    if _rc == 0 & "`cl'" != "" local vceopt ", vce(cluster `cl')"

    * ========================================================================
    * 1) IV：五个 F + OLS/2SLS 并排 + AR 区间 + LTZ 翻转阈值
    * ========================================================================
    local have_iv = 1
    if "`d'" == "" | "`z'" == "" {
        local have_iv = 0
    }
    else {
        foreach v in `d' `z' {
            capture confirm variable `v'
            if _rc local have_iv = 0
        }
    }

    if `have_iv' == 0 {
        di as text "SKIP: IV 诊断（缺 $ENDOG/$IV 或其变量不存在）"
        file open fs using "`skips'", write append
        file write fs "iv,missing_vars,endog=`d'; iv=`z'" _n
        file close fs
    }
    else {
        di as text "--> IV 诊断：五个 F 变体 / OLS-2SLS / AR / LTZ 阈值"

        quietly ivregress 2sls `y' `ctrl' (`d' = `z')`vceopt'
        local iv_b  = _b[`d']
        local iv_se = _se[`d']
        quietly regress `y' `d' `ctrl'`vceopt'
        local ols_b  = _b[`d']
        local ols_se = _se[`d']
        local ratio = .
        if `ols_b' != 0 local ratio = `iv_b'/`ols_b'

        quietly regress `d' `z' `ctrl'
        quietly test `z'
        local F_std = r(F)

        quietly regress `d' `z' `ctrl', robust
        quietly test `z'
        local F_rob = r(F)

        local F_clu = .
        if "`vceopt'" != "" {
            quietly regress `d' `z' `ctrl'`vceopt'
            quietly test `z'
            local F_clu = r(F)
        }

        * bootstrap F：聚类块重抽样的平均 t²（近似 ivDiag 的 F.bootstrap；仅单工具）
        local F_boot = .
        local pz0 : word count `z'
        if `pz0' > 1 {
            file open fs using "`skips'", write append
            file write fs "iv_bootstrap,multi_instrument,多工具下 bootstrap F 未定义；改看 effective F 与 AR" _n
            file close fs
        }
        else capture {
            if "`vceopt'" != "" {
                quietly bootstrap _fboot_t=_b[`z']/_se[`z'], reps(`reps') cluster(`cl') idcluster(_bdid) nodots: ///
                    regress `d' `z' `ctrl'`vceopt'
            }
            else {
                quietly bootstrap _fboot_t=_b[`z']/_se[`z'], reps(`reps') nodots: ///
                    regress `d' `z' `ctrl', vce(robust)
            }
            local F_boot = _b[_fboot_t]*_b[_fboot_t]
        }
        capture drop _bdid
        if `F_boot' == . di as text "  note: bootstrap F 未收敛，记缺失"

        * effective F：单工具 = 稳健/聚类 F；多工具 = Mata 迹公式
        local pz : word count `z'
        local F_eff = .
        if `pz' == 1 {
            if `F_clu' != . local F_eff = `F_clu'
            else local F_eff = `F_rob'
        }
        else {
            local rzlist ""
            local k = 0
            foreach zz of local z {
                local ++k
                quietly regress `zz' `ctrl'
                quietly predict double _rz`k', resid
                local rzlist "_rz`k' `rzlist'"
            }
            tempname Q V b
            capture matrix accum `Q' = `rzlist', noconstant
            quietly regress `d' `z' `ctrl'`vceopt'
            capture matrix `V' = e(V)
            capture matrix `b' = e(b)
            if `pz' > 1 & _rc == 0 {
                mata: st_local("F_eff", strofreal(_causal_effF("`Q'", "`b'", "`V'", "`z'", `N')))
            }
            capture drop _rz*
            if `F_eff' == . {
                di as text "  note: 多工具 effective F 计算失败，回退为经典 F"
                local F_eff = `F_std'
            }
        }

        * AR 区间：网格反演（β0 处检验工具系数联合为零）
        local ar_lo = .
        local ar_hi = .
        local ar_bounded = 0
        capture {
            local grid 80
            local lo_hit = .
            local hi_hit = .
            forvalues i = 0/`grid' {
                local b0 = `iv_b' - 6*`iv_se' + (`i'/`grid')*12*`iv_se'
                quietly gen double _yd = `y' - `b0'*`d'
                quietly regress _yd `z' `ctrl'`vceopt'
                quietly test `z'
                if r(p) > `alpha' {
                    if `lo_hit' == . local lo_hit = `b0'
                    local hi_hit = `b0'
                }
                quietly drop _yd
            }
            if `lo_hit' != . {
                local ar_lo = `lo_hit'
                local ar_hi = `hi_hit'
                local ar_bounded = 1
            }
        }

        * LTZ：恰好识别时「把结果解释光所需的直接效应」= 简约式系数（多工具时无闭式解）
        local mu_star = .
        if `pz0' == 1 {
            quietly regress `y' `z' `ctrl'`vceopt'
            capture local mu_star = _b[`z']
        }

        local main_ci "analytic"
        if `F_eff' != . {
            if `F_eff' < 23 & `F_eff' >= 10 local main_ci "tF_or_ar"
            if `F_eff' < 10 local main_ci "ar"
        }

        preserve
        tempfile _fs1
        postfile _h1 str12 model double(F_standard F_robust F_cluster F_bootstrap F_effective) ///
            double(N N_cluster ols_coef ols_se iv_coef iv_se ratio ar_ci_lo ar_ci_hi ar_bounded) ///
            str16 main_ci_type double(mu_star_reduced_form) using "`_fs1'", replace
        post _h1 ("iv_main") (`F_std') (`F_rob') (`F_clu') (`F_boot') (`F_eff') ///
            (`N') (`ncl') (`ols_b') (`ols_se') (`iv_b') (`iv_se') (`ratio') ///
            (`ar_lo') (`ar_hi') (`ar_bounded') ("`main_ci'") (`mu_star')
        postclose _h1
        use "`_fs1'", clear
        export delimited using "`out'/tables/first_stage_five_f.csv", replace
        restore

        di as result "  F_std=" %6.2f `F_std' "  F_rob=" %6.2f `F_rob' "  F_clu=" %6.2f `F_clu' "  F_boot=" %6.2f `F_boot' "  F_eff=" %6.2f `F_eff'
        di as result "  2SLS=" %6.4f `iv_b' "  OLS=" %6.4f `ols_b' "  ratio=" %6.2f `ratio' "  AR=[" %6.3f `ar_lo' ", " %6.3f `ar_hi' "]"
        if `F_eff' != . & `F_eff' < 23 di as text "  提示：effective F < 23，主区间应为 tF/AR（见 iv-three-stage-protocol.md 动作 7）"
    }

    * ========================================================================
    * 2) DiD：Bacon 分解（需 bacondecomp）
    * ========================================================================
    capture which bacondecomp
    if _rc {
        di as text "SKIP: Bacon 分解（bacondecomp 未安装）"
        file open fs using "`skips'", write append
        file write fs "did_bacon,missing_package,bacondecomp" _n
        file close fs
        file open f2 using "`out'/tables/bacon_decomp.csv", write replace
        file write f2 "term,weight,estimate,note" _n
        file write f2 "SKIP,,,bacondecomp 未安装；可从 causal_models.log 的 ddetail 输出人工抄录" _n
        file close f2
    }
    else {
        di as text "--> DiD 诊断：Bacon 分解（解析 ddetail 输出）"
        capture confirm variable `treat'
        if _rc == 0 & "`treat'" != "" {
            capture xtset `id' `tm'
            capture log using "`out'/reports/bacon-raw.log", text replace name(baconlog)
            capture noisily bacondecomp `y' `treat', ddetail
            local bacon_rc = _rc
            capture log close baconlog
            if `bacon_rc' != 0 {
                file open fs using "`skips'", write append
                file write fs "did_bacon,run_failed,bacondecomp rc=`bacon_rc'（需交错采纳且处理不倒退）" _n
                file close fs
                file open f2 using "`out'/tables/bacon_decomp.csv", write replace
                file write f2 "term,weight,estimate,note" _n
                file write f2 "SKIP,,,bacondecomp 运行失败 rc=`bacon_rc'；见 reports/bacon-raw.log" _n
                file close f2
            }
            else {
                * 解析 ddetail 的表格行：| Early_v_Late | beta weight | 之类
                tempname f2h
                file open f2h using "`out'/tables/bacon_decomp.csv", write replace
                file write f2h "term,weight,estimate,note" _n
                capture file close rfb
                file open rfb using "`out'/reports/bacon-raw.log", read text
                local nrow = 0
                local idx = 0
                file read rfb line
                while r(eof) == 0 {
                    local l = strtrim(`"`line'"')
                    if substr(`"`l'"', 1, 1) == "|" & strpos(`"`l'"', "-") == 0 {
                        local body = subinstr(`"`l'"', "|", " ", .)
                        tokenize `body'
                        local term "`1'"
                        if inlist("`term'", "Early_v_Late", "Late_v_Early", "Never_v_timing") ///
                           & "`2'" != "" & "`3'" != "" {
                            local ++idx
                            file write f2h "`term'_`idx',`3',`2',parsed_ddetail" _n
                            local ++nrow
                        }
                    }
                    file read rfb line
                }
                capture file close rfb
                if `nrow' == 0 {
                    file write f2h "see_log,,,未能解析 ddetail 表格；原文见 reports/bacon-raw.log" _n
                    file open fs using "`skips'", write append
                    file write fs "did_bacon,parse_failed,见 reports/bacon-raw.log" _n
                    file close fs
                }
                file close f2h
                di as result "  Bacon 分解：解析出 `nrow' 行 2×2 权重 → tables/bacon_decomp.csv"
            }
        }
        else {
            file open fs using "`skips'", write append
            file write fs "did_bacon,missing_vars,treat" _n
            file close fs
        }
    }

    * ========================================================================
    * 3) RDD：base Stata 局部线性回退（conventional 行）+ 窗内密度二项检验
    *    非 rdrobust/RBC：仅供敏感性核对，主报仍须 rdrobust 的 Robust 行
    * ========================================================================
    capture confirm variable `rv'
    if _rc | "`rv'" == "" {
        di as text "SKIP: RDD 诊断（缺 $RUNNING）"
        file open fs using "`skips'", write append
        file write fs "rdd,missing_vars,RUNNING" _n
        file close fs
        file open f3 using "`out'/tables/rdd_three_rows.csv", write replace
        file write f3 "row,coef,se,p,ci_lo,ci_hi,report_use,bw_selector,h,kernel,p_order,density_p,note" _n
        file write f3 "SKIP,,,,,,,,,,,缺 running variable" _n
        file close f3
    }
    else {
        * 密度检验（base Stata 二项检验，窗口 = rdrobust 带宽或 0.5*SD）
        quietly summarize `rv' if `rv' != .
        local sd = r(sd)
        local h0 = 0.5*`sd'
        capture which rdrobust
        local have_rd = (_rc == 0)
        if `have_rd' == 0 {
            di as text "SKIP: rdrobust 未安装，改用 base 局部线性回退"
            file open fs using "`skips'", write append
            file write fs "rdd_fallback,missing_package,rdrobust" _n
            file close fs
        }

        if `have_rd' {
            di as text "--> RDD 诊断：rdrobust 三行 + 密度二项检验"
            capture noisily rdrobust `y' `rv', c(`cut') all
            local rd_rc = _rc
            if `rd_rc' == 0 {
                local h = e(h_l)
                local kern : di e(kernel)
                local pord = e(p)
                * 密度：断点两侧 ±h 的观测数与二项检验
                quietly count if `rv' < `cut' & abs(`rv' - `cut') <= `h'
                local n_l = r(N)
                quietly count if `rv' >= `cut' & abs(`rv' - `cut') <= `h'
                local n_r = r(N)
                local dens_p = .
                capture {
                    quietly bitesti `=`n_l' + `n_r'' `n_l' 0.5
                    local dens_p = r(p)
                }
                local se_bc = .
                capture local se_bc = e(se_tau_bc)
                if `se_bc' == . {
                    capture local ci_l_bc = e(ci_l_bc)
                    capture local ci_r_bc = e(ci_r_bc)
                }
                local h_bw = `h'
                preserve
                tempfile _fs3
                postfile _h3 str20 row double(coef se p ci_lo ci_hi) str26 report_use str12 bw_selector ///
                    double(h) str12 kernel int p_order double(density_p) str80 note using "`_fs3'", replace
                post _h3 ("conventional") (e(tau_cl)) (e(se_tau_cl)) (e(pv_cl)) (e(ci_l_cl)) (e(ci_r_cl)) ///
                    ("point_estimate") ("mserd") (`h_bw') ("`kern'") (`pord') (`dens_p') ///
                    ("点估计取此行；CI 不取此行")
                post _h3 ("bias_corrected") (e(tau_bc)) (`se_bc') (e(pv_bc)) (`ci_l_bc') (`ci_r_bc') ///
                    ("not_default") ("mserd") (`h_bw') ("`kern'") (`pord') (`dens_p') ///
                    ("rdrobust 未单独返回此行的 SE；推断以 robust 行为准")
                post _h3 ("robust") (e(tau_bc)) (e(se_tau_rb)) (e(pv_rb)) (e(ci_l_rb)) (e(ci_r_rb)) ///
                    ("p_and_ci") ("mserd") (`h_bw') ("`kern'") (`pord') (`dens_p') ///
                    ("p 值与置信区间取此行（稳健偏差修正）")
                postclose _h3
                use "`_fs3'", clear
                export delimited using "`out'/tables/rdd_three_rows.csv", replace
                restore
                di as result "  RD：conventional coef=" %7.4f e(tau_cl) "；robust p=" %6.4f e(pv_rb) "；带宽=" %6.3f `h_bw'
            }
            else {
                file open fs using "`skips'", write append
                file write fs "rdd,run_failed,rdrobust rc=`rd_rc'" _n
                file close fs
                file open f3 using "`out'/tables/rdd_three_rows.csv", write replace
                file write f3 "row,coef,se,p,ci_lo,ci_hi,report_use,bw_selector,h,kernel,p_order,density_p,note" _n
                file write f3 "SKIP,,,,,,,,,,,rdrobust 运行失败 rc=`rd_rc'" _n
                file close f3
            }
        }
        else {
            di as text "--> RDD 诊断：base 局部线性回退（非 RBC）"
            quietly gen byte _rdpos = (`rv' >= `cut') if `rv' != .
            quietly gen double _rdc = (`rv' - `cut') if abs(`rv' - `cut') <= `h0'
            quietly gen double _rdw = 1 - abs(_rdc)/`h0'
            quietly regress `y' c._rdc##i._rdpos [aw=_rdw] if abs(`rv'-`cut')<=`h0', vce(robust)
            local b  = _b[1._rdpos]
            local se = _se[1._rdpos]
            local p  = 2*ttail(e(df_r), abs(`b'/`se'))
            local lo = `b' - 1.96*`se'
            local hi = `b' + 1.96*`se'
            quietly count if `rv' < `cut' & abs(`rv'-`cut')<=`h0'
            local n_l = r(N)
            quietly count if `rv' >= `cut' & abs(`rv'-`cut')<=`h0'
            local n_r = r(N)
            local dens_p = .
            capture {
                quietly bitesti `=`n_l'+`n_r'' `n_l' 0.5
                local dens_p = r(p)
            }
            preserve
            tempfile _fs3
            postfile _h3 str20 row double(coef se p ci_lo ci_hi) str26 report_use str12 bw_selector ///
                double(h) str12 kernel int p_order double(density_p) str80 note using "`_fs3'", replace
            post _h3 ("conventional") (`b') (`se') (`p') (`lo') (`hi') ///
                ("fallback_conventional") ("manual_h") (`h0') ("triangular") (1) (`dens_p') ///
                ("base Stata 回退；主报须 rdrobust 的 Robust 行")
            postclose _h3
            use "`_fs3'", clear
            export delimited using "`out'/tables/rdd_three_rows.csv", replace
            restore
            capture drop _rdpos _rdc _rdw
            di as result "  RD 回退：coef=" %6.4f `b' " se=" %6.4f `se' " 窗内左右=" `n_l' "/" `n_r'
        }
    }

    di as result "因果识别诊断完成：`out'/tables/{first_stage_five_f,bacon_decomp,rdd_three_rows}.csv；跳过项 `skips'"
end

* ---------------- Mata：多工具 effective F（Montiel Olea–Pflueger 迹公式） ----------------
capture mata: mata drop _causal_effF()
mata:
real scalar _causal_effF(string scalar Qname, string scalar bname, string scalar Vname, string scalar zlist, real scalar N) {
    real matrix Q, b, V, bz, Vz
    real scalar i, j, num, den
    string rowvector zn
    string matrix S
    Q  = st_matrix(Qname)      /* Z̃'Z̃（工具对控制变量残差化后） */
    b  = st_matrix(bname)
    V  = st_matrix(Vname)
    zn = tokens(zlist)
    S  = st_matrixcolstripe(bname)
    bz = J(cols(zn), 1, 0)
    for (i = 1; i <= cols(zn); i++) {
        for (j = 1; j <= cols(b); j++) {
            if (S[j, 2] == zn[i]) bz[i] = b[1, j]
        }
    }
    Vz = J(cols(zn), cols(zn), 0)
    for (i = 1; i <= cols(zn); i++) {
        for (j = 1; j <= cols(zn); j++) {
            Vz[i, j] = V[selectindex(S[., 2] :== zn[i]), selectindex(S[., 2] :== zn[j])]
        }
    }
    num = (bz' * Q * bz)[1, 1] / N
    den = trace(Vz * Q) / N
    if (den <= 0 | den == .) return(.)
    return(num / den)
}
end

causal_diag
