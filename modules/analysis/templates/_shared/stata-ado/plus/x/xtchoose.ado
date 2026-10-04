* To choose which model is best from FE, POOL and RE

capture program drop xtchoose

program define xtchoose
	version 17.0
	syntax varlist
	
	local model `varlist'
	
local z=1

while `z'==1 {
	qui xtreg `model',fe
	estimates store FE
	local p_f=e(p_f)
	while `p_f'<0.05{
		local result "FE is better than POOL"
		local p_f=0.05
	}
	while `p_f'>0.05{
		local result "POOL is better than FE"
		local p_f=0.05
	}
	di ""
	di "F test: `result'"
	qui xtreg `model',re r theta
	qui xttest0
	local p=r(p)
	while `p'<0.05{
		local result "RE is better than POOL"
		local p=0.05
	}
	while `p'>0.05{
		local result "FE is better than POOL"
		local p=0.05
	}
	di ""
	di "Breusch-Pagan test: `result'"
	qui xtreg `model',re
	estimates store RE
	qui hausman FE RE,c sig
	local p=r(p)
	while `p'<0.05{
		local result "FE is better than RE"
		local p=0.05
	}
	while `p'>0.05{
		local result "RE is better than FE"
		local p=0.05
	}
	local z=0
	qui drop _est_FE _est_RE
	}
	di ""
	di "Traditional Hausman test: `result'"
	di ""
	di "Robust Hausman test:"
	di ""
	di in red "	由于稳健的豪斯曼检验命令xtoverid中没有自动判别功能，需自行查看结果：P值拒绝原假设就是FE优于RE，否则就是RE优于FE。"
	di in red "	Since there is no automatic discrimination function in the robust Hausmann test command xtoverid, you need to check the results by yourself: the P-value rejects the original hypothesis is that FE outperforms RE, otherwise it is that RE outperforms FE."
	di ""

qui xtreg `model'
xtoverid

end