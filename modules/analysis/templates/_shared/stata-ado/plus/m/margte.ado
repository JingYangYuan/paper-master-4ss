*! margte v1.0.0 09oct2012
*  Authors: Thomas Walstrum & Scott Brave
*  This program is part of the margte package.

*Program margte
{
program define margte, eclass
	version 11

	if replay() {
		if "`e(cmd)'" != "margte" error 301
		
		_coef_table_header
		if "`polynomial'" != "" | "`semiparametric'" != "" {
			_coef_table, level(`e(level)') neq(2) 
		}
		else {
			_coef_table, level(`e(level)') neq(4)
		}
	}
	else {
		mteMain `0'
	}
end
}
*Program mteMain
{
program define mteMain, eclass
	*************************************************************************************************
	* Process the arguments.																		*
	*************************************************************************************************
	syntax varlist [if] [in], Treatment(passthru) [ /*	
		*First step.
			*/First /*
			*/Link(string) /*
			*/Common /*
			*/noCommongraph /*
			*/CSBARwidth(passthru) /*
		*Model.
			*/SEMIparametric /*
			*/POLYnomial(integer 0) /*
			*/Xvalues(string) /*
			*/Constraints(passthru) /*
			*/MLikelihood /*
			*/DEGree(passthru) /*
			*/Kernel(passthru) /*
			*/YBWidth(passthru) /*
			*/XBWidth(passthru) /*
			*/SAVEPRopensity /*
			*/noPlot /*
			*/Plotci(passthru) /*
		*Bootstrap.
			*/noBOot /*
			*/Level(passthru) /*
			*/bca /*
			*/BSOpts(string) /*
		*Maximum likelihood options.
			*/MLOpts(passthru) /* 
		*/]
		
	marksample touse
	
	tokenize `varlist'
	local y "`1'"
	macro shift
	local x "`*'"
	
	*Process the link function and set the default.
	if "`link'" == "" local link probit	
	local link = lower("`link'")
	local capLink = proper("`link'")
	if "`capLink'" == "Lpm" local capLink LPM
	
	*Make sure that if link is Probit when poly isn't specified, an error is given.
	if "`link'" != "probit" & `polynomial' == 0 & "`semiparametric'" == "" {
		display as error `"If the link function is not Probit you must enter a polynomial option."'
		exit
	}
	
	*Possible errors when maximum likelihood is requested.
	if "`mlikelihood'" != "" {
		if "`link'" != "probit" {
			display as error "Option link() not allowed in maximum likelihood estimation."
			exit
		}
		if `polynomial' != 0 {
			display as error "Option mlikelihood not allowed in polynomial estimation."
			exit
		}
		if "`semiparametric'" != "" {
			display as error "Option mlikelihood not allowed in semiparametric estimation."
			exit
		}
	}
	
	*Create the xvalues matrix.
	tempname mtexs
	if "`xvalues'" == "" {
		quietly mean `x' if `touse'
		matrix `mtexs' = e(b)
	}
	else {
		*Make sure the correct number of xvalues have been provided.
		if wordcount("`x'") > wordcount(subinstr("`xvalues'", ",", " ", .)) {
			display in red `"Error: not enough x values provided."'
			exit
		}
		if wordcount("`x'") < wordcount(subinstr("`xvalues'", ",", " ", .)) {
			display in red `"Error: too many x values provided."'
			exit
		}		
		matrix `mtexs' = [`xvalues']
	}
	
	*************************************************************************************************
	* Define the propensity score variable, run the first step, and check the common support.		*
	*************************************************************************************************
	tempvar p
	tempname support evalgrid
	firstStep `y' `x' if `touse', `treatment' link(`link') p(`p') `semiparametric' `first' /* 
		*/`common' `commongraph' `csbarwidth' `mlikelihood' `constraints' `mlopts'
	*If requested, save the common support.
	if "`common'" != "" | "`semiparametric'" != "" {
		matrix `support' = r(support)
	}
	*Make the grid of Ud evaluation points. 
	if "`semiparametric'" != "" {
		matrix `evalgrid' = `support'
	}
	else {
		forvalues i = 1(1)99 {
			matrix `evalgrid' = [nullmat(`evalgrid') \ `i' / 100 ]
		}
	}
	*Save `p' if requested.
	if "`savepropensity'" != "" {
		quietly generate p = `p' if `touse'
		*Label the propensity score.
		label variable p "Propensity Score"
	}
	*************************************************************************************************
	* Match the link function and run the specified model.											*
	*************************************************************************************************
	if `polynomial' != 0 & "`semiparametric'" == "" {
		*The parametric polynomial model.
		if "`boot'" != "" {
			*Run the parametric polynomial model without bootstrapping the standard errors.
			parametric_polynomial `y' `x' if `touse', `treatment' p(`p') /*
					*/polynomial(`polynomial') mtexs(`mtexs') `constraints'
		}
		else {
			*Run the parametric polynomial model with bootstrapped standard errors.
			bootstrap, /*
					*/`bsopts' /*
					*/`bca' /*
					*/`level' /*
					*/ noheader /*
					*/ notable /*
				*/:parametric_polynomial `y' `x' if `touse', `treatment' p(`p') /*
					*/polynomial(`polynomial') mtexs(`mtexs') `constraints'
		}			
		ereturn local title2 	"Treatment Model: `capLink'"
		ereturn local title		"Parametric Polynomial MTE Model"
	}
	else if "`semiparametric'" != "" {
		*The semiparametric model.
		if "`boot'" != "" {
			*Run the semiparametric model without bootstrapping the standard errors.
			semiparametric `y' `x' if `touse', `treatment' p(`p') evalgrid(`evalgrid') /*
				*/mtexs(`mtexs') polynomial(`polynomial') `degree' `kernel' `ybwidth' `xbwidth'/*
				*/`constraints'
		}
		else {
			*Run the semiparametric model with bootstrapped standard errors.
			bootstrap, /*
					*/`bsopts' /*
					*/`bca' /*
					*/`level' /*
					*/ noheader /*
					*/ notable /*
				*/:semiparametric `y' `x' if `touse', `treatment' p(`p') evalgrid(`evalgrid') /*
					*/mtexs(`mtexs') polynomial(`polynomial') `degree' `kernel' `ybwidth' /*
					*/ `xbwidth' `constraints'
		}		
		ereturn local title2 	"Treatment Model: `capLink'"
		if `polynomial' == 0 {
			ereturn local title	"Semiparametric LIV MTE Model"
		}
		else {
			ereturn local title	"Semiparametric Polynomial MTE Model"
		}
	}
	else {
		*The parametric normal model.		
		if "`boot'" != "" {
			*Run the semiparametric model without bootstrapping the standard errors.
			parametric_normal `y' `x' if `touse', `treatment' p(`p') mtexs(`mtexs') /*
				*/`mlikelihood' `constraints' `mlopts'
		}
		else {
			*Run the parametric normal model with bootstrapped standard errors.
			bootstrap, /*
					*/`bsopts' /*
					*/`bca' /*
					*/`level' /*
					*/ noheader /*
					*/ notable /*
				*/:parametric_normal `y' `x' if `touse', `treatment' p(`p') mtexs(`mtexs') /*
					*/`mlikelihood' `constraints' `mlopts'
		}
		if "`mlikelihood'" != "" {
			*Modify e(V) to incorporate the ML results
			if "`boot'" == "" {
				*Combine the ML variance matrix with the ate and mte variance matrix.
				tempname VML V
				matrix `VML' 		= e(VML)
				local VMLnames		: colnames `VML'
				local VMLeqs		: coleq `VML'
				matrix `V'	 		= e(V)
				local Vnames		: colnames `V'
				local Veqs			: coleq `V'
				local VMLsize		= colsof(`VML')
				local Vsize			= colsof(`V')
				matrix `VML' 		= [`VML'\ J(`Vsize', `VMLsize', 0)]
				matrix `V'			= [J(`VMLsize', `Vsize', 0)\ `V']
				matrix `V'			= [`VML', `V']
				matrix rownames `V' = `VMLnames' `Vnames'
				matrix colnames `V' = `VMLnames' `Vnames'
				matrix roweq `V'	= `VMLeqs' `Veqs'
				matrix coleq `V'	= `VMLeqs' `Veqs'
				*Rearrange V for display purposes (put ATE before FirstStep)
				tempname Vt Vut Vm Vfs Vate Vmte
				forvalues i = 1(1)2 {
					*Parse e(V) by equation.
					matrix `Vt' 	= `V'[1..., "Treated:"]
					matrix `Vut' 	= `V'[1..., "Untreated:"]
					matrix `Vm' 	= `V'[1..., "Mills:"]
					matrix `Vfs' 	= `V'[1..., "FirstStep:"]
					matrix `Vate' 	= `V'[1..., "ATE:"]
					matrix `Vmte' 	= `V'[1..., "mte:"]
					*Rearrange.
					matrix `V' = [`Vt', `Vut', `Vm', `Vate', `Vfs', `Vmte']
					matrix `V' = `V''
				}
				ereturn repost V = `V'
			}
			ereturn local vce "oim"
			ereturn local vcetype "ML"
			ereturn local title2 "Maximum Likelihood Estimation"
		}
		else {
			ereturn local title2 "Treatment Model: Probit"
		}
		ereturn local title "Parametric Normal MTE Model"
	}
	
	*************************************************************************************************
	* Return the results.																			*
	*************************************************************************************************
	*Modify e() a bit for presentation's sake and to have the right values in cmd and cmdline.
	ereturn local cmd 		"margte"
	ereturn local cmdline 	"margte `0'"
	
	*Return the confidence interval matrices if the errors were bootstraped.
	if "`boot'" == "" {
		tempname mte_bc mte_bca mte_percentile mte_normal
		foreach ci in normal percentile `bca' bc {
			matrix `mte_`ci'' = e(ci_`ci')
			matrix `mte_`ci'' = `mte_`ci''[1..2, "mte:"]
			ereturn matrix mte_`ci' = `mte_`ci''
		}
	}
	
	*Return the main results matrices. This is not strictly necessary. We do it to get the order 
	*right when ereturn list is called.
	tempname ate mte
	matrix `ate'   = e(ate)
	matrix `mte'   = e(mte)
	ereturn matrix ate   = `ate'
	ereturn matrix mte   = `mte'
	if `polynomial' == 0 & "`semiparametric'" == "" {
		tempname vml fs treated untreated mills
		matrix `mills' 		= e(mills)
		matrix `untreated'	= e(untreated)
		matrix `treated'	= e(treated)
		ereturn matrix mills 		= `mills'
		ereturn matrix untreated	= `untreated'
		ereturn matrix treated		= `treated'
		if "`mlikelihood'" != "" {
			matrix `vml' = e(VML)
			ereturn matrix VML = `vml'		
		}
	}
	
	*Return the common support if requested.
	if "`common'" != "" | "`semiparametric'" != "" {
		ereturn matrix common = `support'
	}
	
	*************************************************************************************************
	* Display the results.																			*
	*************************************************************************************************
	if "`boot'" != "" {
		*Count the number of observations used and return them.
		quietly count if `touse'
		ereturn scalar N = `r(N)'
		
		_coef_table_header
		if `polynomial' != 0 | "`semiparametric'" != "" {
			_coef_table, `level' neq(2)
		}
		else {
			_coef_table, `level' neq(4)
		}
	}
	else {
		_coef_table_header
		if `polynomial' != 0 | "`semiparametric'" != "" {
			_coef_table, `level' neq(2)
		}
		else {
			_coef_table, `level' neq(4)
		}
	}
	
	*************************************************************************************************
	* Plot the results.																				*
	*************************************************************************************************
	if "`plot'" == "" mtePlot, `plotci' `level' evalgrid(`evalgrid') `boot'
end
}
*Program firstStep
{
program define firstStep, rclass	
	syntax varlist [if], Treatment(string) Link(string) P(namelist) [Semiparametric Common /*
		*/noCommongraph First CSBARwidth(real .01) MLikelihood CONSTraints(string) MLOpts(string)]
	
	marksample touse

	tokenize `varlist'
	local y "`1'"
	macro shift
	local x "`*'"
	
	tokenize `treatment'
	local d "`1'"
	macro shift
	local xz "`*'"
	
	if "`first'" != "" {
		local first ""
	}
	else {
		local first "quietly"
	}
	
	*Generate the propensity score.
	if "`mlikelihood'" != "" {
		display as text "Running maximum likelihood via movestay..."
		if "`first'" == "quietly" {
			display as text "Note: if Stata is churning for a long time, the likelihood " _continue
			display as text "function may not be concave."
			display as text `"Rerun margte with option "first" to see the maximum likelihood output."'
		}
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
		`first' movestay `y' `x' if `touse', select(`d' `xz') constraints(`constraints') `mlopts'
		quietly predict `p' if `touse', psel
		*Specify the start for the histogram range and the start and finish for the label range.
		local start 		-.005
		local startLabel	0
		local finishLabel 	1
	}
	else {
		if "`link'" == "lpm" {
			`first' regress `d' `xz' if `touse'
			quietly predict `p' if `touse', xb
			*Specify the start for the histogram range and the start and finish for the label range.
			quietly summarize `p' if `touse'
			local minp   		= r(min)
			local start			= floor(100 * `minp') / 100 - .005
			local startLabel 	= floor(10  * `minp') / 10
			local maxp   		= r(max)
			local finishLabel 	= ceil(10   * `maxp') / 10
		}
		else if "`link'" == "logit" {
			`first' logit `d' `xz' if `touse'
			quietly predict `p' if `touse', pr
			*Specify the start for the histogram range and the start and finish for the label range.
			local start 		-.005
			local startLabel	0
			local finishLabel 	1
		}
		else {
			`first' probit `d' `xz' if `touse'
			quietly predict `p' if `touse', pr
			*Specify the start for the histogram range and the start and finish for the label range.
			local start 		-.005
			local startLabel	0
			local finishLabel 	1
		}
	}
	
	*Determine the common support and graph it.
	if "`common'" != "" | "`semiparametric'" != "" {
		*These commands generate the density for neighborhoods of +/- .005 around hundredths of the 
		*propensity score.
		tempvar h0 h1 d0 d1
		twoway__histogram_gen `p' if `d' == 1 & `touse', width(.01) start(`start') /*
			*/generate(`h1' `d1', replace)
		twoway__histogram_gen `p' if `d' == 0 & `touse', width(.01) start(`start') /*
			*/generate(`h0' `d0', replace)
		
		*Generate the common support grid and save it as a matrix.
		*Go through each value of the support for d = 1.
		tempname support
		local i = 1
		while `d1'[`i'] != . {
			*Go through each value of the support for d = 0.
			local j = 1
			while `d0'[`j'] != . {
				*If there is common support and it's between 0 and 1, save it.
				if `d1'[`i'] == `d0'[`j'] & 0 < `d1'[`i'] & `d1'[`i'] < 1 {
					matrix `support' = [nullmat(`support') \ round(`d1'[`i'], .01)]
				}
				local j = `j' + 1
			}
			local i = `i' + 1
		}
		return matrix support = `support' 		
		
		if "`commongraph'" == "" {
			*Plot the common support of the propensity score.
			*Note: .01138 is the barwidth for a good looking 6.5" by 8.95" graph. 0.1 will give a 
			*consistent appearance.
			quietly twoway /*
				*/(bar `h1' `d1', fcolor(eltblue) lcolor(eltblue) barwidth(`csbarwidth'))  /*
				*/(bar `h0' `d0', fcolor(none)    lcolor(edkblue) barwidth(`csbarwidth')), /*
				*/xtitle(Propensity Score) xlabel(`startLabel'(.1)`finishLabel') /*
				*/title(Frequency of Propensity Score by Treatment Status) /*
				*/legend(order(1 "Treated" 2 "Untreated")) /*
				*/name("commonSupport", replace) nodraw
			*I name the graph and display it so I can see both the common support and mtes.
			graph display commonSupport
		}
	}
end
}
*Program mtePlot
{
program define mtePlot
	syntax , EVALgrid(namelist) [Plotci(namelist) Level(cilevel) noBoot]
	
	*Set the default confidence interval type.
	if "`plotci'" == "" {
		local plotci normal
	}
	
	***Construct and graph the variables.
	tempvar mte ud mte`plotci'LL mte`plotci'UL 
	
	*Generate the mte variable.
	tempname mte
	matrix `mte' = e(mte)
	*Count the number of points to graph.
	local count = colsof(`mte')
	quietly generate `mte' = `mte'[1, _n] in 1/`count'
	label variable `mte' "MTE"
	
	*Generate ud.
	quietly generate `ud' = `evalgrid'[_n, 1] in 1/`count'
	label variable `ud'	"U_D"
	
	*Get the ATE.
	tempname ate
	matrix `ate' = e(ate)
	local ate = round(`ate'[1, 1], .01)
		
	*Generate the requested confidence intervals.
	tempname mte`plotci'
	matrix `mte`plotci'' = e(mte_`plotci')
	quietly generate `mte`plotci'LL' = `mte`plotci''[1, _n] in 1/`count'
	quietly generate `mte`plotci'UL' = `mte`plotci''[2, _n] in 1/`count'
	
	local ciLegend = substr("`plotci'", 1, 4)
	if "`boot'" != "" {
		quietly twoway (function `mte' = `ate', range(`ud') lcolor(maroon) lpattern(dash)) /*
			*/(line `mte' `ud', lcolor(navy)), /*
			*/legend(order(2 "MTE" 1 "ATE = `ate'")) /*
			*/title("Estimated Marginal Treatment Effects") name("MTEPlot", replace)
	}
	else {
		quietly twoway (rarea `mte`plotci'LL' `mte`plotci'UL' `ud', fcolor(gs11) lcolor(gs12)) /* 
			*/(function `mte' = `ate', range(`ud') lcolor(maroon) lpattern(dash))  /*
			*/(line `mte' `ud', lcolor(navy)), /*
			*/legend(order(3 "MTE" 2 "ATE = `ate'" 1 "`level'% `ciLegend' CI")) /*
			*/title("Estimated Marginal Treatment Effects") name("MTEPlot", replace)
	}
end
}
