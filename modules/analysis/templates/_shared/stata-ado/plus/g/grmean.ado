prog def grmean
*! Version 1.6 Peter Sasieni 3 Aug 2011
version 9
syntax varlist(numeric) [if] [in] [, STandard(varname) by(string) over(string) ///
			noMean addplot(string) *]
tempvar touse
mark `touse' `if' `in'
tokenize `varlist'
local rate `1'
macro shift
local i=0
while "`1'"!="" {
	local i=`i'+1
	local prate`i' `1'
	macro shift
	tempvar s_pr`i'
}
local xvar `prate`i''
local Np=`i'-1

quietly {
tempvar gp
if "`over'"!="" {
	_getbyvar `over'
	local overvar = r(var)
	local overtotal = r(total)
	local error=word("`overvar'",2)
	if "`error'"!= "" {
		di as error "Only one variable allowed in over()"
		exit
	}

	egen `gp'=group(`overvar') if `touse'
	sum 	`gp' ,mean
	local ngp=r(max)
	local OVER : val lab `overvar'
	local OVER=cond("`OVER'"!="","`OVER'","`overvar'")
}
else {
	gen byte `gp'=1
	local ngp=1
}
if `ngp' >15 {
	noi di as error "Too many values of `overvar' in over()"
	exit
}
if "`standard'"=="" {
	tempvar standard
	gen byte `standard'=1
}
if "`by'" !="" {
	nois _getbyvar `by'
	local byvar = r(var)
} 

	tempvar s_r gruse
	if "`mean'"==""  qui bysort `touse' `byvar' `xvar' `gp': gen byte `gruse' = (_n==1 & `touse')
	else qui gen byte `gruse' = `touse'
	if "`mean'"=="" strate `rate' `standard' if `touse' ,by(`byvar' `xvar' `gp') gen(`s_r')
	else local s_r "`rate'"
	local s_pr_list ""
	forval j=1/`Np' {
		if "`mean'"==""  strate `prate`j'' `standard' if `touse' ,by(`byvar' `xvar' `gp') gen(`s_pr`j'')
		else local s_pr`j' "`prate`j''"
		local s_pr_list "`s_pr_list' `s_pr`j''"
	}


local lplist "l dash dot longdash dash_dot"
forval i=1/`ngp'  {
	local plot "`plot' (scatter `s_r' `xvar' if `gp'==`i',msty(p`i'))"
	local plist ""
	forval j=1/`Np' {
		local plist "`plist' p`i'"
	}
	if `Np'>0 local plot "`plot' (line `s_pr_list' `xvar' if `gp'==`i',lsty(`plist') lpat(`lplist') sort)"
	if "`over'"!="" {
		qui sum `overvar' if `gp'==`i' & `touse',mean
		local ival =r(mean)
		local overi : lab `OVER' `ival'
		local jj =(`Np'+1)*(`i'-1)+1
		local order `"`order' `jj' `"`overvar': `overi'"' "'
	}
	local i = `i'+1
}
}
if "`by'"!="" local by "by(`by')"

if "`overtotal'"=="total" {
	tempvar s_rt gruset
	qui bysort `touse' `byvar' `xvar' (`gp'): gen byte `gruset' = (_n==1 & `touse' &`gp'<.)
	if "`mean'"==""  strate `rate' `standard' if `touse' & `gp'<. ,by(`byvar' `xvar') gen(`s_rt')
	else local s_rt "`rate'"
	local s_prt_list ""
	local clist ""
	forval j=1/`Np' {
		tempvar s_prt`j'
		if "`mean'"==""  strate `prate`j'' `standard' if `touse' & `gp'<.,by(`byvar' `xvar') gen(`s_prt`j'')
		else local s_prt`j' "`prate`j''"
		local s_prt_list "`s_prt_list' `s_prt`j''"
		local clist "`clist' black"
	}
	local plot "`plot' (scatter `s_rt' `xvar' if `gp'<.,mcol(black))"
	if `Np'>0 local plot "`plot' (line `s_prt_list' `xvar' if `gp'<.,lcol(`clist') lpat(`lplist') sort)"
}

twoway `plot' if `gruse' ||  `addplot' , ///
		`by' legend(col(2) order(`order') textfirst) `options'  

end

prog def _getbyvar,rclass
	version 9
	syntax varlist [, Total *]
	return local var "`varlist'"
	return local total "`total'"
end 

prog def strate
	version 9
	syntax varlist [if] [,by(varlist) gen(name)]
	marksample touse
	tokenize `varlist'
	local rate `1'
	local wt `2'
	local name: var lab `rate'
	if "`name'"=="" {
		local name "`rate'"
	}
	sort `touse' `by' 
	qui by `touse' `by': gen `gen'=sum(`rate'*`wt')/sum(`wt') if `touse' 
	qui by `touse' `by': replace `gen'= `gen'[_N ]
	lab var `gen' "`name'"
end

