/*
program to estimate a double hurdle model
ml component if upper hurdle is chosen
Christoph Engel and Peter Moffatt
120913
*/

program define dhup
		
	args lnf theta1 theta2 theta3
	tempvar d p z p0 p1 ppza ppxb

	quietly gen double `d'=$ML_y1<_depmax
	quietly gen double `ppza'=normal(`theta3')
	quietly gen double `z'=($ML_y1-`theta1')/(`theta2')
	quietly gen double `p0' = 1-(`ppza'*normal((_depmax-`theta1')/(`theta2')))
	quietly gen double `p1'=`ppza'*normalden(`z')/`theta2'
	quietly replace `lnf'=(1-`d')*ln(`p0')+`d'*ln(`p1')

end
