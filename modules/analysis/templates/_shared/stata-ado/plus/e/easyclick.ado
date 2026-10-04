//One-click cross-section data analysis

capture program drop easyclick
program define easyclick
    version 17.0

* 解析输入
	syntax varlist(min=1), save(string)
	local y : word 1 of `varlist'
	foreach var in `varlist'{
		if "`var'" != "`y'"{
			local x `x' `var'
		}
	}

di ""	
di in red "表格汇总路径如下："
qui efolder, cd(`save'easyclick)
cd `save'easyclick

local files : dir . files "*.doc"
foreach f of local files {
    erase "`f'"
	}


	
local cunzhao=1
while `cunzhao'==1{
	di in white _n _n "一、描述数据"
	asdoc su `y' `x', save(sum.doc) replace

	di in white _n _n "二、相关性分析"
	asdoc pwcorr `y' `x', save(pwcorr_nostar.doc) replace
	asdoc pwcorr_a `y' `x', save(pwcorr_star.doc) replace
	
	di in white _n _n "三、OLS基准回归"
	di in white _n "(一)有常数项回归"
	reg `y' `x'
	mat result=r(table)
	estimates store OLS
	di in white "① 模型的拟合优度为" e(r2)
	di in white "② 模型的调整的判定系数为" e(r2_a)
	foreach var in `x' _cons{
		local beta=el(result,1,colnumb(result,"`var'"))
		local p=el(result,4,colnumb(result,"`var'"))
		while `p' < 0.05{
			local result "显著"
			local p=0.05
		}
		while `p' > 0.05{
			local result "不显著"
			local p=0.05
		}
		di in white "`var'的回归系数为" `beta' "，`result'"
	}
	di in white _n "(二)无常数项回归"
	reg `y' `x',nocons
	estimates store OLS_noc
	di in white "① 模型的拟合优度为" e(r2)
	di in white "② 模型的调整的判定系数为" e(r2_a)
	mat result=r(table)
	foreach var in `x'{
		local beta=el(result,1,colnumb(result,"`var'"))
		local p=el(result,4,colnumb(result,"`var'"))
		while `p' < 0.05{
			local result "显著"
			local p=0.05
		}
		while `p' > 0.05{
			local result "不显著"
			local p=0.05
		}
		di in white " `var'的回归系数为" `beta' "，`result'"
	}
	di in white _n _n "四、计算VIF值"
	di ""
	di in white "(一)有常数项的OLS回归:"
	qui reg `y' `x'
	asdoc vif, save(vif_cons.doc) replace
	di ""
	di in white "(二)无常数项的OLS回归:"
	qui reg `y' `x', nocons
	asdoc estat vif, unc save(vif_nocons.doc) replace


	di in white _n _n "五、RESET检验"
	
* 1、使用被解释变量拟合值的高次项检验

	qui reg `y' `x'
	qui estat ovtest
	local p=r(p)
	while `p'<0.05{
		local result "有高次项遗漏"
		local p=0.05
	}
	while `p'>0.05{
		local result "无高次项遗漏"
		local p=0.05
	}
	di ""
	di in white "1、使用被解释变量拟合值的高次项检验，认为`result'"
	asdoc estat ovtest, save(reset1.doc) replace
	di ""
	
* 2、使用解释变量的高次项检验

	qui reg `y' `x'
	qui estat ovtest,rhs
	local p=r(p)
	while `p'<0.05{
		local result "有高次项遗漏"
		local p=0.05
	}
	while `p'>0.05{
		local result "无高次项遗漏"
		local p=0.05
	}
	di in white "2、使用解释变量的高次项检验，认为`result'"
	asdoc estat ovtest, rhs save(reset2.doc) replace
	di ""
	
	di in white _n _n "六、信息准则"
	
* 1、有常数项的OLS回归

	qui reg `y' `x'
	qui estat ic
	mat S=r(S)
	local aic=el(S,1,5)
	local bic=el(S,1,6)
	di ""
	di in white "1、有常数项的OLS回归：AIC=" `aic' ",BIC=" `bic'
	asdoc estat ic, save(ig1.doc) replace
	di ""
	
* 2、无常数项的OLS回归

	qui reg `y' `x',nocons
	qui estat ic
	mat S=r(S)
	local aic=el(S,1,5)
	local bic=el(S,1,6)
	di in white "2、无常数项的OLS回归：AIC=" `aic' ",BIC=" `bic'
	asdoc estat ic, save(ig2.doc) replace
	di ""

	di in white _n _n "七、观测数据的影响力"
	
	qui reg `y' `x'
	predict lev1,lev
	qui su lev1
	di ""
	di in white "1、有常数项的OLS回归：lev最大值是其平均值的" r(max)/r(mean) "倍"
	qui drop lev1
	di ""
	qui reg `y' `x',nocons
	predict lev2,lev
	qui su lev2
	di in white "2、无常数项的OLS回归：lev最大值是其平均值的" r(max)/r(mean) "倍"
	qui drop lev2
	
	di in white _n _n "八、异方差检验"
	qui reg `y' `x'
	qui estat hettest,iid
	local p=r(p)
	while `p'<0.05{
		local result "存在异方差"
		local yfc=1
		local p=0.05
	}
	while `p'>0.05{
		local result "不存在异方差"
		local yfc=0
		local p=0.05
	}
	di ""
	di in white "1、使用被解释变量的拟合值进行BP检验，`result'"
	asdoc estat hettest, iid save(bp1.doc) replace

	qui estat hettest,iid rhs
	local p=r(p)
	while `p'<0.05{
		local result "存在异方差"
		local yfc=1
		local p=0.05
	}
	while `p'>0.05{
		local result "不存在异方差"
		local yfc=0
		local p=0.05
	}
	di ""
	di in white "2、使用所有解释变量进行BP检验，`result'"
	asdoc estat hettest,iid rhs save(bp2.doc) replace
	di ""

	
	qui estat imtest,white
	while `p'<0.05{
		local result "存在异方差"
		local yfc=1
		local p=0.05
	}
	while `p'>0.05{
		local result "不存在异方差"
		local yfc=0
		local p=0.05
	}
	di ""
	di in white "3、对有常数项回归进行怀特检验，`result'"
	asdoc estat imtest, white save(ht1.doc) replace
	di ""

	
	qui reg `y' `x',nocons
	qui estat imtest,white
	while `p'<0.05{
		local result "存在异方差"
		local yfc=1
		local p=0.05
	}
	while `p'>0.05{
		local result "不存在异方差"
		local yfc=0
		local p=0.05
	}
	di ""
	di in white "4、对无常数项回归进行怀特检验，`result'"
	qui reg `y' `x',nocons
	asdoc estat imtest, white save(ht2.doc) replace
	di ""

	local yfc2=0
	
	while `yfc'==1{
		di in white _n _n "九、对异方差的处理"
		di ""
		di in white _n "(一)异方差稳健标准误回归"
		di ""
		di in white "1.有常数项、稳健标准误回归："
		di ""
		reg `y' `x',r
		estimates store Robust
		di in white "① 模型的拟合优度为" e(r2)
	di in white "② 模型的调整的判定系数为" e(r2_a)
	mat result=r(table)
	foreach var in `x'{
		local beta=el(result,1,colnumb(result,"`var'"))
		local p=el(result,4,colnumb(result,"`var'"))
		while `p' < 0.05{
			local result "显著"
			local p=0.05
		}
		while `p' > 0.05{
			local result "不显著"
			local p=0.05
		}
		di in white "③ `var'的回归系数为" `beta' "，`result'"
	}
		di ""
		di in white "2.无常数项、稳健标准误回归："
		di ""
		reg `y' `x',r nocons
		estimates store Robust_noc
		di in white "① 模型的拟合优度为" e(r2)
	di in white "② 模型的调整的判定系数为" e(r2_a)
	mat result=r(table)
	foreach var in `x'{
		local beta=el(result,1,colnumb(result,"`var'"))
		local p=el(result,4,colnumb(result,"`var'"))
		while `p' < 0.05{
			local result "显著"
			local p=0.05
		}
		while `p' > 0.05{
			local result "不显著"
			local p=0.05
		}
		di in white "③ `var'的回归系数为" `beta' "，`result'"
	}
		di in white _n "(二)FWLS回归"
		di ""
		di in white "1.有常数项FWLS回归："
		di ""
		qui reg `y' `x'
		local r2_con=e(r2)
		qui reg `y' `x',nocons
		local r2_noc=e(r2)
		while `r2_con'>`r2_noc'{
			qui reg `y' `x'
			predict e1,r
			g e2=e1^2
			g lne2=ln(e2)
			local r2_con=0
			local r2_noc=0
		}
		while `r2_con'<`r2_noc'{
			qui reg `y' `x',nocons
			predict e1,r
			g e2=e1^2
			g lne2=ln(e2)
			local r2_con=0
			local r2_noc=0
		}
		qui reg lne2 `x'
		local r2_con=e(r2)
		qui reg lne2 `x',nocons
		local r2_noc=e(r2)
		while `r2_con'>`r2_noc'{
			qui reg lne2 `x'
			predict lne2f
			g e2f=exp(lne2f)
			local r2_con=0
			local r2_noc=0
		}
		while `r2_con'<`r2_noc'{
			qui reg lne2 `x',nocons
			predict lne2f
			g e2f=exp(lne2f)
			local r2_con=0
			local r2_noc=0
		}
		reg `y' `x' [aw=1/e2f]
		estimates store FWLS
		di in white "① 模型的拟合优度为" e(r2)
	di in white "② 模型的调整的判定系数为" e(r2_a)
	mat result=r(table)
	foreach var in `x'{
		local beta=el(result,1,colnumb(result,"`var'"))
		local p=el(result,4,colnumb(result,"`var'"))
		while `p' < 0.05{
			local result "显著"
			local p=0.05
		}
		while `p' > 0.05{
			local result "不显著"
			local p=0.05
		}
		di in white "③ `var'的回归系数为" `beta' "，`result'"
	}
		foreach var in e1 e2 lne2 lne2f e2f{
			drop `var'
		}
		di ""
		di in white "2.无常数项FWLS回归："
		di ""
		qui reg `y' `x'
		local r2_con=e(r2)
		qui reg `y' `x',nocons
		local r2_noc=e(r2)
		while `r2_con'>`r2_noc'{
			qui reg `y' `x'
			predict e1,r
			g e2=e1^2
			g lne2=ln(e2)
			local r2_con=0
			local r2_noc=0
		}
		while `r2_con'<`r2_noc'{
			qui reg `y' `x',nocons
			predict e1,r
			g e2=e1^2
			g lne2=ln(e2)
			local r2_con=0
			local r2_noc=0
		}
		qui reg lne2 `x'
		local r2_con=e(r2)
		qui reg lne2 `x',nocons
		local r2_noc=e(r2)
		while `r2_con'>`r2_noc'{
			qui reg lne2 `x'
			predict lne2f
			g e2f=exp(lne2f)
			local r2_con=0
			local r2_noc=0
		}
		while `r2_con'<`r2_noc'{
			qui reg lne2 `x',nocons
			predict lne2f
			g e2f=exp(lne2f)
			local r2_con=0
			local r2_noc=0
		}
		reg `y' `x' [aw=1/e2f],nocons
		estimates store FWLS_noc
		di in white "① 模型的拟合优度为" e(r2)
	di in white "② 模型的调整的判定系数为" e(r2_a)
	mat result=r(table)
	foreach var in `x'{
		local beta=el(result,1,colnumb(result,"`var'"))
		local p=el(result,4,colnumb(result,"`var'"))
		while `p' < 0.05{
			local result "显著"
			local p=0.05
		}
		while `p' > 0.05{
			local result "不显著"
			local p=0.05
		}
		di in white "③ `var'的回归系数为" `beta' "，`result'"
	}
		
		local yfc=0
		local yfc2=1
	}
	
	while `yfc2'==0{
		di in white _n _n "九、结果汇总"
		esttab OLS OLS_noc, r2 ar2 b 
		outreg2 [OLS OLS_noc] using summary.doc, title("Regress Output") replace
		capture qui drop _est_OLS _est_OLS_noc
		local yfc2=2
	}
	while `yfc2'==1{
		di in white _n _n "十、结果汇总"
		esttab OLS OLS_noc Robust Robust_noc FWLS FWLS_noc, r2 ar2 b se mtitle
		outreg2 [OLS OLS_noc Robust Robust_noc FWLS FWLS_noc] using summary.doc, title("Regress Output") replace
		foreach var in e1 e2 lne2 lne2f e2f{
			drop `var'
		}
		capture qui drop _est_OLS_noc _est_Robust _est_Robust_noc _est_FWLS _est_FWLS_noc _est_OLS
		local yfc2=2
	}
	local cunzhao=2
	
}
dis in red "完毕！"
end