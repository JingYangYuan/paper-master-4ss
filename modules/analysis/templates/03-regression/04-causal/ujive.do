* ============================================================================
* Paper Analysis 4SS — UJIVE（undirected jackknife IV）执行层补丁
*
* 背景：宽严度设计（leniency design）的默认估计量是 UJIVE（留一法相对宽严度当工具），
*       它近似无偏、小 F 下不成问题。三语言生态里没有现成一步实现，本文件补这一块。
*
* 实现要点（单内生回归元、p_z ≥ 1 个工具）：
*   1) 把 y、d、Z 对控制变量 W（含常数）残差化：X̃ = X − W(W'W)⁻¹W'X
*   2) 首阶段 π̂ = (Z̃'Z̃)⁻¹Z̃'d̃，残差 ν̂ = d̃ − Z̃π̂，杠杆 H_ii = z̃_i'(Z̃'Z̃)⁻¹z̃_i
*   3) UJIVE 工具 ζ_i = d̃_i − ν̂_i/(1 − H_ii)   （= z̃_i'π̂_{−i}，留一法拟合值）
*   4) β_UJIVE = Σζ_i ỹ_i / Σζ_i d̃_i；稳健方差 = Σζ_i²ε̂_i² / (Σζ_i d̃_i)²
*
* 同时报告 2SLS、OLS 与 (经典) JIVE 作为对照，便于展示偏误方向与量级。
*
* 用法：
*   ujive yvar dvar ivvarlist [if] [, controls(varlist)]
*   例：ujive wage schooling (exp1 exp2 ... exp40), controls(age age2 region)
*   自检：ujive_selftest [, n(2000) k(40) reps(1)]
* ============================================================================

version 16
set more off

capture program drop ujive
program define ujive, rclass
    syntax varlist(min=3) [if] [, CONTROLS(varlist)]

    local yv : word 1 of `varlist'
    local dv : word 2 of `varlist'
    local zv ""
    local nw : word count `varlist'
    forvalues j = 3/`nw' {
        local zv "`zv' `: word `j' of `varlist''"
    }

    marksample touse
    quietly count if `touse'
    local nobs = r(N)

    * 变量名交给 Mata
    mata: st_local("yv_m", "`yv'")
    mata: st_local("dv_m", "`dv'")
    mata: st_local("zv_m", "`zv'")
    mata: st_local("cv_m", "`controls'")
    mata: st_local("tv_m", "`touse'")

    mata: _ujive_calc()

    return scalar b_ols   = _uj_b_ols
    return scalar se_ols  = _uj_se_ols
    return scalar b_2sls  = _uj_b_2sls
    return scalar se_2sls = _uj_se_2sls
    return scalar b_ujive = _uj_b_ujive
    return scalar se_ujive= _uj_se_ujive
    return scalar F_first = _uj_F_first
    return scalar hmax    = _uj_hmax
    return scalar kz      = _uj_kz

    di as text ""
    di as text "UJIVE / 2SLS / OLS 对照（N = " `nobs' "，工具数 = " r(kz) "）"
    di as text "{hline 64}"
    di as text "  OLS        b = " %9.5f r(b_ols) "   se = " %9.5f r(se_ols)
    di as text "  2SLS       b = " %9.5f r(b_2sls) "   se = " %9.5f r(se_2sls)
    di as text "  UJIVE      b = " %9.5f r(b_ujive) "   se = " %9.5f r(se_ujive) "   <-- 默认"
    di as text "{hline 64}"
    di as text "  首阶段 F（经典）= " %9.2f r(F_first) "   最大杠杆 = " %6.3f r(hmax)
    di as text "  提示：决策者宽严度设计中按分派层级定聚类、不按决策者聚类（见 leniency 协议步骤 1c）"
    di as text ""
end

* ---------------- Mata 核心 ----------------
capture mata: mata drop _ujive_calc()
mata:
void _ujive_calc() {
    string scalar yv, dv, zv, cv, tv
    real matrix Y, D, Z, W, Zt, Dt, Yt, ZZinv, pi, nu, H, zeta, eps
    real scalar n, kz, b2sls, bujive, se2sls, seujive, bols, seols
    real scalar s1, s2, F_first, hmax

    yv = st_local("yv_m"); dv = st_local("dv_m")
    zv = st_local("zv_m"); cv = st_local("cv_m"); tv = st_local("tv_m")

    Y = st_data(., yv, tv)
    D = st_data(., dv, tv)
    Z = st_data(., tokens(zv), tv)
    n = rows(Y); kz = cols(Z)

    if (cv != "") W = st_data(., tokens(cv), tv), J(n, 1, 1)
    else W = J(n, 1, 1)

    /* FWL：对控制变量残差化 */
    real matrix Wi
    Wi = invsym(W' * W)
    Yt = Y - W * Wi * (W' * Y)
    Dt = D - W * Wi * (W' * D)
    Zt = Z - W * Wi * (W' * Z)

    ZZinv = invsym(Zt' * Zt)
    pi = ZZinv * (Zt' * Dt)
    nu = Dt - Zt * pi
    H = rowsum((Zt * ZZinv) :* Zt)
    zeta = Dt - nu :/ (1 :- H)

    /* 估计量 */
    b2sls  = (Dt' * Zt * ZZinv * (Zt' * Yt)) / (Dt' * Zt * ZZinv * (Zt' * Dt))
    bujive = (zeta' * Yt) / (zeta' * Dt)
    /* OLS（含控制变量） */
    real matrix X
    X = W, D
    bols = (invsym(X' * X) * (X' * Y))[cols(X), 1]

    /* 稳健（HC1）标准误 */
    real matrix u2, uj, uo, V2, Vj, Vo, Xo, Xi
    u2 = Yt - b2sls * Dt
    se2sls = sqrt( _ujive_var_iv(Zt, Dt, u2, b2sls) )
    uj = Yt - bujive * Dt
    seujive = sqrt( (colsum((zeta :^ 2) :* (uj :^ 2)) / (zeta' * Dt)^2) * n/(n - kz - 1) )
    uo = Y - bols * D
    Xo = W, D
    Vo = invsym(Xo' * Xo) * ((Xo :* (uo :^ 2))' * Xo) * invsym(Xo' * Xo) * n/(n - cols(Xo))
    seols = sqrt(Vo[cols(Xo), cols(Xo)])

    /* 首阶段 F（经典） */
    real matrix rp
    rp = Dt - Zt * pi
    s2 = (rp' * rp) / (n - kz)
    F_first = (pi' * (Zt' * Zt) * pi) / (kz * s2)
    hmax = max(H)

    st_numscalar("_uj_b_ols", bols)
    st_numscalar("_uj_se_ols", seols)
    st_numscalar("_uj_b_2sls", b2sls)
    st_numscalar("_uj_se_2sls", se2sls)
    st_numscalar("_uj_b_ujive", bujive)
    st_numscalar("_uj_se_ujive", seujive)
    st_numscalar("_uj_F_first", F_first)
    st_numscalar("_uj_hmax", hmax)
    st_numscalar("_uj_kz", kz)
}

real scalar _ujive_var_iv(real matrix Zt, real matrix Dt, real matrix u, real scalar b) {
    real matrix ZZinv, dhat, V
    ZZinv = invsym(Zt' * Zt)
    dhat = Zt * ZZinv * (Zt' * Dt)
    V = (colsum((u :^ 2) :* (dhat :^ 2)) / (dhat' * dhat)^2) * rows(u)/(rows(u) - cols(Zt) - 1)
    return(V)
}
end

* ---------------- 自检：多工具下的偏误对照 ----------------
capture program drop ujive_selftest
program define ujive_selftest
    syntax [, N(integer 2000) K(integer 40) REPS(integer 1) TAU(real 1) SCALE(real 0.15) CONFound(real 0.7)]
    quietly {
        clear
        set obs `n'
        set seed 20261115
        gen double _u = rnormal()
        gen double _v = rnormal()
        gen double _c = rnormal()
        local zl ""
        forvalues j = 1/`k' {
            gen double _z`j' = rnormal() + 0.15*_v
            local zl "`zl' _z`j'"
        }
        * 单个工具的信号随 K 缩小（many-weak instruments）：总强度大致不变
        local a = `scale'/sqrt(`k')
        local zsum "0"
        forvalues j = 1/`k' {
            local zsum "`zsum' + `a'*_z`j'"
        }
        gen double _d = `zsum' + 0.7*_v + 0.3*_c
        gen double _y = `tau'*_d + `confound'*_v + 0.5*_c + _u
        quietly ujive _y _d `zl', controls(_c)
        noisily di as result "真值 tau = `tau'；OLS = " %6.4f r(b_ols) "；2SLS = " %6.4f r(b_2sls) ///
            "；UJIVE = " %6.4f r(b_ujive) "；首阶段 F = " %6.2f r(F_first)
        noisily di as text  "偏误：2SLS = " %6.4f (r(b_2sls)-`tau') "；UJIVE = " %6.4f (r(b_ujive)-`tau')
        noisily di as text  "（UJIVE 修正的是 many-instrument 偏误，不修正未观测混淆：confound 越大，两个 IV 都向 OLS 靠）"
    }
end
