/*bootdhreg
program to estimate a double hurdle model
with bootstrapping
by Christoph Engel and Peter Moffatt
this version 131102
rev1: standardize output: noheader; equation names added
rev2: standardize order of output: hurdle, main, sigma
rev3: make overall statistics for ml models available
rev4: add Wald tests for joint significance of coefficients from main equation / overall
*/

program drop _all

program define bootdhreg

	version 11
	if replay() {
		if (`"`e(cmd)'"' != "bootdhreg") error 301
		Replay `0'
		}
	else	Estimate `0'
end	


program Estimate, eclass sortpreserve
	
	syntax varlist(fv) [if] [in] [, reps(int 50) seed(int 220256) strata(varlist) cluster(varlist) ///
	capt maxiter(int 50) up ptobit hd(varlist) millr margins(string asis)]
	gettoken depvar indep: varlist
	capt drop _depmin
	capt drop _depmax
	capt drop _res* 
	capt drop _bres*
	capt drop _mar*
	capt drop _mill
	marksample touse
	set seed `seed'

	****** checking whether boundary conditions are fulfilled

	if "`ptobit'" != "" & "`hd'" !="" {
		error 184
		}

	else{
		
			qui su `depvar' if `touse'
			tempvar dum // this generates the hurdle
			if "`up'" == "" {
				gen `dum' = (`depvar' > r(min))
				label var `dum' "hurdle"
				scalar _depmin = r(min) // allow for arbitrary hurdles	
				local depmin = _depmin
				}
			else {
				qui su `depvar'
				tempvar dum // this generates the hurdle
				gen `dum' = (`depvar' < r(max))
				label var `dum' "hurdle"
				scalar _depmax = r(max) // allow for arbitrary hurdles	
				local depmax = _depmax
				}

			***** first stage (assuming error terms are uncorrelated)
			*** generating starting values
			** for hurdle
			* if ptobit is specified (= intercept only)
			
			if "`ptobit'" !="" {
					di "{bf: starting values for hurdle}{break}"
					probit `dum' if `touse'
					mat boprobit=e(b)
				}
			
			* if hurdle has different indepvars

			else if "`hd'" != "" {
					di "{bf: starting values for hurdle}{break}"
					probit `dum' `hd' if `touse'
					mat boprobit=e(b)
					}
				
			* if hurdle and above have the same set of indepvars
				
			else {
				di "{bf: starting values for hurdle}{break}"
				probit `dum' `indep' if `touse'
				mat boprobit=e(b)
			}
			
				
			** tobit for amount contributed:

			di "{bf: starting values conditional on hurdle being passed}{break}"
			if "`up'" == "" {
				tobit `depvar' `indep' if `touse', ll(`depmin')
				}
			else {
				tobit `depvar' `indep' if `touse', ul(`depmax')
				}
			mat botobit=e(b)


			*** ML estimation of double hurdle model

			di "{it: estimation assuming independence}{hline}"
			di "{bf: maximum likelihood estimates of double hurdle model}{break} "
			mat ostart=botobit,boprobit
			
		
			* ptobit

			if "`ptobit'" !="" {
				if "`up'" == "" {
					ml model lf dh (main:`depvar' = `indep') (sigma: ) (hurdle: ) if `touse'
					}
				else {
					ml model lf dhup (main:`depvar' = `indep') (sigma: ) (hurdle: ) if `touse'
					}
				ml init ostart, copy  
				qui ml maximize, difficult
				di "N = " e(N)
				di "log likelihood = " e(ll)
				di "chi square model = " e(chi2)
				di "p model = "e(p)
				matrix A0 = e(b)
				if "`millr'" != "" {
					di "{bf: no second stage estimation possible}"
					di "by design, inverse Mill's ratio from first stage is identical for all observations"
					}
				if "`margins'" != "" {
					margins, `margins' post
					matrix M0 = e(b)
					}		
					
				forvalues i = 1/`reps' {
				preserve
				set maxiter `maxiter'
				bsample, strata(`strata') cluster(`cluster')
				if "`up'" == "" {					
					ml model lf dh (main:`depvar' = `indep') (sigma: ) (hurdle: ) if `touse'
					}
				else {
					ml model lf dhup (main:`depvar' = `indep') (sigma: ) (hurdle: ) if `touse'
					}
				ml init ostart, copy  
				qui `capt' ml maximize, difficult
				matrix A`i' = e(b)	
				if "`margins'" != "" {
					qui margins, `margins' post
					matrix M`i' = e(b)
					}						
				restore
				}
			}
			
			* if hurdle has different indepvars
			
			else if "`hd'" != "" {
				if "`millr'" != "" {
					di "{bf: first stage results}{break} "
					}
				if "`up'" == "" {					
					ml model lf dh (main:`depvar' = `indep') (sigma: ) (hurdle: `dum' = `hd') if `touse'
					}
				else {
					ml model lf dhup (main:`depvar' = `indep') (sigma: ) (hurdle: `dum' = `hd') if `touse'
					}
				ml init ostart, copy  
				qui ml maximize, difficult
				di "N = " e(N)
				di "log likelihood = " e(ll)
				di "chi square hurdle equation = " e(chi2)
				di "p hurdle equation = "e(p)
				qui test [main] `indep'
				di "chi square main equation = " r(chi2)
				di "p main equation = " r(p)
				qui test ([hurdle] `hd') ([main] `indep')
				di "chi square overall = " r(chi2)
				di "p overall = " r(p)				
				matrix A0 = e(b)
				tempvar hhat
				predict `hhat', xb eq(hurdle)
				if "`millr'" != "" {
					gen _mill = normalden(`hhat')/normal(`hhat')
					}
				if "`margins'" != "" {
					margins, `margins' post
					matrix M0 = e(b)
					}
					
				forvalues i = 1/`reps' {
				preserve
				set maxiter `maxiter'
				bsample, strata(`strata') cluster(`cluster')
				if "`up'" == "" {			
					ml model lf dh (main:`depvar' = `indep') (sigma: ) (hurdle: `dum' = `hd') if `touse'
					}
				else {
					ml model lf dhup (main:`depvar' = `indep') (sigma: ) (hurdle: `dum' = `hd') if `touse'
					}
				ml init ostart, copy  
				qui `capt' ml maximize, difficult
				matrix A`i' = e(b)	
				if "`margins'" != "" {
					qui margins, `margins' post
					matrix M`i' = e(b)
					}					
				restore
				}
			}
			
			
			* both equations have same set of indepvars
			
			else {
				if "`millr'" != "" {
					di "{bf: first stage results}{break}"
					}
				if "`up'" == "" {		
					ml model lf dh (main: `depvar' = `indep') (sigma: ) (hurdle: `dum' =`indep') if `touse'
					}
				else {
					ml model lf dhup (main: `depvar' = `indep') (sigma: ) (hurdle: `dum' =`indep') if `touse'
					}
				ml init ostart, copy  
				qui ml maximize, difficult
				di "N = " e(N)
				di "log likelihood = " e(ll)
				di "chi square hurdle equation = " e(chi2)
				di "p hurdle equation = " e(p)	
				qui test [main] `indep'
				di "chi square main equation = " r(chi2)
				di "p main equation = " r(p)
				qui test ([hurdle] `indep') ([main] `indep')
				di "chi square overall = " r(chi2)
				di "p overall = " r(p)				
				matrix A0 = e(b)				
				tempvar hhat
				predict `hhat', xb eq(hurdle)
				if "`millr'" != "" {
					gen _mill = normalden(`hhat')/normal(`hhat')
					}
				if "`margins'" != "" {
					margins, `margins' post
					matrix M0 = e(b)					
					}				

				forvalues i = 1/`reps' {
				preserve
				set maxiter `maxiter'
				bsample, strata(`strata') cluster(`cluster')
				if "`up'" == "" {
					ml model lf dh (main: `depvar' = `indep') (sigma: ) (hurdle: `dum' =`indep') if `touse'
					}
				else {
					ml model lf dhup (main: `depvar' = `indep') (sigma: ) (hurdle: `dum' =`indep') if `touse'
					}
				ml init ostart, copy  
				qui `capt' ml maximize, difficult
				matrix A`i' = e(b)
				if "`margins'" != "" {
					qui margins, `margins' post
					matrix M`i' = e(b)
					}					
				restore
				}
			}

			
			*** presentation of bootstrap results
			** coefficients
			
			tempname B C
			matrix `B' = A1
			forvalues i = 2/`reps' {
				matrix `C' = `B'\A`i'
				matrix drop `B'
				matrix ren `C' `B'
				}
				
			svmat `B', names(_res)

			local ABC = colsof(A1)

			forvalues j = 1/`ABC' {
				qui su _res`j', d
				local mean = A0[1,`j']
				local sd = r(sd)
				qui centile _res`j', centile(2.5 97.5)
				if `mean' < 0 {
					local p = normal(`mean'/`sd')
					}
				else{
					local p = 1-normal(`mean'/`sd')
					}
				matrix D`j'  = `mean', `sd', `p', `mean'-1.96*`sd', `mean'+1.96*`sd', r(c_1), r(c_2)
				}

			tempname E F
			matrix `E' = D1
			forvalues j = 2/`ABC' {
				matrix `F' = `E'\D`j'
				matrix drop `E'
				matrix ren `F' `E'
				}	
						
			local rownames: colfullnames A1
			matrix rownames `E' = `rownames'
			matrix colnames `E' = c1 c2 c3 c4 c5 c6 c7

			
			if "`margins'" != "" {
				di "{hline}"
				di "{title:bootstrap results: coefficients}{break}"
				}
			else {	
				di "{title:bootstrap results}{break}"
				}
			tempname E1 E2 E3
			matrix `E1' = `E'["hurdle:","c1".."c7"]
			matrix `E2' = `E'["main:","c1".."c7"]
			matrix `E3' = `E'["sigma:","c1".."c7"]
			matrix `F' = (`E1' \ `E2' \ `E3')
			matrix colnames `F' = coef se p lowciz upciz lowcip upcip
			matlist `F', lines(oneline) border(rows)
				
			
			** marginal effects
			
			if "`margins'" != "" {
				tempname N O
				matrix `N' = M1
				forvalues i = 2/`reps' {
					matrix `O' = `N'\M`i'
					matrix drop `N'
					matrix ren `O' `N'
					}
					
				svmat `N', names(_mar)

				local MN = colsof(M1)

				forvalues j = 1/`MN' {
					qui su _mar`j', d
					local mean = M0[1,`j']
					local sd = r(sd)
					qui centile _mar`j', centile(2.5 97.5)
					if `mean' < 0 {
						local p = normal(`mean'/`sd')
						}
					else{
						local p = 1-normal(`mean'/`sd')
						}
					matrix P`j'  = `mean', `sd', `p', `mean'-1.96*`sd', `mean'+1.96*`sd', r(c_1), r(c_2)
					}

				tempname Q R
				matrix `Q' = P1
				forvalues j = 2/`MN' {
					matrix `R' = `Q'\P`j'
					matrix drop `Q'
					matrix ren `R' `Q'
					}	
							
				local rownames: colfullnames M1
				matrix rownames `Q' = `rownames'
				matrix colnames `Q' = coef se p lowciz upciz lowcip upcip

				di "{hline}"
				di "{title:bootstrap results: marginal effects}{break}"
				matlist `Q', lines(oneline) border(rows)
			}
			
			
			**** second stage (correcting for potential correlation of error terms)
			// no calculations for ptobit, since mill's ratio is meaningless
			
			if "`millr'" != "" {
				if "`ptobit'" == "" {
				
					*** prepare for estimation
					** enriched set of indepvars
					
					local indep2 "`indep' _mill"
					
					** clean matrices
					
					mat drop `B' `E'
					capt mat drop `N' `Q'
					
					forvalues i = 0/`reps' {
						matrix drop A`i'
						capt matrix drop M`i'
						}
					forvalues j = 1/`ABC' {	
						matrix drop D`j'
						capt matrix drop P`i'
						}
					
					** generate new starting values
					// (only needed for tobit, but ml init wants full set)
					
					if "`ptobit'" !="" {
						qui probit `dum' if `touse'
						mat bprobit=e(b)
						}

					* if hurdle has different indepvars

					else if "`hd'" != "" {
						qui probit `dum' `hd' if `touse'
						mat bprobit=e(b)
						}
						
					* if hurdle and above have the same set of indepvars
						
					else {
						qui probit `dum' `indep' if `touse'
						mat bprobit=e(b)
						}

					di "{it: estimation allowing for correlation of error terms}{hline}"
					di "{bf: new starting values for tobit}{break} "
					if "`up'" == "" {
						tobit `depvar' `indep2' if `touse', ll(`depmin')
						}
					else {
						tobit `depvar' `indep2' if `touse', ul(`depmax')
						}
					mat btobit = e(b)

					matrix start=btobit,bprobit
					
					
					
					*** ML estimation
					** if hurdle has different indepvars
					
					if "`hd'" != "" {
						di "{bf: second stage results}{break} "
						if "`up'" == "" {
							ml model lf dh (main:`depvar' = `indep2') (sigma: ) (hurdle: `dum' = `hd') if `touse'
							}
						else {
							ml model lf dhup (main:`depvar' = `indep2') (sigma: ) (hurdle: `dum' = `hd') if `touse'
							}
						ml init start, copy  
						qui ml maximize, difficult
						di "N = " e(N)
						di "log likelihood = " e(ll)
						di "chi square model = " e(chi2)
						di "p model = "e(p)
						matrix A0 = e(b)
						
						if "`margins'" != "" {
							margins, `margins' post
							matrix M0 = e(b)
						}						

						forvalues i = 1/`reps' {
						preserve
						set maxiter `maxiter'
						bsample, strata(`strata') cluster(`cluster')
						if "`up'" == "" {
							ml model lf dh (main:`depvar' = `indep2') (sigma: ) (hurdle: `dum' = `hd') if `touse'
							}
						else {
							ml model lf dh (main:`depvar' = `indep2') (sigma: ) (hurdle: `dum' = `hd') if `touse'
							}
						ml init start, copy  
						qui `capt' ml maximize, difficult
						restore
						matrix A`i' = e(b)
						if "`margins'" != "" {
							qui margins, `margins' post
							matrix M`i' = e(b)
							}						
						}
					}
					
					
					** both equations have same set of indepvars
					
					else {
						di "{bf: second stage results}{break}"
						
						if "`up'" == "" {
							ml model lf dh (main: `depvar' = `indep2') (sigma: ) (hurdle: `dum' =`indep') if `touse'
							}
						else {
							ml model lf dhup (main: `depvar' = `indep2') (sigma: ) (hurdle: `dum' =`indep') if `touse'
							}
						ml init start, copy  
						qui ml maximize, difficult
						di "N = " e(N)
						di "log likelihood = " e(ll)
						di "chi square model = " e(chi2)
						di "p model = "e(p)			
						matrix A0 = e(b)
						if "`margins'" != "" {
							margins, `margins' post
							matrix M0 = e(b)
							}

						forvalues i = 1/`reps' {
						preserve
						set maxiter `maxiter'
						bsample, strata(`strata') cluster(`cluster')
						if "`up'" == "" {
							ml model lf dh (main: `depvar' = `indep2') (sigma: ) (hurdle: `dum' =`indep') if `touse'
							}
						else {
							ml model lf dhup (main: `depvar' = `indep2') (sigma: ) (hurdle: `dum' =`indep') if `touse'
							}
						ml init start, copy  
						qui `capt' ml maximize, difficult
						restore
						matrix A`i' = e(b)
						if "`margins'" != "" {
							qui margins, `margins' post
							matrix M`i' = e(b)
							}
						}
					}
					
					
			*** presentation of bootstrap results
			** coefficients
			
			tempname B C
			matrix `B' = A1
			forvalues i = 2/`reps' {
				matrix `C' = `B'\A`i'
				matrix drop `B'
				matrix ren `C' `B'
				}
				
			svmat `B', names(_bres)

			local ABC = colsof(A1)

			forvalues j = 1/`ABC' {
				qui su _bres`j', d
				local mean = A0[1,`j']
				local sd = r(sd)
				qui centile _bres`j', centile(2.5 97.5)
				if `mean' < 0 {
					local p = normal(`mean'/`sd')
					}
				else{
					local p = 1-normal(`mean'/`sd')
					}
				matrix D`j'  = `mean', `sd', `p', `mean'-1.96*`sd', `mean'+1.96*`sd', r(c_1), r(c_2)
				}

			tempname E F
			matrix `E' = D1
			forvalues j = 2/`ABC' {
				matrix `F' = `E'\D`j'
				matrix drop `E'
				matrix ren `F' `E'
				}	
						
			local rownames: colfullnames A1
			matrix rownames `E' = `rownames'
			matrix colnames `E' = c1 c2 c3 c4 c5 c6 c7

			
			if "`margins'" != "" {
				di "{hline}"
				di "{title:bootstrap results: coefficients}{break}"
				}
			else {	
				di "{title:bootstrap results}{break}"
				}
			tempname E1 E2 E3
			matrix `E1' = `E'["hurdle:","c1".."c7"]
			matrix `E2' = `E'["main:","c1".."c7"]
			matrix `E3' = `E'["sigma:","c1".."c7"]
			matrix `F' = (`E1' \ `E2' \ `E3')
			matrix colnames `F' = coef se p lowciz upciz lowcip upcip
			matlist `F', lines(oneline) border(rows)
				
			
			** marginal effects
			
			if "`margins'" != "" {
				tempname N O
				matrix `N' = M1
				forvalues i = 2/`reps' {
					matrix `O' = `N'\M`i'
					matrix drop `N'
					matrix ren `O' `N'
					}
					
				svmat `N', names(_bmar)

				local MN = colsof(M1)

				forvalues j = 1/`MN' {
					qui su _mar`j', d
					local mean = M0[1,`j']
					local sd = r(sd)
					qui centile _bmar`j', centile(2.5 97.5)
					if `mean' < 0 {
						local p = normal(`mean'/`sd')
						}
					else{
						local p = 1-normal(`mean'/`sd')
						}
					matrix P`j'  = `mean', `sd', `p', `mean'-1.96*`sd', `mean'+1.96*`sd', r(c_1), r(c_2)
					}

				tempname Q R
				matrix `Q' = P1
				forvalues j = 2/`MN' {
					matrix `R' = `Q'\P`j'
					matrix drop `Q'
					matrix ren `R' `Q'
					}	
							
				local rownames: colfullnames M1
				matrix rownames `Q' = `rownames'
				matrix colnames `Q' = coef se p lowciz upciz lowcip upcip

				di "{hline}"
				di "{title:bootstrap results: marginal effects}{break}"
				matlist `Q', lines(oneline) border(rows)
				}
			}
			else {
			}
			
		
		****** drop temporary variables and matrices
		
		capt drop _depmin
		capt drop _depmax

		forvalues i = 0/`reps' {
			matrix drop A`i'
			capt drop M`i'
			}
		forvalues j = 1/`ABC' {	
			matrix drop D`j'
			capt drop P`i'
			}
		capt matrix drop start 
		capt matrix drop botobit 
		capt matrix drop boprobit 
		capt matrix drop btobit 
		capt matrix drop bprobit 
		capt matrix drop ostart	
		capt matrix drop B
		capt matrix drop N
		capt matrix drop Q

	}
}
	ereturn local cmd "bootdhreg"

end

program Replay
	syntax
	ml display
end
