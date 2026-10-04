*! parametric_normal v1.0.1 19may2014
*  Authors: Thomas Walstrum & Scott Brave
*  This program is part of the margte package.

*Program parametric_normal
{
program define parametric_normal, eclass
	syntax varlist [if], Treatment(string) P(varname) MTEXs(namelist) [MLikelihood /*
		*/Constraints(string) MLOpts(string)]
	
	marksample touse

	tokenize `varlist'
	local y "`1'"
	macro shift
	local x "`*'"

	tokenize `treatment'
	local d "`1'"
	macro shift
	local xz "`*'"
		
	local numXVars: word count `x'
	local numVars = `numXVars' + 2
		
	*Define temporary variables, matrices, and scalars.
	tempvar		k `d'X_cons
	tempname	coef vari t ut m diffAlpha diffBeta diffRho
		
	if "`mlikelihood'" != "" {
		*********************************************************************************************
		* Estimate the model parameters using maximum likelihood.											  *
		*********************************************************************************************
		if "`constraints'" != "" {
			*Modify the constraints to fit the requested model's implementation.
			foreach i of numlist `constraints' {
				constraint get `i'
				*Save the constraint before modifying it.
				local svconst`i' = r(contents)
				*Modify the constraint to match the proper variable.
				local const`i' = r(contents)
				foreach indepVar in _cons `x'{ 
					local const`i' = subinstr("`const`i''", "[Treated]`indepVar'", /*
										*/"[`y'1]`indepVar'", .)
					local const`i' = subinstr("`const`i''", "[Untreated]`indepVar'", /*
										*/"[`y'0]`indepVar'", .)
					constraint `i' `const`i''
				}
				foreach indepVar in lns r { 
					local const`i' = subinstr("`const`i''", "[Treated]`indepVar'", /*
										*/"[`indepVar'1]_cons", .)
					local const`i' = subinstr("`const`i''", "[Untreated]`indepVar'", /*
										*/"[`indepVar'0]_cons", .)
					constraint `i' `const`i''
				}
			}
		}
				
		quietly movestay `y' `x' if `touse', select(`d' `xz') constraints(`constraints') `mlopts'
		matrix `coef' = e(b)
		matrix `vari' = e(V)
		*Create the treated, untreated, mills, and first step matrices. 
		tempname t tlns tr ut utlns utr m fs
		matrix `t'		= `coef'[1, "`y'1:"]
		matrix `tlns'	= `coef'[1, "lns1:"]
		matrix `tr'		= `coef'[1, "r1:"]
		matrix `t'		= [`t', `tlns', `tr']
		matrix `ut' 	= `coef'[1, "`y'0:"]
		matrix `utlns'	= `coef'[1, "lns0:"]
		matrix `utr'	= `coef'[1, "r0:"]
		matrix `ut'		= [`ut', `utlns', `utr']
		*Note: what movestay calls rho1 and rho0 are corr(U1, V) and corr(U0, V). margte calls rho1
		*and rho0 cov(U1, V) and cov(U0, V). So rho1 and rho0 from movestay are scaled by sigma1 and 
		*simga0.
		matrix `m'		= [/*
							*/-(exp(_b[lns1:_cons]) * tanh(_b[r1:_cons])), /*
							*/-(exp(_b[lns0:_cons]) * tanh(_b[r0:_cons])), /*
							*/-(exp(_b[lns1:_cons]) * tanh(_b[r1:_cons])) - /*
							*/-(exp(_b[lns0:_cons]) * tanh(_b[r0:_cons])) /*
							*/]
		matrix `fs'		= `coef'[1, "select:"]
		matrix colnames `t' 	= `x' _cons lns r
		matrix coleq `t'  		= Treated
		matrix colnames `ut'	= `x' _cons lns r
		matrix coleq `ut' 		= Untreated
		matrix colnames `m'		= rho1 rho0 rho1-rho0
		matrix coleq `m'  		= Mills
		matrix coleq `fs'			= FirstStep
		
		**Rearrange e(V) to be match the ordering of what e(b) will be.
		tempname VML VMLt VMLtlns VMLtr VMLut VMLutlns VMLutr VMLfs VMLm VMLmbelow
		
		*Get the variances of rho1, rho0, and the Mills Ratio test and put them in a matrix.
		quietly nlcom -(exp(_b[lns1:_cons]) * tanh(_b[r1:_cons]))
		matrix `VMLm' = [r(V)]
		quietly nlcom -(exp(_b[lns0:_cons]) * tanh(_b[r0:_cons]))
		matrix `VMLm' = [`VMLm', 0\ 0, r(V)]
		quietly nlcom -(exp(_b[lns1:_cons]) * tanh(_b[r1:_cons])) - /*
						*/-(exp(_b[lns0:_cons]) * tanh(_b[r0:_cons]))
		matrix `VMLm' = [`VMLm', J(2, 1, 0)\ 0, 0, r(V)]
		*Put VMLm at the bottom right of `vari'
		matrix `VMLm' 				= [J(rowsof(`vari'), 3, 0)\ `VMLm']
		matrix colnames `VMLm' 		= rho1 rho0 rho1-rho0
		matrix coleq `VMLm'			= Mills
		matrix `VMLmbelow'			= J(3, colsof(`vari'), 0)
		matrix rownames `VMLmbelow'	= rho1 rho0 rho1-rho0
		matrix roweq `VMLmbelow'	= Mills
		matrix `vari' 				= [`vari'\ `VMLmbelow']
		matrix `vari'				= [`vari', `VMLm']
		*Rearrange.
		forvalues i = 1(1)2 {
			*Parse e(V)
			matrix `VMLt' 		= `vari'[1..., "`y'1:"]
			matrix `VMLtlns'	= `vari'[1..., "lns1:"]
			matrix `VMLtr'		= `vari'[1..., "r1:"]
			matrix `VMLt'		= [`VMLt', `VMLtlns', `VMLtr']
			matrix `VMLut'		= `vari'[1..., "`y'0:"]
			matrix `VMLutlns'	= `vari'[1..., "lns0:"]
			matrix `VMLutr'		= `vari'[1..., "r0:"]
			matrix `VMLut'		= [`VMLut', `VMLutlns', `VMLutr']
			matrix `VMLfs'		= `vari'[1..., "select:"]
			matrix `VMLm'		= `vari'[1..., "Mills:"]
			*Name the columns and equations.
			matrix colnames `VMLt'	= `x' _cons tlns tr
			matrix coleq `VMLt'		= Treated
			matrix colnames `VMLut' = `x' _cons utlns utr
			matrix coleq `VMLut'	= Untreated
			matrix coleq `VMLfs'	= FirstStep			
			matrix `VML'  = [`VMLt', `VMLut', `VMLm', `VMLfs']
			matrix `vari' = `VML''
		}
	}
	else {
		*********************************************************************************************
		* Estimate the model parameters using the two step procedure.								*
		*********************************************************************************************
		*Construct control function.
		quietly generate	`k' = .
		quietly replace		`k' =    normalden(invnormal(`p')) / (1 - `p') /*
			*/if `d' == 0 & `touse' 
		quietly replace		`k' = - (normalden(invnormal(`p')) / `p') /*
			*/if `d' == 1 & `touse'
		
		*Conditional expectations.
		*Generate interaction variables.
		quietly generate ``d'X_cons' = `d' if `touse'
		local interacts  ``d'X_cons'
		foreach indepVar in `x' `k'{
			tempname `d'X`indepVar'
			quietly generate ``d'X`indepVar'' = `d' * `indepVar' if `touse'
			local interacts `interacts' ``d'X`indepVar''
		}
	
		*Run either a constrained or unconstrained regression.
		if "`constraints'" != "" {
			*Modify the constraints to fit the requested model's implementation.
			foreach i of numlist `constraints' {
				constraint get `i'
				*Save the constraint before modifying it.
				local svconst`i' = r(contents)
				*Modify the constraint to match the proper variable.
				local const`i' = r(contents)
				foreach indepVar in _cons `x' `k' `interacts' { 
					if "`indepVar'" == "`k'" {
						local const`i' = subinstr("`const`i''", "[Treated]k", /*
											*/"`indepVar' + ``d'X`indepVar''", .)
						local const`i' = subinstr("`const`i''", "[Untreated]k", /*
											*/"`indepVar'", .)
					} 
					else {
						local const`i' = subinstr("`const`i''", "[Treated]`indepVar'", /*
											*/"`indepVar' + ``d'X`indepVar''", .)
						local const`i' = subinstr("`const`i''", "[Untreated]`indepVar'", /*
											*/"`indepVar'", .)
						constraint `i' `const`i''
					}
				}
			}
			
			*Run the constrained regression and save the results.
			quietly cnsreg `y' `x' `k' `interacts' if `touse', constraints(`constraints')
			matrix `coef' = e(b)
			*Restore the original constraints.
			foreach i of numlist `constraints' {
				constraint `i' `svconst`i''
			}
		}
		else {
			*Run the unconstrained regression and save the results.
			quietly regress `y' `x' `k' `interacts' if `touse'
			matrix `coef' = e(b)
		}
		
		*Restore the original constraints.
		if "`constraints'" != "" {
			foreach i of numlist `constraints' {
				constraint `i' `svconst`i''
			}
		}
		
		*Rearrange the untreated constant in the coefficient matrix.
		local utCons					= `coef'[1, `numVars']
		matrix `coef'[1, `numVars'] 	= `coef'[1, `numVars' * 2]
		matrix `coef'[1, `numVars' * 2] = `utCons'
		
		*Create the treated, untreated, and mills matrices.
		matrix `t' 						= `coef'[1, 1..`numVars'] /*
										*/ + `coef'[1, `numVars' + 1..`numVars' * 2] 
		matrix `ut' 					= `coef'[1, 1..`numVars']
		matrix `m'						= `coef'[1, `numVars' * 2 - 1]
		matrix colnames	`t' 			= `x' k _cons
		matrix coleq `t' 				= Treated
		matrix colnames	`ut'			= `x' k _cons
		matrix coleq `ut'				= Untreated
		matrix colnames `m'				= rho1-rho0
		matrix coleq `m'				= Mills
	}
	
	*************************************************************************************************
	* Construct the MTE.																			*
	*************************************************************************************************
	*Get the differences.
	matrix `diffAlpha'	= `t'[1, "Treated:_cons"] - `ut'[1, "Untreated:_cons"]
	matrix `diffBeta'	= `t'[1, 1..`numXVars' ]  - `ut'[1, 1..`numXVars' ]
	matrix `diffRho' 	= `m'[1, "Mills:rho1-rho0"]
	
	*Create the base.
	tempname base mte
	matrix `base' = `diffAlpha' + `mtexs' * `diffBeta''
	
	*Combine the base with the control function.
	forvalues i = 1(1)99 {
		matrix `mte' = [nullmat(`mte'), `base' + `diffRho' * invnormal(`i' / 100)]
		local cnames "`cnames' u`i'"
	}
	matrix coleq	`mte' = mte
	matrix colnames `mte' = `cnames'
	
	*************************************************************************************************
	* Construct the average treatment effect.														*
	*************************************************************************************************
	tempname ate
	matrix 			`ate' = `mte' * J(colsof(`mte'), 1, 1) / colsof(`mte')
	matrix coleq 	`ate' = ATE
	matrix colnames `ate' = E(Y1-Y0)@X
	
	*************************************************************************************************
	* Return the results.																			*
	*************************************************************************************************	
	*Combine the coefficients, the mte estimates, and the ATE into one big b.
	tempname b bML
	if "`mlikelihood'" != "" {
		matrix `b'	= (`t', `ut', `m', `ate', `fs', `mte')	
	}
	else {
		matrix `b' = (`t', `ut', `m', `ate', `mte')
	}
	
	*Return b.
	ereturn post `b', depname(`y') esample(`touse')
	
	*Return the ATE matrix.
	ereturn matrix ate = `ate'
	
	*Return the MTE matrix.
	ereturn matrix mte = `mte'
	
	*Return the Treated, Untreated and Mills matrices.
	ereturn matrix mills		= `m'
	ereturn matrix untreated 	= `ut'
	ereturn matrix treated 		= `t'
	
	if "`mlikelihood'" != "" ereturn matrix VML = `VML'
end
}
