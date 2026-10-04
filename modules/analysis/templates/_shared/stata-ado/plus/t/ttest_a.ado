program define ttest_a

syntax varlist [if] [in], by(varname) [dec(int 2) save(string) word excel tex]

qui egen min111 = min(`by')
qui egen max111 = max(`by')
qui replace `by' = 0 if `by' == min111
qui replace `by' = 1 if `by' == max111
qui drop min111 max111

forvalues i = 0/1{
	qui estpost sum `varlist' if `by' == `i'
	qui matrix mean_`i' = e(mean)
}

qui estpost ttest `varlist', by(`by')
qui estadd matrix mean_0
qui estadd matrix mean_1

if "`save'" == ""{
	esttab , noobs cells("mean_0(fmt(`dec')) mean_1(fmt(`dec')) b(star fmt(`dec')) t(fmt(`dec')) p(fmt(`dec')) count(fmt(0))") `star' collabels("Ave.0" "Ave.1" "Diff." "T-value" "P-value" "Obs.") compress nonumber nomtitle note("*** p﹤0.01, ** p﹤0.05, * p﹤0.1") starlevels(* .1 ** 0.05 *** 0.01) 
}
else{
	logout, save(`save') `word' `excel' `tex' replace: esttab , noobs cells("mean_0(fmt(`dec')) mean_1(fmt(`dec')) b(star fmt(`dec')) t(fmt(`dec')) p(fmt(`dec')) count(fmt(0))") `star' collabels("Ave.0" "Ave.1" "Diff." "T-value" "P-value" "Obs.") compress nonumber nomtitle note("*** p﹤0.01, ** p﹤0.05, * p﹤0.1") starlevels(* .1 ** 0.05 *** 0.01) 
}

end