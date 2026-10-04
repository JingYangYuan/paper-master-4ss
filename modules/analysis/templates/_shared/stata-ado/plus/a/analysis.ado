* 定义 ado 程序
program define analysis, rclass
    version 16.0
	
    * 检查是否已经运行过回归
    if missing("`e(cmd)'") {
        di as error "Error: This command requires a previous regression."
        exit 301
    }

    * 获取用户输入的核心解释变量、控制变量和显著性水平

	syntax  varlist(min=1 fv ts),			    	///
			pvalue(real)							///
			core(varlist fv ts)

    * 检查显著性水平的范围
    if `pvalue' <= 0 | `pvalue' >= 1 {
        di as error "Error: Significance level must be between 0 and 1."
        exit 198
    }

    * 提取被解释变量（因变量）
    local depvar = e(depvar)
    return local depvar `depvar'

    * 核心变量和控制变量
    local core `core'
    local controlvars `varlist'

    * 检查核心变量和控制变量是否存在重复
    foreach var of local core {
        if ":list var in controlvars" {
            di as error "Error: Variable '`var'' is specified as both a core variable and a control variable."
            exit 198
        }
    }

    * 根据回归类型提取相关统计量
    local cmd = e(cmd)
    if "`cmd'" == "regress" | "`cmd'" == "reghdfe" {
        * 线性回归：提取调整后的 R^2
        local adj_r2 = e(r2_a)
        return scalar adj_r2 = `adj_r2'
    }
    else if "`cmd'" == "xtreg" {
        * 面板回归：提取 R^2 或其他相关统计量
        if "`e(model)'" == "fe" | "`e(model)'" == "re" {
            local r2 = e(r2)
            return scalar r2 = `r2'
        }
        else {
            di as error "Error: Unsupported xtreg model type (`e(model)')."
            exit 198
        }
    }
    else if "`cmd'" == "probit" | "`cmd'" == "logit" {
        * 非线性回归：提取伪 R^2
        local pseudo_r2 = e(r2_p)
        return scalar pseudo_r2 = `pseudo_r2'
    }
    else {
        di as error "Error: Unsupported regression command (`cmd')."
        exit 198
    }

    * 初始化显著变量计数器
    local sig_count = 0

    * 遍历核心变量并提取其参数估计值、标准误、t 值、p 值和显著性
    foreach var of local core {
        * 获取该变量的系数
        local coef = _b[`var']

        * 获取该变量的标准误
        local se = _se[`var']

        * 获取该变量的 t 值或 z 值
        local stat = cond("`cmd'" == "probit" | "`cmd'" == "logit", _b[`var'] / _se[`var'], _b[`var'] / _se[`var'])

        * 获取该变量的 p 值
        local pval = el(r(table), 4, colnumb(r(table), "`var'"))

        * 判断是否显著
        local sig = cond(`pval' < `pvalue', "*", "")

        * 返回核心变量的结果
        local scalar coef_`var' = `coef'
        local scalar se_`var' = `se'
        local scalar stat_`var' = `stat'
        local scalar pval_`var' = `pval'
        local local sig_`var' = "`sig'"
    }

    * 遍历控制变量并计算显著的个数
    foreach var of local controlvars {
        * 获取该变量的 p 值
        local pval = el(r(table), 4, colnumb(r(table), "`var'"))

        * 如果 p 值小于显著性水平，则认为是显著的
        if `pval' < `pvalue' {
            local sig_count = `sig_count' + 1
        }
    }

    * 返回显著控制变量的个数
    return scalar sig_count = `sig_count'

    * 输出结果到屏幕
    di _n "Analysis Results:"
    di "Dependent Variable: `depvar'"
    di "Core Independent Variables: `core'"
    di "Control Variables: `controlvars'"
    if "`cmd'" == "regress" | "`cmd'" == "reghdfe" {
        di "Adjusted R-squared: `adj_r2'"
    }
    else if "`cmd'" == "xtreg" {
        di "R-squared: `r2'"
    }
    else if "`cmd'" == "probit" | "`cmd'" == "logit" {
        di "Pseudo R-squared: `pseudo_r2'"
    }
    di "Significance Level: `pvalue'"

    * 输出核心变量的详细信息
    foreach var of local core {
        di "Variable `var': Coefficient = `coef', Std. Err. = `se', Statistic = `stat', p-value = `pval'`sig'"
    }

    * 输出显著控制变量的个数
    di "Number of Significant Control Variables (p < `pvalue'): `sig_count'"
end