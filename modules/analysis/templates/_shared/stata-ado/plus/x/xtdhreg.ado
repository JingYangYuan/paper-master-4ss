/* Engel Moffatt
xtdhreg
130919
rev 1: use constraint free, and drop check that uncorr and constraints may not be combined
	and drop respective paragraph from help file
rev 2: replace autoinstall of mdraws by error message	
rev 3: standardize presentation of Wald tests
*/



/***** prepare do-file

program drop _all  // note: does not work once saved as an ado-file
*/


***** define program: step 1

program xtdhreg

	version 11
	if replay() {
		if (`"`e(cmd)'"' != "xtdhreg") error 301
		Replay `0'
		}
	else	Estimate `0'
end	


***** define program

program Estimate, eclass sortpreserve

	**** syntax

	syntax varlist(fv) [if] [in], [hd(varlist) ptobit up trace difficult uncorr constraints(numlist)]
	gettoken depvar indep: varlist
	marksample touse

	
	**** check mdraws is installed
	// needed for estimation by simulation
	
	capt which mdraws
	if _rc == 111 {
		di in red "xtdhreg works with simulation, and needs package mdraws"
		di in red "mdraws is not preinstalled on your system"
		di in red "please first install it, e.g. using "findit mdraws" "
		}
	
	**** check consistency of options
	
	if "`ptobit'" != "" & "`hd'" !="" {
		di in red "ptobit and hd options may not be combined"
		exit(0)
		}
	if "`ptobit'" == "" & "`hd'" =="" {
		di in red "either the hd or the ptobit option must be chosen"
		exit(0)
		}


	**** drop previous auxiliary variables

	capt drop h1* 
	capt drop _i 
	capt drop _t 
	capt drop _first
	capt drop _last 
	capt drop _sum_y 
	capt drop _hrd
	capt drop _hdum
	capt drop _dum 
	capt drop _minsum 
	capt drop _maxsum
	capt drop _one
	capt drop _draws
	capt drop _merge


	**** generate auxiliary variables
	*** define panel
	
	di "{break}"
	di "{bf: define panel}{break}"

	xtset
	gen _i = `r(panelvar)'
	gen _t = `r(timevar)'


	*** define hurdle

	qui su `depvar'
	if `"`up'"' != "" {
		scalar _hrd = r(max)
		}
	else {	
		scalar _hrd = r(min)
		}


	*** generate identifiers for first and last observation per individual 

	qui su _t
	local tmin = r(min)
	local tmax = r(max)
	bysort _i: gen _first = (_t == `tmin')
	bysort _i: gen _last = (_t == `tmax')


	*** generate auxiliary variables for hurdle equation

	by _i: generate double _sum_y = sum(`depvar') 
	replace _sum_y = . if _last ~= 1
	by _i: replace _sum_y = _sum_y[_N]
	
	qui su _sum_y
	if `"`up'"' != "" {
		scalar _maxsum = r(max)
		}
	else {
		scalar _minsum = r(min)
		}

	
	*** generate dependent variable for hurdle equation	
		
	if `"`up'"' != "" {
		by _i: gen _dum = (_sum_y < _maxsum)
		}
	else {
		by _i: gen _dum = (_sum_y > _minsum)
		}


	**** prepare ptobit option
	
	if `"`ptobit'"' != "" {
		di "{break}"
		di "{bf: prepare ptobit option}{break}"
		gen _one = 1
		}
		
	
	**** prepare uncorr option
	
	if `"`uncorr'"' != "" {
		constraint free
		local constraint = r(free)
		di "{break}"	
		di "{bf: prepare estimation assuming error terms are uncorrelated}"
		di "{sf: option is implemented by constraining the estimator}{break}"
		constraint `constraint' [transformed_rho]_b[_cons] = 0
		}
		
	**** display all constraints
	
	di "{break}"
	di "{bf: list of currently defined constraints}{break}"	
	
	constraint dir
	

	**** generate Halton draws
	
	di "{break}"
	di "{bf: generate Halton draws}{break}"	

	mat p = [3]
	mdraws if _first == 1, neq(1) dr(32) prefix(h) primes(p)
	scalar _draws = r(n_draws)
	recast double h1*
	local hlist h1*

	quietly{
		foreach v of varlist `hlist' {
			by _i: replace `v' = `v'[1] if `v'==.
			replace `v' = invnorm(`v')
			}
		}


	**** generate starting values

	di "{break}"
	di "{bf: generate starting values}{break}"
	di "{bf: hurdle equation}{break}"
	
	if `"`ptobit'"' != "" {
		probit _dum _one if _last == 1 & `touse'
		}
	else {		
		probit _dum `hd' if _last == 1 & `touse'
		}
	mat bprobit = e(b)
	
	di "{break}"
	di "{bf: generate starting values}{break}"
	di "{bf: conditional on first hurdle passed}{break}"		

	if `"`up'"' != "" {
		xttobit `depvar' `indep' if _dum == 1 & `touse', ul(_hrd)   
		}
	else {	
		xttobit `depvar' `indep' if _dum == 1 & `touse', ll(_hrd)
		}
	mat bxttobit = e(b)

	mat start = bprobit, bxttobit, 0
	   	
	   
	**** call program 
	
	di "{break}"
	di "{bf: estimate double hurdle model}{break}"	
	  
	if `"`up'"' != "" {
		if `"`ptobit'"' != "" {
			if `"`uncorr'"' != "" {
				ml model d0 xtdhup (hurdle: _dum = _one) (below: `depvar'  =  `indep') ///
				(sigma_u: ) (sigma_e: ) (transformed_rho: ), constraints(`constraint' `constraints')
				}
			else {
				ml model d0 xtdhup (hurdle: _dum = _one) (below: `depvar'  =  `indep') ///
				(sigma_u: ) (sigma_e: ) (transformed_rho: ), constraints(`constraints')
				}
			}
		else {
			if `"`uncorr'"' != "" {
				ml model d0 xtdhup (hurdle: _dum = `hd') (below: `depvar'  =  `indep') ///
				(sigma_u: ) (sigma_e: ) (transformed_rho: ), constraints(`constraint' `constraints')
				}
			else {	
				ml model d0 xtdhup (hurdle: _dum = `hd') (below: `depvar'  =  `indep') ///
				(sigma_u: ) (sigma_e: ) (transformed_rho: ), constraints(`constraints')
				}
			}
		}
	else {
		if `"`ptobit'"' != "" {
			if `"`uncorr'"' != "" {
				ml model d0 xtdh (hurdle: _dum = _one) (above: `depvar'  =  `indep')  ///
				(sigma_u: ) (sigma_e: ) (transformed_rho: ), constraints(`constraint' `constraints')
				}
			else {
				ml model d0 xtdh (hurdle: _dum = _one) (above: `depvar'  =  `indep')  ///
				(sigma_u: ) (sigma_e: ) (transformed_rho: ), constraints(`constraints')
				}
			}
		else {
			if `"`uncorr'"' != "" {	
				ml model d0 xtdh (hurdle: _dum = `hd') (above: `depvar'  =  `indep')  ///
				(sigma_u: ) (sigma_e: ) (transformed_rho: ), constraints(`constraint' `constraints')
				}
			else {
				ml model d0 xtdh (hurdle: _dum = `hd') (above: `depvar'  =  `indep')  ///
				(sigma_u: ) (sigma_e: ) (transformed_rho: ), constraints(`constraints')
				}
			}
		}
	
	ml init start, copy
	ml max, `trace' `difficult' search(norescale)

	
	**** generate rho from transformed rho
	
	di "{break}"
	di "{bf: generate estimate of correlation in error terms, with confidence interval}{break}"
	nlcom rho: tanh([transformed_rho]_cons)
	
		
	**** generalize Wald tests

	di "{break}"
	di "{bf: separate Wald tests for joint significance of all explanatory variables}{break}"
	di "{bf: note}{break}"
	di "{sf: if you use factor variables, i.e. the i., c., # and ## notation, you must run}"
	di "{sf: the Wald test by hand. For detail see help file}"
	di "{break}"
	di "{bf: estimates of joint significance}"
	di "{break}"

	
	if `"`ptobit'"' != "" {
		di "{break}"
		di "{with ptobit option, hurdle equation has no explanatory variables}{break}"
		
		if `"`up'"' != "" {
			qui test [below] `indep'
			di "chi square below equation = " r(chi2)
			di "p below equation = " r(p)
			}
		else {
			qui test [above] `indep'
			di "chi square above equation = " r(chi2)
			di "p above equation = " r(p)			
			}
		}	
	else {
		if `"`up'"' != "" {
			qui test [hurdle] `hd'
			di "chi square hurdle equation = " r(chi2)
			di "p hurdle equation = " r(p)
			qui test [below] `indep'
			di "chi square below equation = " r(chi2)
			di "p below equation = " r(p)
			qui test ([hurdle] `hd') ([below] `indep')
			di "chi square overall = " r(chi2)
			di "p overall = " r(p)
			}
		else {
			qui test [hurdle] `hd'
			di "chi square hurdle equation = " r(chi2)
			di "p hurdle equation = " r(p)			
			qui test [above] `indep'
			di "chi square above equation = " r(chi2)
			di "p above equation = " r(p)			
			qui test ([hurdle] `hd') ([above] `indep')
			di "chi square overall = " r(chi2)
			di "p overall = " r(p)			
			}
		}	

	

	***** drop auxiliary variables

	capt drop h1* 
	capt drop _i 
	capt drop _t 
	capt drop _first
	capt drop _last 
	capt drop _sum_y
	capt drop _hrd 
	capt drop _hdum
	capt drop _dum 
	capt drop _minsum 
	capt drop _maxsum
	capt drop _one
	capt drop _draws
	
	capt constraint drop _all
	
	
	***** make estimates available

	ereturn local cmd "xtdhreg"

end


***** enable replay

program Replay
	syntax
	ml display
end	
