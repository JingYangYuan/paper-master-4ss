program define pwcorrstar
syntax varlist, [star(string) save(string) word excel tex]
qui estpost correlate `varlist', matrix
if "`star'" == ""{
	if "`save'" == ""{
		esttab, unstack noobs not star(* 0.1 ** 0.05 *** 0.01) compress
	}
	else{
		logout, save(`save') `word' `excel' `tex' replace : esttab, unstack noobs not star(* 0.1 ** 0.05 *** 0.01) compress
	}
}
else{
	if "`save'" == ""{
		esttab, unstack noobs not star(`star') compress
	}
	else{
		logout, save(`save') `word' `excel' `tex' replace : esttab, unstack noobs not star(`star') compress
	}
}
end
