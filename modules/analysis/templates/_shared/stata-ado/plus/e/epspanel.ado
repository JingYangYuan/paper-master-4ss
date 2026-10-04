*! version 1.0  2025-08-21
*! epspanel.ado : 数据重塑和处理程序

capture program drop epspanel
program define epspanel
    version 14.0
    syntax , I(varname) T(varname) N(varname) V(varname) [DESCRIBE]
	local index `i'
	local time  `t'
	local name  `n'
	local value `v'
	qui rename (`index' `time' `name' `value') (索引 时间 指标 数值)
	
	local new_vars ""
	forvalues i = 1/`= _N' {
		local current_indicator = 指标[`i']
		local current_time = 时间[`i']
		local new_varname = "`current_indicator'_`current_time'"
		if !missing("`new_varname'") {
			if "`new_vars'" != "" {
				local new_vars "`new_vars' `new_varname'"
			}
			else {
				local new_vars "`new_varname'"
			}
			capture confirm variable `new_varname'
			if _rc {
				qui generate `new_varname' = .
			}
			qui replace `new_varname' = 数值[`i'] in `i'
		}
	}

	qui collapse (max) *_*, by(索引)

	preserve
	qui drop 索引
	local var_prefixes
	foreach var of varlist * {
		local underscore_pos = strpos("`var'", "_")
		local prefix = substr("`var'", 1, `underscore_pos')
		if `: list prefix in var_prefixes' == 0 {
			local var_prefixes "`var_prefixes' `prefix'"
		}
	}

	restore

	qui reshape long `var_prefixes', i(索引) j(时刻)

	local var_prefixes ""
	foreach var of varlist * {
		if strpos("`var'", "_") > 0 {
			local new_var = subinstr("`var'", "_", "", .)
			qui rename `var' `new_var'
			if `: list prefix in varlist' == 0 {
				local varlist "`varlist' `new_var'"
			}
		}
	}
	qui rename (索引 时刻) (`index' `time')
	display as result "生成新变量：`varlist'"
    display as result "数据处理完成！"

    if "`describe'" != "" {
        display ""
        display as result "最终数据结构："
        describe
    }
end
