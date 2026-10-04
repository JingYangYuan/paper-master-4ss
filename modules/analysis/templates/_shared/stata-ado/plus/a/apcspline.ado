prog def apcspline, eclass
*! Version 3.0.4 Peter Sasieni & Francesca Pesola 6 July 2017
*! It fixes drift bug - but needs to be specified
*! Damping can be set to 1 (no damping)
*! It can now include covariates
*! It can now use factor variables and time-series operators 
*! Based on version 2.0 Dec 2011
version 12
syntax varlist(numeric fv ts) [fw iw pw] [if] [in] [, Exposure(varname numeric) ///
	Link(string) SCAle(string) BACKground(string) REGULARize ///
	DAMPing(real .92) NKAge(int 6) NKPeriod(int 5) NKCohort(int 3) ///
	ITERate(int -1) DRIFT * ]
marksample touse
tokenize `varlist'
local cases `1'
local age `2'
local year `3'
macro shift /* skip cases */
macro shift /* skip age */
macro shift /* skip year */
local covars `*'
local pop `exposure'
		capture assert `cases'==int(`cases') if `touse'
		if _rc {
			di as txt `"note: `cases' has non-integer values"'
		}
capture drop _I* 
qui sum `age' if `touse' ,d
local kmin=r(min)
local kmax=r(max)
local kp=`kmin'

if "`background'"!="" & "`regularize'"!="" {
	noi di as err "Cannot specify both regularize and background"
	exit
}
if `nkage'<1 {
	di as error "Must have at least one knot for age"
	exit
}
if `iterate'== -1 {
	local myiter1 "iter(12)"
} 
else { 
	local myiter1 "iterate(`iterate')"
	local myiter2 "iterate(`iterate')"
}
forval i=1/`nkage' {
	local k`i'=`kmin'+`i'*(`kmax'-`kmin')/(`nkage'+1)
	qui count if `age'>`kp' & `age'<=`k`i'' & `touse'
	if r(N)== 0 {
		local k`i' 
	}
	else {
		local kp=`k`i''
	}
	local knots "`knots' `k`i''"
}
spbase `age', gen(A) knots(`knots') kmin(`kmin') kmax(`kmax')
local D=`damping'
qui sum `year' if `cases'!=. &`touse',mean
local ymax=r(max)
local ymin=r(min)
local ymean=r(mean)

if `D'==1 {
	gen _Idrift=year
} 
else {
	gen _Idrift= cond(`year'<=(`ymax'+1),`year',`ymax'+  (`D'-`D'^(`year'-`ymax' +1))/(1-`D'))-`ymean'
}

local ymin =`ymin'-`ymean'
local ymax =`ymax'-`ymean'
local kp=`ymin'
if `nkperiod'>= 1 {
  local knots
  forval i=1/`nkperiod' {
	local j=`i'-1
	local k`i'=`ymin'+`i'*(`ymax'-`ymin')/(`nkperiod'+1)
	qui count if _Idrift>`kp' & _Idrift<=`k`i'' & `touse'
	if r(N)== 0 {
		local k`i' 
	}
	else {
		local kp=`k`i'' 
	}
	local knots "`knots' `k`i''"
  }
  spbase _Idrift, gen(P) knots(`knots') kmin(`ymin') kmax(`ymax')
  tokenize $P
  macro shift
  global P "`*'"
}
if "`drift'"!=""  { //& `nkperiod'< 1 {
	global D _Idrift
}

qui gen _Icohort=`year'-`age'
local coh _Icohort
qui sum `coh' if `touse' [fw=int(`cases')],d
qui replace _Icohort=_Icohort-r(mean)
qui sum `coh' if `touse' [fw=int(`cases')],d
local kmin=(r(p1)+2*r(p5))/3
local kp=`kmin'
local cmin=r(p5)
local kmax=(2*r(p95)+r(p99))/3
local cmax=r(p95)
qui replace _Icohort=r(p99)+log(_Icohort-r(p99)+1) if _Icohort>r(p99)
if `nkcohort'>= 1 {
  local knots
  forval i=1/`nkcohort' {
	local k`i'=`cmin'+`i'*(`cmax'-`cmin')/(`nkcohort'+1)
	qui count if `coh'>`kp' & `coh'<=`k`i'' & `touse'
	if r(N)== 0 {
		local k`i' 
	}
	else {
		local kp=`k`i''
	}
	local knots "`knots' `k`i''"
  }
  spbase `coh', gen(C) kmin(`kmin') kmax(`kmax') knots(`knots') 
  tokenize $C
  macro shift
  global C "`*'"
}
if "`pop'"!="" {
	local popX = "`pop' * "
	local expos = "expo(`exposure')"
}
if "`background'"=="" & "`regularize'"!="" {
	nois di as text "Regularize option specified, background set to " as result "*1"
	local background "*1"
}
if "`background'"!="" {
	capture gen _Ibackground = `background'
	if _rc!=0 {
		qui egen _Ibackground=mean(`cases'/(`popX'`touse')) ,by(`age')
		qui sum _Ibackground if `touse',mean
		qui replace _Ibackground=sqrt(`popX'(0.98*_Ibackground+r(mean)/50)) `background'
	}
}
else {
	gen byte _Ibackground = 0
}
qui gen _Icases=`cases'+_Ibackground

if "`link'"=="" local link log
if "`scale'"=="" local scale 1
if lower("`link'")!="log" {
	glm _Icases $A $P $C $D `covars' [`weight'`exp'] if `touse',link(`link') family(glim_mypois `pop') ///
		scale(`scale') `myiter1' `options'
	if e(converged)==0 {
		if "`regularize'"==""  & "`background'"=="" {
			nois di as error "Try the option: " as result "regularize"
		}
		else {
			nois di as error "Try increasing background, restricting age, or changing link"
		}
		exit
	}
 	tempvar fit
	qui predict `fit'
	qui replace _Icases =`fit'
	tempname glmres
	_estimates hold `glmres'
	local quietly qui
}
`quietly' poisson _Icases $A $P $C $D `covars' [`weight' `exp'] if `touse',`expos' `myiter2' `options'
tempname B
mat `B'=e(b)
if lower("`link'")!="log" {
	_estimates unhold `glmres'
	ereturn matrix b1 `B'
}
else {
	ereturn local linkt "Log"
}
if lower("`'link'")=="log" ereturn local linkt "Log"
ereturn local predict	`"apcspline_p"'
ereturn local cmd "apcspline"
ereturn local A "$A"
ereturn local P "$P"
ereturn local C "$C"
ereturn local D "$D"
ereturn local age `age'
ereturn local period `year'
ereturn local population `pop'
ereturn local cmdline `"apcspline `0'"'
*drop _Icohort
global A
global P
global C
global D
end

program define spbase
        version 3.0
        local varlist "req ex min(1) max(1)"
        local if "opt"
        local in "opt"
        local options "GEN(string) Nknots(int 0) Knots(string) Kmin(string) Kmax(string) "
        parse "`*'"
        if "`gen'"=="" {
                di in red "Must specify name for basis"
		exit 198
	}
        parse "`varlist'", parse(" ")
        tempvar  X 
        quietly {
                gen `X'=`1' `if' `in'
                count if `X'<.
                local cnt = _result(1)
                if `cnt'<3 { noisily error 2001 }
                local x "`1'"
                _crcslbl `X' `1'
                sort `X'
                if "`kmin'"=="" {
			local k0=`X'[1]
		    }
		    else {
			local k0=`kmin'
                }	
		    if "`kmax'"=="" {
			local kN = `X'[`cnt']
		    }
		    else {
			local kN=`kmax'
                }
		
* GENERATE INTERIOR KNOTS  
                if "`knots'"=="" {
                        local nk = `nknots'
                        if `nk' == 0 {
                                local nk = int((`cnt')^.25)
                        }
                        local j = `nk' 
                        while `j' > 0 {
                                local k`j'=`X'[int((`j'*`cnt'/(`nk'+1))+.5)]
                                local j = `j' -1
                        }
                }
                else {
                        parse "`knots'", parse(" ,")
                        local nk = 0
                        while "`1'"!="" {
			   if "`1'"!=","{
			    	if `1'<`k0' | `1'>`kN' {
					noisily di "knot at `1' ignored"}
			    	else {
                                	local nk = `nk' + 1
					local k`nk' = `1' 
			    	}
			   }
                           macro shift
                        }
                }
* CREATE REGRESSION VARIABLES
                local j = 1
		local gen1 "`x'" 
		tempvar fit
                while `j' <= `nk' {
		   confirm new var _I`gen'`j'
        	   #delimit ;
                   gen _I`gen'`j'= -((`kN'-`k`j'')/(`kN'-`k0'))*(`X'-`k0')^3 ;
                   replace _I`gen'`j'=_I`gen'`j'+(`X'-`k`j'')^3 
				if `X'>`k`j'' & `k`j'' > `k0' ;
                   replace _I`gen'`j'=(`kN'-`k`j'')*(`k`j''-`k0')
				*(`kN'+`k`j''+`k0'-3*`X')	if `X'>`kN' ;
        	   #delimit cr
		   reg _I`gen'`j' `X' if `X'>`kmin' & `X'<`kmax'
		   predict `fit'
		   replace _I`gen'`j'=_I`gen'`j'-`fit'
		   drop `fit'
		   lab var _I`gen'`j' "(`x'-k`j') cubed"
	           local gen1 "`gen1' _I`gen'`j'"
                   local j = `j' +1
                }
		mac def `gen' "`gen1'"
	}
end

