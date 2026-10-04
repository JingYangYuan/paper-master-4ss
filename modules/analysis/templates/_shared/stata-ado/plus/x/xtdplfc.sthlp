{smcl}
{* *! version 1.0 26Aug2018}{...}
{cmd:help xtdplfc}{right: ({browse "https://doi.org/10.1177/1536867X20976339":SJ20-4: st0624})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{hi:xtdplfc} {hline 2}}Partially linear functional-coefficient panel-data models{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:xtdplfc} {varlist}{cmd:,}
{cmdab:u:vars(}{varlist}{cmd:)}
{cmdab:gen:erate(}{it:prefix}{cmd:)} 
[{it:options}]

{pstd}
{opt xtdplfc} can be used only if data are declared to be panel
data through the {helpb xtset} or {helpb tsset} command.  Before using
{opt xtdplfc}, you must install {opt bspline} (Newson 2000) and {opt moremata}
(Jann 2005).

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmdab:u:vars(}{it:{help varlist:varlist}}{cmd:)}}specify variables that enter into the functions{p_end}
{p2coldent :* {cmdab:gen:erate(}{it:prefix}{cmd:)}}specify a prefix for the names to store fitted values of functional coefficients{p_end}
{synopt : {cmdab:z:vars(}{it:varlist}{cmd:)}}specify variables that have functional coefficients{p_end}
{synopt : {opt lags(#)}}use {it:#} lags of dependent variable as covariates; default is {cmd:lags(1)}{p_end}
{synopt : {cmd:lagyinz(}{it:{help numlist:numlist}}{cmd:)}}specify lags of dependent variable that have functional coefficients{p_end}
{synopt : {cmd:endox(}{it:varlist}{cmd:)}}specify endogenous variables that enter into the model linearly{p_end}
{synopt : {opt endoz:flag(numlist)}}specify the orders of variables in
{cmd:zvars(}{it:varlist}{cmd:)} that are endogenous variables{p_end}
{synopt : {cmd:ivx(}{it:varlist}{cmd:)}}specify instrumental
variables (IVs) that enter into the model linearly{p_end}
{synopt : {cmd:ivz(}{it:varlist}{cmd:,} ...{cmd:)}}specify IVs entering into the model nonlinearly{p_end}
{synopt : {cmdab:only:ivxz}}only use instruments specified by {cmd:ivx()} and {cmd:ivz()}{p_end}
{synopt : {opt i:vtype(numlist)}}specify types of instruments constructed via the nonlinear endogenous variables{p_end}
{synopt : {opt te}}specify to include time fixed effects{p_end}
{synopt :{opt power(numlist)}}specify the power (or degree) of the splines for the functions{p_end}
{synopt:{opt nk:nots(numlist)}}specify the number of knots used for the spline interpolation{p_end}
{synopt:{cmdab:quan:tile}}specify creating knots based on empirical quantiles{p_end}
{synopt:{opt maxnk:nots(numlist)}}specify the maximum number of knots used for
performing least-squares cross-validation (LSCV){p_end}
{synopt:{opt minnk:nots(numlist)}}specify the minimum number of knots used for performing LSCV{p_end}
{synopt :{opt grid(string)}}specify the name for storing the grid points of
the variable specified by {opt uvars(varlist)}{p_end}
{synopt :{opt pctile(#)}}specify the domain of the generating grid points; default is {cmd:pctile(0)}{p_end}
{synopt :{opt brep(#)}}specify the number of bootstrap replications; default is {cmd:brep(200)}{p_end}
{synopt :{opt wild}}specify using the wild bootstrap; by default, residual bootstrap with cluster(panelvar) is performed{p_end}
{synopt :{opt predict(prspec)}}store predicted values of
the conditional mean and fixed effects using variable names specified in {it:prspec}{p_end}
{synopt :{opt nodots}}suppress iteration dots{p_end}
{synopt :{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt fast}}speed up using Mata functions{p_end}
{synopt :{opt tenfoldcv}}specify using tenfold cross-validation (CV) instead of LSCV{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {cmd:uvars()} and {cmd:generate()} are required.{p_end}
{pstd}
The full specification of {cmd:ivz()} is{break}
{cmd:ivz(}{it:{help varlist:varlist}}{cmd:,} {opt u:flag(numlist)} 
[{opt i:vtype(numlist)}]{cmd:)}.{p_end}
{p 4 6 2}Note: Unbalanced panel data must be rectangularized in advance; use
{helpb tsfill:tsfill, full}.{p_end}


{title:Description}

{pstd}
{opt xtdplfc} fits Zhang and Zhou's (Forthcoming) partially linear
functional-coefficient panel dynamic data model.

{pstd}
The model can be expressed as

{phang2}
Y_it=X_it'*beta+Z_it'*g(u_it)+a_i+e_it

{pstd}
where subscripts i and t present individual and time period, respectively;
X_it and Z_it are vectors of covariates, respectively; G(U_it) is a vector of
functional coefficients and U_it is a vector of continuous variables
[specifically, Z_it'*G(U_it)=sum{Z_jit*G_j(U_jit)}]; a_i represents the fixed
effects; and e_it is the idiosyncratic error.  lags of Y_it might appear in
X_it or Z_it.

{pstd}
We approximate the functional coefficients by a linear combination of B-spline
base functions (see {helpb bspline}).  The fixed effects are removed by the
first time difference.  Then, the transformed model is fit through the
two-step least-squares (2SLS) technique (see {helpb ivregress}).


{title:Options}

{phang}
{cmd:uvars(}{it:{help varlist:varlist}}{cmd:)} specifies (continuous)
variables that enter into the functional coefficients interacted with
variables in order specified by {cmd:zvars()}.  {cmd:uvars()} is required.

{phang}
{cmd:generate(}{it:prefix}{cmd:)} specifies a prefix for the variable names to
store fitted values of functional coefficients.  {cmd:generate()} is required.

{phang}
{cmd:zvars(}{it:varlist}{cmd:)} specifies the variables that have functional
coefficients.

{phang}
{opt lags(#)} specifies {it:#} lags of the dependent variable as covariates.
The default is {cmd:lags(1)}.

{phang}
{cmd:lagyinz(}{it:{help numlist:numlist}}{cmd:)} specifies lags of the
dependent variable that have functional coefficients.  When this option is
used, the specified lags of the dependent variable are automatically added in
front of variables in {cmd:zvars()}.

{phang}
{cmd:endox(}{it:varlist}{cmd:)} specifies endogenous variables that enter into
the model linearly.

{phang}
{cmd:endozflag(}{it:{help numlist:numlist}}{cmd:)} specifies the orders of
variables in {cmd:zvars(}{it:varlist}{cmd:)} that are endogenous variables.
For example, {cmd:endozflag(1 3)} indicates that the first and third variables
specified in {cmd:zvars(}{it:varlist}{cmd:)} are endogenous.

{phang}
{cmd:ivx(}{it:varlist}{cmd:)} specifies IVs that enter into the model
linearly. 

{phang}
{cmd:ivz(}{it:varlist}{cmd:,} {opt uflag(numlist)} 
[{opt ivtype(numlist)}]{cmd:)} specifies the IVs entering into the model
nonlinearly that interact with the functions specified by the orders in
{opt uflag(numlist)}.  Optionally, one may specify the type of nonlinear IVs
to be constructed.  {opt ivtype(numlist)} means using the {it:#}th lag of the
spline bases, and the final IVs are formed from "I*L#.S(U)" [where I denotes
the IV and S(U) are a vector of spline bases of g(U)].  By default, the first
lag of the spline bases is used.

{phang}
{cmd:onlyivxz} uses only instruments specified by {cmd:ivx()} and {cmd:ivz()}.
By default, additional instruments are automatically constructed using lags of
the dependent variables, variables specified by {cmd:endox()} and
{cmd:endozflag()}, and the generating splines.

{phang}
{opt ivtype(numlist)} specifies the lag of the basis functions to be used for
constructing the IVs.  Suppose Z is an endogenous variable interacting with
g(U); S(U) are basis functions for g(U).  {cmd:ivtype(1)} indicates
constructing IVs from "L2.Z*L.S(U)".

{phang}
{opt te} specifies to include time fixed effects.

{phang}
{opt power(numlist)} (nonnegative integers) specifies the power (or degree) of
the splines in order specified by {cmd:uvars()}.  The default is
{cmd:power(3)}.

{phang}
{opt nknots(numlist)} specifies the number of knots used for the spline
interpolation in order specified by {cmd:uvars()}.  The default is
{cmd:nknots(2)}.

{phang}
{opt quantile} specifies creating knots based on empirical quantiles.  By
default, the knots are generated by the rule of equal space.

{phang}
{opt maxnknots(numlist)} specifies the maximum number of knots used for
conducting LSCV.  If present, LSCV is used to determine the optimal number of
knots.  In our practice, we perform the leave-one-out CV across the
{it:panelvar}.  That is to say, we leave one individual (with all observations
during the sample period) out each time.

{phang}
{opt minnknots(numlist)} specifies the minimum number of knots used for
performing LSCV.  The default is {cmd:minnknots(2)}.

{phang}
{opt grid(string)} specifies the name for storing the grid points of the
variable specified by {opt uvars()}.  If present, the functional coefficients
are estimated over the grid points.  By default, they are estimated over the
observations.

{phang}
{opt pctile(#)} specifies the domain of the generating grid points.  It can be
used only when {opt grid()} is specified.  The default is {cmd:pctile(0)}.

{phang}
{opt brep(#)} specifies the number of bootstrap replications.  The default is
{cmd:brep(200)}.  We recommend that you select the number of replications.

{phang}
{opt wild} specifies using the wild bootstrap.  By default, residual bootstrap
with the option {opt cluster(panelvar)} is performed.

{phang}
{opt predict(prspec)} stores predicted values of the dependent variable and
fixed effects using variable names specified in {it:prspec}.  {it:prspec} is
the following:

{phang2}
{cmd:predict(}{varlist}|{it:stub}{cmd:*} [{cmd:, replace noai}]{cmd:)}

{pmore}
The option takes a variable list or {it:stub}.  The first variable name
corresponds to the predicted outcome mean.  The second name corresponds to
fixed effects.

{pmore}
When {cmd:replace} is used, variables with the names in {it:varlist} or
{it:stub}{cmd:*} are replaced by those in the new computation.  If {cmd:noai}
is specified, only a variable for the mean is created.

{phang}
{opt nodots} suppresses the iteration dots.

{phang}
{opt level(#)} sets the confidence level.  The default is {cmd:level(95)}.

{phang}
{opt fast} speeds up using Mata functions.

{phang}
{opt tenfoldcv} specifies using tenfold CV instead of LSCV.


{title:Example}

{pstd}
Setup{p_end}
{phang2}{cmd:.} {bf:{stata "set obs 50"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate a=rnormal()"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate id=_n"}}{p_end}
{phang2}{cmd:.} {bf:{stata "expand 200"}}{p_end}
{phang2}{cmd:.} {bf:{stata "bysort id: generate year=_n"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate x=10*runiform()+0.5*a"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate z=5+2*rnormal()"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate u=-3+20*runiform()"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate gf1=sin(_pi/3*u)"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate y=0"}}{p_end}
{phang2}{cmd:.} {bf:{stata "xtset id year"}}{p_end}
{phang2}{cmd:.} {bf:{stata "replace y=a+1.2*x+0.3*L2.y+L1.y*gf1+sqrt(2)*rnormal() if year>2"}}{p_end}
{phang2}{cmd:.} {bf:{stata "drop if year<101 "}}{p_end}

{pstd}
Fixed-effects sieve 2SLS estimation{p_end}
{phang2}{cmd:.} {bf:{stata "xtdplfc y x, uvars(u) generate(g) maxnknots(20) lags(2) lagyinz(1) "}}{p_end}

{pstd}
Compute the 95% confidence interval for the functional coefficient{p_end}
{phang2}{cmd:.} {bf:{stata "generate lb=g_1-1.96*g_1_sd"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate ub=g_1+1.96*g_1_sd"}}{p_end}

{pstd}
Plot the fitted values of the functional coefficient{p_end}
{phang2}{cmd:.} {bf:{stata "local plot1 line gf1 u, sort"}}{p_end}
{phang2}{cmd:.} {bf:{stata "local plot2 line g_1 u, sort"}}{p_end}
{phang2}{cmd:.} {bf:{stata "local plot3 rarea lb ub u, color(gs12) sort"}}{p_end}
{phang2}{cmd:.} {bf:{stata `"twoway (`plot3') (`plot1') (`plot2' legend(label(1 "95% CI") label(2 "Real values") label(3 "Fitted values")))"'}}{p_end}
 

{title:Stored results}

{pstd}
{cmd:xtdplfc} stores the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of individuals{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(r2)}}within R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted within R-squared{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(mss)}}model sum of squares{p_end}
{synopt:{cmd:e(rss)}}residual sum of squares{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtdplfc}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(ivlist)}}IVs used for estimation{p_end}
{synopt:{cmd:e(vcetype)}}type of variance-covariance{p_end}
{synopt:{cmd:e(estfun)}}variables storing the estimated functional coefficients{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(model)}}{cmd:Fixed-effect Sieve 2SLS Estimation}{p_end}
{synopt:{cmd:e(k}{it:#}{cmd:)}}list of knots for the {it:#}th function{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector in the linear part{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators in the linear part{p_end}
{synopt:{cmd:e(bs)}}coefficient vector in the approximating model{p_end}
{synopt:{cmd:e(Vs)}}variance-covariance matrix of the estimators in the approximating model{p_end}
{synopt:{cmd:e(nknots)}}number of knots{p_end}
{synopt:{cmd:e(power)}}power (or degree) of splines{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Jann, B. 2005. moremata: Stata module (Mata) to provide various functions.
Statistical Software Components S455001, Department of Economics,
Boston College.
{browse "https://ideas.repec.org/c/boc/bocode/s455001.html"}.

{phang}
Newson, R. B. 2000. bspline: Stata modules to compute B-splines parameterized
by their values at reference points. Statistical Software Components S411701,
Department of Economics, Boston College.
{browse "https://ideas.repec.org/c/boc/bocode/s411701.html"}.

{phang}
Zhang, Y., and Q. Zhou. Forthcoming. Partially linear functional-coefficient
dynamic panel data models: Sieve estimation and specification testing.
{it:Economic Reviews}.


{title:Authors}

{pstd}
Kerry Du{break}
School of Management{break}
Xiamen University{break}
Xiamen, China{break}
{browse "mailto:kerrydu@xmu.edu.cn":kerrydu@xmu.edu.cn}

{pstd}
Yonghui Zhang{break}
School of Economics{break}
Renmin University of China{break}
Beijing, China{break}
{browse "mailto:yonghui.zhang@hotmail.com":yonghui.zhang@hotmail.com}

{pstd}
Qiankun Zhou{break}
Department of Economics{break}
Renmin University of China{break}
Baton Rouge, LA{break}
{browse "mailto:qzhou@lsu.edu":qzhou@lsu.edu}


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 20, number 4: {browse "https://doi.org/10.1177/1536867X20976339":st0624}{p_end}

{p 7 14 2}
Help:  {helpb xtplfc}, {helpb ivxtplfc}, {helpb xtsemipar}, {helpb bspline} (if installed){p_end}
