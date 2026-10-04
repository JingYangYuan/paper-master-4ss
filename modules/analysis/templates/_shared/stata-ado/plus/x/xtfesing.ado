*! Program to produce the Bruno, Magazzini, Stampini (2019) estimator
*! that exploits information from singletons within a fixed effect framework

program define xtfesing
	version 11.0
	if replay() {
		if ("`e(cmd)'" != "xtfesing") error 301
		xtfesing_output `0'
		}
	else xtfesing_est `0'
end


program define xtfesing_est, eclass sortpreserve
    version 11.0
	syntax varlist(numeric) [if] [in]  [, Id(varname numeric) Level(cilevel) noWindmeijer]
	
	preserve
	
	quietly{
	
	marksample touse
	
	if `"`id'"' == "" {
		// id variable not specified
		// check if panel dimensions have been specified
		capture _xt
		if _rc!=0 {
			di as error "must specify panelvar (use xtset) or the option id()"
			exit 459
		}
		else {
			// xtset has been specified: we set id = panelvar
			tempvar id
			gen `id' = `_dta[_TSpanel]'
			local panelvarname = "`_dta[_TSpanel]'"	
		}
	}
	else {
		// else id is specified by the user
		// however, I need the variable name for the output
		local panelvarname = "`id'"
	}
	
	// if the variable id contains missing values, the corresponding observation is not used in estimation
	markout `touse' `id'
	keep if `touse'
	
	tokenize `varlist'
    // count the number of variables in varlist
	local k = 1     // count the number of arguments
	while "``k''" != "" { 
	     local ++k
	}
	local --k // k contains one too many
	// now k contains the number of variables in varlist (y + regressors)

    local y "`1'"
	macro shift 1
    local x "`*'"
	local --k
    // now k contains the number of regressors
	
	sort `id'

	* remove time-invariant variables from the list
	local xtv
	local ktv=0
	tempvar meanx demeaned2
	foreach var in `x' {
	   * check that the variables on the rhs are not time-invariant
	   //xtsum `var'
	   //ztsum can only be used if the data have already been xtset
	   by `id': egen `meanx' = mean(`var')
	   gen `demeaned2' = (`var'-`meanx')^2
	   summ `demeaned2'
	   if r(sd)>0 {
	       local xtv "`xtv' `var'"
		   local ++ktv
		   }
		else {
		   noi di as text "note: `var' omitted because time-invariant in the selected data"
		   }   
	   drop `meanx' `demeaned2'
	}
	
	local x "`xtv'"
	local k "`ktv'"
	
	// identify panel observations and singleton
	tempvar balobs countobs 
	
	by `id': egen `countobs'=count(`y')
	gen `balobs'=0
    replace `balobs'=1 if `countobs'>1
	local xobs = "`balobs'"
	
	summ `countobs'
	if  r(min) > 1 {
	   di as error "no singleton to be exploited"
	   error 100
	   }
	if  r(max) <2 {
	   di as error "cross-sectional data: xtfesing cannot be applied"
	   error 100
	   }
	   
	// check for multicollinearity in the independent variables
	noi _rmcoll `x', forcedrop
	local x `r(varlist)'
	local k = `k'-`r(k_omitted)'
	
	// define GMM equation and variables
	tempvar ycs
    gen `ycs' = `y' if `balobs'==0
    local i=1
	local consreg "(consreg: `y' "
	local biasreg "(biasreg: `y' "
	local biasregcs "(biasregcs: `ycs'  "
	
	local instrconsreg "instruments(consreg: "
	local instrbiasreg "instruments(biasreg: "
	local instrbiasregcs "instruments(biasregcs: "
	
	local listzFE 
	local listzOLS
	local listzOLSs
	
	// columnName and columnNameB will be used after the estimation 
	// to better name estimated coefficients
	local columnName ""
	local columnNameB ""
	foreach var in `x' {
		local columnName `"`columnName' beta:`var'"'
		local columnNameB `"`columnNameB' bias:`var'"'
		
		// variables for homogeneity test
		tempvar `var'_obs
		gen ``var'_obs' = (`var')*(`balobs')
		local xobs  = `"`xobs' ``var'_obs'"'
		
		// define variables used in estimation and GMM equations
	     tempvar `var'i  `var'dem `var'cs
		 by `id' : egen ``var'i' = mean(`var')
		 gen ``var'dem' = `var'-``var'i'
		 gen ``var'cs' = `var' if `balobs'==0
		 
		 local consreg  =  `"`consreg' -{b`i'}*`var' "'
		 local biasreg  =  `"`biasreg' - ({b`i'}+{d`i'})*`var' "'
		 local biasregcs  =  `"`biasregcs' - ({b`i'}+{d`i'})*``var'cs' "'
		 
		 local instrconsreg  =  `"`instrconsreg' ``var'dem' "'
		 local instrbiasreg  =  `"`instrbiasreg' `var' "'
		 local instrbiasregcs  =  `"`instrbiasregcs' ``var'cs' "'
		 
		 local listzFE = `"`listzFE' ``var'dem' "'
		 local listzOLS = `"`listzOLS' `var' "'
		 local listzOLSs = `"`listzOLSs' ``var'cs' "'

		 local ++i
	}
	
	local columnName `"`columnName' beta:_cons"'
	local columnNameB `"`columnNameB' bias:_cons"'
	local columnName `"`columnName'  `columnNameB'"'
	
   * HOMOGENEITY TEST
	reg `y' `x' `xobs' `weight', cluster(`id')
    test `xobs'
	tempname F_hom F_hom_p
    scalar `F_hom'=r(F)
	scalar `F_hom_p'=r(p)
	
	********************************************
	// include constant term in the GMM equations
	local consreg   `"`consreg' - {b0}  ) "' 
	local biasreg  =  `"`biasreg' - ({b0}+{d0}) ) "'
	local biasregcs  =  `"`biasregcs' - ({b0}+{d0}) ) "'
	
    local instrconsreg  =  `"`instrconsreg' )"'
	local instrbiasreg  =  `"`instrbiasreg' ) "'
	local instrbiasregcs  =  `"`instrbiasregcs' ) "'
	
	// First stage estimation of BMS-GMM 
	// Needed to recover V1 and first stage residuals
	// to be used in computations of the Windmeijer correction
	gmm `consreg' `biasreg' `biasregcs'  `weight' ,  `instrconsreg'  `instrbiasreg' `instrbiasregcs'  ///
	    onestep winitial(unadjusted, independent) nocommonesample vce(cluster `id')
	tempname V1
    mat `V1'=e(V)
	
	tempvar res1FE res1OLS res1OLSs

    predict `res1FE', res eq(1)
    predict `res1OLS', res eq(2)
    predict `res1OLSs', res eq(3)
    replace `res1OLSs'=0 if `balobs'==1
	
    // BMS estimator - GMM estimator that exploits singleton information
    gmm `consreg' `biasreg' `biasregcs' `weight',  `instrconsreg'  `instrbiasreg' `instrbiasregcs'  ///
	     twostep  winitial(unadjusted, independent) nocommonesample vce(cluster `id') wmatrix(cluster `id') 

	if `"`windmeijer'"' == "" {
		// the user has not specified the option nowindmeijer 
		// so that the correction is computed
		
		// computation of s.e. with Windmeijer formula
		tempname WN C 
		mat `WN' = e(W)
		mat `C' = e(G)

		tempvar res2FE res2OLS res2OLSs

		predict `res2FE', res eq(1)
		predict `res2OLS', res eq(2)
		predict `res2OLSs', res eq(3)
		replace `res2OLSs'=0 if `balobs'==1

		local mcfe=1
		local kk=`k'+1
		local g=1
		foreach var in `x' {
			// computation of first derivatives for the Windmeijer formula
			tempvar dresFE`g' dresOLS`g' dresOLSs`g' 
			gen `dresFE`g'' = -`var'
			gen `dresOLS`g'' = -`var'
			gen `dresOLSs`g'' = -`var'  if `balobs'==0
			replace `dresOLSs`g'' = 0  if `balobs'==1
	   
			local gg=`g'+`kk'
			tempvar dresFE`gg' dresOLS`gg' dresOLSs`gg' 
			gen `dresFE`gg'' = 0
			gen `dresOLS`gg'' = -`var'
			gen `dresOLSs`gg'' = -`var'  if `balobs'==0
			replace `dresOLSs`gg'' = 0  if `balobs'==1
	   
			local ++g
			
			// moreover, compute the moment conditions in the first stage estimate (g1)
			// and in the second stage estimate (g2)
			// -- the total number of moment condition is 3*kk = 3*k+1
			
			tempvar g1`mcfe' g2`mcfe' 
		
			gen `g1`mcfe''=``var'dem'*`res1FE'
			gen `g2`mcfe''=``var'dem'*`res2FE'
		
			local mcols=`mcfe'+`kk'	
			tempvar g1`mcols' g2`mcols' 
			gen `g1`mcols''=`var'*`res1OLS'
			gen `g2`mcols''=`var'*`res2OLS'
		
			local mcolss=`mcfe'+2*`kk'
			tempvar g1`mcolss' g2`mcolss' 
			gen `g1`mcolss''=`var'*`res1OLSs'
			gen `g2`mcolss''=`var'*`res2OLSs'
		
			local ++mcfe
		
		}
		//noi di as text "." _continue
		* first derivative with respect to the constant term
		tempvar dresFE`g' dresOLS`g' dresOLSs`g' 
		gen `dresFE`g''=-1
		gen `dresOLS`g''=-1
		gen `dresOLSs`g''=-1 if `balobs'==0
		replace `dresOLSs`g''=0 if `balobs'==1
	
		local gg=`g'+`kk'
		tempvar dresFE`gg' dresOLS`gg' dresOLSs`gg' 
		gen `dresFE`gg''=0
		gen `dresOLS`gg''=-1
		gen `dresOLSs`gg''=-1  if `balobs'==0
		replace `dresOLSs`gg''=0 if `balobs'==1
			
		* moment conditions based on the constant term
		tempvar g1`mcfe' g2`mcfe' 
		gen `g1`mcfe''=1*`res1FE'
		gen `g2`mcfe''=1*`res2FE'
		
		local mcols=`mcfe'+`kk'
		tempvar g1`mcols' g2`mcols' 
		gen `g1`mcols''=1*`res1OLS'
		gen `g2`mcols''=1*`res2OLS'
		
		local mcolss=`mcfe'+2*`kk'
		tempvar g1`mcolss' g2`mcolss' 
		gen `g1`mcolss''=1*`res1OLSs'
		gen `g2`mcolss''=1*`res2OLSs'

		local ElencoG1 
		tempname meang
		forvalues gg=1/`mcolss' {
			summ `g2`gg''
			matrix `meang' = (nullmat(`meang')  \ r(mean))
			
			local ElencoG1 "`ElencoG1' `g1`gg''"
		}
    
		local gg=1
		local 2kk=2*`kk'
	
		//noi di as text "." _continue
		foreach zzz in `listzFE'  {
			forvalues pp=1/`kk' {
				** pp is related to beta
				** and pp+kk=bb is related to the bias
								
				* first derivative wrt beta
				tempvar dg_`gg'_`pp'
				gen `dg_`gg'_`pp'' = `zzz'*`dresFE`pp''
			
				* first derivative wrt bias
				local bb=`pp'+`kk'
				tempvar dg_`gg'_`bb'
				gen `dg_`gg'_`bb'' = `zzz'*`dresFE`bb''
			
			}
			local ++gg
		}
		
		// mc related to the constant term
		forvalues pp=1/`2kk'  {
			tempvar dg_`gg'_`pp'
			gen `dg_`gg'_`pp'' = 1*`dresFE`pp''
		}
		local ++gg
	
		//noi di as text "." _continue
		foreach zzz in `listzOLS'  {
			forvalues pp=1/`kk' {
		
				tempvar dg_`gg'_`pp'
				gen `dg_`gg'_`pp'' = `zzz'*`dresOLS`pp''
			
				local bb=`pp'+`kk'
				tempvar dg_`gg'_`bb'
				gen `dg_`gg'_`bb'' = `zzz'*`dresOLS`bb''
			
			}
			local ++gg
		}
		forvalues pp=1/`2kk'  {
			tempvar dg_`gg'_`pp'
			gen `dg_`gg'_`pp'' = 1*`dresOLS`pp''
		}
		local ++gg
	
		//noi di as text "." _continue
		foreach zzz in `listzOLSs'  {
			forvalues pp=1/`kk' {
		
				tempvar dg_`gg'_`pp'
				gen `dg_`gg'_`pp'' = `zzz'*`dresOLSs`pp''
				replace `dg_`gg'_`pp'' = 0 if `balobs'==1
			
				local bb=`pp'+`kk'
				tempvar dg_`gg'_`bb'
				gen `dg_`gg'_`bb'' = `zzz'*`dresOLSs`bb''
				replace `dg_`gg'_`bb'' = 0 if `balobs'==1
			
			}
			local ++gg
		}
		forvalues pp=1/`2kk'  {
			tempvar dg_`gg'_`pp'
			gen `dg_`gg'_`pp'' = 1*`dresOLSs`pp''
			replace `dg_`gg'_`pp'' = 0 if `balobs'==1
			}
	 
		tempname correz invCWC colD D VC correzione VUNC
		mat `correz' = J(colsof(`V1'),colsof(`V1'),0)
		mat `colD' = J(colsof(`V1'),1,0)
		mat `invCWC' = invsym((`C')'*`WN'*`C')

		//noi di as text "." 
		forvalues ii=1/`2kk' {
			local ElencoDG`ii'
			forvalues jj=1/`gg'  {
				local ElencoDG`ii' = "`ElencoDG`ii''   `dg_`jj'_`ii''   "
			}
			mata: calccolD("`ElencoDG`ii''","`ElencoG1'","`invCWC'","`C'","`WN'","`meang'","`colD'")	
			mat `D' = (nullmat(`D'),`colD')
		}
		mat `D'=`D'/e(N)	 
    
		mat `VUNC' = (1/e(N))*`invCWC'
		mat `correzione' = (1/e(N))*(`D'*`invCWC'+`invCWC'*(`D')') + `D'*`V1'*(`D')'
	 
		mat `VC' = `VUNC'+`correzione'
		
		// Substitute the Windmeijer corrected matrix into V
		// Save old e(V) as uncorrected matrix (Vunc)
		tempname matV
		matrix `matV' = e(V)
		matrix colname `matV' = `columnName'
		matrix rowname `matV' = `columnName'
		ereturn repost V = `VC'
	}
	
	// store estimation results
	tempname rank nobs valQ valJ J_df converged n_eq kkk n_moments N_clust
	scalar `rank'=e(rank)
	scalar `nobs'=e(N)
	scalar `valQ'=e(Q)
	scalar `valJ'=e(J)
	scalar `J_df'=e(J_df)
	scalar `converged'=e(converged)
	scalar `n_eq'=e(n_eq)
	scalar `kkk'=e(k)
	scalar `n_moments'=e(n_moments)
	scalar `N_clust'=e(N_clust)
	
	tempname initval valS valW matB matVV
	matrix `initval'=e(init)
	matrix `valS'=e(S)
	matrix `valW'=e(W)
	
	matrix `matB' = e(b)
	matrix colname `matB' = `columnName'
	// in matV we saved V-uncorrected if the nowind option is not specified
	matrix `matVV' = e(V)
	matrix colname `matVV' = `columnName'
	matrix rowname `matVV' = `columnName'
	
	// now clear what's in e() and only keep selected outcomes
	estimates clear
	
	ereturn post `matB' `matVV', esample(`touse')
	
	ereturn scalar rank = `rank'
	ereturn scalar N = `nobs'
	ereturn scalar Q = `valQ'
	ereturn scalar J =`valJ'
	ereturn scalar J_df = `J_df'
	ereturn scalar converged = `converged'
	ereturn scalar n_eq = `n_eq'
	ereturn scalar k = `kkk'
	ereturn scalar n_moments =`n_moments'
	ereturn scalar N_clust = `N_clust'
	// store results of regression-based homogeneity test
	ereturn scalar F_hom=`F_hom' 
	ereturn scalar F_hom_p=`F_hom_p'
	// singleton count
	qui summ `balobs' if `balobs'==0
	local retNS = r(N)
	ereturn scalar NS = `retNS' 
	
	ereturn local nocommonesample "nocommonesample"
	ereturn local winit "Unadjusted"
	ereturn local estimator "twostep"
	ereturn local wmatrix "cluster `panelvarname'"
	ereturn local vce "cluster"
	ereturn local vcetype "Robust"
	
	ereturn local clustvar = "`panelvarname'"
	
	ereturn local predict "xtfesing_p"
	
	ereturn local rhs `x'
	ereturn local depvar `y'
	ereturn local cmdline "xtfesing `0'"
	ereturn local cmd "xtfesing"
	
	ereturn matrix init `initval' 
	ereturn matrix S `valS' 
	ereturn matrix W `valW' 
	
	if `"`matV'"' != ""  {
		ereturn matrix Vunc `matV' 
	}
	
	
	}
	
	xtfesing_output , level(`level')
	
end



program define xtfesing_output 

	syntax [, LEVel(cilevel) ]
	
	if "`level'" == "" {
       `level' = c(level)
    }
	
	local percS=e(NS)/e(N_clust)*100
	
	display as text _newline   "GMM estimation results"  _newline
	di as text "Total number of observations " as result %9.0g e(N)
	di as text "       Total number of units " as result %9.0g e(N_clust) 
	di as text "        Number of singletons " as result %9.0g e(NS) as text " (" as result %4.2f `percS' "%" as text " of total n. of units)" _newline
	
	ereturn display, level(`level')
	
	local hansenjp = 1-chi2(e(J_df),e(J))
    display as text "Hansen-based test of homogeneity:        J = " as result %9.2fc e(J) ///
	        as text " (p-value = " as result %9.3fc `hansenjp' as text ")"
    
	display as text "Regression-based test of homogeneity:    F = " as result %9.2fc  e(F_hom)  ///
	        as text " (p-value = " as result %9.3fc e(F_hom_p) as text ")"
	
	display in smcl "{hline 78}"
	
end


*******************************************************************************
version 11.0

mata:
void calccolD(string scalar ElencoDG,string scalar ElencoG1, string scalar invCWC, string scalar C, string scalar WN, string scalar meang, string scalar colD)
{
    real matrix dwd
	real matrix ggg
	real matrix dggg
	
	ggg=st_data(.,ElencoG1)
	dggg=st_data(.,ElencoDG)
	minvCWC = st_matrix(invCWC)
	mC = st_matrix(C)
	mWN = st_matrix(WN)
	mmeang = st_matrix(meang)
	
	dwd = (((ggg)'*dggg)+((dggg)'*ggg))
	mcolD = minvCWC*(mC)'*mWN*dwd*mWN*mmeang
	
	st_matrix(colD,mcolD)
	
}	 
end

