/*dhreg
program to estimate a double hurdle model
Christoph Engel and Peter Moffatt
rev 1: standardize output
rev 2: standardize overall statistics
131102 */


version 11
program drop _all

***** define program step 1

program dhreg 

	version 11
	if replay() {
		if (`"`e(cmd)'"' != "dhreg") error 301
		Replay `0'
		}
	else	Estimate `0'
end	


***** define program step 2

program Estimate, eclass sortpreserve
	
	syntax varlist(fv) [if] [in] [, up ptobit hd(varlist) millr]
	gettoken depvar indep: varlist
	marksample touse
	markout `touse'

	**** drop earlier auxiliary variables

	capt scalar drop _depmin
	capt scalar drop _depmax
	capt drop _mill

	
	*** checking whether boundary conditions are fulfilled

	if "`ptobit'" != "" & "`hd'" !="" {
		error 184
		}
		
	else{

	**** case of lower hurdle	
	if "`up'" == "" {
		qui su `depvar'
		tempvar dum // this generates the hurdle
		gen `dum' = (`depvar' > r(min))
		scalar _depmin = r(min) // allow for arbitrary hurdles	
		local depmin = _depmin


		*** generating starting values
		** for hurdle
		* if ptobit is specified (= intercept only)

		if "`ptobit'" !="" {
		di "{bf: starting values for hurdle}{break}"
		probit `dum' if `touse'
		mat bprobit=e(b)
		}

		* if hurdle has different indepvars

		else {
			if "`hd'" != "" {
			di "{bf: starting values for hurdle}{break}"
			probit `dum' `hd' if `touse'
			mat bprobit=e(b)
			}
			
		* if hurdle and above have the same set of indepvars
			
		else {
			di "{bf: starting values for hurdle}{break}"
			probit `dum' `indep' if `touse'
			mat bprobit=e(b)
			}
		}

		** tobit for amount contributed:

		di "{bf: starting values conditional on hurdle being passed}{break}"
		tobit `depvar' `indep' if `touse', ll(`depmin')
		mat btobit=e(b)


		*** ML estimation of double hurdle model

		di "{it: estimation assuming independence}{hline}"
		di "{bf: maximum likelihood estimates of double hurdle model}{break} "
		mat start=btobit,bprobit

		* ptobit

		if "`ptobit'" != "" {
		di "{bf: ptobit model, first stage results}{break} "
		ml model lf dh (above:`depvar' = `indep') (sigma: ) (hurdle: ) if `touse'
		ml init start, copy  
		qui ml maximize, difficult
		if `"`millr'"' != "" {
			di "{bf: no second stage estimation possible}"
			di "by design, inverse Mill's ratio from first stage is identical for all observations"
			}
		}

		* separate indepvars for hurdle

		else {
			if "`hd'" != "" {
			ml model lf dh (above: `depvar' = `indep') (sigma: ) (hurdle: `dum' =`hd') if `touse'
			ml init start, copy  
			qui ml maximize, difficult
			tempvar hhat sigma
			predict `hhat', xb eq(hurdle)
			predict `sigma', xb eq(sigma)
			if `"`millr'"' != "" {
				gen _mill = normalden(`hhat'-_depmin,`sigma')/(normal(`hhat'-_depmin)/`sigma')
				}
			}

		* both equations have same set of indepvars
			
		else {
			ml model lf dh (above: `depvar' = `indep') (sigma: ) (hurdle: `dum' =`indep') if `touse'
			ml init start, copy  
			qui ml maximize, difficult
			tempvar hhat sigma
			predict `hhat', xb eq(hurdle)
			if `"`millr'"' != "" {		
				gen _mill = normalden(`hhat'-_depmin,`sigma')/(normal(`hhat'-_depmin)/`sigma')
				}
			}
		if `"`millr'"' != "" {		
			local indep2 "`indep' _mill"
			}

		*** second stage
		if `"`millr'"' != "" {
		** new starting values (only needed for tobit, but ml init command wants full set)
		
			mat drop bprobit btobit

			if "`ptobit'" !="" {
				qui probit `dum' if `touse'
				mat bprobit=e(b)
				}

			* if hurdle has different indepvars

			else {
				if "`hd'" != "" {
				di "starting values for hurdle"
				qui probit `dum' `hd' if `touse'
				mat bprobit=e(b)
				}
				
			* if hurdle and above have the same set of indepvars
				
			else {
				di "starting values for hurdle"
				qui probit `dum' `indep' if `touse'
				mat bprobit=e(b)
				}

			di "{it: estimation allowing for correlation of error terms}{hline}"
			di "{bf: new starting values for tobit}{break} "
			tobit `depvar' `indep2' if `touse', ll(`depmin')
			mat btobit = e(b)

			*** estimation
			* double hurdle model, different sets of indepvars

			if "`hd'" != "" {
				di "{bf: second stage results}{break} "
				ml model lf dh (above: `depvar' = `indep2') (sigma: ) (hurdle: `dum' =`hd') if `touse'
				ml init btobit bprobit, copy  
				qui ml maximize, difficult
				}

			* both equations have same set of indepvars
				
				else {
				di "{bf: second stage results}{break} "
				ml model lf dh (above: `depvar' = `indep2') (sigma: ) (hurdle: `dum' =`indep') if `touse'
				ml init btobit bprobit, copy  
				qui ml maximize, difficult
				}
				
			}
			}
			}
			}
		}


	**** case of upper hurlde

	if "`up'" != "" {
		qui su `depvar'
		tempvar dum // this generates the hurdle
		gen `dum' = (`depvar' < r(max))
		scalar _depmax = r(max)
		local depmax = _depmax // allow for arbitrary hurdles	


		*** generating starting values
		** for hurdle
		* if ptobit is specified (= intercept only)

		if "`ptobit'" !="" {
		di "{bf: starting values for hurdle}{break}"
		probit `dum' if `touse'
		mat bprobit=e(b)
		}

		* if hurdle has different indepvars

		else {
			if "`hd'" != "" {
			di "{bf: starting values for hurdle}{break}"
			probit `dum' `hd' if `touse'
			mat bprobit=e(b)
			}
			
		* if hurdle and above have the same set of indepvars
			
			else {
			di "{bf: starting values for hurdle}{break}"
			probit `dum' `indep' if `touse'
			mat bprobit=e(b)
			}
		}

		** tobit for amount contributed:

		di "{bf: starting values conditional on hurdle being passed}{break}"
		tobit `depvar' `indep' if `touse', ul(`depmax')
		mat btobit=e(b)


		*** ML estimation of double hurdle model

		di "{it: estimation assuming independence}{hline}"
		di "{bf: maximum likelihood estimates of double hurdle model}{break} "
		mat start=btobit,bprobit

		* ptobit

		if "`ptobit'" != "" {
		di "{bf: ptobit model, first stage results}{break} "
		ml model lf dhup (below:`depvar' = `indep') (sigma: ) (hurdle: ) if `touse'
		ml init start, copy  
		qui ml maximize, difficult
		if `"`millr'"' != "" {		
			di "{bf: no second stage estimation possible}"
			di "by design, inverse Mill's ratio from first stage is identical for all observations"
			}
		}

		* separate indepvars for hurdle

		else {
			if "`hd'" != "" {
			ml model lf dhup (below: `depvar' = `indep') (sigma: ) (hurdle: `dum' =`hd') if `touse'
			ml init start, copy  
			qui ml maximize, difficult
			tempvar hhat sigma
			predict `hhat', xb eq(hurdle)
			predict `sigma', xb eq(sigma)
			if `"`millr'"' != "" {			
				gen _mill = normalden(_depmax-`hhat',`sigma')/(normal(_depmax-`hhat')/`sigma')
				}
			}

		* both equations have same set of indepvars
			
			else {
			ml model lf dhup (below: `depvar' = `indep') (sigma: ) (hurdle: `dum' =`indep') if `touse'
			ml init start, copy  
			qui ml maximize, difficult
			tempvar hhat sigma
			predict `hhat', xb eq(hurdle)
			if `"`millr'"' != "" {
				gen _mill = normalden(_depmax-`hhat',`sigma')/(normal(_depmax-`hhat')/`sigma')
				}
			}
			
		if `"`millr'"' != "" {			
			local indep2 "`indep' _mill"
			}

		*** second stage
		if `"`millr'"' != "" {
			** new starting values (only needed for tobit, but ml init command wants full set)

			mat drop bprobit btobit

			if "`ptobit'" !="" {
			qui probit `dum' if `touse'
			mat bprobit=e(b)
			}

			* if hurdle has different indepvars

			else {
				if "`hd'" != "" {
				di "starting values for hurdle"
				qui probit `dum' `hd' if `touse'
				mat bprobit=e(b)
				}
				
			* if hurdle and above have the same set of indepvars
				
				else {
				di "starting values for hurdle"
				qui probit `dum' `indep' if `touse'
				mat bprobit=e(b)
				}

			di "{it: estimation allowing for correlation of error terms}{hline}"
			di "{bf: new starting values for tobit}{break} "
			tobit `depvar' `indep2' if `touse', ul(`depmax')
			mat btobit = e(b)

			*** estimation
			* double hurdle model, different sets of indepvars

			if "`hd'" != "" {
				di "{bf: second stage results}{break} "
				ml model lf dhup (below: `depvar' = `indep2') (sigma: ) (hurdle: `dum' =`hd') if `touse'
				ml init btobit bprobit, copy  
				qui ml maximize, difficult
				}

			* both equations have same set of indepvars
				
				else {
				di "{bf: second stage results}{break} "
				ml model lf dhup (below: `depvar' = `indep2') (sigma: ) (hurdle: `dum' =`indep') if `touse'
				ml init btobit bprobit, copy  
				qui ml maximize, difficult
				}
				
			}
			}
			}
			}
		
			
	** present overall statistics
	
	di "N = " e(N)
	di "log likelihood = " e(ll)
	
	if `"`ptobit'"' == "" {
		if `"`hd'"' != "" {
			if `"`up'"' != "" {
				qui test [hurdle] `hd'
				di "chi square hurdle equation = " r(chi2)
				di "p hurdle equation = " r(p)	
				di "chi square below equation = " e(chi2)
				di "p below equation = " e(p)
				qui test ([hurdle] `hd') ([below] `indep')
				di "chi square overall = " r(chi2)
				di "p overall = " r(p)								
				}
			else {
				qui test [hurdle] `hd'
				di "chi square hurdle equation = " r(chi2)
				di "p hurdle equation = " r(p)	
				di "chi square above equation = " e(chi2)
				di "p above equation = " e(p)
				qui test ([hurdle] `hd') ([above] `indep')	
				di "chi square overall = " r(chi2)
				di "p overall = " r(p)								
				}
			}	
		
		else {
			if `"`up'"' != "" {
				qui test [hurdle] `indep'
				di "chi square hurdle equation = " r(chi2)
				di "p hurdle equation = " r(p)	
				di "chi square below equation = " e(chi2)
				di "p below equation = " e(p)
				qui test ([hurdle] `indep') ([below] `indep')
				di "chi square overall = " r(chi2)
				di "p overall = " r(p)								
				}
			else {
				qui test [hurdle] `indep'
				di "chi square hurdle equation = " r(chi2)
				di "p hurdle equation = " r(p)		
				di "chi square above equation = " e(chi2)
				di "p above equation = " e(p)
				qui test ([hurdle] `indep') ([above] `indep')	
				di "chi square overall = " r(chi2)
				di "p overall = " r(p)								
				}
			}	
		}
		
		** presentation of results
		matrix HB = e(b)
		matrix B = HB'


		* standard errors

		matrix HHV = vecdiag(e(V))
		matrix HV = HHV'
		local rowHV = rowsof(HV)
		matrix V = J(`rowHV',1,0)
		forv i = 1/`rowHV' {
			matrix V[`i',1] = sqrt(HV[`i',1])
			}


		* z values

		matrix Z = J(`rowHV',1,0)
		forv i = 1/`rowHV' {
			matrix Z[`i',1] = B[`i',1]/V[`i',1]
			}


		* p values

		matrix P = J(`rowHV',1,0)
		forv i = 1/`rowHV' {
			if Z[`i',1] > 0 {
				matrix P[`i',1] = 2*(1-normal(Z[`i',1]))
				}
			else {
				matrix P[`i',1] = 2*normal(Z[`i',1])
				}
			}


		* lower ci

		matrix L = J(`rowHV',1,0)
		forv i = 1/`rowHV' {
			matrix L[`i',1] = B[`i',1] - 1.959964*V[`i',1]
			}


		* upper ci
			
		matrix U = J(`rowHV',1,0)
		forv i = 1/`rowHV' {
			matrix U[`i',1] = B[`i',1] + 1.959964*V[`i',1]
			}
			
			
		* combine results

		matrix define HR = B, V, Z, P, L, U	


		* define provisional column names

		matrix colnames HR = "c1" "c2" "c3" "c4" "c5" "c6"


		* change order of presentation

		matrix R1 = HR["hurdle:","c1".."c6"]
		if `"`up'"' == "" {
			matrix R2 = HR["above:", "c1".."c6"]
			}
		else {
			matrix R2 = HR["below:", "c1".."c6"]
			}
		matrix R3 = HR["sigma:", "c1".."c6"]

		matrix R = (R1 \ R2 \ R3)


		* define final column names

		matrix colnames R = "coef" "se" "z" "p" "lower CI" "upper CI"
		
		matlist R, lines(oneline) border(rows)
		


	ereturn local cmd "dhreg"
	
end

program Replay
	syntax
	ml display
end

