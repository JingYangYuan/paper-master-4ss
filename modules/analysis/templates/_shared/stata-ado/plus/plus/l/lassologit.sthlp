{smcl}
{* *! version 7june2019}{...}
{cmd:help lassologit}, {cmd:help cvlassologit}, {cmd:help rlassologit}{right: ({browse "https://doi.org/10.1177/1536867X20909697":SJ20-1: st0594})}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{cmd:lassologit} {hline 2}}Main program for regularized logistic regression{p_end}
{p2colreset}{...}

{p2colset 5 21 23 2}{...}
{p2col:{cmd:cvlassologit} {hline 2}}Program for K-fold cross-validation with logistic regression{p_end}
{p2colreset}{...}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:rlassologit} {hline 2}}Program for regularized logistic regression with rigorous penalization{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


    {title:Full syntax}

{p 8 14 2}
{cmd:lassologit}
{it:depvar} {it:regressors} 
{ifin}
{bind:[{cmd:,}} {cmdab:postl:ogit}
{cmdab:nocon:stant}
{cmdab:l:ambda}{cmd:(}{it:numlist}{cmd:)}
{cmdab:lc:ount}{cmd:(}{it:integer}{cmd:)}
{cmdab:lminr:atio}{cmd:(}{it:real}{cmd:)}
{cmd:lmax}{cmd:(}{it:real}{cmd:)}
{opt lambdan}
{cmd:lic}{cmd:(}{it:string}{cmd:)}
{cmdab:ebicx:i}{cmd:(}{it:real}{cmd:)}
{cmdab:postres:ults}
{cmdab:notp:en(}{it:varlist}{cmd:)}
{opt spsi(matrix)}
{cmdab:nos:td}
{cmd:stdcoef}
{opt holdout(varname)}
{cmdab:lossm:easure}{cmd:(}{it:string}{cmd:)}
{cmdab:tolo:pt}{cmd:(}{it:real}{cmd:)}
{cmdab:tolz:ero}{cmd:(}{it:real}{cmd:)}
{cmdab:maxi:ter}{cmd:(}{it:int}{cmd:)}
{cmdab:quadp:recision}
{cmdab:noseqr:ule}
{cmdab:plot:path}{cmd:(}{it:method}{cmd:)}
{cmdab:plotv:ar}{cmd:(}{it:varlist}{cmd:)}
{cmdab:ploto:pt}{cmd:(}{it:string}{cmd:)}
{cmdab:plotl:abel}
{opt long}
{cmdab:verb:ose}
{cmd:ic}{cmd:(}{it:string}{cmd:)}
{bind:{cmdab:nopro:gressbar}]}

{p 8 14 2}
{cmd:cvlassologit}
{it:depvar} {it:regressors} 
{ifin}
{bind:[{cmd:,}} 
{cmdab:postl:ogit}
{cmdab:nocon:stant}
{cmdab:l:ambda}{cmd:(}{it:numlist}{cmd:)}
{cmdab:lc:ount}{cmd:(}{it:integer}{cmd:)}
{cmdab:lminr:atio}{cmd:(}{it:real}{cmd:)}
{cmd:lmax}{cmd:(}{it:real}{cmd:)}
{opt lambdan}
{cmd:lopt}
{cmd:lse}
{cmdab:postres:ults}
{cmdab:notp:en(}{it:varlist}{cmd:)}
{opt spsi(matrix)}
{cmdab:nos:td}
{cmdab:tolo:pt}{cmd:(}{it:real}{cmd:)}
{cmdab:tolz:ero}{cmd:(}{it:real}{cmd:)}
{cmdab:maxi:ter}{cmd:(}{it:int}{cmd:)}
{cmdab:quadp:recision}
{cmdab:noseqr:ule}
{cmdab:nf:olds}{cmd:(}{it:integer}{cmd:)}
{cmdab:foldv:ar}{cmd:(}{it:varname}{cmd:)}
{cmdab:savef:oldvar}{cmd:(}{it:varname}{cmd:)}
{cmd:seed}{cmd:(}{it:integer}{cmd:)}
{cmdab:strat:ified}
{opt storeest(string)}
{cmdab:lossm:easure}{cmd:(}{it:string}{cmd:)}
{cmd:plotcv}
{cmdab:ploto:pt}{cmd:(}{it:string}{cmd:)}
{opt long}
{cmdab:verb:ose}
{bind:{cmd:tabfold}]}

{p 8 14 2}
{cmd:rlassologit}
{it:depvar} {it:regressors} 
{ifin}
{bind:[{cmd:,}} 
{cmdab:postl:ogit}
{cmdab:nocon:stant}
{opt gamma(real)}
{opt c(real)}
{opt holdout(varname)}
{cmdab:lossm:easure}{cmd:(}{it:string}{cmd:)}
{cmdab:tolo:pt}{cmd:(}{it:real}{cmd:)}
{cmdab:tolz:ero}{cmd:(}{it:real}{cmd:)}
{cmdab:maxi:ter}{cmd:(}{it:int}{cmd:)}
{cmdab:quadp:recision}
{cmdab:noseqr:ule}
{bind:{cmdab:verb:ose}]}


    {title:Options}

{synoptset 23}{...}
{p2coldent :Estimators}Description{p_end}
{synoptline}
{synopt:{cmdab:postl:ogit}}use postestimation logit;
{cmd:lassologit}: if lambda is a list, 
postestimation ordinary least-squares (OLS) results are displayed and returned
in {cmd:e(betas)}; if lambda is a scalar (or {cmd:rlassologit} is used),
postestimation OLS is always displayed, 
and this option controls whether standard or postestimation 
OLS results are stored in {cmd:e(b)};
{cmd:cvlassologit}: postestimation logit 
is used for cross-validation{p_end}
{synopt:{cmdab:nocon:stant}}suppress constant from estimation (not recommended){p_end}
{synoptline}
{p2colreset}{...}
{pstd}

{synoptset 23 tabbed}{...}
{p2coldent :Lambda(s)}Description{p_end}
{synoptline}
{synopt:{cmdab:l:ambda}{cmd:(}{it:numlist}{cmd:)}}a scalar lambda value or list of descending lambda values; each lambda value must be greater than 0; if not specified, the default list is used, which is given by {cmd:exp(rangen(log(lmax),log(lminratio*lmax),lcount))} (see {helpb mata range():mf_range()}){p_end}
{p2coldent :{c 0134} {cmdab:lc:ount}{cmd:(}{it:integer}{cmd:)}}number of
lambda values for which the solution is obtained; default is {cmd:lcount(50)}{p_end}
{p2coldent :{c 0134} {cmdab:lminr:atio}{cmd:(}{it:real}{cmd:)}}ratio of
minimum to maximum lambda; {cmd:lminratio} must be between 0 and 1; default is
{cmd:lminratio(1/1000)}{p_end}
{p2coldent :{c 0134} {cmd:lmax}{cmd:(}{it:real}{cmd:)}}maximum lambda value{p_end}
{synopt:{cmd:lambdan}}use lambda:=lambda/N in the objective function;
this makes lambda comparable with {cmd:glmnet}
(Friedman, Hastie, and Tibshirani {help lassologit##Friedman2010:2010}){p_end}
{synopt:{cmd:lic}{cmd:(}{it:string}{cmd:)}}{cmd:lassologit}: after first
{cmd:lassologit} estimation using the list of lambdas, fit model corresponding
to minimum information criterion; {cmd:aic}, {cmd:bic}, {cmd:aicc}, and
{cmd:ebic} (the default) are allowed; note the lowercase spelling; see
{it:{help lassologit##informationcriteria:Information criteria}} for the
definition of each information criterion{p_end}
{synopt:{cmdab:ebicx:i}{cmd:(}{it:real}{cmd:)}}{cmd:lassologit}: controls the
xi parameter of the extended Bayesian information criterion (EBIC); xi needs
to lie in the [0,1] interval; xi=0 is equivalent to the Bayesian information
criterion (BIC); the default choice is xi=1-log(n)/{2*log(p)}{p_end}
{synopt:{cmd:lopt}}{cmd:cvlassologit}: after cross-validation, fit model
with lambda that minimizes the mean squared prediction error{p_end}
{synopt:{cmd:lse}}{cmd:cvlassologit}: after cross-validation, fit model with
the largest lambda that is within one standard deviation from {cmd:lopt}{p_end}
{synopt:{cmdab:postres:ults}}used in combination with {cmd:lic()},
{cmd:lse}, or {cmd:lopt}; stores estimation results of the model selected by information criterion in {cmd:e()}{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
The above options are applicable only for {cmd:lassologit} and
{cmd:cvlassologit}.{p_end}
{pstd}
{c 0134} Not applicable if {cmd:lambda}{cmd:(}{it:numlist}{cmd:)} is specified.

{synoptset 23}{...}
{p2coldent :Rigorous lambda}Description{p_end}
{synoptline}
{synopt:{opt gamma(real)}}specify the significance-level gamma for the
rigorous lambda; default is
{cmd:gamma(0.05/max((}p{cmd:*log(}n{cmd:),}n{cmd:))}{p_end}
{synopt:{opt c(real)}}specified slack parameter c for
the rigorous lambda; default is {cmd:c(1.1)}{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
The above options are applicable only for {cmd:rlassologit}.

{synoptset 23}{...}
{p2coldent :Loadings/standardization}Description{p_end}
{synoptline}
{synopt:{cmdab:notp:en(}{it:varlist}{cmd:)}}set penalty loadings to zero for
predictors in {it:varlist}; unpenalized predictors are always included in the model{p_end}
{synopt:{opt spsi(matrix)}}row vector of penalty loadings 
(in standard units); overrides the default, which is a vector of ones;
the size of the vector should equal the number of predictors 
(excluding partialed-out variables and excluding the constant){p_end}
{synopt:{cmdab:nos:td}}do not standardize the predictors; default is to 
standardize the predictors to have unit variance{p_end}
{synopt:{cmd:stdcoef}}return coefficient estimates in standardized units; default is to return coefficients in original units{p_end}
{synoptline}
{p2colreset}{...}
{pstd}

{synoptset 23}{...}
{p2coldent :Optimization}Description{p_end}
{synoptline}
{synopt:{cmdab:tolo:pt}{cmd:(}{it:real}{cmd:)}}tolerance for the lasso shooting
algorithm; default is {cmd:tolopt(1e-10)}{p_end}
{synopt:{cmdab:tolz:ero}{cmd:(}{it:real}{cmd:)}}minimum below which
coefficients are rounded down to zero; default is {cmd:tolzero(1e-4)}{p_end}
{synopt:{cmdab:maxi:ter}{cmd:(}{it:int}{cmd:)}}maximum number of iterations
for the lasso shooting algorithm; default is {cmd:maxiter(10000)}{p_end}
{synopt:{cmdab:quadp:recision}}use {helpb mf_quadcross} instead of {helpb
mf_cross} in the shooting algorithm; this will slow down the program
(considerably) but lead to (in our experience, minor) gains in precision; this
will also disable the sequential strong rule; see the next option{p_end}
{synopt:{cmdab:noseqr:ule}}disable use of sequential strong rule, which
discards some predictors before running the shooting algorithm (see section 5
in Tibshirani et al. [{help lassologit##Tib2012:2012}]); the sequential rule
leads to speed gains; note that the sequential rule is automatically disabled
if the intercept is omitted{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 23}{...}
{p2coldent :Cross-validation}Description{p_end}
{synoptline}
{synopt:{cmdab:nf:olds(}{it:integer}{cmd:)}}number of folds used for {it:K}-fold cross-validation; default is {cmd:nfolds(5)}{p_end}
{synopt:{cmdab:foldv:ar(}{it:varname}{cmd:)}}user-specified variable with fold
IDs, ranging from 1 to #folds; by default, fold IDs are randomly generated such that each fold is of approximately equal size{p_end}
{synopt:{cmdab:savef:oldvar(}{it:varname}{cmd:)}}save the fold ID variable{p_end}
{synopt:{cmd:seed(}{it:integer}{cmd:)}}set seed for the generation of a random
fold variable; relevant only if fold variable is randomly generated{p_end}
{synopt:{cmdab:strat:ified}}observations are divided into folds 
such that number of successes / number of failures is 
approximately the same across folds; recommended especially if the share of 
successes is close to 0 or 1{p_end}
{synopt:{cmd:storeest(}{it:string}{cmd:)}}save {cmd:lassologit} results from
each step of the cross-validation in {it:string1}, ..., {it:stringK}, where
{it:K} is the number of folds; intermediate results can be restored using
{helpb estimates restore}{p_end}
{synopt:{cmd:holdout(}{it:varname}{cmd:)}}define a holdout sample;
{cmd:lassologit} and {cmd:rlassologit} only; {it:varname} should be a binary
variable, where 1 indicates that observations are excluded from the
estimation; estimated loss is returned in {cmd:e(loss)}{p_end}
{synopt:{cmdab:lossm:easure(}{it:string}{cmd:)}}loss measure used for
cross-validation or for the holdout sample; {cmd:deviance} and {cmd:class}
(misclassification error) are supported; default is
{cmd:lossmeasure(deviance)}{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
Applicable only for {cmd:cvlassologit}.

{marker plottingopts}{...}
{synoptset 23}{...}
{p2coldent :Plotting {cmd:lassologit}}Description{p_end}
{synoptline}
{synopt:{cmdab:plot:path(}{it:method}{cmd:)}}plot the coefficient path as a
function of the L1 norm ({cmd:norm}), lambda ({cmd:lambda}),
or log of lambda ({cmd:lnlambda}){p_end}
{synopt:{cmdab:plotv:ar(}{it:varlist}{cmd:)}}list of variables to be included
in the plot{p_end}
{synopt:{cmdab:ploto:pt(}{it:string}{cmd:)}}additional plotting options passed
to {helpb line}; for example, use {cmd:plotopt(legend(off))} to turn off the
legend{p_end}
{synopt:{cmdab:plotl:abel}}display variable labels in graph{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
Note: Plotting with {cmd:lassologit} is not available if lambda is a scalar
value.

{marker plottingopts}{...}
{synoptset 23}{...}
{p2coldent :Plotting {cmd:cvlassologit}}Description{p_end}
{synoptline}
{synopt:{cmd:plotcv}}plot the coefficient path as a function of the L1 norm
({cmd:norm}), lambda ({cmd:lambda}), or log of lambda ({cmd:lnlambda}){p_end}
{synopt:{cmdab:ploto:pt(}{it:string}{cmd:)}}additional plotting options passed
to {helpb line}; for example, use {cmd:plotopt(legend(off))} to turn off the
legend{p_end}
{synoptline}
{p2colreset}{...}
{pstd}

{synoptset 23 tabbed}{...}
{p2coldent :Display options}Description{p_end}
{synoptline}
{p2coldent :{c 0134} {cmd:long}}show long output; this option is applicable for {cmd:lassologit} and {cmd:cvlassologit}{p_end}
{synopt:{opt ver:bose}}show additional output{p_end}
{synopt:{cmd:tabfold}}{cmd:cvlassologit}: show frequency
table of fold variable{p_end}
{p2coldent :{c 0134} {cmd:ic}{cmd:(}{it:string}{cmd:)}}controls which
information criterion is shown in the output;
{cmd:aic}, {cmd:bic}, {cmd:aicc}, and {cmd:ebic} (the default) are allowed;
note the lowercase spelling;
see {it:{help lassologit##informationcriteria:Information criteria}} for the definition of each information criterion{p_end}
{synopt:{cmdab:nopro:gressbar}}{cmd:lassologit}: do not show progress bar{p_end}
{synoptline}
{p2colreset}{...}


    {title:Replay syntax}

{pstd}
{cmd:lassologit} and {cmd:cvlassologit} support replay syntax.  The replay
syntax can be used to retrieve estimation results for the models selected by
information criteria (using the {opt lic()} option) or the model selected by
cross-validation (using the {opt lse} or {opt lopt} option).

{p 8 14 2}
{cmd:lassologit}
{bind:[{cmd:,}}
{cmdab:plot:path}{cmd:(}{it:method}{cmd:)}
{cmdab:plotv:ar}{cmd:(}{it:varlist}{cmd:)}
{cmdab:ploto:pt}{cmd:(}{it:string}{cmd:)}
{cmdab:plotl:abel}
{opt long}
{cmdab:postres:ults}
{cmd:lic}{cmd:(}{it:string}{cmd:)}
{bind:{cmd:ic}{cmd:(}{it:string}{cmd:)}]}

{p 8 14 2}
{cmd:cvlassologit}
{bind:[{cmd:,}}
{cmdab:plot:path}{cmd:(}{it:method}{cmd:)}
{cmdab:plotv:ar}{cmd:(}{it:varlist}{cmd:)}
{cmdab:ploto:pt}{cmd:(}{it:string}{cmd:)}
{cmdab:plotl:abel}
{opt long}
{cmdab:postres:ults}
{cmd:lic}{cmd:(}{it:string}{cmd:)}
{bind:{cmd:ic}{cmd:(}{it:string}{cmd:)}]}


    {title:Prediction}

{p 8 14 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} 
{cmd:xb}
{cmdab:p:r}
{cmdab:c:lass}
{cmdab:postl:ogit}
{opt lic(string)}
{cmd:lopt}
{cmd:lse}
{bind:{cmdab:noi:sily}}

{synoptset 23}{...}
{p2coldent :Predict options}Description{p_end}
{synoptline}
{synopt:{cmd:xb}}compute predicted values (the default){p_end}
{synopt:{cmdab:p:r}}predicted probabilities{p_end}
{synopt:{cmdab:c:lass}}predicted class (either 1 or 0){p_end}
{synopt:{cmdab:postl:ogit}}use postlogit (default is to use {cmd:e(b)}){p_end}
{synopt:{cmd:lic}{cmd:(}{it:string}{cmd:)}}after {cmd:lassologit}: selects
which information criterion to use for prediction{p_end}
{synopt:{cmd:lopt}}after {cmd:cvlassologit}: use lambda that minimizes the
mean squared prediction error{p_end}
{synopt:{cmd:lse}}after {cmd:cvlassologit}: use largest lambda that is within
one standard deviation from {cmd:lopt}{p_end}
{synopt:{cmdab:noi:sily}}show estimation output if reestimation is required{p_end}
{synoptline}
{p2colreset}{...}
{pstd}


    {title:Notes}

{pstd}
All {it:varlist}s may contain time-series operators or factor variables; see
{varlist}.


{title:Contents}

{phang}{help lassologit##description:Description}{p_end}
{phang}{help lassologit##penalization:Penalization level: Choice of lambda}{p_end}
{phang}{help lassologit##crossvalidation:K-fold cross-validation}{p_end}
{phang2}{help lassologit##cross-validation_procedure:Cross-validation procedure}{p_end}
{phang2}{help lassologit##stratified_cross-validation:Stratified cross-validation}{p_end}
{phang2}{help lassologit##loss_measures:Loss measures}{p_end}
{phang}{help lassologit##informationcriteria:Information criteria}{p_end}
{phang}{help lassologit##rigorous:Rigorous penalization}{p_end}
{phang}{help lassologit##technical:Technical notes}{p_end}
{phang2}{help lassologit##standardization:Standardization}{p_end}
{phang2}{help lassologit##constant:Constant}{p_end}
{phang}{help lassologit##example:Example using spam data}{p_end}
{phang2}{help lassologit##example_data:Dataset}{p_end}
{phang2}{help lassologit##example_intro:Introduction to lassologit}{p_end}
{phang2}{help lassologit##example_information:Information criteria}{p_end}
{phang2}{help lassologit##example_cv:Cross-validation with cvlassologit}{p_end}
{phang2}{help lassologit##example_rigorous:Rigorous penalization with rlassologit}{p_end}
{phang2}{help lassologit##example_prediction:Prediction}{p_end}
{phang2}{help lassologit##example_holdout:Assessing prediction accuracy with holdout()}{p_end}
{phang2}{help lassologit##example_plot_lassologit:Plotting with lassologit}{p_end}
{phang2}{help lassologit##example_plot_cvlassologit:Plotting with cvlassologit}{p_end}
{phang}{help lassologit##stored_results:Stored results}{p_end}
{phang}{help lassologit##references:References}{p_end}
{phang}{help lassologit##website:Website}{p_end}
{phang}{help lassologit##installation:Installation}{p_end}
{phang}{help lassologit##citation:Citation of lassologit}{p_end}
{phang}{help lassologit##authors:Authors}{p_end}
{phang}{help lassologit##alsosee:Also see}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt lassologit} implements logistic lasso regression.  The logistic lasso
maximizes the penalized log likelihood as follows,

{phang2}
	max  1/N sum_i ( y(i) * log p{x(i)} + {1-y(i)} * log[1-p{x(i)}] )
					- lambda * ||Psi*beta||[1]
	
{pstd}
where

{p2colset 8 17 19 2}{...}
{synopt:y(i)}a binary response that is either 1 or 0{p_end}
{synopt:beta}a p-dimensional parameter vector{p_end}
{synopt:x(i)}a p-dimensional vector of predictors for observation i{p_end}
{synopt:p{x(i)}} the probability that y(i) takes the value 1 given x(i){p_end}
{synopt:p{x(i)}}exp{x(i)'beta} / [1 + exp{x(i)'beta}]{p_end}
{synopt:lambda}the overall penalty level{p_end}
{synopt:||.||[1]}the L(1) vector norm{p_end}
{synopt:Psi}a p by p diagonal matrix of predictor-specific penalty loadings
(note that {cmd:lassologit} treats Psi as a row vector){p_end}
{synopt:N}the number of observations{p_end}

{pstd}
{cmd:lassologit} uses coordinate-descent algorithms for logistic lasso as
described in Friedman, Hastie, and Tibshirani
{help lassologit##Friedman2010:(2010, sec. 3)}.


{marker penalization}{...}
{title:Penalization level: Choice of lambda}

{pstd}
Penalized regression methods rely on tuning parameters that control the degree
and type of penalization.  Logistic lasso relies on the tuning parameter
lambda, which determines the level penalization.  We offer three approaches
for selecting the "optimal" lambda value implemented in {cmd:lassologit},
{cmd:cvlassologit}, and {cmd:rlassologit}:

{phang2}
1)  The penalty level may be chosen by cross-validation to optimize
out-of-sample prediction performance.  K-fold cross-validation is implemented
in {cmd:cvlassologit}.

{phang2}
2)  Theoretically justified and feasible penalty levels and loadings are
available for the logistic lasso via {cmd:rlassologit}.

{phang2}
3)  Lambda can also be selected using information criteria.  {cmd:lassologit}
calculates four information criteria: the Akaike information criterion (AIC;
see Akaike [{help lassologit##Akaike1974:1974}]), BIC (Schwarz
{help lassologit##Schwarz1978:1978}), EBIC (Chen and Chen
{help lassologit##Chen2008:2008}), and corrected AIC (AICc; see Sugiura 
[{help lassologit##Sugiura1978:1978}] and Hurvich and Tsai 
[{help lassologit##Hurvich1989:1989}]).


{marker crossvalidation}{...}
{title:K-fold cross-validation}

{pstd}
{cmd:cvlassologit} implements K-fold cross-validation.  The purpose of
cross-validation is to assess the out-of-sample prediction (classification)
performance.


{marker cross-validation_procedure}{...}
{title:Cross-validation procedure}

{pstd}
K-fold cross-validation divides the data randomly -- or based on the
user-specified {opt foldvar(varname)} -- into K folds, that is, data
partitions of approximately equal size.  In each step, one fold is left out of
the estimation (training) sample and used for validation.  The prediction
(classification) performance is assessed based on loss measures.
{cmd:cvlassologit} offers two loss measures: deviance and misclassification
error (defined below).  For more information, see {helpb cvlasso} (for the
linear case).


{marker stratified_cross-validation}{...}
    {title:Stratified cross-validation}

{pstd}
Simple K-fold cross-validation might fail with randomly generated folds or
produce misleading results if the share of successes (y=1) and failures (y=0)
is low. The {cmd:stratified} option ensures that the number of successes and
the number of failures is approximately the same across folds.  The
{cmd:tabfold} option can be useful in this context; it asks {cmd:cvlassologit}
to show the frequency distribution of successes or failures across folds.


{marker loss_measures}{...}
    {title:Loss measures}

{pstd} 
The prediction performance is assessed based on two loss measures: deviance
and misclassification.  Deviance is the default and is defined as

	Deviance = -2 * {y0 :* log(p0) :+ (1:-y0):*log(1:-p0)} 

{pstd}
where y0 is the response in the validation data and p0 is the predicted
probabilities.	

{pstd}
The misclassification error is the average number of wrongly classified cases
and can be specified using {cmd:lossmeasure(class)}.


{marker informationcriteria}{...}
{title:Information criteria}
 
{pstd} 
The information criteria supported by {cmd:lassologit} are the AIC (Akaike
{help lassologit##Akaike1974:1974}), the BIC (Schwarz
{help lassologit##Schwarz1978:1978}), the AICc (Sugiura
{help lassologit##Sugiura1978:1978}; Hurvich and Tsai
{help lassologit##Hurvich1989:1989}), and the EBIC (Chen and Chen 
{help lassologit##Chen2008:2008}).  These are given by (omitting dependence on
lambda and alpha),

	AIC	= -2*LL + 2*df
	BIC	= -2*LL + df*log(N) 
	AICc	= AIC + {2*df(df+1)}/(N-df-1)
	EBIC	= BIC + 2*xi*df*log(p)

{pstd} 
where LL is the log likelihood and df(lambda,alpha) is the effective degrees
of freedom, which is a measure of model complexity.  Degrees of freedom is
approximated by the number of predictors selected.

{pstd}
By default, {cmd:lassologit} displays EBIC in the output, but all four
information criteria are stored in {cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(ebic)},
and {cmd:e(aicc)}.  See the help file of {helpb lasso2} for more information.


{marker rigorous}{...}
{title:Rigorous penalization}

{pstd}
The theory-driven ("rigorous") penalty level used by {cmd:rlassologit} is

	lambda = c/2 sqrt(N) Phi^(-1)(1-gamma)

{pstd}
where c is a slack parameter (default = 1.1), Phi(.) is the standard normal
cumulative distribution function, and gamma is the significance level.  The
default for gamma is 0.05/max[{p*log(n),n}].  This approach requires the
predictors to be standardized such that mean{x(i)^2}=1.  The penalty level is
motivated by self-normalized moderate deviation theory and is aimed at
overruling the noise associated with the data-generating process.  See
Belloni, Chernozhukov, and Wei ({help lassologit##Belloni2016:2016}).


{marker technical}{...}
{title:Technical notes}


{marker standardization}{...}
    {title:Standardization}

{pstd}
{opt lassologit} centers and standardizes the predictors before estimation.
The coefficient estimates are returned in original scale. If the {cmd:stdcoef}
option is used, coefficients are returned in standardized units.  {cmd:nostd}
can be used to estimate with predictors in original scale.


{marker constant}{...}
    {title:Constant}

{pstd}
The constant is not penalized by default.  Thus, the constant is always
included in the model.  To omit the constant, use {cmd:noconstant} (not
recommended).


{marker example}{...}
{title:Example using spam data}


{marker example_data}{...}
    {title:Dataset}

{pstd}
For demonstration, we consider the Spambase dataset from the Machine Learning
Repository.  The data include 4,601 observations and 57 variables.  The aim is
to predict whether an email is spam (that is, unsolicited commercial email).
Each observation corresponds to one email.

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Predictors}{p_end}
{synopt:{cmd:v1}-{cmd:v48}}percentage of words in the email that match a specific word,
that is, 100 * (number of times the word appears in the email) divided by
the total number of words in the email. 
To see which word each predictor corresponds to, see the link below.{p_end}
{synopt:{cmd:v49}-{cmd:v54}}percentage of characters in the email that match a specific character,
that is, 100 * (number of times the character appears in the email) divided by
the total number of characters in the email. 
To see which character each predictor corresponds to, see the link below.{p_end}
{synopt:{cmd:v55}}average length of uninterrupted sequences of capital letters{p_end}
{synopt:{cmd:v56}}length of longest uninterrupted sequence of capital letters{p_end}
{synopt:{cmd:v57}}total number of capital letters in the email{p_end}

{synoptset 10 tabbed}{...}
{p2col 5 19 23 2: Outcome}{p_end}
{synopt:{cmd:v58}}denotes whether the email was considered spam ({cmd:1})
 or not ({cmd:0}){p_end}
 
{pstd}
For more information about the data, see
{browse "https://archive.ics.uci.edu/ml/datasets/spambase"}.

{pstd}
Load spam data.{p_end}
{phang2}
{bf:. {stata "insheet using https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, comma"}}{p_end}


{marker example_intro}{...}
    {title:Introduction to {cmd:lassologit}}

{pstd}
The basic syntax for {cmd:lassologit} is to specify the dependent variable
followed by a list of predictors:{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57"}}{p_end}

{pstd}
The output of {cmd:lassologit} shows the penalty levels (lambda), 
the number of predictors included (s), the L1 norm, one information criterion
(EBIC by default), McFadden's pseudo-R-squared, and which predictors
are included or removed from the model.

{pstd}
By default, one line per knot is shown.  Knots are points at which predictors
enter or leave the model.  When you specify {opt long}, an extended output
with one row for each lambda is shown.{p_end}
{phang2}
{bf:. {stata "lassologit, long"}}{p_end}

{pstd}
To obtain the logistic lasso estimate for a scalar lambda or a list of lambdas,
you can use the {opt lambda(numlist)} option.  For example,{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57, lambda(40 20)"}}{p_end}
{phang2}
{bf:. {stata "ereturn list"}}{p_end}

{pstd}
As above, but one lambda.{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57, lambda(40)"}}{p_end}
{phang2}
{bf:. {stata "ereturn list"}}{p_end}

{pstd}
Note that output and the objects stored in {opt e()} depend on whether lambda
is only one value or a list of more than one value.


{marker example_information}{...}
    {title:Information criteria}

{pstd}
To fit the model selected by one of the information criteria, use the
{cmd:lic()} option.{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57"}}{p_end}
{phang2}
{bf:. {stata "lassologit, lic(ebic)"}}{p_end}
{phang2}
{bf:. {stata "lassologit, lic(aicc)"}}{p_end}

{pstd}
In the above example, we use the replay syntax that works similarly to a
postestimation command.  The same can also be achieved in one line.{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57, lic(ebic)"}}{p_end}

{pstd}
When {cmd:lic()} is used, {cmd:lassologit} reports the logistic lasso
estimates and the postlogit estimates (from applying logit estimation to the
model selected by the logistic lasso) for the value of lambda selected by the
specified information criterion.

{pstd}
Note that {cmd:lic()} does not change the estimation results in memory.  The
advantage is that this way {cmd:lic()} can be used multiple times to compare
results; without that we need to refit the model.

{pstd}
To store the model selected by one of the information criteria, use
{cmd:postresults}.{p_end}
{phang2}
{bf:. {stata "lassologit, lic(ebic) postresults"}}{p_end}


{marker example_cv}{...}
    {title:Cross-validation with {cmd:cvlassologit}}

{pstd}
{cmd:cvlassologit} implements K-fold cross-validation, where the data are by
default randomly partitioned.

{pstd}
Here we use K=3 and {cmd:seed(123)} to set the seed for reproducibility.  (Be
patient because this takes a minute.){p_end}
{phang2}
{bf:. {stata "cvlassologit v58 v1-v57, nfolds(3) seed(123)"}}{p_end}

{pstd}
The output shows the prediction performance measured by deviance for each
lambda value.  To fit the model selected by cross-validation, we can
specify {cmd:lopt} or {cmd:lse} using the replay syntax.{p_end}
{phang2}
{bf:. {stata "cvlassologit, lopt"}}{p_end}
{phang2}
{bf:. {stata "cvlassologit, lse"}}{p_end}

{pstd}
The data are by default randomly partitioned into K folds.  The {opt tabfold}
option asks {cmd:lassologit} to show the frequency distribution of successes
({cmd:1}) and failures ({cmd:0}) across folds.{p_end}
{phang2}
{bf:. {stata "cvlassologit v58 v1-v57, nfolds(3) seed(123) tabfold"}}{p_end}

{pstd}
Small samples might have a low number of success or failures in
some folds.  The {cmd:stratified} option can help with this: it ensures
that the number of successes (1) and failures (0) is approximately the same
across folds.{p_end}
{phang2}
{bf:. {stata "cvlassologit v58 v1-v57, nfolds(3) seed(123) tabfold stratified"}}{p_end}

{pstd}
As with {cmd:lassologit}, we can use the {opt long} option for an extended
output.{p_end}
{phang2}
{bf:. {stata "cvlassologit, long"}}{p_end}


{marker example_rigorous}{...}
    {title:Rigorous penalization with {cmd:rlassologit}}

{pstd}
Last, we consider the logistic lasso with rigorous penalization.{p_end}
{phang2}
{bf:. {stata "rlassologit v58 v1-v57"}}{p_end}

{pstd}
{cmd:rlassologit} displays the logistic lasso solution and the postlogit
solution.

{pstd}
The rigorous lambda is returned in {cmd:e(lambda)} and is equal to 79.207801.{p_end}
{phang2}
{bf:. {stata "display e(lambda)"}}{p_end}

{pstd}
We get the same result when specifying the rigorous lambda manually using the
{cmd:lambda()} option of {cmd:lassologit}:{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57, lambda(79.207801)"}}{p_end}


{marker example_prediction}{...}
    {title:Prediction}

{pstd}
After selecting a model, we can use {cmd:predict} to obtain predicted
probabilities or linear predictions.

{pstd}
First, we select a model using {cmd:lic()} in combination with
{cmd:postresults} as above:{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57"}}{p_end}
{phang2}
{bf:. {stata "lassologit, lic(ebic) postresults"}}{p_end}

{pstd}
Then, we use {cmd:predict}:{p_end}
{phang2}
{bf:. {stata "predict double phat, pr"}}{p_end}
{phang2}
{bf:. {stata "predict double xbhat, xb"}}{p_end}

{pstd}
{cmd:pr} saves the predicted probability of success, and {cmd:xb} saves the
linear predicted values.

{pstd} 
Note that the use of {cmd:postresults} is required.  Without
{cmd:postresults}, the results of the estimation with the selected penalty
level are not stored.

{pstd}
The approach for {cmd:cvlassologit} is very similar:{p_end}
{phang2}
{bf:. {stata "cvlassologit v58 v1-v57"}}{p_end}
{phang2}
{bf:. {stata "cvlassologit, lopt postresults"}}{p_end}
{phang2}
{bf:. {stata "predict double phat, pr"}}{p_end}

{pstd}
In the case of {cmd:rlassologit}, we do not need to select a specific penalty
level, and we also do not need to specify {cmd:postresults}:{p_end}
{phang2}
{bf:. {stata "rlassologit v58 v1-v57"}}{p_end}
{phang2}
{bf:. {stata "predict double phat, pr"}}{p_end}


{marker example_holdout}{...}
    {title:Assessing prediction accuracy with {opt holdout()}}

{pstd}
We can leave one partition of the data out of the estimation sample and check
the accuracy of prediction using the {opt holdout(varname)} option.

{pstd}
We first define a binary holdout variable:{p_end}
{phang2}
{bf:. {stata "generate myholdout = (_n>4500)"}}{p_end}

{pstd}
There are 4,601 observations in the sample, and we exclude observations 4,501
to 4,601 from the estimation.  The holdout variable should be set to 1 for all
observations that we want to use for assessing classification accuracy:{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57, holdout(myholdout)"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(loss)"}}{p_end}

{phang2}
{bf:. {stata "rlassologit v58 v1-v57, holdout(myholdout)"}}{p_end}
{phang2}
{bf:. {stata "matrix list e(loss)"}}{p_end}

{pstd}
The loss measure is returned in {cmd:e(loss)}.  As with cross-validation,
deviance is used by default.  {cmd:lossmeasure(class)} will return the average
number of misclassifications.{p_end}


{marker example_plot_lassologit}{...}
    {title:Plotting with {cmd:lassologit}}

{pstd}
{cmd:lassologit} supports plotting of the coefficient path over lambda.  Here
we create the plot using the replay syntax, but the same can be achieved in one
line.{p_end}
{phang2}
{bf:. {stata "lassologit v58 v1-v57"}}{p_end}
{phang2}
{bf:. {stata "lassologit, plotpath(lambda) plotvar(v1-v5) plotlabel plotopt(legend(off))"}}{p_end}

{pstd}
In the above example, we use the following settings: {cmd:plotpath(lambda)}
plots estimates against lambda.  {cmd:plotvar(v1-v5)} restricts the set of
variables plotted to {cmd:v1-v5} (to avoid the graph getting too cluttered).
{opt plotlabel} puts variable labels next to the lines.
{cmd:plotopt(legend(off))} turns the legend off.


{marker example_plot_cvlassologit}{...}
    {title:Plotting with {cmd:cvlassologit}}

{pstd}
The {opt plotcv} option creates a graph of the estimates as a loss function of
lambda:{p_end}
{phang2}
{bf:. {stata "cvlassologit v58 v1-v57, nfolds(3) seed(123)"}}{p_end}
{phang2}
{bf:. {stata "cvlassologit v58 v1-v57, plotcv"}}{p_end}

{pstd}
The vertical solid red line indicates the value of lambda that minimizes the
loss function.  The dashed red line corresponds to the largest lambda for
which mean squared prediction error is within one standard error of the
minimum loss.


{marker stored_results}{...}
{title:Stored results}


    {title:lassologit with single lambda and rlassologit}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}sample size{p_end}
{synopt:{cmd:e(cons)}}{cmd:1} if constant is present, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(p)}}number of predictors excluding intercept{p_end}
{synopt:{cmd:e(std)}}{cmd:1} if predictors are standardized{p_end}
{synopt:{cmd:e(lcount)}}number of lambda values{p_end}
{synopt:{cmd:e(ll0)}}log likelihood of null model{p_end}
{synopt:{cmd:e(total_success)}}number of successes{p_end}
{synopt:{cmd:e(total_trials)}}number of trials{p_end}
{synopt:{cmd:e(N_holdout)}}observations in holdout sample{p_end}
{synopt:{cmd:e(lmax)}}largest lambda value{p_end}
{synopt:{cmd:e(lmin)}}smallest lambda value{p_end}
{synopt:{cmd:e(lambda)}}penalty level{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(shat)}}number of selected regressors{p_end}
{synopt:{cmd:e(shat0)}}number of selected and unpenalized regressors including constant (if present){p_end}
{synopt:{cmd:e(tss)}}total sum of squares{p_end}
{synopt:{cmd:e(aic)}}minimum AIC{p_end}
{synopt:{cmd:e(bic)}}minimum BIC{p_end}
{synopt:{cmd:e(aicc)}}minimum AICc{p_end}
{synopt:{cmd:e(ebic)}}minimum EBIC{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lassologit} or {cmd:rlassologit}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(varX)}}all predictors{p_end}
{synopt:{cmd:e(varXmodel)}}penalized predictors{p_end}
{synopt:{cmd:e(selected)}}selected predictors{p_end}
{synopt:{cmd:e(selected0)}}selected predictors including constant{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}posted coefficient vector; used for prediction by default{p_end}
{synopt:{cmd:e(beta_post)}}postlogit coefficient vector{p_end}
{synopt:{cmd:e(beta_dense)}}logistic lasso coefficient vector without zeros{p_end}
{synopt:{cmd:e(beta_post_dense)}}postlogit coefficient vector without zeros{p_end}
{synopt:{cmd:e(beta_std)}}logistic lasso coefficient vector in standard units{p_end}
{synopt:{cmd:e(beta_std_post)}}postlogit coefficient vector in standard units{p_end}
{synopt:{cmd:e(beta)}}logistic lasso coefficient vector{p_end}
{synopt:{cmd:e(sdvec)}}vector of standard deviations of the predictors{p_end}
{synopt:{cmd:e(sPsi)}}penalty loadings in standard units{p_end}
{synopt:{cmd:e(Psi)}}= {cmd:e(sPsi)} :* {cmd:e(sdvec)}{p_end}
{synopt:{cmd:e(loss)}}estimated loss if {opt holdout()} is used{p_end}


    {title:lassologit with multiple lambdas}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}sample size{p_end}
{synopt:{cmd:e(cons)}}{cmd:1} if constant is present, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(p)}}number of predictors excluding intercept{p_end}
{synopt:{cmd:e(std)}}{cmd:1} if predictors are standardized{p_end}
{synopt:{cmd:e(lcount)}}number of lambda values{p_end}
{synopt:{cmd:e(ll0)}}log likelihood of null model{p_end}
{synopt:{cmd:e(total_success)}}number of successes{p_end}
{synopt:{cmd:e(total_trials)}}number of trials{p_end}
{synopt:{cmd:e(N_holdout)}}observations in holdout sample{p_end}
{synopt:{cmd:e(aicmin)}}minimum AIC{p_end}
{synopt:{cmd:e(bicmin)}}minimum BIC{p_end}
{synopt:{cmd:e(aiccmin)}}minimum AICc{p_end}
{synopt:{cmd:e(ebicmin)}}minimum EBIC{p_end}
{synopt:{cmd:e(aicid)}}lambda ID of minimum AIC{p_end}
{synopt:{cmd:e(bicid)}}lambda ID of minimum BIC{p_end}
{synopt:{cmd:e(aiccid)}}lambda ID of minimum AICc{p_end}
{synopt:{cmd:e(ebicid)}}lambda ID of minimum EBIC{p_end}
{synopt:{cmd:e(aiclambda)}}lambda corresponding to minimum AIC{p_end}
{synopt:{cmd:e(biclambda)}}lambda corresponding to minimum BIC{p_end}
{synopt:{cmd:e(aicclambda)}}lambda corresponding to minimum AICc{p_end}
{synopt:{cmd:e(ebiclambda)}}lambda corresponding to minimum EBIC{p_end}
{synopt:{cmd:e(loss)}}estimated loss if {opt holdout()} is used{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:lassologit}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(varX)}}all predictors{p_end}
{synopt:{cmd:e(varXmodel)}}penalized predictors{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Matrices}{p_end}
{synopt:{cmd:e(betas)}}posted coefficient matrix{p_end}
{synopt:{cmd:e(betas_std)}}posted coefficient matrix in standard units{p_end}
{synopt:{cmd:e(lambdas)}}vector of lambdas{p_end}
{synopt:{cmd:e(aic)}}vector of AIC values{p_end}
{synopt:{cmd:e(aicc)}}vector of AICc values{p_end}
{synopt:{cmd:e(bic)}}vector of BIC values{p_end}
{synopt:{cmd:e(ebic)}}vector of EBIC values{p_end}
{synopt:{cmd:e(ll)}}vector of log-likelihood values{p_end}
{synopt:{cmd:e(l1norm)}}vector of L1 norm{p_end}
{synopt:{cmd:e(shat)}}number of included predictors{p_end}
{synopt:{cmd:e(shat0)}}number of included predictors, including intercept{p_end}
{synopt:{cmd:e(sdvec)}}vector of standard deviations of the predictors{p_end}
{synopt:{cmd:e(sPsi)}}penalty loadings in standard units{p_end}
{synopt:{cmd:e(Psi)}}= {cmd:e(sPsi)} :* {cmd:e(sdvec)}{p_end}


    {title:cvlassologit}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(lunique)}}lunique{p_end}
{synopt:{cmd:e(lambdan)}}{cmd:1} if {opt lambdan} option is used{p_end}
{synopt:{cmd:e(mlossmin)}}minimum mean cross-validated loss{p_end}
{synopt:{cmd:e(lmin)}}smallest lambda used for CV{p_end}
{synopt:{cmd:e(lmax)}}maximum lambda used for CV{p_end}
{synopt:{cmd:e(lse)}}lambda se (may be missing if there is no unique minimum
MSPE){p_end}
{synopt:{cmd:e(lopt)}}optimal lambda (may be missing if there is no unique minimum MSPE){p_end}
{synopt:{cmd:e(lseid)}}lambda ID corresponding to {cmd:e(lse)}{p_end}
{synopt:{cmd:e(loptid)}}lambda ID corresponding to {cmd:e(lopt)}{p_end}
{synopt:{cmd:e(nfolds)}}number of folds{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cvlassologit}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(varX)}}all predictors{p_end}
{synopt:{cmd:e(lossmeasure)}}loss measure ({cmd:deviance} or {cmd:class}){p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Matrices}{p_end}
{synopt:{cmd:e(lambdas)}}vector of lambda values used for cross-validation{p_end}
{synopt:{cmd:e(mloss)}}mean cross-validated loss{p_end}
{synopt:{cmd:e(loss)}}cross-validated loss for each fold; a matrix of size {it:nfolds} x {it:lcount}{p_end}
{synopt:{cmd:e(cvsd)}}estimate of standard error of mean cross-validated loss{p_end}
{synopt:{cmd:e(cvlower)}}= {cmd:e(mloss)} - {cmd:e(cvsd)}{p_end}
{synopt:{cmd:e(cvupper)}}= {cmd:e(mloss)} + {cmd:e(cvsd)}{p_end}


    {title:Estimation sample (always returned)}

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

{marker Belloni2016}{...}
{phang}
Belloni, A., V. Chernozhukov, and Y. Wei. 2016. Post-selection inference for
generalized linear models with many controls.
{it:Journal of Business & Economic Statistics} 34: 606-619.
{browse "https://doi.org/10.1080/07350015.2016.1166116"}.

{marker Belloni2017}{...}
{phang}
Belloni, A., V. Chernozhukov, I. Fern{c a'}ndez-Val, and C. Hansen. 2017.
Program evaluation and causal inference with high-dimensional data.
{it:Econometrica} 85: 233-298.
{browse "https://doi.org/10.3982/ECTA12723"}.

{marker Chen2008}{...}
{phang}
Chen, J., and Z. Chen. 2008. Extended Bayesian information criteria for model
selection with large model spaces. {it:Biometrika} 95: 759-771.
{browse "https://doi.org/10.1093/biomet/asn034"}.

{marker Fu1998}{...}
{phang}
Fu, W. J. 1998. Penalized regressions: The bridge versus the lasso.
{it:Journal of Computational and Graphical Statistics} 7: 397-416.
{browse "https://doi.org/0.1080/10618600.1998.10474784"}.

{marker Friedman2007}{...}
{phang}
Friedman, J., T. Hastie, H. H{c o:}fling, and R. Tibshirani. 2007.
Pathwise coordinate optimization. {it:Annals of Applied Statistics} 1: 302-332. 
{browse "https://doi.org/10.1214/07-AOAS131"}.

{marker Friedman2010}{...}
{phang}
Friedman, J., T. Hastie, and R. Tibshirani. 2010. Regularization paths for
generalized linear models via coordinate descent.
{it:Journal of Statistical Software} 33(1): 1-22.
{browse "https://doi.org/10.18637/jss.v033.i01"}.

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

{marker Sugiura1978}{...}
{phang}
Sugiura, N. 1978. Further analysts [{it:sic}] of the data by Akaike's
information criterion and the finite corrections.
{it:Communications in Statistics -- Theory and Methods} 7: 13-26.
{browse "https://doi.org/10.1080/03610927808827599"}.

{marker Tib1996}{...}
{phang}
Tibshirani, R. 1996. Regression shrinkage and selection via the lasso.
{it:Journal of the Royal Statistical Society, Series B} 58: 267-288. 
{browse "https://doi.org/10.1111/j.2517-6161.1996.tb02080.x"}.

{marker Tib2012}{...}
{phang}
Tibshirani, R., J. Bien, J. Friedman, T. Hastie, N. Simon, J. Taylor, and
R. J. Tibshirani. 2012. Strong rules for discarding predictors in lasso-type
problems.  {it:Journal of the Royal Statistical Society, Series B} 74: 245-266.
{browse "https://doi.org/10.1111/j.1467-9868.2011.01004.x"}.

{marker Kooji2007}{...}
{phang}
Van der Kooij, A. 2007. Prediction accuracy and stability of regression with
optimal scaling transformations. PhD thesis, Department of Data Theory,
University of Leiden.  


{marker website}{...}
{title:Website}

{pstd}
Please check our website {browse "https://statalasso.github.io/"} for more
information.


{marker installation}{...}
{title:Installation}

{pstd}
To get the latest stable version of {cmd:lassologit} from our website, check
the installation instructions at
{browse "https://statalasso.github.io/installation/"}.  We update the stable
website version more frequently than the Statistical Software Components
version.

{pstd}
To verify that {cmd:lassologit} is correctly installed, click on or type
{bf:{stata "whichpkg lassopack"}} (which requires {helpb whichpkg} to be
installed; {bf:{stata "ssc install whichpkg"}}).


{marker citation}{...}
{title:Citation of lassologit}

{pstd}
{opt lassologit} is not an official Stata command.  It is a free contribution
to the research community, like an article.  Please cite it as such:

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
Help:  {helpb lasso2}, {helpb cvlasso}, {helpb rlasso}, {helpb ivlasso},
{helpb pdslasso} (if installed){p_end}
