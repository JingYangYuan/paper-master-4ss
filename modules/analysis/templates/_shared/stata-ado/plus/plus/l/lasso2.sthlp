{smcl}
{* *! version 1.0.11  15jan2019}{...}
{cmd:help lasso2}{right: ({browse "https://doi.org/10.1177/1536867X20909697":SJ20-1: st0594})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col:{cmd:lasso2} {hline 2}}Program for lasso, square-root lasso, elastic
net, ridge, adaptive lasso, and postestimation ordinary least squares{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4} Full syntax

{p 8 14 2}
{cmd:lasso2}
{it:depvar} {it:regressors} 
{ifin}
{bind:[{cmd:,}} {cmdab:alp:ha(}{it:real}{cmd:)}
{cmd:sqrt}
{cmdab:ada:ptive}
{cmdab:adal:oadings(}{it:string}{cmd:)}
{cmdab:adat:heta(}{it:real}{cmd:)}
{cmd:ols}
{cmdab:l:ambda}{cmd:(}{it:numlist}{cmd:)}
{cmdab:lc:ount}{cmd:(}{it:integer}{cmd:)}
{cmdab:lminr:atio}{cmd:(}{it:real}{cmd:)}
{cmd:lmax}{cmd:(}{it:real}{cmd:)}
{cmd:lic}{cmd:(}{it:string}{cmd:)}
{cmdab:ebicg:amma}{cmd:(}{it:real}{cmd:)}
{cmdab:postres:ults}
{cmdab:notp:en(}{it:varlist}{cmd:)}
{cmdab:par:tial(}{it:varlist}{cmd:)}
{cmdab:nor:ecover}
{cmdab:pl:oadings(}{it:matrix}{cmd:)}
{cmdab:unitl:oadings}
{cmdab:prestd}
{cmdab:stdc:oef}
{cmd:fe}
{cmd:noftools}
{cmdab:noc:onstant}
{cmdab:tolo:pt}{cmd:(}{it:real}{cmd:)}
{cmdab:tolz:ero}{cmd:(}{it:real}{cmd:)}
{cmdab:maxi:ter}{cmd:(}{it:int}{cmd:)}
{cmdab:plot:path}{cmd:(}{it:method}{cmd:)}
{cmdab:plotv:ar}{cmd:(}{it:varlist}{cmd:)}
{cmdab:ploto:pt}{cmd:(}{it:string}{cmd:)}
{cmdab:plotl:abel}
{opt displayall}
{opt postall}
{cmd:long}
{opt ver:bose}
{cmdab:vver:bose}
{cmd:ic}{cmd:(}{it:string}{cmd:)}
{opt noic}
{bind:{cmd:wnorm}]}

{p 8 14 2}
Note: The {opt fe} option will take advantage of the {cmd:ftools} package
(Correia {help cvlasso##SG2016:2016}) (if installed) for the fixed-effects
transformation; the speed gains using this package can be large.  See
{rnethelp "http://fmwww.bc.edu/RePEc/bocode/f/ftools.sthlp":{cmd:ftools}} or
click on {bf:{stata "ssc install ftools"}} to install.

{synoptset 23}{...}
{p2coldent :Estimators}Description{p_end}
{synoptline}
{synopt:{cmdab:a:lpha(}{it:real}{cmd:)}}elastic-net parameter, which controls
the degree of L1-norm (lasso-type) to L2-norm (ridge-type) penalization;
{cmd:alpha(1)} corresponds to the lasso (the default estimator), and
{cmd:alpha(0)} corresponds to ridge regression; 
{cmd:alpha()} must be in the interval [0,1]{p_end}
{synopt:{cmd:sqrt}}square-root lasso estimator{p_end}
{synopt:{cmdab:ada:ptive}}adaptive lasso estimator; the penalty loading for
predictor j is set to 1/abs(beta0(j))^theta, where beta0(j) is the ordinary
least-squares (OLS) estimate or univariate OLS estimate if p>n; theta is the
adaptive exponent and can be controlled using the
{cmd:adatheta(}{it:real}{cmd:)} option{p_end}
{synopt:{cmdab:adal:oadings(}{it:string}{cmd:)}}alternative initial estimates,
beta0, used for calculating adaptive loadings; for example, this could be the
vector {cmd:e(b)} from an initial {cmd:lasso2} estimation; the elements of the
vector are raised to the power -theta (note the minus); see {cmd:adaptive}
option{p_end}
{synopt:{cmdab:adat:heta(}{it:real}{cmd:)}}exponent for calculating adaptive
penalty loadings; see {cmd:adaptive} option; default is {cmd:adatheta(1)}{p_end}
{synopt:{cmd:ols}}postestimation OLS; if lambda is a list, postestimation
OLS results are displayed and returned in {cmd:e(betas)}; if lambda is a
scalar, postestimation OLS is always displayed, and this option controls
whether standard or postestimation OLS results are stored in {cmd:e(b)}{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
See overview of {help lasso2##estimators:estimation methods}.

{synoptset 23 tabbed}{...}
{p2coldent :Lambda(s)}Description{p_end}
{synoptline}
{synopt:{cmdab:l:ambda}{cmd:(}{it:numlist}{cmd:)}}a scalar lambda value or
list of descending lambda values; each lambda value must be greater than 0;
if not specified, the default list is used, which is defined by {cmd:exp(rangen(log(lmax),log(lminratio*lmax),lcount))} (see {helpb mata range():mf_range()}){p_end}
{p2coldent :{c 0134} {cmdab:lc:ount}{cmd:(}{it:integer}{cmd:)}}number of
lambda values for which the solution is obtained; default is
{cmd:lcount(100)}{p_end}
{p2coldent :{c 0134} {cmdab:lminr:atio}{cmd:(}{it:real}{cmd:)}}ratio of
minimum to maximum lambda; {cmd:lminratio} must be between 0 and 1;
default is {cmd:lminratio(1/1000)}{p_end}
{p2coldent :{c 0134} {cmd:lmax}{cmd:(}{it:real}{cmd:)}}maximum lambda value;
default is {cmd:lmax(2*max(X'y))} or {cmd:lmax(max(X'y))} in the case of the
square-root lasso (where X is the prestandardized regressor matrix and y is
the vector of the response variable){p_end}
{synopt:{cmd:lic}{cmd:(}{it:string}{cmd:)}}after first {cmd:lasso2} estimation
using list of lambdas, fit the model corresponding to minimum information
criterion; {cmd:aic}, {cmd:bic}, {cmd:aicc}, or {cmd:ebic} (the default) are
allowed; note the lowercase spelling; see
{it:{help lasso2##informationcriteria:Information criteria}} for the
definition of each information criterion{p_end}
{synopt:{cmdab:ebicg:amma}{cmd:(}{it:real}{cmd:)}}control the xi parameter of
the extended Bayesian information criterion (EBIC); xi needs to lie in the
[0,1] interval; xi=0 is equivalent to the Bayesian information criterion
(BIC); the default choice is xi=1-log(n)/{2*log(p)}{p_end}
{synopt:{cmdab:postres:ults}}used in combination with {cmd:lic()}; stores
estimation results of the model selected by information criterion in
{cmd:e()}{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
{c 0134} Not applicable if {cmd:lambda()} is specified.

{synoptset 23}{...}
{p2coldent :Loadings/standardization}Description{p_end}
{synoptline}
{synopt:{cmdab:notp:en(}{it:varlist}{cmd:)}}set penalty loadings to zero for
predictors in {it:varlist}; unpenalized predictors are always included in the model{p_end}
{synopt:{cmdab:par:tial(}{it:varlist}{cmd:)}}partial out variables in {it:varlist} prior to estimation{p_end}
{synopt:{cmdab:nor:ecover}}suppress recovery of partialed-out variables after estimation{p_end}
{synopt:{cmdab:pload:ings(}{it:matrix}{cmd:)}}row vector of penalty loadings;
overrides the default standardization
loadings (in the case of the lasso, =sqrt[avg(x^2)]);
the size of the vector should equal the number of predictors (excluding
partialed-out variables and excluding the constant){p_end}
{synopt:{cmdab:unitl:oadings}}penalty loadings set to a vector of ones;
overrides the default standardization loadings (in the case of the lasso,
=sqrt[avg(x^2)]){p_end}
{synopt:{cmdab:pres:td}}standardize dependent variable and predictors prior to estimation 
rather than "on the fly" using penalty loadings;
see {help lasso2##standardization:here} for more details;
by default, the coefficient estimates are unstandardized (that is, returned in original units){p_end}
{synopt:{cmdab:stdc:oef}}return coefficients in standard deviation units; that
is, do not unstandardize; supported only with {cmd:prestd} option{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
See {help lasso2##standardization:discussion of standardization}.

{synoptset 23}{...}
{p2coldent :FE and constant}Description{p_end}
{synoptline}
{synopt:{cmd:fe}}within transformation is applied prior to estimation;
requires data to be {cmd:xtset}{p_end}
{synopt:{cmd:noftools}}do not use the {helpb lasso2##SG2016:ftools} package
for fixed-effects transformation (slower; rarely used){p_end}
{synopt:{cmdab:nocons:tant}}suppress constant from estimation; default behavior is to partial the constant out (that is, to center the regressors){p_end}
{synoptline}
{p2colreset}{...}

{synoptset 23}{...}
{p2coldent :Optimization}Description{p_end}
{synoptline}
{synopt:{cmdab:tolo:pt}{cmd:(}{it:real}{cmd:)}}tolerance for lasso shooting
algorithm; default is {cmd:tolopt(1e-10)}{p_end}
{synopt:{cmdab:tolz:ero}{cmd:(}{it:real}{cmd:)}}minimum below which coefficients are rounded down to zero; default is {cmd:tolzero(1e-4)}{p_end}
{synopt:{cmdab:maxi:ter}{cmd:(}{it:int}{cmd:)}}maximum number of iterations
for the lasso shooting algorithm; default is {cmd:maxiter(10000)}{p_end}
{synoptline}
{p2colreset}{...}

{marker plottingopts}{...}
{synoptset 23}{...}
{p2coldent :Plotting options*}Description{p_end}
{synoptline}
{synopt:{cmdab:plot:path(}{it:method}{cmd:)}}plot the coefficients path as a
function of the L1 norm ({cmd:norm}), lambda ({cmd:lambda}), or log of
lambda ({cmd:lnlambda}){p_end}
{synopt:{cmdab:plotv:ar(}{it:varlist}{cmd:)}}list of variables to be included in the plot{p_end}
{synopt:{cmdab:ploto:pt(}{it:string}{cmd:)}}additional plotting options passed
to {helpb line}; for example, use {cmd:plotopt(legend(off))} to turn off the legend{p_end}
{synopt:{cmdab:plotl:abel}}display variable labels in plot{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
* Plotting is not available if lambda is a scalar value.

{synoptset 23 tabbed}{...}
{p2coldent :Display options}Description{p_end}
{synoptline}
{p2coldent :* {opt displayall}}display full coefficient vectors, including
unselected variables; default is display only selected, unpenalized, and
partialed out{p_end}
{p2coldent :* {opt postall}}post full coefficient vector, including unselected
variables in {cmd:e(b)}; default is {cmd:e(b)} has only selected, unpenalized,
and partialed out{p_end}
{p2coldent :{c 0134} {opt long}}show long output; instead of showing only the points at which predictors enter or leave
 the model, all models are shown{p_end}
{synopt:{opt ver:bose}}show additional output{p_end}
{synopt:{opt vver:bose}}show even more output{p_end}
{p2coldent :{c 0134} {cmd:ic}{cmd:(}{it:string}{cmd:)}}control which
information criterion is shown in the output;
{cmd:aic}, {cmd:bic}, {cmd:aicc}, or {cmd:ebic} (the default) are allowed;
note the lowercase spelling;
see {it:{help lasso2##informationcriteria:Information criteria}} for the definition of each information criterion{p_end}
{p2coldent :{c 0134} {cmd:noic}}suppress the calculation of information
criteria;
this will lead to speed gains if alpha<1
because calculation of effective degrees of freedom requires one inversion per lambda{p_end}
{p2coldent :{c 0134} {opt wnorm}}display the L1 norm of beta estimates weighted
by penalty loadings, that is, ||Psi*beta||(1) instead of ||beta||(1), which is
the default; note that this also affects plotting if {cmd:plotpath(norm)} is
specified{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
* Applicable only if lambda is a scalar value.{p_end}
{pstd}
{c 0134} Applicable only if lambda is a list (the default).

{p 4} Replay syntax

{p 8 14 2}
{cmd:lasso2}
{bind:[{cmd:,}}
{opt long}
{cmd:ic}{cmd:(}{it:string}{cmd:)}
{cmd:lic}{cmd:(}{it:string}{cmd:)}
{cmdab:postres:ults}
{cmdab:plot:path}{cmd:(}{it:method}{cmd:)}
{cmdab:plotv:ar}{cmd:(}{it:varlist}{cmd:)}
{cmdab:ploto:pt}{cmd:(}{it:string}{cmd:)}
{cmdab:plotl:abel}
{bind:{cmd:wnorm}]}

{synoptset 23}{...}
{p2coldent :Replay options}Description{p_end}
{synoptline}
{synopt:{opt long}}show long output; instead of showing only the points at which predictors enter or leave
 the model, all models are shown{p_end}
{synopt:{cmd:ic}{cmd:(}{it:string}{cmd:)}}controls which information criterion
is shown in the output;
{cmd:aic}, {cmd:bic}, {cmd:aicc}, and {cmd:ebic} (the default) are allowed;
note the lowercase spelling;
see {it:{help lasso2##informationcriteria:Information criteria}} for the definition of each information criterion{p_end}
{synopt:{cmd:lic}{cmd:(}{it:string}{cmd:)}}fit the model corresponding to minimum
information criterion;
{cmd:aic}, {cmd:bic}, {cmd:aicc}, and {cmd:ebic} (the default) are allowed;
note the lowercase spelling;
see {it:{help lasso2##informationcriteria:Information criteria}} for the definition of each information criterion{p_end}
{synopt:{cmdab:postres:ults}}store estimation results in {cmd:e()} if {cmd:lic}{cmd:(}{it:string}{cmd:)} is used{p_end}
{synopt:{cmdab:plot:path(}{it:method}{cmd:)}}see {help lasso2##plottingopts:plotting options} above{p_end}
{synopt:{cmdab:plotv:ar(}{it:varlist}{cmd:)}}see {help lasso2##plottingopts:plotting options} above{p_end}
{synopt:{cmdab:ploto:pt(}{it:string}{cmd:)}}see {help lasso2##plottingopts:plotting options} above{p_end}
{synopt:{cmdab:plotl:abel}}see {help lasso2##plottingopts:plotting options} above{p_end}
{synopt:{opt wnorm}}displays L1 norm of beta estimates weighted
by penalty loadings, that is, ||Psi*beta||(1) instead of ||beta||(1), which is
the default; note that this also affects plotting if {cmd:plotpath(norm)} is
specified{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
Applicable only if lambda was a list in the previous {cmd:lasso2} estimation.

{pstd}
Postestimation:

{p 8 14 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} 
{cmd:xb}
{cmdab:r:esiduals}
{cmd:ols}
{cmdab:l:ambda(}{it:real}{cmd:)}
{cmd:lid(}{it:int}{cmd:)}
{opt lic(string)}
{cmdab:appr:ox}
{cmdab:noi:sily}
{bind:{cmdab:postres:ults}]}

{synoptset 23 tabbed}{...}
{p2coldent :Predict options}Description{p_end}
{synoptline}
{synopt:{cmd:xb}}compute predicted values; the default{p_end}
{synopt:{cmdab:r:esiduals}}compute residuals{p_end}
{synopt:{cmd:ols}}use postestimation OLS for prediction{p_end}
{p2coldent :{c 0135} {cmdab:l:ambda(}{it:real}{cmd:)}}lambda value for
prediction; ignored if {cmd:lasso2} was called with scalar lambda value{p_end}
{p2coldent :{c 0135} {cmd:lid(}{it:int}{cmd:)}}index of lambda value for prediction{p_end}
{synopt:{cmd:lic}{cmd:(}{it:string}{cmd:)}}select which information criterion to use for prediction{p_end}
{p2coldent :{c 0135} {cmdab:appr:ox}}linear approximation is used instead of
reestimation;
faster, but only exact if coefficient path is piecewise linear;
only supported in combination with {cmd:lambda()}{p_end}
{p2coldent :{c 0135} {cmdab:noi:sily}}show estimation output if reestimation
is required{p_end}
{p2coldent :{c 0135} {cmdab:postres:ults}}store estimation results in {cmd:e()} if reestimation is used{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
{c 0135} Applicable only if lambda was a list in the previous {cmd:lasso2} estimation.

{pstd}
{opt lasso2} may be used with time-series or panel data, in which case the
data must be {cmd:tsset} or {cmd:xtset} first; see {helpb tsset} or
{helpb xtset}.

{pstd}
All {it:varlist}s may contain time-series operators or factor variables; see
{varlist}.


{title:Contents}

{phang}{help lasso2##description:Description}{p_end}
{phang}{help lasso2##coordinate:Coordinate descent algorithm}{p_end}
{phang}{help lasso2##penalization:Penalization level: Choice of lambda (and alpha)}{p_end}
{phang}{help lasso2##standardization:Standardization of variables}{p_end}
{phang}{help lasso2##estimators:Estimators}{p_end}
{phang2}{help lasso2##rr:Ridge regression (Hoerl and Kennard 1970)}{p_end}
{phang2}{help lasso2##lasso_estimator:Lasso estimator (Tibshirani 1996)}{p_end}
{phang2}{help lasso2##elastic_net:Elastic net (Zou and Hastie 2005)}{p_end}
{phang2}{help lasso2##adaptive_lasso:Adaptive lasso (Zou 2006)}{p_end}
{phang2}{help lasso2##srlasso:Square-root lasso (Belloni, Chernozhukov, and Wang 2011, 2014)}{p_end}
{phang2}{help lasso2##postols:Postestimation OLS}{p_end}
{phang}{help lasso2##informationcriteria:Information criteria}{p_end}
{phang}{help lasso2##examples:Example using prostate cancer data (Stamey et al. 1989)}{p_end}
{phang2}{help lasso2##examples_data:Dataset}{p_end}
{phang2}{help lasso2##examples_general:General demonstration}{p_end}
{phang2}{help lasso2##examples_information:Information criteria}{p_end}
{phang2}{help lasso2##examples_plotting:Plotting}{p_end}
{phang2}{help lasso2##examples_predicted:Predicted values}{p_end}
{phang2}{help lasso2##examples_standardization:Standardization}{p_end}
{phang2}{help lasso2##examples_penalty:Penalty loadings and notpen()}{p_end}
{phang2}{help lasso2##examples_partialing:Partialing versus penalization}{p_end}
{phang2}{help lasso2##examples_adaptive:Adaptive lasso}{p_end}
{phang}{help lasso2##stored_results:Stored results}{p_end}
{phang}{help lasso2##references:References}{p_end}
{phang}{help lasso2##website:Website}{p_end}
{phang}{help lasso2##installation:Installation}{p_end}
{phang}{help lasso2##acknowledgments:Acknowledgments}{p_end}
{phang}{help lasso2##citation:Citation of lasso2}{p_end}
{phang}{help lasso2##authors:Authors}{p_end}
{phang}{help lasso2##alsosee:Also see}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt lasso2} solves the following problem,

{phang2}
	1/N RSS + lambda/N*alpha*||Psi*beta||[1] + lambda/(2*N)*(1-alpha)*||Psi*beta||[2]
	
{pstd}
where

{p2colset 8 17 19 2}{...}
{synopt:RSS}sum{y(i)-x(i)'beta}^2 and denotes the residual sum of
squares{p_end}
{synopt:beta}a p-dimensional parameter vector{p_end}
{synopt:lambda}the overall penalty level{p_end}
{synopt:||.||[j]}the L(j) vector norm for j=1,2{p_end}
{synopt:alpha}the elastic-net parameter, which determines the relative
    contribution of L1 (lasso-type) to L2 (ridge-type) penalization{p_end}
{synopt:Psi}a p by p diagonal matrix of predictor-specific penalty loadings
    (note that {cmd:lasso2} treats Psi as a row vector){p_end}
{synopt:N}the number of observations{p_end}

{pstd}
Note: The above lambda differs from the definition used in parts of the lasso
and elastic-net literature; see, for example, the R package {cmd:glmnet} by
Friedman, Hastie, and Tibshirani ({help lasso2##Friedman2010:2010}).  Here we
have adopted an objective function following
Belloni et al. ({help lasso2##Belloni2012:2012}).  Specifically,
lambda=2*N*lambda(GN), where lambda(GN) is the penalty level used by
{cmd:glmnet}.

{pstd}
In addition, if the option {cmd:sqrt} is specified, {opt lasso2} estimates the
square-root lasso (sqrt-lasso) estimator, which is defined as the solution to
the following objective function:

	sqrt(1/N*RSS) + lambda/N*||Psi*beta||[1]


{marker coordinate}{...}
{title:Coordinate descent algorithm}

{pstd}
{cmd:lasso2} implements the elastic net and sqrt-lasso using coordinate
descent algorithms.  The algorithm  (then referred to as "shooting") was first
proposed by Fu ({help lasso2##Fu1998:1998}) for the lasso and by Van der Kooij
({help lasso2##Kooji2007:2007}) for the elastic net.  Belloni, Chernozhukov,
and Wang ({help lasso2##BelloniSqrt2011:2011}) implement the coordinate
descent for the sqrt-lasso and have kindly provided MATLAB code.

{pstd}
Coordinate descent algorithms repeatedly cycle over predictors j = 1,...,p and
update single coefficient estimates until convergence.  Suppose the predictors
are centered and standardized to have unit variance.  In that case, the update
for coefficient j is obtained using univariate regression of the current
partial residuals (that is, excluding the contribution of predictor j) against
predictor j.

{pstd}
The algorithm requires an initial beta estimate for which the ridge estimate
is used.  If the coefficient path is obtained for a list of lambda values,
{cmd:lasso2} starts from the largest lambda value and uses previous estimates
as warm starts.

{pstd}
See Friedman et al. ({help lasso2##Friedman2007:2007}) and Friedman, Hastie,
and Tibshirani ({help lasso2##Friedman2010:2010}) and references therein for
further information.


{marker penalization}{...}
{title:Penalization level: Choice of lambda (and alpha)}

{pstd}
Penalized regression methods, such as the elastic net and the sqrt-lasso, rely
on tuning parameters that control the degree and type of penalization.  The
estimation methods implemented in {cmd:lasso2} use two tuning parameters:
lambda, which controls the general degree of penalization, and alpha, which
determines the relative contribution of L1-type to L2-type penalization.
{cmd:lasso2} obtains elastic-net and sqrt-lasso solutions for a given lambda
value or list of lambda values and for a given alpha value (default=1).

{pstd}
{cmd:lassopack} offers three approaches for selecting the "optimal" lambda
(and alpha) value:

{phang2}
(1) The penalty level may be chosen by cross-validation to optimize
out-of-sample prediction performance.  K-fold cross-validation and rolling
cross-validation (for panel and time-series data) are implemented in
{helpb cvlasso}.  {cmd:cvlasso} also supports cross-validation across alpha.

{phang2}
(2) Theoretically justified and feasible penalty levels and loadings are
available for the lasso and sqrt-lasso via the separate command
{helpb rlasso}.  The penalization is chosen to dominate the noise of the
data-generating process (represented by the score vector), which allows
derivation of theoretical results with regard to consistent prediction and
parameter estimation.  Because the error variance is in practice unknown,
Belloni et al. ({help lasso2##Belloni2012:2012}) introduce the rigorous (or
feasible) lasso, which relies on an iterative algorithm for estimating the
optimal penalization and is valid in the presence of non-Gaussian and
heteroskedastic errors.  Belloni et al. ({help lasso2##Belloni2016:2016})
extend the framework to the panel-data setting.  In the case of the sqrt-lasso
under homoskedasticity, the optimal penalty level is independent of the
unknown error variance, leading to a practical advantage and better
performance in finite samples (see Belloni, Chernozhukov, and Wang 
[{help lasso2##BelloniSqrt2011:2011}, {help lasso2##BelloniSqrt2014:2014}]).
See {helpb rlasso} for more details.

{phang2}
(3) Lambda can also be selected using information criteria.  {cmd:lasso2}
calculates four information criteria: the Akaike information criterion (AIC;
see Akaike [{help asso2##Akaike1974:1974}]), BIC (Schwarz
{help lasso2##Schwarz1978:1978}), EBIC (Chen and Chen
{help lasso2##Chen2008:2008}), and the corrected AIC (AICc; see Sugiura
[{help lasso2##Sugiura1978:1978}] and Hurvich and Tsai 
[{help lasso2##Hurvich1989:1989}]).  By default, {cmd:lasso2} displays EBIC in
the output, but all four information criteria are stored in {cmd:e(aic)},
{cmd:e(bic)}, {cmd:e(ebic)}, and {cmd:e(aicc)}.  See 
{it:{help lasso2##informationcriteria:Information criteria}} for more
information.


{marker standardization}{...}
{title:Standardization of variables}

{pstd}
Standard practice is for predictors to be "standardized", that is, normalized
to have mean zero and unit variance.  By default, {opt lasso2} achieves this by
incorporating the standardization into the penalty loadings.  We refer to this
method as standardization "on the fly" because standardization occurs during,
rather than before, estimation.  Alternatively, the option {opt prestd} causes
the predictors to be standardized prior to the estimation.

{pstd}
Standardizing "on the fly" via the penalty loadings and prestandardizing the
data prior to estimation are theoretically equivalent.  The default
standardizing "on the fly" is often faster.  The {opt prestd} option can lead
to improved numerical precision or more stable results in the case of
difficult problems; the cost is the computation time required to
prestandardize the data.


{marker estimators}{...}
{title:Estimators}


{marker rr}{...}
    {title:Ridge regression (Hoerl and Kennard {help lasso2##Hoerl1970:1970})}

{pstd}
The ridge estimator can be written as 

	 betahat(ridge) = {X'X+lambda*I(p)}^(-1)X'y

{pstd}
Thus, even if X'X is not full rank (for example, because p>n), the problem
becomes nonsingular by adding a constant to the diagonal of X'X.  Another
advantage of the ridge estimator over least squares stems from the
variance-bias tradeoff.  Ridge regression may improve over OLS by inducing a
mild bias while decreasing the variance, so ridge regression is a popular
method in the context of multicollinearity.  In contrast with estimators
relying on L1 penalization, the ridge does not yield sparse solutions and
keeps all predictors in the model.


{marker lasso_estimator}{...}
    {title:Lasso estimator (Tibshirani {help lasso2##Tib1996:1996})}

{pstd}
The lasso minimizes the residual sum of squares subject to a constraint on the
absolute size of coefficient estimates.  Tibshirani
({help lasso2##Tib1996:1996}) motivates the lasso with two major advantages
over least squares.  First, because of the nature of the L1 penalty, the lasso
tends to produce sparse solutions and thus facilitates model interpretation.
Second, similarly to ridge regression, lasso can outperform least squares in
terms of prediction because of its lower variance.  Another advantage is that
the lasso is computationally attractive because of its convex form.  This is
in contrast with model selection based on AIC and BIC (which use L0
penalization), where each possible submodel has to be fit.


{marker elastic_net}{...}
    {title:Elastic net (Zou and Hastie {help lasso2##Zou2005:2005})}

{pstd}
The elastic net applies a mix of L1 (lasso-type) and L2 (ridge-type)
penalization.  It combines some of the strengths of lasso and ridge
regression.  In the presence of groups of correlated regressors, the lasso
typically selects only one variable from each group, whereas the ridge tends
to produce similar coefficient estimates for groups of correlated variables.
However, the ridge does not yield sparse solutions, impeding model
interpretation.  The elastic net is able to produce sparse solutions (for some
alpha greater than zero) and retains (or drops) correlated variables jointly.


{marker adaptive_lasso}{...}
    {title:Adaptive lasso (Zou {help lasso2##Zou2006:2006})}

{pstd}
The lasso is variable-selection consistent only under the rather strong
"irrepresentable condition", which imposes constraints on the degree of
correlation between predictors in the true model and predictors outside the
model (see Zhao and Yu [{help lasso2##Zhao2006:2006}]; B{c u:}hlmann and
Meinshausen [{help lasso2##Buhlmann2006:2006}]).  Zou
({help lasso2##Zou2006:2006}) proposes the adaptive lasso, which uses penalty
loadings of 1/abs(beta0(j))^theta, where beta0 is an initial estimator.  The
adaptive lasso is variable-selection consistent for a fixed p under weaker
assumptions than the standard lasso.  If p<n, OLS can be used as the initial
estimator.  Huang, Ma, and Zhang ({help lasso2##Huang2008:2008}) suggest using univariate OLS if p>n.  Other initial estimators are possible.


{marker srlasso}{...}
    {title:Square-root lasso (Belloni, Chernozhukov, and Wang {help lasso2##BelloniSqrt2011:2011}, {help lasso2##BelloniSqrt2014:2014})}

{pstd}
The sqrt-lasso is a modification of the lasso that minimizes (RSS)^(1/2)
instead of RSS while also imposing an L1-penalty.  The main advantage of the
sqrt-lasso over the standard lasso is that the theoretically grounded,
data-driven optimal lambda is independent of the unknown error variance under
homoskedasticity.  See {helpb rlasso}.


{marker postols}{...}
    {title:Postestimation OLS}

{pstd}
Penalized regression methods induce a bias that can be alleviated by
postestimation OLS, which applies OLS to the predictors selected by the
first-stage variable-selection method.  For the case of the lasso, Belloni and
Chernozhukov ({help lasso2##Belloni2013:2013}) have shown that the postlasso
OLS performs at least as well as the lasso under mild additional assumptions.

{pstd} 
For further information on the lasso and related methods, see, for example,
the textbooks by Hastie, Tibshirani, and Friedman 
({help lasso2##Hastie2009:2009}); Hastie, Tibshirani, and Wainwright
({help lasso2##Hastie2015:2015}) (both available for free); and B{c u:}hlmann
and Van de Geer ({help lasso2##Buhlmann2011:2011}).


{marker informationcriteria}{...}
{title:Information criteria}
 
{pstd}
The information criteria supported by {cmd:lasso2} are the AIC (Akaike
{help lasso2##Akaike1974:1974}), the BIC (Schwarz
{help lasso2##Schwarz1978:1978}), the AICc 
({help lasso2##Sugiura1978:Sugiura 1978}; Hurvich and Tsai 
{help lasso2##Hurvich1989:1989}), and the EBIC (Chen and Chen
{help lasso2##Chen2008:2008}).  These are given by (omitting dependence on
lambda and alpha)

	AIC	= N*log(RSS/N) + 2*df
	BIC	= N*log(RSS/N) + df*log(N) 
	AICc	= N*log(RSS/N) + 2*df*N/(N-df)
	EBIC	= BIC + 2*xi*df*log(p)

{pstd} 
where RSS(lambda,alpha) is the residual sum of squares and df(lambda,alpha) is
the effective degrees of freedom, which is a measure of model complexity.  In
the linear regression model, the degrees of freedom is simply the number of
regressors.  Zou, Hastie, and Tibshirani ({help lasso2##Zou2007:2007}) show
that the number of nonzero coefficients is an unbiased and consistent
estimator of df(lambda,alpha) for the lasso.  More generally,  the degrees of
freedom of the elastic net can be calculated as the trace of the projection
matrix.  With an unbiased estimator for degrees of freedom available, the
above information criteria can be used to select tuning parameters.

{pstd} 
The BIC is known to be model-selection consistent if the true model is among
the candidate models, whereas the AIC tends to yield an overfitted model.  On
the other hand, the AIC is loss efficient in that it selects the model that
minimizes the squared average prediction error, while the BIC does not possess
this property.  Zhang, Li, and Tsai ({help lasso2##Zhang2010:2010}) show that
these principles also apply when AIC and BIC are used to select the tuning
parameter for penalized regression.

{pstd}
Both AIC and BIC tend to overselect regressors in the small-N-large-p case.
The AICc corrects the small-sample bias of the AIC, which can be especially
severe in the high-dimensional context.  Similarily, the EBIC addresses the
shortcomings of the BIC when p is large by imposing a larger penalty on the
number of coefficients.  Chen and Chen ({help lasso2##Chen2008:2008}) show
that the EBIC performs better in terms of false-discovery rate at the cost of
a negligible reduction in the positive selection rate.

{pstd} 
The EBIC depends on an additional parameter, xi (denoted as gamma in the
original article), that can be controlled using
{cmd:ebicgamma}{cmd:(}{it:real}{cmd:)}.  gamma=0 is equivalent to the BIC.  We
follow Chen and Chen ({help lasso2##Chen2008:2008, 768}) and use
xi=1-log(n)/{2*log(p)} as the default choice.  An upper and lower threshold is
applied to ensure that xi lies in the [0,1] interval.

{pstd} 
The EBIC is displayed in the output of {cmd:lasso2} by default (if lambda is a
list), but all four information criteria are returned in {cmd:e()}.  The
lambda values that minimize the information criteria for a given alpha are
returned in {cmd:e(laic)}, {cmd:e(lbic)}, {cmd:e(laicc)}, and {cmd:e(lebic)},
respectively.  To change the default display, use the
{cmd:ic(}{it:string}{cmd:)} option.  {cmd:noic} suppresses the calculation of
information criteria, which leads to a speed gain if alpha<1.


{marker examples}{...}
{title:Example using prostate cancer data (Stamey et al. {help lasso2##Stamey1989:1989})}


{marker examples_data}{...}
    {title:Dataset}

{pstd}
The dataset is available through Hastie, Tibshirani, and Friedman
({help lasso2##Hastie2009:2009}) on the 
{browse "https://web.stanford.edu/~hastie/ElemStatLearn/":authors' website}.
The following variables are included in the dataset of 97 men:

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Predictors}{p_end}
{synopt:{cmd:lcavol}}log(cancer volume){p_end}
{synopt:{cmd:lweight}}log(prostate weight){p_end}
{synopt:{cmd:age}}patient age{p_end}
{synopt:{cmd:lbph}}log(benign prostatic hyperplasia amount){p_end}
{synopt:{cmd:svi}}seminal vesicle invasion{p_end}
{synopt:{cmd:lcp}}log(capsular penetration){p_end}
{synopt:{cmd:gleason}}Gleason score{p_end}
{synopt:{cmd:pgg45}}percentage Gleason scores 4 or 5{p_end}

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Outcome}{p_end}
{synopt:{cmd:lpsa}}log(prostate specific antigen){p_end}

{pstd}
Load prostate cancer data.{p_end}
{phang2}
{bf:. {stata "insheet using https://web.stanford.edu/~hastie/ElemStatLearn/datasets/prostate.data, tab"}}{p_end}


{marker examples_general}{...}
    {title:General demonstration}

{pstd}
Estimate coefficient lasso path over (default) list of lambda values.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45"}}{p_end}

{pstd}
The replay syntax can be used to redisplay estimation results.{p_end}
{phang2}
{bf:. {stata "lasso2"}}{p_end}

{pstd}
User-specified lambda list.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, lambda(100 50 10)"}}{p_end}

{pstd}
The list of returned {cmd:e()} objects depends on whether {cmd:lambda()} is a
list (the default) or a scalar value.  For example, if lambda is a scalar, one
vector of coefficient estimates is returned.  If lambda is a list, the whole
coefficient path for a range of lambda values is obtained.  The last row of
{cmd:e(betas)} is equal to the row vector {cmd:e(b)}.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, lambda(100 50 10)"}}{p_end}
{phang2}
{bf:. {stata "ereturn list"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(betas)"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, lambda(10)"}}{p_end}
{phang2}
{bf:. {stata "ereturn list"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(b)"}}{p_end}

{pstd}
Sqrt-lasso.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, sqrt"}}{p_end}

{pstd}
Ridge regression.  All predictors are included in the model.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, alpha(0)"}}{p_end}

{pstd}
Elastic net with {cmd:alpha(0.1)}.  Even though alpha is close to zero (ridge
regression), the elastic net can produce sparse solutions.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, alpha(0.1)"}}{p_end}

{pstd}
The option {cmd:ols} triggers the use of postestimation OLS.  OLS alleviates
the shrinkage bias induced by L1- and L2-norm penalization.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, ols"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, sqrt ols"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, alpha(0.1) ols"}}{p_end}


{marker examples_information}{...}
    {title:Information criteria}

{pstd}
{cmd:lasso2} calculates four information criteria: AIC, BIC, EBIC, and AICc. 
The EBIC is shown by default in the output along with the R-squared.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45"}}{p_end}

{pstd}
To see another information criterion in the output, use the
{cmd:ic(}{it:string}{cmd:)} option, where {it:string} can be replaced by
{cmd:aic}, {cmd:bic}, {cmd:ebic}, or {cmd:aicc} (note the lowercase spelling).
For example, to display AIC:{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, ic(aic)"}}{p_end}

{pstd}
In fact, there is no need to rerun the full model.  We can use
the replay syntax:{p_end}
{phang2}
{bf:. {stata "lasso2, ic(aic)"}}{p_end}

{pstd}
The {cmd:long} option triggers extended output; instead of showing only the
points at which predictors enter or leave the model, all models are shown.  An
asterisk marks the model (that is, the value of lambda) that minimizes the
information criterion (here, AIC).{p_end}
{phang2}
{bf:. {stata "lasso2, ic(aic) long"}}{p_end}

{pstd}
To fit the model corresponding to the minimum information criterion, click on
the link at the bottom of the output, or type one of the following:{p_end}
{phang2}
{bf:. {stata "lasso2, lic(aic)"}}{p_end}
{phang2}
{bf:. {stata "lasso2, lic(ebic)"}}{p_end}
{phang2}
{bf:. {stata "lasso2, lic(bic)"}}{p_end}
{phang2}
{bf:. {stata "lasso2, lic(aicc)"}}{p_end}

{pstd}
To store the estimation results of the selected model, add the
{cmd:postresults} option.{p_end}
{phang2}
{bf:. {stata "lasso2, lic(ebic)"}}{p_end}
{phang2}
{bf:. {stata "ereturn list"}}{p_end}
{phang2}
{bf:. {stata "lasso2, lic(ebic) postres"}}{p_end}
{phang2}
{bf:. {stata "ereturn list"}}{p_end}

{pstd}
The same can also be achieved in one line without using the replay syntax.
{cmd:lasso2} first obtains the full coefficient path for a list of lambda values
and then runs the model selected by AIC.  Again, {cmdab:postresults} can be
used to store results of the selected model.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, lic(aic) postres"}}{p_end}


{marker examples_plotting}{...}
    {title:Plotting}

{pstd}
Plot coefficients against lambda:
As lambda increases, the coefficient estimates are shrunk toward zero.
Lambda=0 corresponds to OLS, and if lambda is sufficiently large, the model is empty.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, plotpath(lambda)"}}{p_end}

{pstd}
Plot coefficients against the L1 norm.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, plotpath(norm)"}}{p_end}

{pstd}
The replay syntax can also be used for plotting.{p_end}
{phang2}
{bf:. {stata "lasso2, plotpath(norm)"}}{p_end}

{pstd}
Only selected variables are plotted.{p_end}
{phang2}
{bf:. {stata "lasso2, plotpath(norm) plotvar(lcavol svi)"}}{p_end}

{pstd}
The variable names can be displayed directly next to each series using {cmd:plotlabel}.
{cmd:plotopt(legend(off))} suppresses the legend.{p_end}
{phang2}
{bf:. {stata "lasso2, plotpath(lambda) plotlabel plotopt(legend(off))"}}{p_end}
{phang2}
{bf:. {stata "lasso2, plotpath(norm) plotlabel plotopt(legend(off))"}}{p_end}


{marker examples_predicted}{...}
    {title:Predicted values}

{pstd}
{cmd:xbhat1} is generated by refitting the model for lambda=10. 
The {cmd:noisily} option triggers the display of the estimation results.
{cmd:xbhat2} is generated by linear approximation
using the two beta estimates closest to lambda=10.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45"}}{p_end}
{phang2}
{bf:. {stata "capture drop xbhat1"}}{p_end}
{phang2}
{bf:. {stata "predict double xbhat1, xb l(10) noisily"}}{p_end}
{phang2}
{bf:. {stata "capture drop xbhat2"}}{p_end}
{phang2}
{bf:. {stata "predict double xbhat2, xb l(10) approx"}}{p_end}

{pstd}
The model is fit explicitly using {cmd:lambda(10)}.  If {cmd:lasso2} is called with a
scalar lambda value, the subsequent {cmd:predict} command requires no
{cmd:lambda()} option.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, lambda(10)"}}{p_end}
{phang2}
{bf:. {stata "capture drop xbhat3"}}{p_end}
{phang2}
{bf:. {stata "predict double xbhat3, xb"}}{p_end}

{pstd}
All three methods yield the same results.  However, note that the linear
approximation is only exact for the lasso, which is piecewise linear.{p_end}
{phang2}
{bf:. {stata "summarize xbhat1 xbhat2 xbhat3"}}{p_end}

{pstd}
It is also possible to obtain predicted values 
by referencing a specific lambda ID using the {cmd:lid()} option.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45"}}{p_end}
{phang2}
{bf:. {stata "capture drop xbhat4"}}{p_end}
{phang2}
{bf:. {stata "predict double xbhat4, xb lid(21)"}}{p_end}
{phang2}
{bf:. {stata "capture drop xbhat5"}}{p_end}
{phang2}
{bf:. {stata "predict double xbhat5, xb l(25.45473900468241)"}}{p_end}
{phang2}
{bf:. {stata "summarize xbhat4 xbhat5"}}{p_end}


{marker examples_standardization}{...}
    {title:Standardization}

{pstd}
By default, {cmd:lasso2} standardizes the predictors to have unit variance.
Standardization is done by default on the fly via penalty loadings.
The coefficient estimates are returned in original units.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10)"}}{p_end}

{pstd}
Instead of standardizing "on the fly" by setting penalization loadings equal
to standardization loadings, we can standardize the regressors prior to
estimation with the {opt prestd} option.  Both methods are equivalent in
theory.  Standardizing "on the fly" tends to be faster, but prestandardization
may lead to more stable results in the case of difficult problems.  See
{help lasso2##standardization:here} for more information.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10)"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(Psi)"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) prestd"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(Psi)"}}{p_end}

{pstd}
The used penalty loadings are stored in {cmd:e(Psi)}.  In the first case
above, the standardization loadings are returned.  In the second case, the
penalty loadings are equal to one-for-all regressors.

{pstd}
To get the coefficients in standard deviation units,
{cmd:stdcoef} can be specified along with the {opt prestd} option.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) prestd stdcoef"}}{p_end}

{pstd}
We can override any form of standardization with the {opt unitloadings} option,
which sets the penalty loadings to a vector of 1s.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) unitloadings"}}{p_end}

{pstd}
The same logic applies to the sqrt-lasso (and elastic net).{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) sqrt"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) sqrt prestd"}}{p_end}


{marker examples_penalty}{...}
    {title:Penalty loadings and {cmd:notpen()}}

{pstd}
By default, the penalty loading vector is a vector of standard deviations.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10)"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(Psi)"}}{p_end}

{pstd}
We can set the penalty loading for specific predictors to zero, implying no
penalization.  Unpenalized predictors are always included in the model.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) notpen(lcavol)"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(Psi)"}}{p_end}

{pstd}
We can specify custom penalty loadings.  The option {cmd:ploadings()} expects a
row vector of size p, where p is the number of regressors (excluding the
constant, which is partialed out).  Because we prestandardize the data (and
we are using the lasso), the results are equivalent to the results above
(standardizing on the fly and specifying {cmd:lcavol} as unpenalized).{p_end}
{phang2}
{bf:. {stata "matrix myloadings = (0,1,1,1,1,1,1,1)"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) ploadings(myloadings) prestd"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(Psi)"}}{p_end}


{marker examples_partialing}{...}
    {title:Partialing versus penalization}

{pstd}
If lambda and the penalty loadings are kept constant, partialing out and not
penalizing variables yields the same results for the included or penalized
regressors.  Yamada ({help lasso2##Yamada2017:2017}) shows that the
equivalence of partialing out and not penalizing holds for lasso and ridge
regression.  The examples below suggest that the same result also holds for
the elastic net in general and the sqrt-lasso.  Note that the equivalence
holds only if the regressor matrix and other penalty loadings are the same.
Below,
we use the {opt unitloadings} option to achieve this; alternatively, we could
use the {opt ploadings(.)} option.

{pstd}Lasso.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) notpen(lcavol) unitload"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) partial(lcavol) unitload"}}{p_end}

{pstd}Sqrt-lasso.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) sqrt notpen(lcavol) unitload"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) sqrt partial(lcavol) unitload"}}{p_end}

{pstd}
Ridge regression.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) alpha(0) notpen(lcavol) unitload"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) alpha(0) partial(lcavol) unitload"}}{p_end}

{pstd}Elastic net.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) alpha(0.5) notpen(lcavol) unitload"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) alpha(0.5) partial(lcavol) unitload"}}{p_end}


{marker examples_adaptive}{...}
    {title:Adaptive lasso}

{pstd}
The adaptive lasso relies on an initial estimator to calculate the penalty
loadings.  The penalty loadings are given by 1/abs(beta0(j))^theta, where
beta0(j) denotes the initial estimate for predictor j.  By default,
{cmd:lasso2} uses OLS as the initial estimator as originally suggested by Zou
({help lasso2##Zou2006:2006}).  If the number of parameters exceeds the
numbers of observations, univariate OLS is used; see Huang, Ma, and Zhang
({help lasso2##Huang2008:2008}).{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, adaptive"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(Psi)"}}{p_end}

{pstd}
See the OLS estimates for comparison.{p_end}
{phang2}
{bf:. {stata "regress lpsa lcavol lweight age lbph svi lcp gleason pgg45"}}{p_end}

{pstd}
Theta (the exponent for calculating the adaptive loadings) 
can be changed using the {cmd:adatheta()} option.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, adaptive adat(2)"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(Psi)"}}{p_end}

{pstd}
Other initial estimators such as ridge regression are possible.{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, l(10) alpha(0)"}}{p_end}
{phang2}
{bf:. {stata "matrix bhat_ridge = e(b)"}}{p_end}
{phang2}
{bf:. {stata "lasso2 lpsa lcavol lweight age lbph svi lcp gleason pgg45, adaptive adaloadings(bhat_ridge)"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(Psi)"}}{p_end}


{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:lasso2} stores the following in {cmd:e()}.
The set of returned e-class objects depends on whether lambda is a scalar or a list (the default).

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}sample size{p_end}
{synopt:{cmd:e(cons)}}{cmd:1} if constant is present, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(fe)}}{cmd:1} if fixed-effects model is used, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(alpha)}}elastic-net parameter{p_end}
{synopt:{cmd:e(sqrt)}}{cmd:1} if the sqrt-lasso is used, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(ols)}}{cmd:1} if postestimation OLS results are returned, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(adaptive)}}{cmd:1} if adaptive loadings are used, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(p)}}number of penalized regressors in model{p_end}
{synopt:{cmd:e(notpen_ct)}}number of unpenalized variables{p_end}
{synopt:{cmd:e(partial_ct)}}number of partialed-out regressors (including constant){p_end}
{synopt:{cmd:e(prestd)}}{cmd:1} if prestandardized{p_end}
{synopt:{cmd:e(lcount)}}number of lambda values{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Scalars (only if lambda is a list)}{p_end}
{synopt:{cmd:e(lmax)}}largest lambda value{p_end}
{synopt:{cmd:e(lmin)}}smallest lambda value{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Scalars (only if lambda is a scalar)}{p_end}
{synopt:{cmd:e(lambda)}}penalty level{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(rmseOLS)}}root mean squared error of postestimation OLS{p_end}
{synopt:{cmd:e(pmse)}}minimized objective function (penalized mean squared error, lasso/elastic net/ridge only){p_end}
{synopt:{cmd:e(prmse)}}minimized objective function (penalized root mean
squared error, sqrt-lasso only){p_end}
{synopt:{cmd:e(k)}}number of selected and unpenalized/partialed-out regressors including constant
(if present){p_end}
{synopt:{cmd:e(s)}}number of selected regressors{p_end}
{synopt:{cmd:e(s0)}}number of selected and unpenalized regressors including constant (if present){p_end}
{synopt:{cmd:e(niter)}}number of iterations{p_end}
{synopt:{cmd:e(maxiter)}}maximum number of iterations{p_end}
{synopt:{cmd:e(tss)}}total sum of squares{p_end}
{synopt:{cmd:e(aicmin)}}minimum AIC{p_end}
{synopt:{cmd:e(bicmin)}}minimum BIC{p_end}
{synopt:{cmd:e(aiccmin)}}minimum AICc{p_end}
{synopt:{cmd:e(ebicmin)}}minimum EBIC{p_end}
{synopt:{cmd:e(laic)}}lambda corresponding to minimum AIC{p_end}
{synopt:{cmd:e(lbic)}}lambda corresponding to minimum BIC{p_end}
{synopt:{cmd:e(laicc)}}lambda corresponding to minimum AICc{p_end}
{synopt:{cmd:e(lebic)}}lambda corresponding to minimum EBIC{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lasso2}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(varX)}}all predictors{p_end}
{synopt:{cmd:e(varXmodel)}}penalized predictors{p_end}
{synopt:{cmd:e(partial)}}partialed out predictors{p_end}
{synopt:{cmd:e(notpen)}}unpenalized predictors{p_end}
{synopt:{cmd:e(method)}}estimation method{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Macros (only if lambda is a scalar)}{p_end}
{synopt:{cmd:e(selected)}}selected predictors{p_end}
{synopt:{cmd:e(selected0)}}selected predictors excluding constant{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Matrices}{p_end}
{synopt:{cmd:e(Psi)}}row vector used penalty loadings{p_end}
{synopt:{cmd:e(stdvec)}}row vector of standardization loadings{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Matrices (only if lambda is a list)}{p_end}
{synopt:{cmd:e(lambdamat)}}column vector of lambdas{p_end}
{synopt:{cmd:e(l1norm)}}column vector of L1 norms for each lambda value (excludes the intercept){p_end}
{synopt:{cmd:e(wl1norm)}}column vector of weighted L1 norms for each lambda
value (excludes the intercept); see {cmd:wnorm}{p_end}
{synopt:{cmd:e(dof)}}column vector of L0 norm for each lambda value (excludes the intercept){p_end}
{synopt:{cmd:e(betas)}}matrix of estimates, where each row corresponds to one
lambda value; the intercept is stored in the last column{p_end}
{synopt:{cmd:e(ess)}}column vector of explained sum of squares for each lambda value{p_end}
{synopt:{cmd:e(rss)}}column vector of residual sum of squares for each lambda value{p_end}
{synopt:{cmd:e(ebic)}}column vector of EBIC for each lambda value{p_end}
{synopt:{cmd:e(bic)}}column vector of BIC for each lambda value{p_end}
{synopt:{cmd:e(aic)}}column vector of AIC for each lambda value{p_end}
{synopt:{cmd:e(aicc)}}column vector of AICc for each lambda value{p_end}
{synopt:{cmd:e(rsq)}}column vector of R-squared for each lambda value{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Matrices (only if lambda is a scalar)}{p_end}
{synopt:{cmd:e(b)}}posted coefficient vector (see {cmd:postall} and
{cmd:displayall}); used for prediction{p_end}
{synopt:{cmd:e(beta)}}coefficient vector{p_end}
{synopt:{cmd:e(betaOLS)}}coefficient vector of postestimation OLS{p_end}
{synopt:{cmd:e(betaAll)}}full coefficient vector, including omitted variables, 
factor base variables, etc.{p_end}
{synopt:{cmd:e(betaAllOLS)}}full postestimation OLS coefficient vector,
including omitted variables, 
factor base variables, etc.{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker references}{...}
{title:References}

{marker Akaike1974}{...}
{phang}
Akaike, H. 1974. A new look at the statistical model identification.
{it:IEEE Transactions on Automatic Control} 19: 716-723.
{browse "https://doi.org/10.1109/TAC.1974.1100705"}.

{marker Belloni2012}{...}
{phang}
Belloni, A., D. Chen, V. Chernozhukov, and C. Hansen. 2012. Sparse models
and methods for optimal instruments with an application to eminent domain.
{it:Econometrica} 80: 2369-2429.
{browse "https://doi.org/10.3982/ECTA9626"}.

{marker Belloni2013}{...}
{phang}
Belloni, A., and V. Chernozhukov. 2013. Least squares after model selection
in high-dimensional sparse models. {it:Bernoulli} 19: 521-547.
{browse "https://doi.org/10.3150/11-BEJ410"}.

{marker Belloni2016}{...}
{phang}
Belloni, A., V. Chernozhukov, C. Hansen, and D. Kozbur. 2016. Inference in
high dimensional panel models with an application to gun control.
{it:Journal of Business & Economic Statistics} 34: 590-605.
{browse "https://doi.org/10.1080/07350015.2015.1102733"}.

{marker BelloniSqrt2011}{...}
{phang}
Belloni, A., V. Chernozhukov, and L. Wang. 2011. 
Square-root lasso: Pivotal recovery of sparse signals via conic programming. 
{it:Biometrika} 98: 791-806.
{browse "https://doi.org/10.1093/biomet/asr043"}.

{marker BelloniSqrt2014}{...}
{phang}
------. 2014. Pivotal estimation via
square-root lasso in nonparametric regression. {it:Annals of Statistics}
42: 757-788.
{browse "https://doi.org/10.1214/14-AOS1204"}.

{marker Buhlmann2006}{...}
{phang}
B{c u:}hlmann, P., and N. Meinshausen. 2006. High-dimensional graphs and
variable selection with the lasso. {it:Annals of Statistics} 34: 1436-1462. 
{browse "https://doi.org/10.1214/009053606000000281"}.

{marker Buhlmann2011}{...}
{phang}
B{c u:}hlmann, P., and S. Van de Geer. 2011. 
{it:Statistics for High-Dimensional Data: Methods, Theory and Applications}.
Berlin: Springer.

{marker Chen2008}{...}
{phang}
Chen, J., and Z. Chen. 2008. Extended Bayesian information criteria for
model selection with large model spaces. {it:Biometrika} 95: 759-771.
{browse "https://doi.org/10.1093/biomet/asn034"}.

{marker SG2016}{...}
{phang}
Correia, S. 2016.
ftools: Stata module to provide alternatives to common Stata commands
optimized for large datasets. Statistical Software Components S458213,
Department of Economics, Boston College.
{browse "https://ideas.repec.org/c/boc/bocode/s458213.html"}.

{marker Fu1998}{...}
{phang}
Fu, W. J. 1998. Penalized regressions: The bridge versus the lasso.
{it:Journal of Computational and Graphical Statistics} 7: 397-416.
{browse "https://doi.org/10.1080/10618600.1998.10474784"}.

{marker Friedman2007}{...}
{phang}
Friedman, J., T. Hastie, H. H{c o:}fling, and R. Tibshirani. 2007. Pathwise
coordinate optimization. {it:Annals of Applied Statistics} 1: 302-332. 
{browse "https://doi.org/10.1214/07-AOAS131"}.

{marker Friedman2010}{...}
{phang}
Friedman, J., T. Hastie, and R. Tibshirani. 2010. Regularization paths for
generalized linear models via coordinate descent.
{it:Journal of Statistical Software} 33(1): 1-22.
{browse "https://doi.org/10.18637/jss.v033.i01"}.

{marker Hastie2009}{...}
{phang}
Hastie, T., R. Tibshirani, and J. Friedman. 2009. 
{it:The Elements of Statistical Learning: Data Mining, Inference, and Prediction}. 2nd ed. New York: Springer.

{marker Hastie2015}{...}
{phang}
Hastie, T., R. Tibshirani, and M. Wainwright. 2015. 
{it:Statistical Learning with Sparsity: The Lasso and Generalizations}.
Boca Raton: CRC Press. 

{marker Hoerl1970}{...}
{phang}
Hoerl, A. E., and R. W. Kennard. 1970. Ridge regression: Applications to
nonorthogonal problems. {it:Technometrics} 12: 69-82.
{browse "https://doi.org/10.2307/1267352"}.

{marker Huang2008}{...}
{phang}
Huang, J., S. Ma, and C.-H. Zhang. 2008. Adaptive lasso for sparse
high-dimensional regression models supplement. {it:Statistica Sinica} 18:
1603-1618. 

{marker Hurvich1989}{...}
{phang}
Hurvich, C. M., and C.-L. Tsai. 1989. Regression and time series model
selection in small samples. {it:Biometrika} 76: 297-307.
{browse "https://doi.org/10.1093/biomet/76.2.297"}.

{marker Schwarz1978}{...}
{phang}
Schwarz, G. 1978. Estimating the dimension of a model.
{it:Annals of Statistics} 6: 461-464.
{browse "https://doi.org/10.1214/aos/1176344136"}.

{marker Stamey1989}{...}
{phang}
Stamey, T. A., J. N. Kabalin, J. E. Mcneal, I. M. Johnstone, F. Freiha, 
E. A. Redwine, and N. Yang. 1989. Prostate specific antigen in the
diagnosis and treatment of adenocarcinoma of the prostate. II. Radical
prostatectomy treated patients. {it:Journal of Urology} 141: 1076-1083.
{browse "https://doi.org/10.1016/s0022-5347(17)41175-x"}.

{marker Sugiura1978}{...}
{phang}
Sugiura, N. 1978. Further analysts [{it:sic}] of the data by Akaike's information
criterion and the finite corrections.
{it:Communications in Statistics -- Theory and Methods} 7: 13-26.
{browse "https://doi.org/10.1080/03610927808827599"}.

{marker Tib1996}{...}
{phang}
Tibshirani, R. 1996. Regression shrinkage and selection via the lasso.
{it:Journal of the Royal Statistical Society, Series B} 58: 267-288.
{browse "https://doi.org/10.1111/j.2517-6161.1996.tb02080.x"}.

{marker Kooji2007}{...}
{phang}
Van der Kooij, A. 2007. Prediction accuracy and stability of regression with optimal scaling transformations. PhD thesis, Department of Data Theory, University of Leiden.  

{marker Yamada2017}{...}
{phang}
Yamada, H. 2017. The Frisch-Waugh-Lovell theorem for the lasso and the ridge
regression. {it:Communications in Statistics -- Theory and Methods} 46:
10897-10902.
{browse "https://doi.org/10.1080/03610926.2016.1252403"}.

{marker Zhang2010}{...}
{phang}
Zhang, Y., R. Li, and C.-L. Tsai. 2010. Regularization parameter selections
via generalized information criterion.
{it:Journal of the American Statistical Association} 105: 312-323.
{browse "https://doi.org/10.1198/jasa.2009.tm08013"}.

{marker Zhao2006}{...}
{phang}
Zhao, P., and B. Yu. 2006. On model selection consistency of lasso.
{it:Journal of Machine Learning Research} 7: 2541-2563. 

{marker Zou2006}{...}
{phang}
Zou, H. 2006. The adaptive lasso and its oracle properties.
{it:Journal of the American Statistical Association} 101: 1418-1429.
{browse "https://doi.org/10.1198/016214506000000735"}.

{marker Zou2005}{...}
{phang}
Zou, H., and T. Hastie. 2005. Regularization and variable selection via the
elastic net. {it:Journal of the Royal Statistical Society, Series B}
67: 301-320.
{browse "https://doi.org/10.1111/j.1467-9868.2005.00503.x"}.

{marker Zou2007}{...}
{phang}
Zou, H., T. Hastie, and R. Tibshirani. 2007. On the "degrees of freedom" of
the lasso. {it:Annals of Statistics} 35: 2173-2192.
{browse "https://doi.org/10.1214/009053607000000127"}.


{marker website}{...}
{title:Website}

{pstd}
Please check our website {browse "https://statalasso.github.io/"} for more information. 


{marker installation}{...}
{title:Installation}

{pstd}
To get the latest stable version of {cmd:lassopack} from our website, check
the installation instructions at
{browse "https://statalasso.github.io/installation/"}.  We update the stable
website version more frequently than the Statistical Software Components
version.

{pstd}
To verify that {cmd:lassopack} is correctly installed, click on or type
{bf:{stata "whichpkg lassopack"}} (which requires {helpb whichpkg} to be
installed; {bf:{stata "ssc install whichpkg"}}).


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
Thanks to Alexandre Belloni, who provided MATLAB code for the square-root
lasso estimator, Sergio Correia for advice on the use of the {cmd:ftools}
package, and Jan Ditzen. 


{marker citation}{...}
{title:Citation of lasso2}

{pstd}
{opt lasso2} is not an official Stata command. It is a free contribution to
the research community, like an article. Please cite it as such:

{phang2}
Ahrens, A., C. B. Hansen, M. E. Schaffer. 2018.
lassopack: Stata module for lasso, square-root lasso, elastic net, ridge,
adaptive lasso estimation and cross-validation. Statistical Software
Components S458458, Department of Economics, Boston College.
{browse "http://ideas.repec.org/c/boc/bocode/s458458.html"}.

{phang2}
------. 2020.
{browse "https://doi.org/10.1177/1536867X20909697":lassopack: Model selection and prediction with regularized regression in Stata}.
{it:Stata Journal} 20: 176-235.


{marker authors}{...}
{title:Authors}

{pstd}
Achim Ahrens{break}
The Economic and Social Research Institute{break}
Dublin, Ireland{break}
achim.ahrens@esri.ie

{pstd}
Christian B. Hansen{break}
University of Chicago{break}
Chicago, IL{break}
Christian.Hansen@chicagobooth.edu

{pstd}
Mark E. Schaffer{break}
Heriot-Watt University{break}
Edinburgh, UK{break}
m.e.schaffer@hw.ac.uk


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 20, number 1: {browse "https://doi.org/10.1177/1536867X20909697":st0594}{p_end}

{p 7 14 2}
Help:  {helpb cvlasso}, {helpb rlasso}, {helpb lassologit}, {helpb ivlasso}, {helpb pdslasso} (if installed){p_end}
