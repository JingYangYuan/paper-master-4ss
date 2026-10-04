{smcl}
{* *! version 1  15March2018}{...}
{cmd:help heckman_fixedrho}{right: ({browse "https://doi.org/10.1177/1536867X211063149":SJ21-4: st0658})}
{hline}

{title:Title}

{p2colset 5 25 27 2}{...}
{p2col :{cmd:heckman_fixedrho} {hline 2}}Linear regression with sample
selection that allows the user to specify the value of "rho"{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 24 2}
{cmd:heckman_fixedrho} {depvar} [{indepvars}] {ifin}{cmd:,}
{opt sel:ect}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s}
[{cmd:,} {opth off:set(varname)} {opt nocon:stant}]{cmd:)} {opt rho(#)}
[{opth vce(vcetype)}
{opt l:evel(#)}
{it:{help heckman_fixedrho##maximize_options:maximize_options}}]
{p2colreset}{...}

{synoptset 20}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt sel:ect()}}specify selection
equation{p_end}
{p2coldent :* {opt rho(#)}}specify correlation between the unobservables in
the selection and outcome equations{p_end}
{synopt :{opth vce(vcetype)}}specify type of standard errors to be used for
estimates; {it:vcetype} may be {opt oim}, {opt r:obust}, 
{opt cl:uster(clustvar)}, {cmd:opg}, {opt boot:strap}, or 
{opt jack:knife}{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is
{cmd:level(95)}{p_end}
{synopt :{it:{help heckman_fixedrho##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt select()} and {opt rho()} are required.  The full specification is {opt sel:ect}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s} [{cmd:,} {opt off:set(varname)} {opt nocon:stant}]{cmd:)}.{p_end}
{p 4 6 2}{cmd:bootstrap}, {cmd:by}, {cmd:jackknife}, {cmd:rolling},
{cmd:statsby}, and {cmd:svy} are allowed; see {help prefix}.{p_end}
{p 4 6 2}Weights are not allowed with the {helpb bootstrap} prefix.{p_end}
{p 4 6 2}{opt vce()}, {opt first}, {opt noskip}, and weights are not allowed
with the {helpb svy} prefix.{p_end}
{p 4 6 2}{opt fweight}s, {opt iweight}s, and {opt pweight}s are allowed; see
{help weight}.{p_end}


{title:Description}

{pstd}
{cmd:heckman_fixedrho} is a modification of Stata's {helpb heckman} command
that allows the user to specify the value of "rho", the correlation between the
unobservables.  


{title:Options}

{phang}
{opt select(depvar_s = varlist_s)} [{cmd:,} {opt offset(varname)} 
{opt noconstant}]{cmd:)} specifies the selection equation.  {cmd:select()} is
required.

{pmore}
{it:depvar_s} should be coded as 0 or 1, with 0 indicating an observation not
selected and 1 indicating a selected observation.

{phang}
{opt rho(#)} specifies the correlation between the unobservables in the
selection and outcome equations.  {cmd:rho()} is required and must take a value
between -1 and 1.

{phang}
{opt vce(vcetype)} specifies the type of standard errors to be used for the
estimates.  {it:vcetype} may be {opt oim}, {opt r:obust}, 
{opt cl:uster(clustvar)}, {cmd:opg}, {opt boot:strap}, or {opt jack:knife}.

{phang}
{opt level(#)} sets the confidence level.  The default is {cmd:level(95)} or
as set by {cmd:set level}.  
See {helpb estimation options##level():[R] estimation options}.

{marker maximize_options}{...}
{phang}
{it:maximize_options} control the maximization process.  Options include
{opt dif:ficult}, [{cmd:no}]{opt log}, {opt tr:ace}, {opt grad:ient},
{opt showstep}, {opt hess:ian}, {opt showtol:erance}, {opt tol:erance(#)}, 
{opt ltol:erance(#)}, {opt nrtol:erance(#)}, and {opt nonrtol:erance}; see 
{manhelp maximize R}.  These options are seldom used.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/ec-p/data/wooldridge/mroz}{p_end}
{phang2}{cmd:. generate agesq = age^2}{p_end}
{phang2}{cmd:. generate child = kidslt6 + kidsge6}{p_end}

{pstd}Fit a regression with sample selection and specify the value of rho to be
-0.7{p_end}
{phang2}{cmd:. heckman_fixedrho lwage educ exper expersq city, select(inlf = age agesq nwifeinc child educ) rho(-0.7)}{p_end}

{pstd}Compare with the output from {cmd:heckman}{p_end}
{phang2}{cmd:. heckman lwage educ exper expersq city, select(inlf = age agesq faminc child educ)}{p_end}
{phang2}{cmd:. heckman_fixedrho lwage educ exper expersq city, select(inlf = age agesq nwifeinc child educ) rho(-0.8)}{p_end}

{pstd}Technical note: Even when {cmd:heckman_fixedrho} is provided with the
value of rho found by {cmd:heckman}, the results may differ between these two
commands.  The difference is due to the maximization procedures.{p_end}


{title:Stored results}

{pstd}
{cmd:heckman_fixedrho} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(p)}}{it:p}-value for model test{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:heckman_fixedrho}{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
        test{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                         maximization or minimization{p_end}
{synopt:{cmd:e(depvar)}}names of dependent variables{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Author}

{pstd}
Jonathan Cook{break}
Public Company Accounting Oversight Board (PCAOB){break}
Washington, DC{break}
jacook@uci.edu


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 21, number 4: {browse "https://doi.org/10.1177/1536867X211063149":st0658}{p_end}

{p 7 14 2}
Help:   
{helpb biprobit_fixedrho}, 
{helpb biprobit_scanrho}, 
{helpb etregress_fixedrho}, 
{helpb etregress_scanrho}, 
{helpb heckman_scanrho}, 
{helpb heckprobit_fixedrho}, 
{helpb heckprobit_scanrho}
(if installed){p_end}
