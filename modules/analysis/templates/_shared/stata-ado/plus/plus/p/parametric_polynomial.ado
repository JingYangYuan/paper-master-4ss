*! parametric_polynomial v1.0.0 09oct2012
*  Authors: Thomas Walstrum & Scott Brave
*  This program is part of the margte package.

*Program parametric_polynomial
{
program define parametric_polynomial, eclass
	syntax varlist [if], Treatment(string) P(varname) POLYnomial(integer) MTEXs(namelist) /*
		*/[constraints(string)]
	
	marksample touse

	tokenize `varlist'
	local y "`1'"
	macro shift
	local x "`*'"

	tokenize `treatment'
	local d "`1'"
	macro shift
	local xz "`*'"
	
	*Check to make sure the polynomial value is greater than one.
	if `polynomial' < 2 {
		display in red `"The order of the polynomial must be greater than one."'
		exit 301
	}
	
	************************************************************************************************
	* Estimate the model parameters.															   *
	************************************************************************************************
	*Generate interaction variables.
	foreach indepVar in `x' {
		tempname `indepVar'Xp
		quietly generate ``indepVar'Xp' = `indepVar' * `p' if `touse'
		local interacts 		`interacts' ``indepVar'Xp'
		local interactsNames	`interactsNames' `indepVar'Xp
	}
	*Generate polynomial variables.
	forvalues i = 1(1)`polynomial' {
		tempname p`i'
		quietly generate `p`i'' = `p'^`i' if `touse'
		local polyVars 	`polyVars' `p`i''
		local polyNames `polyNames' p`i'
	}
	*If there are constraints, modify them to fit the requested model's implementation.
	if "`constraints'" != "" {
		foreach i of numlist `constraints' {
			constraint get `i'
			*Save the constraint before modifying it.
			local svconst`i' = r(contents)
			*Modify the constraint to match the proper variable.
			local const`i' = r(contents)
			foreach indepVar in `interactsNames' `polyNames'{ 
				local const`i' = subinstr("`const`i''", "`indepVar'", "``indepVar''", .)
			}
			constraint `i' `const`i''
		}
	}
	*Run regressions with polynomials in p of order 1 to `polynomial'.
	if "`constraints'" != "" {
		*Run a constrained regression and save the results.
		quietly cnsreg  `y' `x' `interacts' `polyVars' if `touse', constraints(`constraints')
	}
	else {
		*Run an unconstrained regression and save the results.
		quietly regress `y' `x' `interacts' `polyVars' if `touse'
	}
	*Save the results.
	tempname coef
	matrix `coef' 			= e(b)
	matrix colnames `coef'	= `x' `interactsNames' `polyNames' _cons
	matrix coleq	`coef'	= Parameters
	
	*If there are constraints, restore the original ones.
	if "`constraints'" != "" {
		foreach i of numlist `constraints' {
			constraint `i' `svconst`i''
		}
	}
	
	************************************************************************************************
	* Construct the MTE.																		   *
	************************************************************************************************
	*Get the coefficients on the interacted Xs.
	tempname diffBeta polys
	local numXs = wordcount("`x'")
	matrix `diffBeta' 	= `coef'[1, 	`numXs' + 1	..`numXs' * 2				]
	matrix `polys'		= `coef'[1, 2 * `numXs' + 1	..`numXs' * 2 + `polynomial']
	
	*Construct base of the MTE.
	*Note: the base also technically includes the coefficient on p. I include that coefficient
	*in the build-up of the polynomial terms below.
	tempname base mte
	matrix `base' = `mtexs' * `diffBeta''
	
	*Combine the base with the control function.
	local cnames ""
	forvalues i = 1(1)99 {
		local mtePoly`i' ""
		forvalues j = 1(1)`polynomial' {
			local mtePoly`i' = `mtePoly`i'' + `j' * `polys'[1, `j'] * (`i' / 100) ^ (`j' - 1)
		}
		matrix `mte' = [nullmat(`mte') , `base' + `mtePoly`i'']
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
	*Combine the coefficients and the mte estimates into one big b.
	tempname b
	matrix `b' = [`coef', `ate', `mte']
	
	*Return b.
	ereturn post `b', depname(`y') esample(`touse')
	
	*Return the ATE matrix.
	ereturn matrix ate = `ate'
	
	*Return the MTE matrix.
	ereturn matrix mte = `mte'
end
}
