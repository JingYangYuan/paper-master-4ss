{smcl}
{* *! version 1.1.0 19may2014}{...}
{cmd:help margte}{right: ({browse "http://www.stata-journal.com/article.html?article=st0331":SJ14-1: st0331})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col:{cmd:margte} {hline 2}}Marginal treatment effects{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Parametric normal model

{p 8 11 2}
{cmd:margte} {depvar:_o} {indepvars:_o} {ifin}{cmd:,} {cmdab:t:reatment(}{depvar:_t} {indepvars:_t}{cmd:)} [{it:advanced_options}]


{pstd}
Parametric polynomial model

{p 8 11 2}
{cmd:margte} {it:depvar_o} {it:indepvars_o} {ifin}{cmd:,} {cmdab:t:reatment(}{it:depvar_t} {it:indepvars_t}{cmd:)} {opt poly:nomial(#)} [{it:advanced_options}]


{pstd}
Semiparametric local instrumental variables (LIV) model

{p 8 11 2}
{cmd:margte} {it:depvar_o} {it:indepvars_o} {ifin}{cmd:,} {cmdab:t:reatment(}{it:depvar_t} {it:indepvars_t}{cmd:)} 
	{opt semi:parametric} [{it:advanced_options}]


{pstd}
Semiparametric polynomial model

{p 8 11 2}
{cmd:margte} {it:depvar_o} {it:indepvars_o} {ifin}{cmd:,} {cmdab:t:reatment(}{it:depvar_t} {it:indepvars_t}{cmd:)}
	 {opt poly:nomial(#)} {opt semi:parametric} [{it:advanced_options}]

	
{synoptset 32 tabbed}{...}
{synopthdr:required_options}
{synoptline}
{p2coldent :* {cmdab:t:reatment(}{it:depvar_t} {it:indepvars_t}{cmd:)}}specify the treatment equation that estimates the propensity score{p_end}
{p2coldent :* {opt poly:nomial(#)}}specify the degree of the polynomial for
the parametric or semiparametric polynomial model{p_end}
{p2coldent :* {opt semi:parametric}}specify that the semiparametric LIV or
polynomial model be fit{p_end}
{synoptline}
{p 4 6 2}* {cmd:treatment()} is required.{p_end}
{p 4 6 2}* {cmd:polynomial()} is required when specifying a parametric
polynomial model or a semiparametric polynomial model.{p_end}
{p 4 6 2}* {cmd:semiparametric} is required when specifying a semiparametric
LIV model or a semiparametric polynomial model.{p_end}

{synoptset 25}{...}
{synopthdr:advanced_options}
{synoptline}
{synopt:{opt f:irst}}report the first-step estimates{p_end}
{synopt:{opt l:ink(string)}}link function can be {cmd:probit}, {cmd:logit}, or {cmd:lpm}; default is {cmd:link(probit)}{p_end}
{synopt:{opt c:ommon}}calculate and graph the common support{p_end}
{synopt:{opt noc:ommongraph}}suppress the graph generated when {opt common} is specified{p_end}
{synopt:{opt csbar:width(#)}}specify the bar width in the common support graph; default is {cmd:csbarwidth(.01)}{p_end}
{synopt:{cmdab:x:values(}{it:#}{cmd:,} {it:#}{cmd:,} ...{cmd:)}}specify values
of the independent variables at which to calculate the MTE; default is the
means{p_end}
{synopt:{cmdab: c:onstraints(}{it:#}{cmd:,} {it:#}{cmd:,} ...{cmd:)}}apply specified linear constraints{p_end}
{synopt:{opt ml:ikelihood}}fit the parametric normal model using maximum
likelihood; use caution when {helpb test:test}ing hypotheses (see {help margte##mlikelihood:below}){p_end}
{synopt:{cmdab:mlo:pts(}{it:string}{cmd:)}}control the maximization process; seldom used{p_end}
{synopt:{opt deg:ree(#)}}specify the number of polynomial degrees in the nonparametric regression of Ytilde on K(p) for the semiparametric LIV model; default is {cmd:degree(2)}{p_end}
{synopt:{opt k:ernel(kernel)}}specify the kernel function; default is {cmd:kernel(epanechnikov)}{p_end}
{synopt:{opt ybw:idth(#)}}specify the kernel bandwidth for {it:depvar_o};
default is {helpb lpoly}'s rule-of-thumb estimator{p_end}
{synopt:{opt xbw:idth(#)}}specify the kernel bandwidth for all
{it:indepvars_o}; default is {cmd:lpoly}'s rule-of-thumb estimator{p_end}
{synopt:{opt savepr:opensity}}save the propensity score as variable {cmd:p}{p_end}
{synopt:{opt nop:lot}}suppress the MTE plot{p_end}
{synopt:{opt p:lotci(string)}}specify the confidence interval type for the MTE plot{p_end}
{synopt:{opt nobo:ot}}turn off standard error bootstrapping{p_end}
{synopt:{opt l:evel(#)}}specify a confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt bca}}compute acceleration for bias-corrected confidence intervals{p_end}
{synopt:{cmdab:bso:pts(}{it:string}{cmd:)}}specify other {cmd:bootstrap} options{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}See {helpb bootstrap_postestimation:[R] bootstrap postestimation} for
features available after estimation.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:margte} calculates marginal treatment effects (MTEs) derived
from the generalized Roy model by using parametric or semiparametric
methods.


{marker options}{...}
{title:Options}

{phang}
{cmd:treatment(}{depvar:_t} {indepvars:_t}{cmd:)} specifies the
treatment equation that estimates the propensity score.  The first
variable in the list is the dependent variable and all following
variables are the independent variables.  The independent variable list
should, in most cases, contain at least one variable that is not in the
outcome equation.  {cmd:treatment()} is required.

{phang}
{opt polynomial(#)} specifies the degree of the polynomial in the
propensity score used to fit K(p) for the parametric and
semiparametric polynomial models.  If the option is not specified,
{cmd:margte} will fit the parametric normal or semiparametric LIV
model depending on whether the {cmd:semiparametric} option is also
present.  {cmd:polynomial()} is required when specifying a parametric
polynomial model or a semiparametric polynomial model.

{phang}
{opt semiparametric} specifies that the semiparametric LIV or, when
combined with the {cmd:polynomial()} option, the semiparametric
polynomial model be fit.  {cmd:semiparametric} is required when
specifying a semiparametric LIV model or a semiparametric polynomial
model.

{phang}
{opt first} specifies that {cmd:margte} display the first-step estimates of
the treatment equation before estimation.  If the model is estimated by
maximum likelihood, {cmd:margte} will display the output from 
{helpb movestay}.

{phang}
{opt link(string)} specifies the link function used in estimating the
propensity score.  It can be estimated using {helpb probit}, 
{helpb logit}, or the linear probability model ({cmd:lpm}).  The
default, {cmd:link(probit)}, is also the only link function allowed if
{cmd:margte} is fitting the parametric normal model.

{phang}
{opt common} specifies that the common support be calculated and
graphed.  For U_D from 0.01 to 0.99 in increments of 0.01, a given value
of U_D is in the common support if both treated and untreated
observations are in the neighborhood |U_D(obs) - U_D| < 0.005.  MTE
is identified for semiparametric models only at values of U_D that have
common support, thus {cmd:margte} automatically invokes this option if a
semiparametric model is specified.  Parametric models do not depend on
common support for identification and by default do not invoke
{cmd:common}.

{phang}
{opt nocommongraph} suppresses the graph generated when the option
{cmd:common} is specified.

{phang}
{opt csbarwidth(#)} specifies the width of the bars in the common
support graph.  The default, {cmd:csbarwidth(0.1)}, gives a consistent
appearance regardless of the graph's dimensions.

{phang}
{cmd:xvalues(}{it:#}{cmd:,} {it:#}{cmd:,} ...{cmd:)} specifies
the values of {indepvars:_o} at which to calculate the MTE.  The
values must be separated by commas and follow the order of {it:indepvars_o}.
The default is to evaluate the MTE at the means of {it:indepvars_o}.

{phang}
{cmd:constraints(}{it:#}{cmd:,} {it:#}{cmd:,} ...{cmd:)} specifies
linear constraints on the model's parameters; see {helpb constraint}.

{marker mlikelihood}{...}
{phang}
{opt mlikelihood} fits the parametric normal model with maximum
likelihood.  When {cmd:mlikelihood} is specified, {cmd:margte} calls 
{helpb movestay:movestay} and reformats the output to conform with the
standard described here.  To see the original output from
{cmd:movestay}, specify option {opt first} as well.  Postestimation
hypothesis testing is allowed, but use caution because {cmd:e(V)}
contains 0s when covariances are undefined.  In such circumstances,
{helpb test} may return an invalid answer.  Note that in the {cmd:movestay} 
output, rho1 and rho0 are corr(U1, V) and corr(U0, V).  {cmd:margte} follows
the notation of Heckman, Urzua, Vytlacil (2006b), where rho1 and rho0 are
cov(U1, V) and cov(U0, V).

{phang}
{opt mlopts(string)} controls the maximization process in
{cmd:movestay}.  See {helpb movestay}'s {it:maximize_options} and see
{helpb maximize} for details.  These options are seldom used.

{phang}
{opt degree(#)} specifies the degree of the polynomial in the
nonparametric regression of Ytilde on K(p) for the semiparametric LIV
model.  The regression provides dK(p)/dp, which is then used to
calculate the MTE.  The minimum degree allowed is 1.  The default is
{cmd:degree(2)}.  The semiparametric polynomial model matches the degree
to that specified in the {opt polynomial()} option.  See 
{helpb locpoly2} for details.

{phang}
{opth "kernel(kdensity##kernel:kernel)"} specifies the kernel
function used in the nonparametric regressions of the semiparametric
models.  The default is {cmd:kernel(epanechnikov)}.  (See {helpb lpoly}
for details.)  {cmd:kernel(epan2)} is not allowed.

{phang}
{opt ybwidth(#)} specifies the half-width of the kernel for
{it:depvar_o}, that is, the width of the smoothing window around each
point.  The specified value applies to all nonparametric regressions
involving {it:depvar_o}.  If left unspecified, {cmd:margte} uses
{cmd:lpoly's} rule-of-thumb (ROT) bandwidth estimator.

{phang}
{opt xbwidth(#)} specifies the half-width of the kernel for
{it:indepvars_o}, that is, the width of the smoothing window around each
point.  The specified value applies to all nonparametric regressions
involving {it:indepvars_o}.  If left unspecified, {cmd:margte} uses
{cmd:lpoly's} ROT bandwidth.

{phang}
{opt savepropensity} saves the propensity score as the variable {cmd:p}.
If any of the variables in memory are named {cmd:p}, then {cmd:margte} will
return an error.

{phang}
{opt noplot} suppresses the plot of the MTE.

{phang}
{opt plotci(string)} specifies which confidence intervals to plot for
the MTE from those provided by {cmd:bootstrap}.  {it:string} can be
{cmd:normal}, {cmd:percentile}, {cmd:bc}, and {cmd:bca}.  See 
{helpb bootstrap} for a detailed exposition on the differences between
the options.

{phang}
{opt noboot} turns off standard error bootstrapping.  No closed-form
solution for the standard error of the MTE exists.  Because
bootstrapping is computationally intensive, it may take a long time for
{cmd:margte} to run.

{phang}
{opt level(#)} specifies a confidence level for all standard errors.
The default is {cmd:level(95)}.

{phang}
{opt bca} computes acceleration for the bias-corrected confidence
intervals.  {cmd:bootstrap} automatically computes normal, percentile,
and bias-corrected confidence intervals, but {opt bca} must be called
separately because it is computationally intensive.

{phang}
{opt bsopts(string)} specifies other {cmd:bootstrap} options.  Useful
options include {opt reps(#)} and {opt cluster(varlist)}.  See 
{helpb bootstrap} for more information.


{marker remarks}{...}
{title:Remarks}

{pstd}
{ul:The model}{p_end}
{pstd}
The MTE is derived from the generalized Roy model{p_end}

{p 10} Y = (1 - D)Y_0 + DY_1{p_end}
{pin}Y_1 = a_1 + Xb_1 + U_1{p_end}
{pin}Y_0 = a_0 + Xb_0 + U_0{p_end}
{p 10} I = Zg - V{p_end}

{pstd}where{p_end}

{p 9} D = 1 if I > 0{p_end}
{p 9} D = 0 if I < 0{p_end}
{p 9}(U_0, U_1, V) ~ (0, S){p_end}

{pstd}
Transforming the treatment condition I > 0 gives{p_end}

{p 13}Zg > V{p_end}
{p 6}->{space 2}F(Zg) > F(V){p_end}
{p 6}->{space 3}P(Z) > U_D{p_end}

{pstd}
where F is the cumulative distribution function of V.  P(Z) is the
probability of treatment conditional on Z (often called the propensity
score), and U_D is a uniformly distributed random variable between 0 and
1 (often called the propensity not to be treated).{p_end}

{pstd}
For individuals at the margin of treatment, P(Z) = U_D.  The derivative
of E{Y|X = x, P(Z) = p} with respect to p identifies the MTE,
E{Y_1-Y_0|X = x, P(Z) = u_D}.  It is the change in E{Y|X = x, P(Z) = p}
that results from a small change in p.  Formally,{p_end}

{pin}MTE(x, p) = E{Y1 - Y0|X = x, P(Z) = u_D} = dE{Y|X = x, P(Z) =
p}/dp{p_end}

{pstd}
We can trace out the distribution of the MTE over U_D, MTE(x, u_D),
within the support of p.  For parametric models, the support of p is the
range 0 < p < 1.  For semiparametric models, the support of p are those
values for which we possess treated and untreated observations (known as
the common support).{p_end}

{pstd}{ul:Estimation}{p_end}
{pstd}
To estimate E{Y|X = x, P(Z) = p} and its derivative with respect to p,
{cmd:margte} provides four methods, two parametric and two semiparametric.
It can be shown that{p_end}

{pin}E{Y|X = x, P(Z) = p} = a_0 + Xb_0 + (a_1 - a_0)p + X(b_1-b_0)p +
K(p){p_end}

{pstd}where{p_end}

{pin}K(p) = E{U_0|X = x, P(Z) = p} + E{U1 - U0|X = x, P(Z) = p}p{p_end}

{pstd}
The methods differ in how they estimate K(p).{p_end}

{pstd}
Parametric normal (nests {helpb etregress} and {cmd:movestay}):  Assumes
(U_0, U_1, V) ~ N(0, S), permitting E{Y_1|X = x, P(Z) = p} and E{Y_0|X =
x, P(Z) = p} to be estimated directly.  The method normalizes the
variance of V to 1 and uses {helpb probit} to estimate the propensity
score.  Then

{p 12 16}E{Y_1|X = x, P(Z) = p} = a_1 + Xb_1 + rho_1[-{helpb normalden}{
{helpb invnormal}(p)} / p ]{p_end} {p 12 16}E{Y_0|X = x, P(Z) = p} = a_0
+ Xb_0 + rho_0[ {cmd:normalden}{ {cmd:invnormal}(p)} / (1 - p)]{p_end}

{pstd}Thus the parametric normal MTE is

{p 12 16}MTE(x, u_D) = (a_1 - a_0) + X(b_1 - b_0){p_end}
{p 16}+ (rho_1 - rho0)invnormCDF(u_D){p_end}

{pstd}
Note: For the remaining methods, the propensity score can be estimated
using {cmd:probit}, {cmd:logit}, or {cmd:lpm}.

{pstd}
Parametric polynomial: Approximates K(p) using a polynomial in p
of degree theta.

{p 12 16}K(p) = theta_1 * p + theta_2 * p^2 + ... + theta_i * p^i{p_end}

{pstd}Thus the parametric polynomial MTE is{p_end}
	
{p 12 16}MTE(x, p) = (a_1 - a_0) + X(b_1 - b_0){p_end}
{p 16}+ theta_1 + 2 * theta_2 * p + ... + i * theta_i * p^(i-1){p_end}

{pstd}
Semiparametric LIV: Runs a local linear regression of Y, X, and X*P(Z)
on p at each observed value of p with {cmd:lpoly} and saves the
residuals as eY, eX, and eXP.  Then the method linearly regresses eY on
eX and eXP to obtain b_0 and b_1.  Finally, it nonparametrically
regresses Ytilde on p over the common support using {cmd:locpoly2} where
{p_end}

{p 12 16}Ytilde = Y - X(b_1 - b_0) - X(b_1 - b_0)p{p_end}

{pstd}
The first derivative of Ytilde with respect to p is saved as dKdp(p).
Thus the semiparametric LIV MTE is{p_end}

{p 12 16}MTE(x, p) = X(b_1 - b_0) + dKdp(p)

{pstd}
Semiparametric polynomial: Approximates K(p) using a polynomial in p of
degree theta to obtain b_0 and b_1 as in the parametric polynomial
method, but then it follows the semiparametric LIV method and
nonparametrically regresses Ytilde on p over the common support to
obtain dKdp(p).  Thus the semiparametric polynomial MTE is{p_end}

{p 12 16}MTE(x, p) = X(b_1 - b_0) + dKdp(p)


{marker examples}{...}
{title:Examples}

{pstd}
Setup: Generate 5,000 observations from a parametric normal
data-generating process modeling the returns to college{p_end}
{phang2}{cmd:. margte_dgps}{p_end}

{pstd}
The parametric normal model{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol)}{p_end}

{pstd}
The parametric normal model with no plot or no bootstrapped standard errors{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) noplot noboot}{p_end}

{pstd}
The parametric normal model showing the first step and the common
support graph{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) first common}{p_end}

{pstd}
The parametric normal model evaluated at exp = 2, exp2 = 4, and momsEdu = 12{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) xvalues(2, 4, 12)}{p_end}

{pstd}
The parametric normal model with a confidence level of 80 and percentile confidence intervals{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) level(80) plotci(percentile)}{p_end}

{pstd}
The parametric normal model fit by using maximum likelihood via {helpb movestay}{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) mlikelihood}{p_end}

{pstd}
The parametric normal model constrained to match the model in {helpb etregress}{p_end}
{phang2}{cmd:. constraint 1 [Treated]exp{space 4} = [Untreated]exp}{p_end}
{phang2}{cmd:. constraint 2 [Treated]exp2{space 3} = [Untreated]exp2}{p_end}
{phang2}{cmd:. constraint 3 [Treated]momsEdu = [Untreated]momsEdu}{p_end}
{phang2}{cmd:. constraint 4 [Treated]r{space 6} = [Untreated]r}{p_end}
{phang2}{cmd:. constraint 5 [Treated]lns{space 4} = [Untreated]lns}{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) mlikelihood constraints(1/5)}{p_end}

{pstd}
The parametric polynomial model with a polynomial in p of degree four{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) polynomial(4)}{p_end}

{pstd}
The parametric polynomial model using logit to fit p{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) polynomial(4) link(logit)}{p_end}

{pstd}
The semiparametric LIV model{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) semiparametric}{p_end}

{pstd}
The semiparametric LIV model without bootstrapped standard errors{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) semiparametric noboot}{p_end}

{pstd}
The semiparametric LIV model using a local polynomial regression of degree four{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) semiparametric degree(4)}{p_end}

{pstd}
The semiparametric LIV model using a Gaussian kernel function and a bandwidth of 0.5 for the independent variables{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) semiparametric kernel(gaussian) xbwidth(0.5)}{p_end}

{pstd}
The semiparametric polynomial model{p_end}
{phang2}{cmd:. margte lwage exp exp2 momsEdu, treatment(enroll momsEdu distCol) semiparametric polynomial(4)}{p_end}


{marker saved_results}{...}
{title:Stored results}

{pstd}
{cmd:margte} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:margte}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(title2)}}secondary title in estimation output{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}; {cmd:V} excluded if {cmd:noboot} specified{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of {cmd:b}{p_end}
{synopt:{cmd:e(common)}}vector of common support over p{p_end}
{synopt:{cmd:e(mte)}}vector of MTE estimates{p_end}
{synopt:{cmd:e(ate)}}estimate of the average treatment effect conditional on
{cmd:xvalues()}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{pstd}{cmd:margte} additionally stores the following in {cmd:e()} if the
parametric normal model is specified:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(treated)}}parameters for treated observations{p_end}
{synopt:{cmd:e(untreated)}}parameters for untreated observations{p_end}
{synopt:{cmd:e(mills)}}difference between inverse Mills ratio coefficients{p_end}

{pstd}
If option {opt mlikelihood} is specified:{p_end}
{synopt:{cmd:e(VML)}}variance-covariance matrix from maximum likelihood
stage of estimation{p_end}

{pstd}
{cmd:margte} additionally stores the following in {cmd:e()} if standard
errors are bootstrapped:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(mte_bc)}}matrix of bias-corrected confidence intervals (CIs) for MTE estimates{p_end}
{synopt:{cmd:e(mte_bca)}}matrix of bias-corrected and accelerated CIs for MTE estimates{p_end}
{synopt:{cmd:e(mte_percentile)}}matrix of percentile CIs for MTE estimates{p_end}
{synopt:{cmd:e(mte_normal)}}matrix of normal-approximation CIs for MTE estimates{p_end}

{pstd}
Note: {cmd:bootstrap} stores its own output in {cmd:e()} as well.  See
{helpb bootstrap##saved_results:bootstrap}.
{p2colreset}{...}

{pstd}
{cmd:margte} additionally stores the following in {cmd:e()} if a
semiparametric model is specified:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(}{it:depvar}{cmd:BWidth)}}half-width of the kernel for the {it:depvar} in the double residual regression{p_end}
{synopt:{cmd:e(}{it:indepvars}{cmd:BWidth)}}half-width of the kernels for the {it:indepvars} in the double residual regression{p_end}
{synopt:{cmd:e(}{it:depvar}{cmd:tildeBW)}}half-width of the kernel for the {it:depvar} in the Ytilde regression{p_end}


{marker references}{...}
{title:References}

{phang}
Heckman, J. J. 2010. Building bridges between structural and program evaluation approaches to evaluating policy. {it:Journal of Economic Literature} 48: 356-398.

{phang}
Heckman, J. J., S. Urzua, and E. J. Vytlacil. 2006. Understanding instrumental variables in models with essential heterogeneity. {it:Review of Economics and Statistics} 88: 389-432.

{phang}
------. 2006b. Web supplement to understanding instrumental variables in models with essential heterogeneity: Estimation of treatment effects under essential heterogeneity. 
{browse "http://jenni.uchicago.edu/underiv/documentation_2006_03_20.pdf"}.

	
{marker Authors}{...}
{title:Authors}

{pstd}Thomas Walstrum{p_end}
{pstd}University of Illinois at Chicago{p_end}
{pstd}Federal Reserve Bank of Chicago{p_end}
{pstd}Chicago, IL{p_end}
{pstd}twalstrum@frbchi.org{p_end}

{pstd}Scott Brave{p_end}
{pstd}Federal Reserve Bank of Chicago{p_end}
{pstd}Chicago, IL{p_end}
{pstd}sbrave@frbchi.org{p_end}


{marker also_see}{...}
{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 1: {browse "http://www.stata-journal.com/article.html?article=st0331":st0331}

{p 7 14 2}Help:  {helpb movestay}, {helpb locpoly2} (if installed),
{manhelp lpoly R}, {manhelp etregress TE}, {manhelp probit R}, 
{manhelp logit R}, {manhelp regress R}, {manhelp bootstrap R}{p_end}
