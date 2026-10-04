{smcl}
{* *! version 1.0.0  05apr2012}{...}
{cmd:help spm}{right:dialog:  {dialog spm}{space 15}}
{right:also see:  {help spm postestimation}}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:spm} {hline 2}}SAR, SEM and Durbin Fixed Effects Spatial Models with Double Weights Matrix for Balanced Panel Data{p_end}
{p2colreset}{...}

{title:Syntax}

{phang}
Spatial Autoregressive (SAR) model

{p 8 16 2}{cmd:spm} {depvar} [{indepvars}] {ifin} {weight}
[, {it:{help spm##saroptions:SAR_options}}]

{phang}
Spatial Error (SEM) model

{p 8 16 2}{cmd:spm} {depvar} [{indepvars}] {ifin} {weight} 
, {cmdab:m:odel(sem)} [{it:{help spm##semoptions:SEM_options}}]

{phang}
Spatial Durbin (SDM) model

{p 8 16 2}{cmd:spm} {depvar} [{indepvars}] {ifin} {weight} 
, {cmdab:m:odel(durbin)} [{it:{help spm##durbinoptions:DURBIN_options}}]



{marker saroptions}{...}
{synoptset 29 tabbed}{...}
{synopthdr :SAR_options}
{synoptline}
{syntab:Spatial Matrix}
{synopt :{cmdab:sarw:mat(}{opt name)}} First Stata matrix used in the spatial-autoregressive term{p_end}

{synopt :{cmdab:sarw2:mat(}{opt name)}} Second Stata matrix used in the spatial-autoregressive term{p_end}

{syntab:Fixed Effects}
{synopt :{cmdab:type(}{opt name)}}  May be {opt ind} for individual fixed effects effects, {opt time} for time fixed effects or {opt both} for time and individual fixed effects{p_end}

{synopt :{cmdab:detrend}}  Removes unit specific linear trend 

{synopt :{cmdab:detrend quadratic}}  Removes unit specific quadratic trend 

{syntab:Other}

{synopt :{opt rob:ust}}  Uses the robust or sandwich estimator of variance.  This estimator is robust to some types of misspecification so long as the observations are independent{p_end}

{synopt :{cmdab:drobust:(}{opt name)}}  Uses the Stata matrix ({opt name)} to compute double-clustered standard errors as in Cameron et al 2011. The Stata matrix can be one of the two used 
in {cmdab:sarw:mat(}{opt name)} or {cmdab:sarw2:mat(}{opt name)} or a different one{p_end}

{synopt :{opt l:evel(#)}} Set confidence level; default is {cmd:level(95)}{p_end}



{marker semoptions}{...}
{synoptset 29 tabbed}{...}
{synopthdr :SEM_options}
{synoptline}
{syntab:Spatial Matrix}
{synopt :{cmdab:semw:mat(}{opt name)}} First Stata matrix used in the spatial-autoregressive disturbance term{p_end}
{synopt :{cmdab:semw2:mat(}{opt name)}} Second Stata matrix used in the spatial-autoregressive disturbance{p_end}


{syntab:Fixed Effects}
{synopt :{cmdab:type(}{opt name)}}  May be {opt ind} for individual fixed effects effects, {opt time} for time fixed effects or {opt both} for time and individual fixed effects{p_end}
{synopt :{cmdab:detrend}}  Removes unit specific linear trend 

{synopt :{cmdab:detrend quadratic}}  Removes unit specific quadratic trend 


{syntab:Other}
{synopt :{opt rob:ust}}  Uses the robust or sandwich estimator of variance.  This estimator is robust to some types of misspecification so long as the observations are independent{p_end}
{synopt :{opt l:evel(#)}} Set confidence level; default is {cmd:level(95)}{p_end}



{marker durbinoptions}{...}
{synoptset 29 tabbed}{...}
{synopthdr :DURBIN_options}
{synoptline}
{syntab :Spatial Matrix}
{synopt :{cmdab:sarw:mat(}{opt name)}} First Stata matrix used in the spatial-autoregressive term{p_end}
{synopt :{cmdab:sarw2:mat(}{opt name)}} Second Stata matrix used in the spatial-autoregressive term{p_end}

{syntab:Fixed Effects}
{synopt :{cmdab:type(}{opt name)}}  May be {opt ind} for individual fixed effects effects, {opt time} for time fixed effects or {opt both} for time and individual fixed effects{p_end}
{synopt :{cmdab:detrend}}  Removes unit specific linear trend 

{synopt :{cmdab:detrend quadratic}}  Removes unit specific quadratic trend 



{syntab:Spatially lagged regressors}
{synopt :{cmdab:durb:in}({varlist} [, {it:{help spm##sdmoptions:SDM_options}}])}  Specifies the regressor that have to be spatially lagged using both {cmdab:sarw:mat(}{opt name)} or {cmdab:sarw2:mat(}{opt name)}{p_end}


{syntab:Other}
{synopt :{opt rob:ust}}  Uses the robust or sandwich estimator of variance.  This estimator is robust to some types of misspecification so long as the observations are independent{p_end}
{synopt :{opt l:evel(#)}} Set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{cmdab:drobust:(}{opt name)}}  Uses the Stata matrix ({opt name)} to compute double-clustered standard errors as in Cameron et al 2011. The Stata matrix can be one of the two 
used in {cmdab:sarw:mat(}{opt name)} or {cmdab:sarw2:mat(}{opt name)} or a different one{p_end}


{marker sdmoptions}{...}
{synoptset 39 tabbed}{...}
{synopthdr :SDM_options}
{syntab :Direct and indirect effects}
{synopt :{opt ind:irect}} Calculates direct and indirect effects {p_end}
{synopt :{opt nsim(#)}} Set the number of simulations for the Lesage and Pace (2009) procedure to calculate the standard errors for the direct and indirect effects{p_end}


{title:Remarks}
{pstd}
spm allows to estimate balanced spatial panel data models with double weights matrix as in Atella V., Belotti F., Depalo D., Piano Mortari A., (2014), "Measuring spatial 
effects in the presence of institutional constraints: The case of Italian Local Health Authority expenditure", Regional Science and Urban Economics, 49, 232–241.{p_end}

{pstd}
When variance-covariance matrix is not positive definite, direct, indirect and total effects standard errors are computed using a modified positive definite matrix as in Rebonato and Jackel (1999).{p_end}

{title:Bibliography}
{phang}
Cameron, A.C.,Gelbach, J.B.,Miller, D.L., 2011. Robust inference with multiway clustering. J. Bus. Econ. Stat. 29, 238–249.

{phang}
LeSage, J.P.,Pace, R.K., 2009. Introduction to Spatial Econometrics. Taylor & Francis.

{phang}
Rebonato, R., Jackel, P., 1999,  
The most general methodology to create a valid correlation matrix for risk management and option pricing purposes. Quantitative Research Centre of the NatWest Group


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use "http://www.econometrics.it/stata/data/spm_demo.dta", clear}{p_end}
{phang2}{cmd:. mata mata matuse "http://www.econometrics.it/stata/data/W1.mmat", replace}{p_end}
{phang2}{cmd:. mata st_matrix("W1",W1)}{p_end}
{phang2}{cmd:. mata mata matuse "http://www.econometrics.it/stata/data/W2.mmat", replace}{p_end}
{phang2}{cmd:. mata st_matrix("W2",W2)}{p_end}
{phang2}{cmd:. xtset id t}{p_end}

{pstd}Durbin model{p_end}
{phang2}{cmd:. spm y x1, model(durbin) sarwmat(W1) sarw2mat(W2)}{p_end}



{title:Saved results}

{pstd}
{cmd:spm} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_c)}}concentrated log likelihood{p_end}
{synopt:{cmd:e(g_min)}}minimum number of observations per group{p_end}
{synopt:{cmd:e(g_avg)}}average number of observations per group{p_end}
{synopt:{cmd:e(g_max)}}maximum number of observations per group{p_end}
{synopt:{cmd:e(rank)}}rank of the variance-covariance matrix{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:spm}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}variable denoting groups{p_end}
{synopt:{cmd:e(tvar)}}variable denoting time{p_end}
{synopt:{cmd:e(type)}}type of fixed effects{p_end}
{synopt:{cmd:e(model)}} estimated spatial model{p_end}
{synopt:{cmd:e(effects)}} fixed or random effects {p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


