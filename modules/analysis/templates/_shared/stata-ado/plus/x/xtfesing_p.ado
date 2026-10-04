program define xtfesing_p
	version 13
	
	syntax newvarlist [, xb ue ]
	
	if ("`e(cmd)'" != "xtfesing") error 301
	
	tempvar touse
	gen byte `touse'=1
	markout `touse' `e(depvar)'
	markout `touse' `e(rhs)'
	
	quietly {
	
		local allopts "`xb' `ue'"
		if (wordcount("`allopts'")>1)  {
			display as error "Only one statistic is allowed"
			exit 198
		}
		if wordcount("`allopts'")==0 {
			noisily display as text "(option xb assumed)"
			local xb  "xb"
		}
		
		tempname b
		matrix `b' = e(b)
		
		tempname b_fe
		matrix `b_fe' = `b'[1,"beta:"]
		tempvar xb_fe
		matrix score double `xb_fe' = `b_fe' 
		
		if  `"`xb'"'!="" {
			// prediction : xb
			generate `typlist' `varlist' =  `xb_fe' if `touse'==1
		}

		if  `"`ue'"'!="" {
			// prediction : y-xb
			generate `typlist' `varlist' =  `e(depvar)' - `xb_fe' if `touse'==1
		}
		
	}	
end
