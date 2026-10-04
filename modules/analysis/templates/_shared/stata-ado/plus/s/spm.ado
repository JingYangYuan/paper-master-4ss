*! version 1.1.0  11may2015

** Versioning at the end of the file

prog define spm, eclass prop(xt swml)

syntax varlist [if] [in]  [, SARWmat(namelist min=1) SEMWmat(namelist min=1) ///
							 SARW2mat(namelist min=1) SEMW2mat(namelist min=1) ///
							 Model(string) EFFects(string) TYPE(string) ///
							 DURBin(string) POOLED WITHINONLY BETWEENONLY ///
							 Level(cilevel) DETREND QUADRATIC CUBIC DROBust(namelist max=1) ///
							 ROBust MAXITerations(real 100) TECHnique(string) ///
							 LEEYU LRXTREG NOCONStant POSTVARIANCE POSTSCORE POSTHESSIAN *] 



*** Model: sar, sem, sarar, durbin
*** Effects: fe, re
*** Type: ind, time, both
*** GMM and IV must be explicitly specified
*** Default model: SAR, fe, ind
if "`model'" == "" local model "sar"
if "`effects'" == "" local effects "fe"
if "`type'" == "" local type "ind"

if "`noconstant'"!= "" local noconst 1
else local noconst 0
if "`technique'"!="" local technique "`technique'"
else local technique "nr"

/// Parsing of display options
_get_diopts diopts options, `options'

/// ERRORS

*** Set sarwmat and sarw2mat local as wmat and w2mat only because we are lazy 
if "`sarwmat'" != "" local wmat "`sarwmat'"
if "`sarw2mat'" != "" local w2mat "`sarw2mat'"
if "`drobust'" != "" {
	local wclust "`drobust'"
	local drobust "drobust"
}

if "`model'" == "sar" & "`sarwmat'" == "" {
	if "`semwmat'" == "" noi di as err "Option " in yel "sarwmat" in red " must be specified."
	else noi di as err "Model " in yel "sem" in red " must be specified."
    error 198
    exit	
}

if "`model'" == "sem" & "`semwmat'" == "" {
	noi di as err "Option " in yel "semwmat" in red " must be specified."
    error 198
    exit	
}

if "`model'" == "sarar" & "`sarwmat'" == "" & "`semwmat'" == "" {
	noi di as err "Option " in yel "sarwmat" in red " and " in yel "semwmat" in red " must be specified."
    error 198
    exit	
}

if "`sarw2mat'" != "" local w2yes 1 
else local w2yes 0
if "`semw2mat'" != "" local semw2yes 1
else local semw2yes 0
if "`withinonly'" != "" local within 1
else local within 0
if "`betweenonly'" != "" local between 1
else local between 0

if "`model'" == "sarar" {
	if (`w2yes' == 0  & `semw2yes' == 1) | (`w2yes' == 1  & `semw2yes' == 0) {
		noi di as err "Both " in yel "sarw2mat" in red " and " in yel "semw2mat" in red " must be specified."
		error 198
		exit	
	}
}

if "`model'" != "durbin" & "`durbin'" != "" {
	noi di as err "Option " in yel "durbin" in red " cannot be specified with " in yel "`model'" in red " model."
    error 198
    exit		
}

if "`model'" == "durbin" & "`semwmat'" != "" {
	noi di as error in yel "semwmat " in red "cannot be specified in SDM models"
	error 198
    exit	
}

if "`effects'" == "re" & "`detrend'" != "" {
	noi di as error in yel "Detrending " in red "not allowed in RE models"
	error 198
    exit	
}

/*
if ("`model'" == "sem" | "`model'" == "durbin" | "`model'" == "sar") & "`leeyu'" != "" {
	noi di as error "Option " in yel "leeyu " in red "cannot be specified" in red " in `model' models"
	error 198
    exit	
}
*/

*** Check for Panel setup                             
_xt, trequired

*** Mark sample
marksample touse

*** First parsing
gettoken lhs rhs: varlist 
if "`durbin'" != "" {
	gettoken durbin indirect: durbin, parse(",")
	local indirect = regexr("`indirect'",",","")
	ParseIndirect indirect nsim : `"`indirect'"'
}

*** Parsing of display options
_get_diopts diopts options, `options'

*** Remove collinearity 
cap noi _rmcoll `rhs' if `touse'
local rhs `r(varlist)'
local lhsname "`lhs'"
local rhsnames "`rhs'"

if "`durbin'" != "" {
	cap noi _rmcoll `durbin' if `touse'
	local durbin `r(varlist)'
}

if "`model'"=="durbin" {
	if "`durbin'"=="" {
		local durbin "`rhs'"
		di ""
		di in yel "Warning: All the specified regressors will be spatially lagged."
		di ""
	}
	local durbinnames "`durbin'"
	local _kd: word count `durbin'
	if `w2yes' == 1 local _kd = `_kd'*2
}
local _kr: word count `rhs'
scalar _skr = `_kr'

*** Fix the esample
markout `touse' `rhs' `durbin'

qui count if `touse'==1 
local obs = r(N)

local id: char _dta[_TSpanel]
local time: char _dta[_TStvar]
tempvar temp_id temp_t
qui egen `temp_id'=group(`id') if `touse'==1
sort `temp_id' `time'
qui by `temp_id': g `temp_t' = _n if `temp_id'!=.

********************** Display info ********************** 
tempvar Ti 
tempname S_E_T g_min g_avg g_max
qui by `temp_id': gen long `Ti' = _N if _n==_N & `touse'==1
qui summ `Ti' if `touse'==1
scalar `S_E_T' = r(max)
scalar `g_min' = r(min)
scalar `g_avg' = r(mean)
scalar g_max = r(max)
local g_max = g_max
local check = g_max
qui count if `Ti'<.
scalar N_g = r(N)
local N_g = N_g




*** Check for balanced panel and W number-consistency

*** SAR component

if "`wmat'" != "" { 
	local nwmat: word count `wmat'
	if `nwmat' == 1 {
		forvalues mat=1/`check' {
			local newwmat "`newwmat' `wmat'"
		}
		local wmat "`newwmat'"
	}
	else {
		if `nwmat' != `check' {
			noi di as err "As many " in yel "`: word 1 of `wmat''" in red " matrices as panel lenght" in yel " (`check')" in red " must be specified."
			error 198
			exit	
		}
	}
	
	
	if `w2yes'==1 {
		local nw2mat: word count `w2mat'
		if `nw2mat' == 1 {
			forvalues mat=1/`check' {
				local neww2mat "`neww2mat' `w2mat'"
			}
			local w2mat "`neww2mat'"
		}
		else {
			if `nw2mat' != `check' {
				noi di as err "As many " in yel "`: word 1 of `w2mat''" in red " matrices as panel lenght" in yel " (`check')" in red " must be specified."
				error 198
				exit	
			}
		}
	}
}


*** SEM component 
	
if "`semwmat'" != "" {

	local nwmat: word count `semwmat'
	if `nwmat' == 1 {
		forvalues mat=1/`check' {
			local newsemwmat "`newsemwmat' `semwmat'"
		}
		local semwmat "`newsemwmat'"
	}
	else {
		if `nwmat' != `check' {
			noi di as err "As many " in yel "`: word 1 of `semwmat''" in red " matrices as panel lenght" in yel " (`check')" in red " must be specified."
			error 198
			exit	
		}
	}
	
	
	if `semw2yes'==1 {
		local nw2mat: word count `semw2mat'
		if `nw2mat' == 1 {
			forvalues mat=1/`check' {
				local newsemw2mat "`newsemw2mat' `semw2mat'"
			}
			local semw2mat "`newsemw2mat'"
		}
		else {
			if `nw2mat' != `check' {
				noi di as err "As many " in yel "`: word 1 of `semw2mat''" in red " matrices as panel lenght" in yel " (`check')" in red " must be specified."
				error 198
				exit	
			}
		}
	}

}

*** Structure definition to make computation efficient (and generalizable to panel unbalanced case)

if "`wmat'" != "" { 
	local w_num = 1
	mata: _w = J(1, `g_max' ,_spm_WMAT())
	foreach w of local wmat {
		mata: _w = _spm_GeT_mOrE_w("`model'", "`w'", `w_num', _w)	
		local w_num = `w_num' + 1
	}
	
	*** Parsing into the structure of the dclust matrix
	if "`wclust'" != "" mata: _w = _spm_GeT_wclust("`wclust'", 1, _w)	
	
	if `w2yes'==1 {
		local w_num = 1
		foreach w2 of local w2mat {
			mata: _w = _spm_GeT_mOrE_w2("`model'", "`w2'", `w_num', _w)	
			local w_num = `w_num' + 1
		}
	}
}

if "`semwmat'" != "" { 
	local w_num = 1
	mata: _w = J(1, `g_max' ,_spm_WMAT())
	foreach w of local semwmat {
		mata: _w = _spm_GeT_mOrE_w("`model'", "`w'", `w_num', _w)	
		local w_num = `w_num' + 1
	}
	
	if `semw2yes'==1 {
		local w_num = 1
		foreach w2 of local semw2mat {
			mata: _w = _spm_GeT_mOrE_w2("`model'", "`w2'", `w_num', _w)	
			local w_num = `w_num' + 1
		}
	}
}





if "`effects'" == "fe" {
	
	if "`model'" == "sar" | "`model'" == "durbin" {
		
		*** This is to get WY 
		tempvar wy
		qui gen `wy'=.
		
		local ii=1
		mata: wy = J(0,3,.)
		**mata: eigen = J(0,1,.)
		foreach w of local wmat {
			mata: w`ii' = st_matrix("`w'")
			tempvar y`ii'
			qui gen `y`ii'' = `lhs' if `temp_t'==`ii'
			mata: y`ii' = st_data(.,tokens("`y`ii''"),tokens("`touse'"))
			mata: y`ii' = select(y`ii', rowmissing(y`ii'):==0)
			**mata: eigen`ii' = eigenvalues(w`ii')'
			mata: wy`ii' = (w`ii' * y`ii'),(1::rows(y`ii')),(J(rows(y`ii'),1,`ii'))
			** This is for stack W_t and eigen_t
			**mata: eigen = eigen	\ eigen`ii'
			mata: wy = wy \ wy`ii'
			local ii = `ii'+1
		}
		mata: st_view(__esample=., ., "`touse'")
		mata: __rule = mm_which(__esample)
		mata: wy = sort(wy,(2,3))
		mata: st_store(__rule,"`wy'",wy[.,1])
	
		if "`model'" == "durbin" {
			*** This is to get WX 
			
			foreach r of local durbin {
				tempvar wx`r'
				qui gen `wx`r''=.
				
				local ii=1
				mata: wx = J(0,3,.)
				**mata: eigen = J(0,1,.)
				foreach w of local wmat {
					mata: w`ii' = st_matrix("`w'")
					tempvar x`ii'
					qui gen `x`ii'' = `r' if `temp_t'==`ii'
					mata: x`ii' = st_data(.,tokens("`x`ii''"),tokens("`touse'"))
					mata: x`ii' = select(x`ii', rowmissing(x`ii'):==0)
					mata: wx`ii' = (w`ii' * x`ii'),(1::rows(x`ii')),(J(rows(x`ii'),1,`ii'))
					mata: wx = wx \ wx`ii'
					local ii = `ii'+1
				}
				mata: st_view(__esample=., ., "`touse'")
				mata: __rule = mm_which(__esample)
				mata: wx = sort(wx,(2,3))
				mata: st_store(__rule,"`wx`r''",wx[.,1])
				local durbin_vars "`durbin_vars' `wx`r''"
			}
		}	

		if "`w2mat'"!="" {
			*** This is to get W2Y 
			tempvar w2y
			qui gen `w2y'=.
			
			local ii=1
			mata: w2y = J(0,3,.)
			**mata: eigen = J(0,1,.)
			foreach w2 of local w2mat {
				mata: w2`ii' = st_matrix("`w2'")
				tempvar y`ii'
				qui gen `y`ii'' = `lhs' if `temp_t'==`ii'
				mata: y`ii' = st_data(.,tokens("`y`ii''"),tokens("`touse'"))
				mata: y`ii' = select(y`ii', rowmissing(y`ii'):==0)
				**mata: eigen`ii' = eigenvalues(w`ii')'
				mata: w2y`ii' = (w2`ii' * y`ii'),(1::rows(y`ii')),(J(rows(y`ii'),1,`ii'))
				** This is for stack W_t and eigen_t
				**mata: eigen = eigen	\ eigen`ii'
				mata: w2y = w2y \ w2y`ii'
				local ii = `ii'+1
			}
			mata: st_view(__esample=., ., "`touse'")
			mata: __rule = mm_which(__esample)
			mata: w2y = sort(w2y,(2,3))
			mata: st_store(__rule,"`w2y'",w2y[.,1])
			
			
			if "`model'" == "durbin" {
				*** This is to get W2X 

				foreach r of local durbin {
					tempvar w2x`r'
					qui gen `w2x`r''=.

					local ii=1
					mata: w2x = J(0,3,.)
					**mata: eigen = J(0,1,.)
					foreach w2 of local w2mat {
						mata: w2`ii' = st_matrix("`w2'")
						tempvar x2`ii'
						qui gen `x2`ii'' = `r' if `temp_t'==`ii'
						mata: x2`ii' = st_data(.,tokens("`x2`ii''"),tokens("`touse'"))
						mata: x2`ii' = select(x2`ii', rowmissing(x2`ii'):==0)
						mata: w2x`ii' = (w2`ii' * x2`ii'),(1::rows(x2`ii')),(J(rows(x2`ii'),1,`ii'))
						mata: w2x = w2x \ w2x`ii'
						local ii = `ii'+1
					}
					mata: st_view(__esample=., ., "`touse'")
					mata: __rule = mm_which(__esample)
					mata: w2x = sort(w2x,(2,3))
					mata: st_store(__rule,"`w2x`r''",w2x[.,1])
					local durbin_vars2 "`durbin_vars2' `w2x`r''"
				}
			}			
		}	
	}
	
	if "`leeyu'" == "" & "`detrend'"=="" {
		** Fix variables for both SAR and SEM
		if "`model'" == "sar" {
			if "`w2mat'"==""  local varlist "`varlist' `wy'"
			else local varlist "`varlist' `wy' `w2y'"
		}
		if "`model'" == "durbin" {
			if "`w2mat'"==""  local varlist "`varlist' `durbin_vars' `wy'"
			else local varlist "`varlist' `durbin_vars' `durbin_vars2' `wy' `w2y'"	
		}
		foreach k of local varlist {
			tempvar mean_`k' mean1_`k' mean2_`k' demean_`k'
			if "`pooled'"=="" {				
				if "`type'" == "ind" qui egen double `mean_`k'' = mean(`k') if `touse'==1, by(`temp_id')
				if "`type'" == "time" qui egen double `mean_`k'' = mean(`k') if `touse'==1, by(`temp_t')
				if "`type'" == "both" {
					qui egen double `mean1_`k'' = mean(`k') if `touse'==1, by(`temp_id')
					qui egen double `mean2_`k'' = mean(`k'-`mean1_`k'') if `touse'==1, by(`temp_t')
				}	
				if "`type'" == "ind" | "`type'" == "time" qui gen double `demean_`k'' = `k' - `mean_`k'' if `touse'==1
				else qui gen double `demean_`k'' = `k' - `mean1_`k'' - `mean2_`k'' if `touse'==1
			}
			else gen `demean_`k'' = `k'
			local newvarlist "`newvarlist' `demean_`k''"
		}
	}
	else {
		if "`model'" == "sarar" | "`model'" == "sem"  local newvarlist "`varlist'"	
		if "`model'" == "sar" {
			if "`w2mat'"==""  local newvarlist "`varlist' `wy'"
			else local newvarlist "`varlist' `wy' `w2y'"
		}
		if "`model'" == "durbin" {
			if "`w2mat'"==""  local newvarlist "`varlist' `durbin_vars' `wy'"
			else local newvarlist "`varlist' `durbin_vars' `durbin_vars2' `wy' `w2y'"	
		}
	}
}
if "`effects'" == "re" {
	
	
	local newmeanlist
	** Fix variables for SAR & DURBIN
	
	foreach k of local varlist {
		tempvar tmean_`k' mean_`k' 	 
		
		qui egen double `tmean_`k'' = mean(`k') if `touse'==1, by(`temp_id')
		qui gen double `mean_`k'' = .
		qui bys `temp_id': replace `mean_`k'' = `tmean_`k'' if _n == _N
				
		local newmeanlist "`newmeanlist' `mean_`k''"
	}
	
	if "`model'" == "durbin" {
	
			*** This is to get WX 
			
			foreach r of local durbin {
				tempvar wx`r'
				qui gen `wx`r''=.
				
				local ii=1
				mata: wx = J(0,3,.)
				**mata: eigen = J(0,1,.)
				foreach w of local wmat {
					mata: w`ii' = st_matrix("`w'")
					tempvar x`ii'
					qui gen `x`ii'' = `r' if `temp_t'==`ii'
					mata: x`ii' = st_data(.,tokens("`x`ii''"),tokens("`touse'"))
					mata: x`ii' = select(x`ii', rowmissing(x`ii'):==0)
					mata: wx`ii' = (w`ii' * x`ii'),(1::rows(x`ii')),(J(rows(x`ii'),1,`ii'))
					mata: wx = wx \ wx`ii'
					local ii = `ii'+1
				}
				mata: st_view(__esample=., ., "`touse'")
				mata: __rule = mm_which(__esample)
				mata: wx = sort(wx,(2,3))
				mata: st_store(__rule,"`wx`r''",wx[.,1])
				local durbin_vars "`durbin_vars' `wx`r''"
			}	

			if "`w2mat'" != "" {
				*** This is to get W2X 

				foreach r of local durbin {
					tempvar w2x`r'
					qui gen `w2x`r''=.

					local ii=1
					mata: w2x = J(0,3,.)
					**mata: eigen = J(0,1,.)
					foreach w2 of local w2mat {
						mata: w2`ii' = st_matrix("`w2'")
						tempvar x2`ii'
						qui gen `x2`ii'' = `r' if `temp_t'==`ii'
						mata: x2`ii' = st_data(.,tokens("`x2`ii''"),tokens("`touse'"))
						mata: x2`ii' = select(x2`ii', rowmissing(x2`ii'):==0)
						mata: w2x`ii' = (w2`ii' * x2`ii'),(1::rows(x2`ii')),(J(rows(x2`ii'),1,`ii'))
						mata: w2x = w2x \ w2x`ii'
						local ii = `ii'+1
					}
					mata: st_view(__esample=., ., "`touse'")
					mata: __rule = mm_which(__esample)
					mata: w2x = sort(w2x,(2,3))
					mata: st_store(__rule,"`w2x`r''",w2x[.,1])
					local durbin_vars2 "`durbin_vars2' `w2x`r''"
				}
			}	
			
		local newdmeanlist
		
		if "`w2mat'"=="" local adurbin_vars "`durbin_vars'"
		else local adurbin_vars "`durbin_vars' `durbin_vars2'"
				
		foreach k of local adurbin_vars {
			tempvar tdmean_`k' dmean_`k' 	 
			
			qui egen double `tdmean_`k'' = mean(`k') if `touse'==1, by(`temp_id')
			qui gen double `dmean_`k'' = .
			qui bys `temp_id': replace `dmean_`k'' = `tdmean_`k'' if _n == _N
						
			local newdmeanlist "`newdmeanlist' `dmean_`k''"
		}	
	}
	
}

// Indices for subsetting score and hessian matrices
if "`effects'"=="re" {
	local countrhsnames: word count `rhsnames'
	scalar countrhsnames = `countrhsnames'
}

*** second parsing

if "`effects'" == "fe" gettoken lhs rhs: newvarlist
else gettoken lhs rhs: varlist

if "`detrend'" != "" {
	
	sort `temp_id' `temp_t'
	mata: _detrended = _spm_data_detrend("`touse'","`temp_id' `temp_t'","`lhs'","`rhs'","`quadratic'","`cubic'")
	local varstodetrend "`lhs' `rhs'"
	foreach var of local varstodetrend {
		tempvar t`var'
		local detrendedvars "`detrendedvars' `t`var''"
	}
	qui getmata (`detrendedvars')=_detrended, replace
	gettoken lhs rhs: detrendedvars
}

sort `temp_t' `temp_id' 
local lxtset "`temp_id' `temp_t'"

mata: sv = _spm_est("`lxtset'","`lhs'", "`rhs'", "`model'", "`effects'", "`type'","`robust'", "`drobust'", "`leeyu'", `maxiterations', `g_max', `N_g', "`touse'", _w , `w2yes', `semw2yes', `noconst', "`newmeanlist'", "`adurbin_vars'", "`newdmeanlist'", "`technique'")
/// The following is nedeed to compute variance covariance matrix

if "`effects'" == "fe" {
	//if "`model'" == "sar" | "`model'" == "durbin" mata: _spm_sar_hessian_eval("`lxtset'","`lhs'", "`rhs'", `N_g', `g_max', "`touse'", "`robust'", "`leeyu'", sv, _w, `w2yes')
	if "`model'" == "sem" mata: _spm_sem_hessian_eval("`lxtset'","`lhs'", "`rhs'", `N_g', `g_max', "`touse'", "`robust'", "`leeyu'", sv, _w, `semw2yes')
	if "`model'" == "sarar" mata: _spm_sarar_hessian_eval("`lxtset'","`lhs'", "`rhs'", `N_g', `g_max', "`touse'", "`robust'", "`leeyu'", sv, _w, `w2yes', `semw2yes')
}


// Names for display
if "`effects'"=="re" {
	if `noconst'==0 local _cons _cons
	else local _cons
	local rhsnames "`rhsnames' `_cons'"
}

foreach name of local rhsnames {
	local _colnames "`_colnames' Main"
}

if "`model'" == "sarar" {
	if (`w2yes' == 0 & `semw2yes' == 0)  {
		local _regr_names "`rhsnames' rho lambda sigma2"
		local __colnames2 "`_colnames' Spatial Spatial Variance"
	}
	else if (`w2yes' == 1 & `semw2yes' == 1) {
		local _regr_names "`rhsnames' rho rho2 lambda lambda2 sigma2"
		local __colnames2 "`_colnames' Spatial Spatial Spatial Spatial Variance"
	}
}
if "`model'" == "sar" {
	if "`effects'"=="fe" {
		if `w2yes' == 0 {
			local _regr_names "`rhsnames' rho sigma2"
			local __colnames2 "`_colnames' Spatial Variance"
		}
		else {
			local _regr_names "`rhsnames' rho rho2 sigma2"
			local __colnames2 "`_colnames' Spatial Spatial Variance"
		}
	}
	else {
		if `w2yes' == 0 {
			local _regr_names "`rhsnames' rho theta sigma2"
			local __colnames2 "`_colnames' Spatial Variance Variance"
		}
		else {
			local _regr_names "`rhsnames' rho rho2 theta sigma2"
			local __colnames2 "`_colnames' Spatial Spatial Variance Variance"
		}				
	}
}
if "`model'" == "sem" {
	if `semw2yes' == 0 {
		local _regr_names "`rhsnames' lambda sigma2"
		local __colnames2 "`_colnames' Spatial Variance"
	}
	else {
		local _regr_names "`rhsnames' lambda lambda2 sigma2"
		local __colnames2 "`_colnames' Spatial Spatial Variance"
	}
}
if "`model'" == "durbin" {
	foreach name of local durbinnames {
		local _colnamesd "`_colnamesd' Durbin"
	}
	if "`effects'"=="fe" {
		if `w2yes' == 0 {
			local _regr_names "`rhsnames' `durbinnames' rho sigma2"
			local __colnames2 "`_colnames' `_colnamesd' Spatial Variance"
		}
		else {
			foreach name of local durbinnames {
				local _colnamesd2 "`_colnamesd2' Durbin2"
			}
			local _regr_names "`rhsnames' `durbinnames' `durbinnames' rho rho2 sigma2"
			local __colnames2 "`_colnames' `_colnamesd' `_colnamesd2' Spatial Spatial Variance"
		}
	}
	else {
		if `w2yes' == 0 {
			local _regr_names "`rhsnames' `durbinnames' rho theta sigma2"
			local __colnames2 "`_colnames' `_colnamesd' Spatial Variance Variance"
		}
		else {
			foreach name of local durbinnames {
				local _colnamesd2 "`_colnamesd2' Durbin2"
			}
			local _regr_names "`rhsnames' `durbinnames' `durbinnames' rho rho2 theta sigma2"
			local __colnames2 "`_colnames' `_colnamesd' `_colnamesd2' Spatial Spatial Variance Variance"
		}				
	}
}

/// Assign names
mat colnames b = `_regr_names' 
mat coleq b = `__colnames2'
mat colnames V = `_regr_names'
mat rownames V = `_regr_names' 
mat coleq V = `__colnames2'
mat roweq V = `__colnames2'

if "`model'" == "durbin" & "`indirect'"!="" {
	
	tempname _Vc _simbeta 
	local _nrows = rowsof(V)
	cap mat `_Vc' = cholesky(V)

	if _rc!=0 {
		qui{
		mata: VVV = st_matrix("V")
		mata: eigensystem(VVV, X=., L=.)
		mata: nlesszero = cols(L[mm_which(Re(L):<0)])
		mata: L[mm_which(Re(L):<0)] = J(1,nlesszero,0.000000001)
		mata: AAA = Re((X*diag(L)*X'))
		mata: st_matrix("`_Vc'", cholesky(AAA))	
		mat colnames `_Vc' = `_regr_names'
		mat rownames `_Vc' = `_regr_names' 
		mat coleq `_Vc' = `__colnames2'
		mat roweq `_Vc' = `__colnames2'
		}
	}
	local _ndurb: word count `durbinnames'
	mata: sim_dir = J(`nsim',`_ndurb',.)
	mata: sim_indir = J(`nsim',`_ndurb',.)
	mata: sim_tot = J(`nsim',`_ndurb',.)
	mata: __V = st_matrix("V")
	mat `_simbeta' =  b 

	mata: rseed(`nsim')
	mata: randn = rnormal(`_nrows',`nsim',0,1)
	 	
	forvalues sim = 1/`nsim' {
		
		mata: st_matrix("randn", randn[.,`sim'])
		mat `_simbeta' =  b + (`_Vc'*randn)' 	

		
		tempname _beta _theta _theta2
		foreach n of local durbinnames {		
			mat `_beta' = (nullmat(`_beta'), `_simbeta'[1,"Main:`n'"])
			mat `_theta' = (nullmat(`_theta'), `_simbeta'[1,"Durbin:`n'"])
			if `w2yes' == 1 mat `_theta2' = (nullmat(`_theta2'), `_simbeta'[1,"Durbin2:`n'"])
		}
		tempname _rho _rho2
		mat `_rho' = `_simbeta'[1,"Spatial:rho"]
		if `w2yes' != 0 mat `_rho2' = `_simbeta'[1,"Spatial:rho2"]
    	
		if `w2yes' == 0 mata: _spm_indirect_effects(`N_g',"`_beta'","`_theta'","`_rho'", _w, `w2yes')
		else mata: _spm_indirect_effects(`N_g',"`_beta'","`_theta'","`_rho'", _w, `w2yes',"`_theta2'","`_rho2'",`within',`between')
		
		mata: sim_dir[`sim',.] = st_matrix("_dir")
		mata: sim_indir[`sim',.] = st_matrix("_indir")
		mata: sim_tot[`sim',.] = st_matrix("_tot")
	}
	
	** Fix names
	foreach name of local durbinnames {
		local _colnamesd_dir "`_colnamesd_dir' Direct_effects"
	}
	foreach name of local durbinnames {
		local _colnamesd_indir "`_colnamesd_indir' Indirect_effects"
	}
	foreach name of local durbinnames {
		local _colnamesd_tot "`_colnamesd_tot' Total_effects"
	}	

	local _effects "dir indir tot"
	foreach eff of local _effects {
		mata: st_matrix("avg_`eff'", mean(sim_`eff'))
		mata: st_matrix("avg_std_`eff'" , diag(diagonal(variance(sim_`eff'))))

		mat colnames avg_`eff' = `durbinnames'
		mat coleq avg_`eff' = `_colnamesd_`eff''
		
		mat b = b,avg_`eff'	
		mata: __V = blockdiag(__V,st_matrix("avg_std_`eff'"))
		
	}
	mata: st_matrix("V", __V)
	mat colnames V = `_regr_names' `durbinnames' `durbinnames' `durbinnames'
	mat rownames V = `_regr_names' `durbinnames' `durbinnames' `durbinnames' 
	mat coleq V = `__colnames2' `_colnamesd_dir' `_colnamesd_indir' `_colnamesd_tot'
	mat roweq V = `__colnames2' `_colnamesd_dir' `_colnamesd_indir' `_colnamesd_tot'
}

eret post b V, dep(`lhsname') e(`touse') obs(`obs')

///////////////// Display results /////////////////

*** Common post 
eret local predict "spm_p"
eret local depvar "`lhsname'"
if "`lrxtreg'"== "" eret local cmd "spm" 
else eret local cmd "xtreg" 
eret local model "`model'"
eret local effects "`effects'"
eret local type "`type'"
eret local ivar `id'
eret local tvar `time'
eret scalar g_min = `g_min'
eret scalar g_avg = `g_avg'
eret scalar g_max = g_max
eret scalar N_g = N_g
if `w2yes' == 0 & "`e(model)'" == "sem" eret scalar ll_c = ll_c
eret scalar ll = ll
if "`e(model)'" != "sem" mata: rank = rank(st_matrix("e(V)"))
else if "`e(model)'" == "sem" mata: rank = rank(st_matrix("e(V)")) + 1
mata: st_numscalar("e(rank)",rank)
eret scalar df_m = e(N_g)+e(rank)
// This command allows only balanced panels
if "`e(effects)'" == "fe"  eret scalar df_r = e(N)-e(N_g)-e(rank)
if "`robust'" != "" {
eret local vcetype "Robust"
eret local vce "cluster"
eret local clustervar "`id'"
eret scalar N_clust = N_clust
eret local crittype "Log-pseudolikelihood"
}

//for internal use only
eret scalar df_a = e(N_g)
eret scalar df_b = e(rank)

if "`effects'" == "fe" {
	if "`model'" == "sar" {
		if "`type'" == "ind" eret local title "SLM with spatial fixed effects"
		if "`type'" == "time" eret local title "SLM with time fixed effects"
		if "`type'" == "both" eret local title "SLM with spatial and time fixed effects"
	}
	if "`model'" == "durbin" {
		if "`type'" == "ind" eret local title "SDM with spatial fixed effects"
		if "`type'" == "time" eret local title "SDM with time fixed effects"
		if "`type'" == "both" eret local title "SDM with spatial and time fixed effects"
	}
	if "`model'" == "sem" {
		if "`type'" == "ind" eret local title "SEM with spatial fixed effects"
		if "`type'" == "time" eret local title "SEM with time fixed effects"
		if "`type'" == "both" eret local title "SEM with spatial and time fixed effects"
	}
	if "`model'" == "sarar" {
		if "`type'" == "ind" eret local title "SARAR with spatial fixed effects"
	}
}

if "`leeyu'" != "" {
	local __N_leeyu = `e(N)' - `e(df_a)'
	eret scalar N = `__N_leeyu'
	local __df_r_leeyu = `e(N)' - `e(df_m)'
	eret scalar df_r = `__df_r_leeyu'
}

DiSpLaY, `level' model(`model') `diopts'


/// Distructor
cap scalar drop N_g g_max

end

*** Ancillary programs 

program define DiSpLaY, eclass
        syntax [, Level(cilevel) model(string) *]
	  

        #delimit ;
		di as txt _n "`e(title)'" _col(54) "Number of obs " _col(68) "=" /*
			*/ _col(70) as res %9.0g e(N) _n;
        di in gr "Group variable: " in ye abbrev("`e(ivar)'",12) 
           in gr _col(51) "Number of groups" _col(68) "="
                 _col(70) in ye %9.0g `e(N_g)' _n;
        di in gr "Time variable: " in ye abbrev("`e(tvar)'",12)                    
           in gr _col(49) in gr "Obs per group: min" _col(68) "="
                 _col(70) in ye %9.0g `e(g_min)' ;
        di       _col(64) in gr "avg" _col(68) "="
                 _col(70) in ye %9.1f `e(g_avg)' ;
        di       _col(64) in gr "max" _col(68) "="
                 _col(70) in ye %9.0g `e(g_max)' _n ;
        di "";          
        di in green "Log-likelihood = " in yellow %10.4f `e(ll)';
        #delimit cr                    
    

*** DISPLAY RESULTS

if "`model'"!= "durbin" _coef_table, level(`level') `diopts' neq(3)
else _coef_table, level(`level') `diopts'

end


program define ParseIndirect
	args retumac retumac1 colon opts 

	local 0 ", `opts'"
	
	syntax [, INDirect NSIM(integer 500) * ]


	if `"`options'"' != "" {
		di as error "`options' not allowed"
		exit 198
	}

	c_local `retumac' `indirect'
	c_local `retumac1' `nsim'
	
end


exit


*! version 1.0.1  20 Sep 2011
*! version 1.0.2 28 Sep 2011
*! version 1.0.3 15 Nov 2011
*! version 1.0.4 4 apr 2012
*! version 1.0.5 24 oct 2012
*! version 1.1.0 11 may 2015 It has been made publicly available

***************************************************************************************************
*** 06/04/2012 TO DO:
***					* Robust in all models
***					* Se for sigma2 in sem
***					* Remove double matrix 
***					* Remove df_a df_b
***************************************************************************************************



