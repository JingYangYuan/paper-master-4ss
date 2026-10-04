*! margte_dgps v2.0.0 06may2013
*  Authors: Thomas Walstrum & Scott Brave
*  This program is part of the margte package.

*Program margte_dgps.
{
program define margte_dgps, rclass
	version 11
	syntax, [obs(integer 5000) dgp(string) model(string) prblm(string)]
	clear
	quietly set obs `obs'
	***Generate the unobservables, the observables, and the first stage.***
	**Unobservables.**
	matrix me = [ 0.00,  0.00,  0.00 ]
	matrix co = [ 0.30, -0.25, -0.15 \ /*
	*/			 -0.25,  0.30,  0.25 \ /*
	*/   		 -0.15,  0.25,  1.00 ]
	quietly drawnorm u1 u0 V, n(`numObs') means(me) cov(co) clear
	**Observables.**
	*experience has mean 20.
	quietly generate exp = 40 * runiform()
	*experience squared has mean 533.33.
	quietly generate exp2 = exp ^ 2
	*momsEdu has mean 12.
	quietly generate momsEdu = 8 + 8 * runiform()
	*distCol has mean 25.
	if "`prblm'" == "inst" {
		quietly generate distCol = 50 * runiform() 				if mod(_n, 3) != 0
		quietly replace  distCol = 50 * normal(u0 / sqrt(.3))	if mod(_n, 3) == 0
	}
	else {
		quietly generate distCol = 50 * runiform()
	}
	*Generate i and d.*
	tempvar truep
	if "`prblm'" == "supp" {
		quietly generate i  = .015 + .03 * momsEdu - .015 * distCol - V
		quietly generate enroll = 0
		quietly replace  enroll = 1 if i > 0
		quietly generate `truep' = normal(.015 + .03 * momsEdu - .015 * distCol)
	}
	else {
		quietly generate i  = .06 + .12 * momsEdu - .06 * distCol - V
		quietly generate enroll = 0
		quietly replace  enroll = 1 if i > 0
		quietly generate `truep' = normal(.06 + .12 * momsEdu - .06 * distCol)
	}
	***Pick the data generating process and generate the data.***
	if "`dgp'" == "poly" {
		*Drop u0 because it's not used.
		drop u0 u1
		generate u = rnormal(0, .55)
		*Generate the p's.
		quietly generate p1 = `truep'
		quietly generate p2 = p1^2
		quietly generate p3 = p1^3
		quietly generate p4 = p1^4
		*Generate lwage.
		*E(ATE) = .32 = -.6 + .02 * 20 + .0003 * 533.33 + .03 * 12
		quietly generate lwage = .9 + .12 * exp - .0015 * exp2 + .05 * momsEdu - .6 * p1 + .02 * exp * p1 + .0003 * exp2 * p1 /*
			*/+ .03 * momsEdu * p1 + 4 * p1 - 12 * p2 + 16 * p3 - 8 * p4 + u
		*quietly drop if lwage < 0
		*Order the variables.
		order lwage exp exp2 momsEdu distCol enroll i p1 p2 p3 p4 u V
	}
	else {
		*Generate lwage. 
		*E(ATE) = .32 = (.3 - .9) + (.14 - .12) * 20 + (-.0012 - -.0015) * 533.33 + (.08 - .05) * 12
		quietly generate lwage = .
		quietly replace  lwage = .9 + .12 * exp - .0015 * exp2 + .05 * momsEdu + u0 if enroll == 0
		quietly replace  lwage = .3 + .14 * exp - .0012 * exp2 + .08 * momsEdu + u1 if enroll == 1
		quietly drop if lwage < 0
		*Order the variables.
		order lwage exp exp2 momsEdu distCol enroll i u0 u1 V
	}
	***Pick the model and run it.***
	if "`model'" != "" {
		if "`model'" == "pnorm" {
			margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) noboot noplot
			return scalar texp 		= [Treated]_b[exp]
			return scalar texp2 	= [Treated]_b[exp2]
			return scalar tmomsEdu 	= [Treated]_b[momsEdu]
			return scalar tk 		= [Treated]_b[k]
			return scalar tcons 	= [Treated]_b[_cons]
			return scalar uexp 		= [Untreated]_b[exp]
			return scalar uexp2		= [Untreated]_b[exp2]
			return scalar umomsEdu	= [Untreated]_b[momsEdu]
			return scalar uk 		= [Untreated]_b[k]
			return scalar ucons 	= [Untreated]_b[_cons]
			return scalar mills		= [Mills]_b[rho1-rho0]
		}
		else if "`model'" == "ml" {
			margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) noboot noplot ml
			return scalar texp 		= [Treated]_b[exp]
			return scalar texp2 	= [Treated]_b[exp2]
			return scalar tmomsEdu 	= [Treated]_b[momsEdu]
			return scalar tk 		= [Mills]_b[rho1]
			return scalar tcons 	= [Treated]_b[_cons]
			return scalar uexp 		= [Untreated]_b[exp]
			return scalar uexp2		= [Untreated]_b[exp2]
			return scalar umomsEdu	= [Untreated]_b[momsEdu]
			return scalar uk 		= [Mills]_b[rho0]
			return scalar ucons 	= [Untreated]_b[_cons]
			return scalar mills		= [Mills]_b[rho1-rho0]
		}
		else if "`model'" == "ppoly" {
			margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) noboot noplot poly(4)
			return scalar exp 		= [Parameters]_b[exp]
			return scalar exp2 		= [Parameters]_b[exp2]
			return scalar momsEdu	= [Parameters]_b[momsEdu]
			return scalar expXp		= [Parameters]_b[expXp]
			return scalar exp2Xp 	= [Parameters]_b[exp2Xp]
			return scalar momsEduXp = [Parameters]_b[momsEduXp]
			return scalar p1		= [Parameters]_b[p1]
			return scalar p2 		= [Parameters]_b[p2]
			return scalar p3 		= [Parameters]_b[p3]
			return scalar p4 		= [Parameters]_b[p4]
			return scalar cons		= [Parameters]_b[_cons]
		}
		else if "`model'" == "semil" {
			margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) noboot noplot nocommongraph semiparametric degree(4) ybwidth(.15) /*
				*/xbwidth(.01)
			return scalar exp 		= [Parameters]_b[exp]
			return scalar exp2 		= [Parameters]_b[exp2]
			return scalar momsEdu	= [Parameters]_b[momsEdu]
			return scalar expXp		= [Parameters]_b[expXp]
			return scalar exp2Xp 	= [Parameters]_b[exp2Xp]
			return scalar momsEduXp = [Parameters]_b[momsEduXp]
		}
		else if "`model'" == "semip"{
			margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) noboot noplot nocommongraph semiparametric poly(4) ybwidth(.15)
			return scalar exp 		= [Parameters]_b[exp]
			return scalar exp2 		= [Parameters]_b[exp2]
			return scalar momsEdu	= [Parameters]_b[momsEdu]
			return scalar expXp		= [Parameters]_b[expXp]
			return scalar exp2Xp 	= [Parameters]_b[exp2Xp]
			return scalar momsEduXp = [Parameters]_b[momsEduXp]
			return scalar p1		= [Parameters]_b[p1]
			return scalar p2 		= [Parameters]_b[p2]
			return scalar p3 		= [Parameters]_b[p3]
			return scalar p4 		= [Parameters]_b[p4]
			return scalar cons		= [Parameters]_b[_cons]
		}
		if inlist("`model'", "pnorm", "ml", "ppoly", "semil", "semip") {
			return scalar ate = [ATE]_b[E(Y1-Y0)@X]
			forvalues i = 1(1)99 {
				capture local ui = [mte]_b[u`i']
				if _rc != 0 {
					return scalar u`i' = -9999
				}
				else {
					return scalar u`i' = `ui'
				}
			}
		}
	}
end
}
