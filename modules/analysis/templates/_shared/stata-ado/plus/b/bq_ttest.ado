program define bq_ttest
syntax varlist, by(varname) [dec(int 2) save(string) word excel tex]

forvalues i = 0/1{
	qui estpost sum `varlist' if `by' == `i'
	qui matrix mean_`i' = e(mean)
}

qui estadd matrix mean_0
qui estadd matrix mean_1

if "`save'" == ""{
	esttab , noobs cells("mean_0(fmt(`dec')) mean_1(fmt(`dec')) b(star fmt(`dec')) t(fmt(`dec')) count(fmt(0))") `star' collabels("Mean(`by'=0)" "Mean(`by'=1)" "Diff." "T_value" "Obs.") compress
}
else{
	logout, save(`save') `word' `excel' `tex' replace: esttab , noobs cells("mean_0(fmt(`dec')) mean_1(fmt(`dec')) b(star fmt(`dec')) t(fmt(`dec')) count(fmt(0))") `star' collabels("Mean(`by'=0)" "Mean(`by'=1)" "Diff." "T_value" "Obs.") compress
}

dis in green "更多精彩视频和产品请B站喝茶翻阅，阿婆主：宝气Stata"

end
