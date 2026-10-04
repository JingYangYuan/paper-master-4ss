*! version 1.1 Peter Sasieni 23 Aug 2010
prog def apcspline_p, eclass
version 9
syntax newvarname [if] [in] [,Age PERiod COHort Year IR RAte(real 1) *]

if "`options'"!="" & "`ir'"!="" {
	no di as err "Option ir not allowed with other options"
	exit
}
if "`age'`period'`cohort'`year'"=="" {
	if e(linkt)=="Log" {
		local com_p "poisso_p"
	} 
	else {
		local com_p "glim_p"
	}
	if "`ir'" !="" local myqui "quietly"
	`myqui' `com_p' `varlist' `if' `in', `options' 
	if "`options'`ir'"== "" | "`options'"=="mu" {
		qui replace `varlist'=max(0,`varlist'-_Ibackground)
	}
	if "`ir'"!="" {
		qui replace `varlist'=`rate'*max(0,`varlist'-_Ibackground)/`e(population)'
		noi di as text "(predicted rate _Icases/`e(population)')"
		lab var `varlist' "predicted rate (per `rate')"
	}
}
else {
	if e(linkt)!="Log" {
		tempname B B1
		matrix `B'=e(b)
		matrix `B1'=e(b1)
		ereturn repost b = `B1'
	}
	if "`age'"!="" {
		tempvar fit
		qui gen double `fit'=_b[_cons]
		foreach var of varlist `e(A)' {
			capture qui replace `fit'=`fit'+_b[`var']*`var'
		}
		gen `varlist'=exp(`fit')*`rate'
		local if `rate'!=1 local ratestr "per `rate' "
		lab var `varlist' "Rate `ratestr' as a function of age"
	}
	if "`period'`year'"!="" {
		tempvar fit
		qui gen double `fit'=0
		foreach var of varlist `e(P)' {
			capture qui replace `fit'=`fit'+_b[`var']*`var'
		}
		gen `varlist'=exp(`fit')
		lab var `varlist' "Relative risk as a function of period"
	}
	if "`cohort'"!="" {
		tempvar fit
		qui gen double `fit'=0
		foreach var of varlist `e(C)' {
			capture qui replace `fit'=`fit'+_b[`var']*`var'
		}
		gen `varlist'=exp(`fit')
		lab var `varlist' "Relative risk as a function of cohort"
	}
		if e(linkt)!="Log" ereturn repost b = `B'
}

end
