/* Engel Moffatt
xtdhreg
130511
xtdh component
rev2: split main program and ml component
rev4: generalize _i _t _first _last
rev5: generalize _sum_y _draws _hdum _dum
rev7: allow for arbitrary upper hurdle
rev8: make sure rho cannot go out of bounds
*/


program drop _all
program define xtdhup
	version 11
	args todo b lnf
	tempvar theta1 theta2 z p0 pp0 ppp0 p1 pp1 ppp1 pp ppp pd ppd y_t
	tempname ln_s_u ln_s_e s_u s_e rr rrr ll y_t_min
	local hlist h1*
		
	mleval `theta1'= `b', eq(1)	
	mleval `theta2' = `b', eq(2) 
	mleval `s_u' = `b', eq(3) scalar
	mleval `s_e' = `b', eq(4) scalar
	mleval `rrr' = `b', eq(5) scalar   // must be left as is in rev8
	
		
	quietly gen double `p1'=.
	quietly gen double `pp1'=.
	quietly gen double `ppp1'=0
		
	quietly gen double `p0'=.
	quietly gen double `pp0'=.
	quietly gen double `ppp0'=0	
		
	quietly gen double `pp'=.
	quietly gen double `ppp'=0
	
	quietly gen double `pd'=.
	quietly gen double `ppd'=0
	
	scalar `rr'=tanh(`rrr')  //changed back in rev8
		
	quietly{
		
		foreach v of varlist `hlist' {
			*replace  `p1'= (1/`s_e')*normalden(($ML_y2-(`theta2' + `s_u'*`v'))/`s_e') if $ML_y2>0  // change in rev7
			*replace  `p1'=1-normal((`theta2'+ `s_u'*`v')/`s_e') if $ML_y2==0  
			replace  `p1' = (1/`s_e')*normalden(($ML_y2 - (`theta2' + `s_u'*`v'))/`s_e') if $ML_y2 < _hrd  // change in rev7
			replace  `p1' = 1-normal((_hrd - (`theta2' + `s_u'*`v'))/`s_e') if $ML_y2 == _hrd	// change in rev7		
			by _i: replace `pp1' = exp(sum(ln(`p1')))
			replace `pp1'=. if _last~=1
					
			replace `pd'=normal((`theta1'+`rr'*`v')/sqrt(1-`rr'^2))  // changed in rev8
			replace `pd'=. if _last~=1
			
			replace `pp0'= 0 if _sum_y < _maxsum  // change in rev7
			replace `pp0' = 1 if _sum_y== _maxsum  // change in rev7
			replace `pp0'=. if _last~=1
			
			replace `pp'=`pd'*`pp1'+(1-`pd')*`pp0'
			replace `ppp'=`ppp'+`pp'	
			}	
		
		replace `ppp'=`ppp'/_draws
				
		mlsum `lnf'=ln(`ppp') if _last==1
		}
end

