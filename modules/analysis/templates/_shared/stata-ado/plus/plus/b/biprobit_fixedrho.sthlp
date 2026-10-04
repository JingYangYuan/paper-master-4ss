{smcl}
{* *! version 1  April2019}{...}
{cmd:help biprobit_fixedrho}{right:({browse "https://doi.org/10.1177/1536867X211063149":SJ21-4: st0658})}
{hline}

{title:Title}

{p2colset 5 26 28 2}{...}
{p2col :{cmd:biprobit_fixedrho} {hline 2}}Bivariate probit regression that
allows the user to specify the value of "rho"{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 25 2}
{cmd:biprobit_fixedrho}
{depvar} [{indepvars}] {ifin}{cmd:,} 
{opt eq2}{cmd:(}{it:depvar_s} {cmd:=} {it:varlist_s}{cmd:)} 
{opt rho(#)}
[{opth vce(vcetype)}
{opt l:evel(#)}
{it:{help biprobit_fixedrho##maximize_options:maximize_options}}]
{p2colreset}{...}

{synoptset 30}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt eq2(depvar_s = varlist_s)}}specify second
equation{p_end}
{p2coldent :* {opt rho(#)}}specify correlation between unobservables in
selection and outcome equations{p_end}
{synopt :{opth vce(vcetype)}}specify type of standard errors to be used for
estimates; {it:vcetype} may be {opt oim}, {opt r:obust},
{opt cl:uster(clustvar)}, {cmd:opg}, {opt boot:strap}, or
{opt jack:knife}{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is
{cmd:level(95)}{p_end}
{synopt :{it:{help biprobit_fixedrho##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2} * {opt eq2()} and {opt rho()} are required.{p_end}
{p 4 6 2}{it:indepvars} may contain factor variables; see {helpb fvvarlist}.
{p_end}
{p 4 6 2}{it:depvar} and {it:indepvars} may
contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}{cmd:bootstrap}, {cmd:by}, {cmd:jackknife}, {cmd:rolling},
{cmd:statsby}, and {cmd:svy} are allowed; see {help prefix}.{p_end}
{p 4 6 2}Weights are not allowed with the {helpb bootstrap} prefix.{p_end}
{p 4 6 2}{opt vce()}, {opt first}, {opt noskip}, and weights are not allowed
with the {helpb svy} prefix.{p_end}
{p 4 6 2}{opt fweight}s, {opt iweight}s, and {opt pweight}s are allowed; see
{help weight}.{p_end}


{title:Description}

{pstd}
{cmd:biprobit_fixedrho} is a command for bivariate probit regression that
allows the user to specify the value of "rho".  This command is based on
Stata's {helpb biprobit} command.  


{title:Options}

{phang}
{opt eq2(depvar_s = varlist_s)} specifies the second equation.  {cmd:eq2()} is
required.

{pmore}
{it:depvar_s} should be coded as 0 or 1, with 0 indicating an observation not
selected and 1 indicating a selected observation.

{phang}
{opt rho(#)} specifies the correlation between the unobservables in the
selection and outcome equations.  {cmd:rho()} is required and must take a value
between -1 and 1.

{phang}
{opth vce(vcetype)} specifies the type of standard errors to be used for the
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
{phang2}{cmd:. webuse school}{p_end}

{pstd}Estimation{p_end}
{phang2}{cmd:.biprobit_fixedrho private logptax loginc years vote, eq2(vote = logptax loginc years) rho(0)}{p_end}

{pstd}Compare with {cmd:biprobit}{p_end}
{phang2}{cmd:.biprobit (private = years vote) (vote = logptax loginc years)}{p_end}
{phang2}{cmd:.biprobit_fixedrho private years vote, eq2(vote = logptax loginc years) rho(-0.7277168)}{p_end}

{pstd}Technical note: The estimates differ because of differences in the maximization procedures.{p_end}


{title:Stored results}

{pstd}
{cmd:biprobit_fixedrho} stores the following in {cmd:e()}:

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
{synopt:{cmd:e(cmd)}}{cmd:biprobit_fixedrho}{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
        test{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform{p_end}
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
{helpb biprobit_scanrho},
{helpb etregress_fixedrho},
{helpb etregress_scanrho},
{helpb heckman_fixedrho},
{helpb heckman_scanrho},
{helpb heckprobit_fixedrho},
{helpb heckprobit_scanrho}
(if installed){p_end}
