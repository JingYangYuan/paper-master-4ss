{smcl}
{* *! version 1.0.0 18Jun2020}{...}
{cmd:help rwrmed}{right: ({browse "https://doi.org/10.1177/1536867X211045511":SJ21-3: st0646})}
{hline}

{title:Title}

{p2colset 5 15 16 2}{...}
{p2col:{cmd:rwrmed} {hline 2}}Causal mediation analysis using regression with residuals{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:rwrmed} 
{depvar}
[{help indepvars:{it:lvars}}]
{ifin} 
{weight}{cmd:,}
{cmdab:avar(}{it:{help varname:varname}}{cmd:)}
{cmdab:mvar(}{it:{help varname:varname}}{cmd:)}
{opt a(#)}
{opt astar(#)}
{opt m(#)}
[{it:options}]

{pstd}
{it:lvars} are posttreatment covariates.

{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt avar}{cmd:(}{it:varname}{cmd:)}}specify the treatment (exposure) variable{p_end}
{p2coldent:* {opt mvar}{cmd:(}{it:varname}{cmd:)}}specify the mediator variable{p_end}
{p2coldent:* {opt a}{cmd:(}{it:#}{cmd:)}}set the reference level of treatment{p_end}
{p2coldent:* {opt astar}{cmd:(}{it:#}{cmd:)}}set the alternative level of treatment{p_end}
{p2coldent:* {opt m}{cmd:(}{it:#}{cmd:)}}set the level of the mediator at which the controlled direct effect 
is evaluated; if there is no treatment-mediator interaction, then the controlled direct effect
is the same at all levels of the mediator, and thus an arbitrary value can be chosen{p_end}
{synopt:{opt mreg}{cmd:(}{it:string}{cmd:)}}specify the form of regression
model to be fit for the mediator variable;
options are {opt reg:ress}, {opt log:it}, or {opt poi:sson}; default is
{cmd:mreg(regress)}{p_end}
{synopt:{opt cvars}{cmd:(}{it:varlist}{cmd:)}}specify the pretreatment covariates to be included in the analysis{p_end}
{synopt:{opt cat}{cmd:(}{it:varlist}{cmd:)}}specify which of the {cmd:cvars()}
and {it:lvars} should be handled as categorical variables{p_end}
{synopt:{opt nointer:action}}specify that a treatment-mediator interaction should not be included in the outcome model{p_end}
{synopt:{opt cxa}}specify that treatment-covariate interactions should be included in the mediator and outcome models{p_end}
{synopt:{opt cxm}}specify that mediator-covariate interactions should be included in the outcome model{p_end}
{synopt:{opt lxm}}specify that mediator-posttreatment interactions should be included in the outcome model{p_end}
{synopt:{opt noi:sily}}display GSEM output tables; this option is not available with {cmd:bootstrap}{p_end}
{synopt:{opt boot:strap}[{cmd:(}{it:bootstrap_options}{cmd:)]}}specify that
bootstrap replications be used to estimate the variance-covariance matrix; 
all {helpb bootstrap} options are available{p_end}
{synopt:{it:model_options}}specify any option available for {helpb gsem}{p_end}
{synopt:{cmd:vce(robust)}}Huber/White/sandwich estimator{p_end}
{synopt:{cmd:vce(}{cmdab:cl:uster} {it:clustvar}{cmd:)}}clustered sandwich estimator{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {cmd:avar()}, {cmd:mvar()}, {cmd:a()}, {cmd:astar()}, and {cmd:m()} are required.
{p_end}
{marker weight}{...}
{p 4 6 2}{opt pweight}s are allowed; see {help weight}.{p_end}


{title:Description}

{pstd}
{cmd:rwrmed} performs causal mediation analysis using regression with
residuals.  Using {helpb gsem}, two models are fit: a model for the mediator
conditional on treatment and the pretreatment covariates (if specified) after
centering them on their sample means and a model for the outcome conditional
on treatment, the mediator, the pretreatment covariates (if specified) after
centering them on their sample means, and the posttreatment covariates (if
specified) after centering them on their estimated conditional means given all
prior variables.  Thus, {cmd:rwrmed} allows for the presence of
treatment-induced confounders, which are posttreatment covariates that
confound the mediator-outcome relationship.

{pstd}
{cmd:rwrmed} uses {opt regress} for the outcome and requires the user to
specify an appropriate form for the mediator model ({opt regress},
{opt logit}, or {opt poisson}).  Posttreatment covariates are residualized
with respect to treatment and the pretreatment covariates.

{pstd}
{cmd:rwrmed} provides estimates of the controlled direct effect and then the
randomized intervention analogues to the natural direct effect, the natural
indirect effect, and the total effect when a set of measured posttreatment
covariates are included in {it:lvars}.  When posttreatment covariates are not
included in {it:lvars}, the command instead provides estimates of the
conventional natural direct and indirect effects and the conventional total
effect.

{pstd}
By default, standard errors and confidence intervals for mediation effect
estimates are derived by {helpb margins} with the {cmd:vce(unconditional)}
option.  However, bootstrap standard errors are preferred when posttreatment
covariates are included in the model (that is, by specifying {it:lvars})
because the bootstrap procedure properly accounts for the uncertainty that
arises from fitting the models used to residualize the posttreatment
covariates, whereas the analytic standard errors do not.


{title:Assumptions}

{pstd}
Let C be the measured pretreatment covariates included in
{opt cvars(varlist)}, and let L be the measured posttreatment covariates
included in {it:lvars}.  Obtaining consistent estimates of the controlled
direct effect requires two main assumptions:{p_end}

{phang2}1. There are no unmeasured treatment-outcome confounders given C.{p_end}
{phang2}2. There are no unmeasured mediator-outcome confounders given C and L.{p_end}

{pstd}
Obtaining consistent estimates of the randomized intervention analogues to
natural direct and indirect effects requires assumptions 1 and 2 and then an
additional assumption:{p_end}

{phang2}
3. There are no unmeasured treatment-mediator confounders given C.{p_end}

{pstd}
Note that assumptions 1 and 3 are satisfied by random assignment of the
treatment variable.  See references for further details.{p_end}


{title:Options}

{p 4 8 2}
{cmd:avar(}{it:varname}{cmd:)} specifies the treatment (exposure) variable.
{cmd:avar()} is required.

{p 4 8 2}
{cmd:mvar(}{it:varname}{cmd:)} specifies the mediator variable.  {cmd:mvar()}
is required.

{p 4 8 2}
{cmd:a(}{it:#}{cmd:)} sets the reference level of treatment.  {cmd:a()} is
required.

{p 4 8 2}
{cmd:astar(}{it:#}{cmd:)} sets the alternative level of treatment.  Together,
{cmd:astar()} and {cmd:a()} define the treatment contrast of interest.
{cmd:astar()} is required.

{p 4 8 2}
{cmd:m(}{it:#}{cmd:)} sets the level of the mediator at which the controlled
direct effect is evaluated.  If there is no treatment-mediator interaction,
then the controlled direct effect is the same at all levels of the mediator,
and thus an arbitrary value can be chosen.  {cmd:m()} is required.

{p 4 8 2}
{opt mreg}{cmd:(}{it:string}{cmd:)} specifies the form of regression model to
be fit for the mediator variable.  Options include {opt regress}, {opt logit},
and {opt poisson}.  The default is {cmd:mreg(regress)}.

{p 4 8 2}
{opt cvars}{cmd:(}{it:varlist}{cmd:)} specifies the pretreatment covariates to
be included in the analysis.

{p 4 8 2}
{opt cat}{cmd:(}{it:varlist}{cmd:)} specifies which of the {cmd:cvars()} and
{it:lvars} should be handled as categorical variables.  For categorical
variables with more than two levels, {cmd:rwrmed} generates dummy variables
for each level and then residualizes them individually.  A warning message
will be issued if the logit model produces perfect predictions, resulting in
dropped observations.  The program will terminate if the logit model cannot
converge.  In both of these cases (dropped observations or model
nonconvergence), the user should consider either collapsing the
multicategorical variable into fewer categories or specifying it as a
continuous variable by not adding it to {cmd:cat()} if appropriate.

{p 4 8 2}
{opt nointeraction} specifies that a treatment-mediator interaction should not
be included in the outcome model.  When not specified, {cmd:rwrmed} will
generate a treatment-mediator interaction term.

{p 4 8 2}
{opt cxa} specifies that all two-way interactions between treatment and the
baseline covariates be included in the mediator and outcome models.

{p 4 8 2}
{opt cxm} specifies that all two-way interactions between the mediator and the
baseline covariates be included in the outcome model.

{p 4 8 2}
{opt lxm} specifies that all two-way interactions between the mediator and the
posttreatment covariates be included in the outcome model.

{p 4 8 2}
{opt noisily} displays the {cmd:gsem} output tables; this option is not
available with {cmd:bootstrap}.

{p 4 8 2}
{opt bootstrap}[{cmd:(}{it:bootstrap_options}{cmd:)}] specifies that bootstrap
replications be used to estimate the variance-covariance matrix.  All
{helpb bootstrap} options are available.  Specifying {cmd:bootstrap} without
options uses the default bootstrap settings.

{p 4 8 2}
{it:model_options} allows the user to specify any option available for 
{helpb gsem}.

{phang}
{cmd:vce(robust)} and {cmd:vce(cluster} {it:clustvar}{cmd:)}; see
{manhelpi vce_option R}.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use depression}{p_end}
 
{pstd}
A continuous outcome ({cmd:cesd40}), a continuous mediator ({cmd:ses}), a
binary treatment ({cmd:college}), nine pretreatment covariates (of which five
are categorical), three posttreatment covariates, no interaction between
treatment and mediator, and the default analytic method for estimation{p_end}
{phang2}
{cmd:. rwrmed cesd40 cesd92 prmarr98 transitions98, avar(college) mvar(ses) cvar(male black test_score educ_exp father hispanic urban educ_mom num_sibs) cat(male black father hispanic urban) a(0) astar(1) m(0) mreg(reg) nointer}

{pstd}
Same as above, but include all interactions, and specify that 1,000 bootstrap
replications be used for estimation{p_end}
{phang2}
{cmd:. rwrmed cesd40 cesd92 prmarr98 transitions98, avar(college) mvar(ses) cvar(male black test_score educ_exp}
{cmd:father hispanic urban educ_mom num_sibs) cat(male black father hispanic urban) a(0) astar(1) m(0) mreg(reg) cxa cxm lxm boot(reps(1000) seed(1234))}

{pstd}
Display all available postestimation bootstrap confidence intervals{p_end}
{phang2}
{cmd:. estat boot, all}
 
{pstd}
Same as the first model, but now include the survey weights (note: bootstrap
cannot be used in conjunction with weights){p_end}
{phang2}
{cmd:. rwrmed cesd40 cesd92 prmarr98 transitions98 [pw=weights], avar(college)}
{cmd:mvar(ses) cvar(male black test_score educ_exp father hispanic urban educ_mom num_sibs) cat(male black father hispanic urban) a(0) astar(1) m(0) mreg(reg)  nointer}
 
{pstd}
This model includes a binary mediator.  All interactions are included and the
bootstrap is specified{p_end}
{phang2}
{cmd:. rwrmed cesd40 cesd92 prmarr98 transitions98, avar(college)}
{cmd:mvar(ses_bin) cvar(male black test_score educ_exp father hispanic urban educ_mom num_sibs) cat(male black father hispanic urban) a(0) astar(1) m(0) mreg(logit) cxa cxm lxm boot(reps(1000) seed(1234))}
		
{pstd}
This model includes a mediator that is a count variable.  All interactions are
included and the bootstrap is specified{p_end}
{phang2}
{cmd:. rwrmed cesd40 cesd92 prmarr98 transitions98, avar(college) mvar(ses_count)}
{cmd:cvar(male black test_score educ_exp father hispanic urban educ_mom num_sibs) cat(male black father hispanic urban) a(0) astar(1) m(0) mreg(poisson) cxa cxm lxm boot(reps(1000) seed(1234))}


{title:Stored results}

{pstd}
When {cmd:margins} is used for estimating the variance-covariance estimator,
{cmd:rwrmed} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(NDEtype)}}natural direct effect type{p_end}
{synopt:{cmd:r(NDEtext)}}natural direct effect description{p_end}
{synopt:{cmd:r(NIEtype)}}natural indirect effect type{p_end}
{synopt:{cmd:r(NIEtext)}}natural indirect effect description{p_end}
{synopt:{cmd:r(ATEtype)}}average total effect type{p_end}
{synopt:{cmd:r(ATEtext)}}average total effect description{p_end}

{pstd}
It also stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vector of transformed coefficients{p_end}
{synopt:{cmd:e(V)}}estimated variance-covariance matrix of the transformed
coefficients{p_end}

{pstd}
When the bootstrap method is specified for estimating the variance-covariance
estimator, {cmd:rwrmed} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(NDEtype)}}natural direct effect type{p_end}
{synopt:{cmd:r(NDEtext)}}natural direct effect description{p_end}
{synopt:{cmd:r(NIEtype)}}natural indirect effect type{p_end}
{synopt:{cmd:r(NIEtext)}}natural indirect effect description{p_end}
{synopt:{cmd:r(ATEtype)}}average total effect type{p_end}
{synopt:{cmd:r(ATEtext)}}average total effect description{p_end}

{pstd}
It also stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:e(cmdname)}}command name from {it:command}{p_end}
{synopt:{cmd:e(cmd)}}same as {cmd:e(cmdname)} or {cmd:bootstrap}{p_end}
{synopt:{cmd:e(command)}}{it:command}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(prefix)}}{cmd:bootstrap}{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(strata)}}strata variables{p_end}
{synopt:{cmd:e(cluster)}}cluster variables{p_end}
{synopt:{cmd:e(rngstate)}}random-number state used{p_end}
{synopt:{cmd:e(size)}}from the {cmd:size(}{it:#}{cmd:)} option{p_end}
{synopt:{cmd:e(exp}{it:#}{cmd:)}}expression for the {it:#}th statistic{p_end}
{synopt:{cmd:e(ties)}}{cmd:ties}, if specified{p_end}
{synopt:{cmd:e(mse)}}{cmd:mse}, if specified{p_end}
{synopt:{cmd:e(vce)}}{cmd:bootstrap}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}observed statistics{p_end}
{synopt:{cmd:e(b_bs)}}bootstrap estimates{p_end}
{synopt:{cmd:e(reps)}}number of nonmissing results{p_end}
{synopt:{cmd:e(bias)}}estimated biases{p_end}
{synopt:{cmd:e(se)}}estimated standard errors{p_end}
{synopt:{cmd:e(z0)}}median biases{p_end}
{synopt:{cmd:e(accel)}}estimated accelerations{p_end}
{synopt:{cmd:e(ci_normal)}}normal-approximation CIs{p_end}
{synopt:{cmd:e(ci_percentile)}}percentile CIs{p_end}
{synopt:{cmd:e(ci_bc)}}bias-corrected CIs{p_end}
{synopt:{cmd:e(ci_bca)}}bias-corrected and accelerated CIs{p_end}
{synopt:{cmd:e(V)}}bootstrap variance-covariance matrix{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}  


{marker citation}{...}
{title:Citation of rwrmed}

{pstd}
{cmd:rwrmed} is not an official Stata command.  It is a free contribution to
the research community, like an article.  Please cite it as such:{p_end}

{p 4 8 2}
Linden, A., C. Huber, G. T. Wodtke. 2020. rwrmed: Stata module for conducting
causal mediation analysis using regression-with-residuals. Statistical
Software Components S458801, Department of Economics, Boston College.
{browse "https://ideas.repec.org/c/boc/bocode/s458801.html"}.

{phang}
Linden, A., C. Huber, G. T. Wodtke. 2021. A regression-with-residuals method
for analyzing causal mediation: The rwrmed package.
{it:Stata Journal} 21: 559-574.
{browse "https://doi.org/10.1177/1536867X211045511"}.


{title:Acknowledgment}

{pstd}
We thank Enrique Pinzon of StataCorp for his helpful suggestion to use
{cmd:margins} with the {cmd:vce(unconditional)} option for estimating analytic
standard errors.{p_end}

	  
{title:Authors}

{p 4 4 2}
Ariel Linden{break}
Linden Consulting Group{break}
San Francisco, CA{break}
alinden@lindenconsulting.org

{p 4 4 2}
Chuck Huber{break}
StataCorp{break}
College Station, TX{break}
chuber@stata.com

{p 4 4 2}
Geoffrey T. Wodtke{break}
Department of Sociology{break}
University of Chicago{break}
Chicago, IL{break}
wodtke@uchicago.edu


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 21, number 3: {browse "https://doi.org/10.1177/1536867X211045511":st0646}{p_end}

{p 7 14 2}
Help:  {manhelp gsem_command SEM:gsem}, {manhelp margins R}, {manhelp bootstrap R}{p_end}
