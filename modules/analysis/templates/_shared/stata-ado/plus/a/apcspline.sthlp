{smcl}
{* *! version 1.1.10  23apr2007}{...}
{cmd:help apcspline}{right: ({browse "http://www.stata-journal.com/article.html?article=up0057":SJ17-4: st0245_1})}
{vieweralsosee "apcspline postestimation" "help apcspline postestimation"}{...}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:apcspline} {hline 2}}Age-period-cohort modeling{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:apcspline} {depvar} {it:agevar periodvar} {ifin} {weight} [{cmd:,}
{it:options}] 

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt :{opth e:xposure(varname:varname_e)}}include ln({it:varname_e}) in
model with coefficient constrained to 1{p_end}
{synopt :{opth l:ink(glm##linkname:linkname)}}link function; default is logarithmic link {p_end}
{synopt :{cmdab:sca:le(x2}|{cmd:dev}|{it:#}{cmd:)}}set the scale parameter{p_end}
{synopt :{opt regular:ize}}set {cmd:background()} to 0.5 if background is not
specified{p_end}
{synopt :{opt back:ground(#)}}set the amount of background events added to smooth the fits; default is {cmd:background(0.5)}{p_end}
{synopt :{opt drift}}specifies whether the drift is included in the model; default is to exclude{p_end}
{synopt :{opt damp:ing(#)}}set the factor by which the drift is attenuated in each successive period after the last observation; default is {cmd:damping(0.92)}{p_end}
{synopt :{opt nka:ge(#)}}set the number of internal knots for the spline for the age variable; default is {cmd:nkage(6)}{p_end}
{synopt :{opt nkp:eriod(#)}}set the number of internal knots for the spline for the period variable; default is {cmd:nkperiod(5)}{p_end}
{synopt :{opt nkc:ohort(#)}}set the number of internal knots for the spline for the cohort variable; default is {cmd:nkcohort(3)}{p_end}
{synoptline}
{p 4 6 2}Many of the options available to {helpb glm} or {helpb poisson}
related to the standard error, maximization, and reporting may also be
used.{p_end}
{p 4 6 2}
See {help apcspline_postestimation:apcspline postestimation} for
postestimation commands specific to this command.  See 
{manhelp poisson_postestimation R:poisson postestimation} or 
{manhelp glm_postestimation R:glm postestimation} for other features
available after estimation.{p_end}


{title:Description}

{pstd}
{cmd:apcspline} fits an age-period-cohort Poisson regression of
{it:depvar} using natural cubic splines, where {it:depvar} is a
nonnegative count variable.


{title:Options}

{phang}
{opth "exposure(varname:varname_e)"}; see
{helpb estimation options:[R] estimation options}.

{phang}
{opt link(linkname)} specifies the link function as in the {cmd:glm}
command except that the exposure is handled differently for power links.
The default is {cmd:link(log)}.

{phang}
{cmd:scale(x2}|{cmd:dev}|{it:#}{cmd:)} overrides the default scale
parameter; see {manhelp glm R}.

{pmore}
By default, {cmd:scale(1)} is assumed for the discrete distributions
(binomial, Poisson, and negative binomial), and {cmd:scale(x2)} is assumed for
the continuous distributions (Gaussian, gamma, and inverse Gaussian).

{pmore}
{cmd:scale(x2)} specifies that the scale parameter be set to the Pearson
chi-squared (or generalized chi-squared) statistic divided by the residual
degrees of freedom, which is recommended by McCullagh and Nelder (1989) as a
good general choice for continuous distributions.

{pmore}
{cmd:scale(dev)} sets the scale parameter to the deviance divided by the
residual degrees of freedom.  This option provides an alternative to
{cmd:scale(x2)} for continuous distributions and overdispersed or
underdispersed discrete distributions.

{pmore}
{opt scale(#)} sets the scale parameter to {it:#}.
For example, using {cmd:scale(1)} in {cmd:family(gamma)} models results in
exponential-errors regression.  Additional use of {cmd:link(log)} rather than
the default {cmd:link(power -1)} for {cmd:family(gamma)} essentially
reproduces Stata's {opt streg}, {cmd:dist(exp) nohr} command (see
{manhelp streg ST}) if all the observations are uncensored.

{phang}{cmd:regularize} specifies that a default number of events be
added to each observation before fitting the model.  The default is a
noninteger variable that is different for each value of age.  The
variable {cmd:regular} is equal to sqrt(0.98 x E_age + E_0/50) where
E_age is the expected count given the age and E_0 is the expected count
based on the overall rate.  The background numbers are stored in
{cmd:_Ibackground} and subtracted back to obtain the fitted values.

{phang}
{opt background(#)} specifies the background rate of events added to each
observation (dependent on age) so as to stabilize the estimates. The default
is {cmd:background(0.5)}.  Specifying {cmd:background(0)} indicates no
background.

{phang}
{opt drift} specifies whether the drift is included in the model.  By default,
the drift is not included.  Specify {cmd:drift} for the linear term to be
included.

{phang}
{opt damping(#)} specifies the factor by which the drift is dampened as it is
extrapolated beyond the last observed period.  The default is
{cmd:damping(0.92)}.  Specifying {cmd:damping(1.0)} indicates no damping.

{phang}
{opt nkage(#)}, {opt nkperiod(#)}, and {opt nkcohort(#)} specify the
number of interior knots in the natural cubic spline functions used for
each of the variables age, period, and cohort, respectively.  The
default values are 6, 5, and 3, respectively.  {it:#} should be
an integer.  The knots are roughly evenly placed over the range for which
{it:depvar} is nonmissing.  Setting the number of knots to 0 results in the
variable being omitted from the model.  To enter period or cohort linearly,
specify the {cmd:drift} option.


{title:Examples}

{pstd}Fit an age-period-cohort Poisson regression{p_end}
{phang2}{cmd:. apcspline deaths age year, drift exposure(population)}
{p_end}

{pstd}Fit an age-period-cohort regression with power link{p_end}
{phang2}{cmd:. apcspline cases age year if age>=20, exposure(population) link(power 0.2)}{p_end}

{phang}Obtain fitted rates per 100,000{p_end}
{phang2}{cmd:. predict fitrate, irr rate(1e5)}

{phang}Obtain fitted cohort relative-risk function{p_end}
{phang2}{cmd:. predict f_coh, cohort}{p_end}


{title:Saved results}

{pstd}
{cmd:apcspline} saves the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(df)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(phi)}}scale parameter{p_end}
{synopt:{cmd:e(aic)}}model AIC{p_end}
{synopt:{cmd:e(bic)}}model BIC{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(p)}}significance{p_end}
{synopt:{cmd:e(deviance)}}deviance{p_end}
{synopt:{cmd:e(deviance_s)}}scaled deviance{p_end}
{synopt:{cmd:e(deviance_p)}}Pearson deviance{p_end}
{synopt:{cmd:e(deviance_ps)}}scaled Pearson deviance{p_end}
{synopt:{cmd:e(dispers)}}dispersion{p_end}
{synopt:{cmd:e(dispers_s)}}scaled dispersion{p_end}
{synopt:{cmd:e(dispers_p)}}Pearson dispersion{p_end}
{synopt:{cmd:e(dispers_ps)}}scaled Pearson dispersion{p_end}
{synopt:{cmd:e(nbml)}}{cmd:1} if negative binomial parameter estimated via ML,
	{cmd:0} otherwise{p_end}
{synopt:{cmd:e(vf)}}factor set by {cmd:vfactor()}, {cmd:1} if not set{p_end}
{synopt:{cmd:e(power)}}power set by {cmd:power()}, {cmd:opower()}{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:apcspline}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(link)}}name of link function used{p_end}
{synopt:{cmd:e(linkt)}}link title{p_end}
{synopt:{cmd:e(linkf)}}link form{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(offset)}}offset{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared
	test{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(crittype)}}optimization criterion{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(population)}}population variable{p_end}
{synopt:{cmd:e(age)}}age variable{p_end}
{synopt:{cmd:e(period)}}period variable{p_end}
{synopt:{cmd:e(C)}}variables forming basis for spline in cohort{p_end}
{synopt:{cmd:e(P)}}variables forming basis for spline in period{p_end}
{synopt:{cmd:e(A)}}variables forming basis for spline in age{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(b1)}}coefficient vector for log link fit to nonlog link fitted
values (with nonlog link only){p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Reference}

{phang}
McCullagh, P., and J. A. Nelder.  1989.  
{browse "http://www.stata.com/bookstore/glm.html":{it:Generalized Linear Models}. 2nd ed.}
London: Chapman & Hall/CRC.


{title:Author}

{pstd}Peter D. Sasieni{p_end}
{pstd}Centre for Cancer Prevention{p_end}
{pstd}Wolfson Institute of Preventive Medicine{p_end}
{pstd}Queen Mary, University of London{p_end}
{pstd}London, UK {p_end}
{pstd}p.sasieni@qmul.ac.uk{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 4: {browse "http://www.stata-journal.com/article.html?article=up0057":st0245_1},{break}
                    {it:Stata Journal}, volume 12, number 1: {browse "http://www.stata-journal.com/article.html?article=st0245":st0245}

{p 5 14 2}Manual:  {manlink R poisson}

{p 7 14 2}Help:  {help apcspline postestimation},
{manhelp poisson_postestimation R:poisson postestimation};{break}
{manhelp glm R},
{manhelp nbreg R},
{manhelp svy_estimation SVY:svy estimation},
{manhelp tpoisson R},
{manhelp xtpoisson XT},
{manhelp zip R}
{p_end}
