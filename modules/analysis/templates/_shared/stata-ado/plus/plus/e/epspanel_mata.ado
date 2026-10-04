*! version 6.0  2025-08-26
*! epspanel_mata.ado : 数据重塑和处理程序 (Mata实现, 宽表版)

capture program drop epspanel_mata
program define epspanel_mata
    version 14.0
    syntax , I(varname) T(varname) N(varname) V(varname) [DESCRIBE]

    mata: st_local("idx", "`i'")
    mata: st_local("t",   "`t'")
    mata: st_local("n",   "`n'")
    mata: st_local("v",   "`v'")
    mata: st_local("showdesc", cond("`describe'"=="", "0", "1"))

    mata: epspanel()
end

mata:

void epspanel()
{
    string scalar idx, t, n, v
    real scalar showdesc

    idx      = st_local("idx")
    t        = st_local("t")
    n        = st_local("n")
    v        = st_local("v")
    showdesc = strtoreal(st_local("showdesc"))

    /* ---- 取数据 ---- */
    string colvector id    = st_sdata(., idx)
    real   colvector time  = st_data(., t)
    string colvector name  = st_sdata(., n)
    real   colvector value = st_data(., v)
    real scalar N = rows(id)

    /* ---- 唯一 id ---- */
    string colvector uniqid = uniqrows(id)
    real scalar Nid = rows(uniqid)

    /* ---- 唯一组合 (指标+时间) ---- */
    string colvector combo = J(N,1,"")
    for (i=1; i<=N; i++) {
        combo[i] = name[i] + "_" + strofreal(time[i])
    }
    string colvector uniqcombo = uniqrows(combo)
    real scalar K = rows(uniqcombo)

    /* ---- 初始化宽表 ---- */
    real matrix W = J(Nid, K, .)

    /* ---- 填充 ---- */
    for (i=1; i<=N; i++) {
        string scalar idval = id[i]
        string scalar varnm = combo[i]

        real scalar idpos  = panelindex(idval, uniqid)
        real scalar varpos = panelindex(varnm, uniqcombo)

        if (idpos>0 & varpos>0) {
            W[idpos,varpos] = value[i]
        }
    }

    /* ---- 把结果导回 Stata ---- */
    st_addvar("str20", idx)
    st_store(., idx, uniqid)

    for (j=1; j<=K; j++) {
        /* 保证变量名合法：去掉小数点 */
        string scalar newv = subinstr(uniqcombo[j], ".", "", .)
        st_addvar("double", newv)
        st_store(., newv, W[.,j])
    }

    if (showdesc) {
        printf(">>> epspanel_mata 运行成功\n")
        printf("索引变量: %s, 时间变量: %s\n", idx, t)
        printf("指标变量: %s, 数值变量: %s\n", n, v)
        printf("生成新变量共 %g 个\n", K)
        describe()
    }
}

/* 工具函数：返回字符串在向量中的位置 */
real scalar panelindex(string scalar val, string colvector arr)
{
    for (i=1; i<=rows(arr); i++) {
        if (arr[i]==val) return(i)
    }
    return(0)
}

end
