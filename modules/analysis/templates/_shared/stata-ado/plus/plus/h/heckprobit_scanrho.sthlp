{smcl}
{* *! version 1  15March2018}{...}
{cmd:help heckprobit_scanrho}{right: ({browse "https://doi.org/10.1177/1536867X211063149":SJ21-4: st0658})}
{hline}

{title:Title}

{p2colset 5 27 29 2}{...}
{p2col :{cmd:heckprobit_scanrho} {hline 2}}Probit regression with sample
selection that maximizes the likelihood function by scanning over values of
"rho"{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 26 2}
{cmd:heckprobit_scanrho} {depvar} [{indepvars}] {ifin}{cmd:,}
{opt sel:ect}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s}
[{cmd:,} {opth off:set(varname)} {opt nocon:stant}]{cmd:)} 
[{opt minrho(#)} {opt maxrho(#)} {opt step(#)}
{opth vce(vcetype)}
{opt l:evel(#)}
{opt nog:raph}
{it:{help heckman_scanrho##maximize_options:maximize_options}}]
{p2colreset}{...}


{synoptset 20}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt sel:ect()}}specify selection
equation{p_end}
{p2coldent : {opt minrho(#)}}specify minimum value of correlation between
unobservables in selection and outcome equations to be considered;
default is -0.9{p_end}
{p2coldent : {opt maxrho(#)}}specify maximum value of correlation between
unobservables in selection and outcome equations to be considered;
default is 0.9{p_end}
{p2coldent : {opt step(#)}}specify size of step when scanning over
values of correlation; default is 0.01{p_end}
{synopt :{opth vce(vcetype)}}specify type of standard errors to be used for
estimates; {it:vcetype} may be {opt oim}, {opt r:obust},
{opt cl:uster(clustvar)}, {cmd:opg}, {opt boot:strap}, or
{opt jack:knife}{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is
{cmd:level(95)}{p_end}
{synopt :{opt nog:raph}}suppress graphical output{p_end}
{synopt :{it:{help heckman_scanrho##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt select()} is required.  The full specification is 
{opt sel:ect}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s} [{cmd:,} 
{opt off:set(varname)} {opt nocon:stant}]{cmd:)}.{p_end}
{p 4 6 2}{cmd:bootstrap}, {cmd:by}, {cmd:jackknife}, {cmd:rolling},
{cmd:statsby}, and {cmd:svy} are allowed; see {help prefix}.{p_end}
{p 4 6 2}Weights are not allowed with the {helpb bootstrap} prefix.{p_end}
{p 4 6 2}{opt vce()}, {opt first}, {opt noskip}, and weights are not allowed
with the {helpb svy} prefix.{p_end}
{p 4 6 2}{opt fweight}s, {opt iweight}s, and {opt pweight}s are allowed; see
{help weight}.{p_end}


{title:Description}

{pstd}
{cmd:heckprobit_scanrho} is a modification of Stata's {helpb heckprobit}
command that allows the user to scan over values of "rho", the correlation
between the unobservables.  This command can be used to verify that the results
reported by {cmd:heckprobit} are the maximum likelihood estimates.  


{title:Options}

{phang}
{cmd:select(}{it:depvar_s} {cmd:=} {it:varlist_s} [{cmd:,} 
{opt offset(varname)} {opt noconstant}]{cmd:)} specifies the selection
equation.  {cmd:select()} is required.

{pmore}
{it:depvar_s} should be coded as 0 or 1, with 0 indicating an observation not
selected and 1 indicating a selected observation.

{phang}
{opt minrho(#)} specifies the minimum value of correlation between the
unobservables in the selection and outcome equations to be considered.  It must
take a value between -1 and 1.  Note that convergence may be difficult at
values of -1 and 1.  The default is {cmd:minrho(-0.9)}.

{phang}
{opt maxrho(#)} specifies the maximum value of correlation between the
unobservables in the selection and outcome equations to be considered.  It must
take a value between -1 and 1.  Note that convergence may be difficult at
values of -1 and 1.  The default is {cmd:maxrho(0.9)}.

{phang}
{opt step(#)} specifies the size of the step to use when scanning over values
of correlation.  This procedure will take a long time to run when
the step size is small.  The default is {cmd:step(0.01)}.

{phang}
{opt vce(vcetype)} specifies the type of standard errors to be used for the
estimates.  {it:vcetype} may be {opt oim}, {opt r:obust},
{opt cl:uster(clustvar)}, {cmd:opg}, {opt boot:strap}, or {opt jack:knife}.

{phang}
{opt level(#)} sets the confidence level.  The default is {cmd:level(95)} or
as set by {cmd:set level}.
See {helpb estimation options##level():[R] estimation options}.

{phang}
{opt nograph} suppresses the graphical output.

{marker maximize_options}{...}
{phang}
{it:maximize_options} control the maximization process.  Options include
{opt dif:ficult}, [{cmd:no}]{opt log}, {opt tr:ace}, {opt grad:ient},
{opt showstep}, {opt hess:ian}, {opt showtol:erance}, {opt tol:erance(#)},
{opt ltol:erance(#)}, {opt nrtol:erance(#)}, and {opt nonrtol:erance}; see
{manhelp maximize R}.  These options are seldom used.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse school}{p_end}

{pstd}Compare with the output from {cmd:heckprobit}{p_end}
{phang2}{cmd:. heckprobit private years logptax, select(vote = years loginc logptax)}{p_end}
{phang2}{cmd:. heckprobit_scanrho private years logptax, select(vote = years loginc logptax)}{p_end}


{title:Stored results}

{pstd}
{cmd:heckprobit_scanrho} stores the following in {cmd:e()}:

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
{synopt:{cmd:e(cmd)}}{cmd:heckprobit_scanrho}{p_end}
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
{synopt:{cmd:e(b)}}estimation results{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(init_values)}}vector to pass as initial values to {cmd:heckprobit}{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
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
{helpb heckman_fixedrho},
{helpb heckman_scanrho},
{helpb heckprobit_fixedrho}
(if installed){p_end}
