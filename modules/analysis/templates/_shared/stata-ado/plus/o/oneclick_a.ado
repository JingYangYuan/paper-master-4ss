*===================================================================================*
* Ado-file: 	OneClick Version 6
* Author: 		Shutter Zor(左祥太)
* Affiliation: 	Accounting Department, Xiamen University
* E-mail: 		Shutter_Z@outlook.com 
* Date: 		2024/11/21
* Update: 		Optimise output, add options                          
*===================================================================================*

*- Decimal-to-Binary function
capture program drop bin_transfer_a_a
program define bin_transfer_a, rclass
	version 14
	args dec_num
	local bin_num ""
	local remainder 0
	while `dec_num' > 0 {
		local remainder = mod(`dec_num', 2)
		local bin_num "`remainder'`bin_num'"
		local dec_num = floor(`dec_num'/2)
	}
	return local binary "`bin_num'"
end

*- Main function - oneclick_a 6 complete edition
capture program drop oneclick_a
program define oneclick_a
	version 14
	
	syntax  varlist(min=3 fv ts),			    	///
			Method(string)							///
			Pvalue(real)							///
			FIXvar(varlist fv ts)					///
			[										///
				Options(string)						///
				Zvalue								///
				Threshold(numlist integer>0)		///
				Saveplace(string)					///
				BEST								///
				SORT								///
				FULL								///
				KEEP(string)						///
				OPPOSITE							///
			]

	cap ma drop oppo1 oppo2 text1 text2 all1 all2 all3
	if "`opposite'" == "" {
		global oppo1 "<"
		global oppo2 ">="
		global text2 "Significant"
		}
	else {
		global oppo1 ">="
		global oppo2 "<="
		global text1 " Opposite version!!!!"
		global text2 "NON Significant"
	}
	
	if "`keep'" != "" {
		global all1 "`fixvar' `keep' ctrls"
		}
	else {
		global all1 "`fixvar' ctrls"
	}
	
	
	gettoken y ctrlvar : varlist
	gettoken x otherx : fixvar
	tokenize "`ctrlvar'"
	
	preserve
		qui gen subset = ""
		qui gen direction = .
		qui gen coef = .
		qui gen p = ""
		qui gen r2 = .
		
		* computer combination
		local CtrlLen = wordcount("`ctrlvar'")
		local temp = ustrregexra("`ctrlvar'"," ","")
		local Lenth = 2^`CtrlLen'
		forvalues i = 1/`Lenth' {
			local Combo ""
			bin_transfer_a `i'
			forvalues j = 1/`CtrlLen' {
				if substr(r(binary),-`j',1) == "1" {
					local addword "``j''"
					local Combo "`Combo' `addword'"
				}
			}
			local Combo`i' = "`Combo'"
		}
		
		*- set obs num
		local n = _N
		if `Lenth' > `n' {
			qui set obs `Lenth'
		}
		if `Lenth' <= `n' {
			qui set obs `n'
		}
		
		dis as text ""
		display as text  _dup(54) "_"
		dis as text "{bf:#1 oneclick_a abstract:}$text1"
		display as text  _dup(54) "-"
		dis as text _skip(3) "Number of control variables: " _c
		dis as result "`CtrlLen' "
		dis as text _skip(3) "Number of regressions: " _c
		local regNum = 0
		if "`threshold'" == "" {
			local regNum = `regNum' + `Lenth' - 1
		}
		if "`threshold'" != "" {
			forvalues i = 1/`Lenth' {
				if wordcount("`Combo`i''") >= `threshold' {
					local regNum = `regNum' + 1
				}
			}
		}
		dis as result "`regNum'"
		dis as text _skip(3) "Command: " _c
		if "`options'" == "" {
			dis as result "`method' `y' $all1"
		}
		if "`options'" != "" {
			dis as result "`method' `y' $all1, `options'"
		}
		display as text _n _dup(54) "_"
		dis as text "{bf:#2 oneclick_a progress bar:}"
		display as text  _dup(54) "-"
		
		* select
		timer clear 1
		timer on 1
		
		if "`threshold'" == "" {
			forvalues i = 1/`Lenth' {
				_dots `dotDisplay' 0
				quietly {
					capture `method' `y' `fixvar' `Combo`i'' `keep', `options'
					if _rc == 0 {
						* Get the coefficients of x and the p-values
						local distribution_v_x = _b[`x']/_se[`x']
						if "`zvalue'" == "" & !missing(e(df_r)){
							local pv_x = 2 * ttail(e(df_r), abs(`distribution_v_x'))
						}
						if "`zvalue'" != ""{
							local pv_x = 2 * (1 - normal(abs(`distribution_v_x')))
						}
						
						*- Get the coefficients and p values ​​of otherx
						local all_otherx_significant = 1  // Initialize all otherxes to be significantly true
						if "`otherx'" != "" {  // When otherx variables exist
							foreach var of varlist `otherx' {
								local distribution_v_otherx = _b[`var']/_se[`var']
								if "`zvalue'" == "" & !missing(e(df_r)){
									local pv_this_var = 2 * ttail(e(df_r), abs(`distribution_v_otherx'))
								}
								if "`zvalue'" != ""{
									local pv_this_var = 2 * (1 - normal(abs(`distribution_v_otherx')))
								}
								if `pv_this_var' $oppo2 `pvalue' {  // Any one is not significant and is marked as false
									local all_otherx_significant = 0
									continue, break  // Exit the loop immediately if it is found that it is not significant
								}
							}
						}

						*- Determine whether it is significant at the same time
						local ifsignificant = 0
						if `pv_x' $oppo1 `pvalue' & `all_otherx_significant' {
							local ifsignificant = 1
						}


						* Update results
						replace subset = "`Combo`i''" in `i' if `ifsignificant'
						replace direction = 1 in `i' if `ifsignificant' & `distribution_v_x' > 0
						replace direction = 0 in `i' if `ifsignificant' & `distribution_v_x' < 0
						replace coef = _b[`x'] in `i' if `ifsignificant'
						replace p = "*" in `i' if `ifsignificant' & `pv_x' < 0.1 & `pv_x' > 0.05
						replace p = "**" in `i' if `ifsignificant' & `pv_x' < 0.05 & `pv_x' > 0.01
						replace p = "***" in `i' if `ifsignificant' & `pv_x' < 0.01
						replace r2 = e(r2) in `i' if `ifsignificant'
					}
					if _rc != 0 {
						replace subset = "(Error) `Combo`i''" in `i'
					}
				}
				local dotDisplay = `dotDisplay' + 1
			}			
		}
		if "`threshold'" != "" {
			forvalues i = 1/`Lenth' {
				_dots `dotDisplay' 0
				if wordcount("`Combo`i''") >= `threshold' {
					quietly {
						capture `method' `y' `fixvar' `Combo`i'' `keep', `options'
						if _rc == 0 {
							* Get the coefficients of x and the p-values
							local distribution_v_x = _b[`x']/_se[`x']
							if "`zvalue'" == "" & !missing(e(df_r)){
								local pv_x = 2 * ttail(e(df_r), abs(`distribution_v_x'))
							}
							if "`zvalue'" != ""{
								local pv_x = 2 * (1 - normal(abs(`distribution_v_x')))
							}

							*- Get the coefficients and p values ​​of otherx						
							local all_otherx_significant = 1  // Initialize all otherxes to be significantly true				
							if "`otherx'" != "" {  // When otherx variables exist
								noisily dis "have otherx"
								foreach var of varlist `otherx' {
									local distribution_v_otherx = _b[`var']/_se[`var']
									if "`zvalue'" == "" & !missing(e(df_r)){
										local pv_this_var = 2 * ttail(e(df_r), abs(`distribution_v_otherx'))
									}
									if "`zvalue'" != ""{
										local pv_this_var = 2 * (1 - normal(abs(`distribution_v_otherx')))
									}
									if `pv_this_var' $oppo2 `pvalue' {  // Any one is not significant and is marked as false
										local all_otherx_significant = 0
										continue, break  // Exit the loop immediately if it is found that it is not significant
									}
								}
							}

							*- Determine whether it is significant at the same time
							local ifsignificant = 0
							if `pv_x' $oppo1 `pvalue' & `all_otherx_significant' {
								local ifsignificant = 1
							}
							
							* Update results
							replace subset = "`Combo`i''" in `i' if `ifsignificant'
							replace direction = 1 in `i' if `ifsignificant' & `distribution_v_x' > 0
							replace direction = 0 in `i' if `ifsignificant' & `distribution_v_x' < 0
							replace coef = _b[`x'] in `i' if `ifsignificant'
							replace p = "*" in `i' if `ifsignificant' & `pv_x' < 0.1 & `pv_x' > 0.05
							replace p = "**" in `i' if `ifsignificant' & `pv_x' < 0.05 & `pv_x' > 0.01
							replace p = "***" in `i' if `ifsignificant' & `pv_x' < 0.01
							replace r2 = e(r2) in `i' if `ifsignificant'							
						}
						if _rc != 0 {
							replace subset = "(Error) `Combo`i''" in `i'
						}
					}
				}
    		local dotDisplay = `dotDisplay' + 1
		}
    }
			
		
		timer off 1
		qui timer list 1
		dis _newline "Time= " r(t1) " S"
		
		gen cv_count = strlen(subset) - strlen(subinstr(subset, " ", "", .))
		gen p_count = strlen(p) - strlen(subinstr(p, "*", "", .))

		* drop
		display as text _n _dup(54) "_"
		dis as text "{bf:#3 oneclick_a result description:}"
		display as text  _dup(54) "-"
		quietly {
			drop if subset == ""
			keep subset direction coef p r2 cv_count p_count
			
			count if !strmatch(subset, "*Error*")
			local sigNum = r(N)
			drop if strmatch(subset, "*Error*")
			sum direction if direction == 1
			local positiveNum = r(N)
			sum direction if direction == 0
			local negativeNum = r(N)
			
			noisily dis as text _skip(3) "$text2 groups: " _c
			noisily dis as result "`sigNum'"
			if `sigNum' == 0 {
				noisily dis as error "oneclick_a REALLY tried its best, but... (T_T)"
				error 1
			}
			noisily dis as text _skip(6) "Positive: " _c
			noisily dis as result "`positiveNum'"
			noisily dis as text _skip(6) "Negative: " _c
			noisily dis as result "`negativeNum'"
			
			noisily display as text _n _dup(54) "_"
			noisily dis as text "{bf:#4 oneclick_a storage path:}"
			noisily dis as text _dup(54) "-"
			
			*- best option
			if "`best'" != "" {
				sort r2
				local bestctrls = subset[`=_N']
			}
			
			*- sort option
			if "`sort'" != "" {
				sort cv_count p_count r2
				local mostctrls = subset[`=_N']
			}
		
			*- full option
			if "`full'" != "" & "`options'" != "" {
				gen command = "`method' " + "`y' " + "`fixvar' `keep'" + subset + ", `options'"
				keep command direction coef p r2 cv_count p_count
				order command direction coef p r2 cv_count p_count
				label var command "regression command"
			}	
			if "`full'" != "" & "`options'" == "" {
				gen command = "`method' " + "`y' " + "`fixvar' `keep'" + subset
				keep command direction coef p r2 cv_count p_count
				order command direction coef p r2 cv_count p_count
				label var command "regression command"
			}
			if "`full'" == "" {
				keep subset direction coef p r2 cv_count p_count
				order subset direction coef p r2 cv_count p_count
				label var subset "subset of control variables"
			}
			
			label var direction "1=postive, 0=negative"
			label var coef "coefficient of independent variable"
			label var p "mysterious stars of significance"
			label var r2 "r-squared"
			label var cv_count "the number of control variables"
			label var p_count "the number of stars"
			
			if "`opposite'" != "" {
				drop p p_count
			}
			
			if "`saveplace'" != "" {
				noisily dis as result "`c(pwd)'/`saveplace'"
				save "`saveplace'", replace
			}
			if "`saveplace'" == "" {
				noisily dis as result "`c(pwd)'/oneclick_a_subset.dta"
				save oneclick_a_subset.dta, replace
			}
			noisily display as text  _dup(54) "_"
		}

	restore
	
	if "`keep'" != "" {
		global all2 "`fixvar'`keep' `bestctrls'"
		}
	else {
		global all2 "`fixvar'`bestctrls'"
		}
	
	if wordcount("`bestctrls'") != 0 {
		display as text _n _dup(54) "_"
		dis as text "{bf:#5 oneclick_a best regression:}"
		dis as text _dup(54) "-"
		if "`options'" == "" {
			dis as result "`method' `y' $all2"
		}
		if "`options'" != "" {
			dis as result "`method' `y' $all2, `options'"
		}
		`method' `y' `fixvar' `keep' `bestctrls', `options'
	}
	
	if wordcount("`mostctrls'") != 0 {
		display as text _n _dup(54) "_"
		dis in red "Since you entered the sort option"
		dis in red "The most cv sets is:`mostctrls'."
		dis as text _dup(54) "-"
	}
	
	cap ma drop oppo1 oppo2 text1 text2 all1 all2
end



