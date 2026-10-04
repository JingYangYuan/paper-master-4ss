*! Semiparametric v1.0.0 09oct2012
*  Authors: Thomas Walstrum & Scott Brave
*  This program is part of the margte package.

*Program semiparametric
{
program define semiparametric, eclass
	syntax varlist [if], Treatment(string) P(varname) evalgrid(namelist) MTEXs(namelist) /*
		*/POLYnomial(integer) [DEGree(integer 2) Kernel(string) YBWidth(string) XBWidth(string) /*
		*/constraints(string)]

	marksample touse

	tokenize `varlist'
	local y "`1'"
	macro shift
	local x "`*'"

	tokenize `treatment'
	local d "`1'"
	macro shift
	local xz "`*'"
	
	*Generate the interaction variables.
	foreach indepVar in `x' {
		tempname `indepVar'Xp
		quietly generate ``indepVar'Xp' = `indepVar' * `p' if `touse'
		local interacts 		`interacts' ``indepVar'Xp'
		local interactsNames	`interactsNames' `indepVar'Xp
	}	
	
	*Turn the support matrix into a temporary variable.
	tempvar evalgridVar
	matrix colnames `evalgrid' = `evalgridVar'
	svmat `evalgrid', names(col)
	
	*************************************************************************************************
	* Method 1: local instrumental variables.														*
	*************************************************************************************************
	if `polynomial' == 0 {
		***Step 1: Run a semiparametric double residual regression over the common support.
		*Nonparametrically remove the covariation of the other variables with p.
		local numVars: word count `y' `x' `interacts'
		foreach var of varlist `y' `x' `interacts' {
			display as text "Variables remaining in double residual regression: `numVars'"
			local numVars = `numVars' - 1
			tempvar `var'hat e`var'
			if `var' == `y' {
				lpoly `var' `p' if `touse', degree(1) kernel(`kernel') bwidth(`ybwidth') at(`p') /*
					*/generate(``var'hat') nograph
			} 
			else {
				lpoly `var' `p' if `touse', degree(1) kernel(`kernel') bwidth(`xbwidth') at(`p') /*
					*/generate(``var'hat') nograph
			}
			local `var'BWidth = r(bwidth)
			*Generate a new variable that has the nonparametric relationship with p removed from it.
			quietly generate `e`var'' = `var' - ``var'hat' if `touse'
			local eNames `eNames' `e`var''
		}
		*If there are constraints, modify them to fit the requested model's implementation.
		if "`constraints'" != "" {
			foreach i of numlist `constraints' {
				constraint get `i'
				*Save the constraint before modifying it.
				local svconst`i' = r(contents)
				*Modify the constraint to match the proper variable.
				local const`i' = r(contents)
				foreach var in `interactsNames' { 
					local const`i' = subinstr("`const`i''", "`var'"  , "`e``var'''", .)
				}
				foreach var in `y' `interactsNames' `x' { 
					local const`i' = subinstr("`const`i''", "`var'"  , "`e`var''", .)
				}
				constraint `i' `const`i''
			}
			quietly cnsreg  `eNames' if `touse', noconstant constraints(`constraints')
		}
		else {
			quietly regress `eNames' if `touse', noconstant
		}
		*Save results.
		tempname coef
		matrix `coef' = e(b)
		matrix colnames `coef'	= `x' `interactsNames'
		matrix coleq	`coef'	= Parameters
	}
	
	*************************************************************************************************
	* Method 2: polynomial in p.																	*
	*************************************************************************************************	
	else {
		*** Step 1: Run a regression of x, interacts, and a polynomial of p on y 
		*** to get ytilde and B1-B0.
		*Generate the polynomial variables.
		if `polynomial' != 0 {
			*Check to make sure the polynomial value is greater than one.
			if `polynomial' < 2 {
				display in red `"The order of the polynomial must be greater than one."'
				exit 301
			}
			forvalues i = 1(1)`polynomial' {
				tempname p`i'
				quietly generate `p`i'' = `p'^`i' if `touse'
				local polys 	`polys' `p`i''
				local polyNames `polyNames' p`i'
			}
		}
		*Run the regression, save the coefficients, generate ytilde.
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
			quietly cnsreg  `y' `x' `interacts' `polys' if `touse', constraints(`constraints')
		}
		else {
			quietly regress `y' `x' `interacts' `polys' if `touse'
		}		
				
		*Save results.
		tempname coef
		matrix `coef' = e(b)
		matrix colnames `coef'	= `x' `interactsNames' `polyNames' _cons
		matrix coleq	`coef'	= Parameters
		
		*Put _cons in `tildenames'.
		tempvar constant
		local constLoc: word count `x' `interacts' `polys' _cons
		quietly generate `constant' = `coef'[1, `constLoc'] if `touse'
		local tildeNames - `constant'
	}
	*If there are constraints, restore the original ones.
	if "`constraints'" != "" {
		foreach i of numlist `constraints' {
			constraint `i' `svconst`i''
		}
	}
	
	*************************************************************************************************
	* Construct ytilde																				*
	*************************************************************************************************	local counter = 0
	*Generate predicted y and subtract it from y to get ytilde.
	foreach var of varlist `x' `interacts' {
		local counter = `counter' + 1
		tempvar b`var'
		quietly generate `b`var'' = `coef'[1, `counter'] * `var' if `touse'
		local tildeNames `tildeNames' - `b`var''
	}
	tempvar ytilde
	quietly generate `ytilde' = `y' `tildeNames' if `touse'
	
	*************************************************************************************************
	* Estimatate dK(p)/dp nonparametrically over the common support grid.							*
	*************************************************************************************************
	tempvar k dkdp
	tempname dkdp
	if `polynomial' != 0 local degree = `polynomial'
	
	if "`ybwidth'" == "" {
		*Use the rule of thumb bandwidth from lpoly if ybwidth is not specified.
		quietly lpoly `ytilde' `p' if `touse', degree(1) kernel(`kernel') at(`evalgridVar') nograph
		local ytildebw = r(bwidth)
		*Get the first derivative of K(p) and save it as dkdp.
		quietly locpoly2 `ytilde' `p' if `touse', degree(`degree') `kernel' at(`evalgridVar') /*
			*/width(`ytildebw') generate(`k' `dkdp') nograph
	}
	else {
		*Get the first derivative of K(p) and save it as dkdp.
		quietly locpoly2 `ytilde' `p' if `touse', degree(`degree') `kernel' at(`evalgridVar') /*
			*/width(`ybwidth') generate(`k' `dkdp') nograph
	}
	local returnKernel = r(kernel)
	local returnDegree = r(degree)
	*Save the first derivative as a matrix.
	local numRows = rowsof(`evalgrid')
	forvalues i = 1(1)`numRows' {
		matrix `dkdp' = [nullmat(`dkdp') \ `dkdp'[`i']]
	}
			
	*************************************************************************************************
	* Construct the MTE at the common support.														*
	*************************************************************************************************
	tempname base Xp mte
	*Get only the B1-B0 coefficients.
	local numXs: word count `x'
	matrix `Xp' = `coef'[1, `numXs' + 1 .. 2 * `numXs']
	matrix `base' = `mtexs' * `Xp''
	*Create the mte matrix.
	forvalues i = 1(1)`numRows' {
		matrix `mte' = [nullmat(`mte'), `base' + `dkdp'[`i', 1]]
		local u = round(100 * `evalgrid'[`i', 1])
		local cnames `cnames' u`u'
	}
	matrix coleq	`mte' = mte
	matrix colnames `mte' = `cnames'
	
	*************************************************************************************************
	* Construct the average treatment effect.														*
	*************************************************************************************************
	tempname ate
	matrix `ate' = `mte' * J(colsof(`mte'), 1, 1) / colsof(`mte')
	matrix coleq 	`ate' = ATE
	matrix colnames `ate' = E(Y1-Y0)@X
	
	*************************************************************************************************
	* Return the results.																		   	*
	*************************************************************************************************
	*Combine the coefficients and the mte estimates into one big b.
	tempname b
	matrix `b' = [`coef', `ate', `mte']
	
	*Return b.
	ereturn post `b', depname(`y') esample(`touse')
	
	*Return the bandwidths.
	if `polynomial' == 0 {
		if "`ybwidth'" == "" {
			ereturn scalar ytildeBW = `ytildebw'
		}
		local count: word count `interactsNames'
		forvalues i = 1(1)`count'{ 
			local var = word("`interactsNames'", -`i')
			ereturn scalar `var'BWidth = ```var''BWidth'
		}
		local count: word count `y' `x'
		forvalues i = 1(1)`count'{ 
			local var = word("`y' `x'", -`i')
			ereturn scalar `var'BWidth = ``var'BWidth'
		}
	}
	else {
		if "`ybwidth'" == "" {
			ereturn scalar ytildeBW = `ytildebw'
		}
		else {
			ereturn scalar ytildeBW = `ybwidth'
		}
	}
	
	*Return the degree and kernel.
	ereturn scalar degree = `returnDegree'
	ereturn local kernel    `returnKernel'
		
	*Return the ATE matrix.
	ereturn matrix ate = `ate'
	
	*Return the MTE matrix.
	ereturn matrix mte = `mte'
end
}
