* To test whether var is stability

capture program drop xtstable

program define xtstable
	version 17.0
	syntax varlist
	
foreach var in `varlist' {
    local variable "`var'"
	di _n _n "---`variable'---"
	qui xtsum `var'
	local n=r(n)
	local T=r(Tbar)
	while `T'<`n'{
		di _n "直接进行检验:"
		qui xtunitroot ht `var',tr
		local p=r(p)
		while `p'<0.05{
			local result "平稳"
			local p=0.05
		}
		while `p'>0.05{
			local result "非平稳"
			local p=0.05
		}
		di "同时加入个体固定效应与时间趋势,`result'"
		qui xtunitroot ht `var'
		local p=r(p)
		while `p'<0.05{
			local result "平稳"
			local p=0.05
		}
		while `p'>0.05{
			local result "非平稳"
			local p=0.05
		}
		di "只加入个体固定效应,`result'"
		qui xtunitroot ht `var',nocons
		local p=r(p)
		while `p'<0.05{
			local result "平稳"
			local p=0.05
		}
		while `p'>0.05{
			local result "非平稳"
			local p=0.05
		}
		di "无个体固定效应与时间趋势,`result'"
		di _n "将面板数据减去各截面单位的均值进行检验:"
		qui xtunitroot ht `var',tr demean
		local p=r(p)
		while `p'<0.05{
			local result "平稳"
			local p=0.05
		}
		while `p'>0.05{
			local result "非平稳"
			local p=0.05
		}
		di "同时加入个体固定效应与时间趋势,`result'"
		qui xtunitroot ht `var',demean
		local p=r(p)
		while `p'<0.05{
			local result "平稳"
			local p=0.05
		}
		while `p'>0.05{
			local result "非平稳"
			local p=0.05
		}
		di "只加入个体固定效应,`result'"
		qui xtunitroot ht `var',nocons demean
		local p=r(p)
		while `p'<0.05{
			local result "平稳"
			local p=0.05
		}
		while `p'>0.05{
			local result "非平稳"
			local p=0.05
		}
		di "无个体固定效应与时间趋势,`result'"
		local T=0
		local n=0
	} 
	while `T'>`n'{
		di "该面板为长面板,不适合HT检验"
		local T=0
		local n=0
	}
}

end