{smcl}
{* *! version 1.0.2  11feb2011}{...}
{cmd:help spreg postestimation}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 29 31 2}{...}
{p2col:{hi:spreg postestimation} {hline 2}}Postestimation tools for spreg{p_end}


{title:Description}

{pstd}The following postestimation commands are available after
{cmd:spreg}:

{synoptset 13}{...}
{p2coldent :command}Description{p_end}
{synoptline}
{synopt:{bf:{help estat}}}AIC, BIC, VCE, and estimation sample summary{p_end}
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_lrtest
INCLUDE help post_nlcom
{synopt :{helpb spreg postestimation##predict:predict}}predicted values{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} 
{opt rf:orm}|{opt li:mited}|{opt na:ive}|{opt xb} 
{opt rft:ransform(matname)}]


{title:Options for predict}

{phang}See {it:{help spreg_postestimation##remarks:Remarks}} below for a
detailed explanation of the {bf:predict} options.

{phang}{opt rform}, the default, calculates predicted values calculated
from the reduced-form equation {bf:y} =
({bf:I}-lambda*{bf:W})^(-1)*{bf:X}*{bf:b}.

{phang}{opt limited} calculates predicted values based on the
limited-information set.  This option is available only for a model with
homoskedastically distributed errors.

{phang}{opt naive} calculates predicted values based on the observed
values of {bf:y}, lambda*{bf:W}*{bf:y} + {bf:X}*{bf:b}.

{phang}{opt xb} calculates the linear prediction {bf:X}*{bf:b}.

{phang}{opt rftransform(matname)} tells {cmd:predict} to use the
user-specified inverse of ({bf:I}-lambda*{bf:W}).  The matrix {bf:T}
should reside in Mata memory.  This option is available only with the
reduced-form predictor.


{marker remarks}{...}
{title:Remarks}

{pstd}Recall the spatial-autoregressive spatial-error (SARAR) model:

{p 8 6 2}
{bf:y} = lambda*{bf:W}*{bf:y} + {bf:X}*{bf:b} + {bf:u}

{p 8 6 2}
{bf:u} = rho*{bf:M}*{bf:u} + {bf:e}

{pstd}This model specifies a system of n simultaneous equations for the
dependent variable {bf:y}.

{pstd}The predictor based on the reduced-form equation is obtained by
solving the model for the endogenous variable {bf:y}, which gives
({bf:I}-lambda*{bf:W})^(-1)*{bf:X}*{bf:b} for the spatial-autoregressive
(SAR) and SARAR models and {bf:X}*{bf:b} for the SAR error model.

{pstd}The limited-information-set predictor is described in 
{help spreg postestimation##KP2007:Kelejian and Prucha (2007)}.  Let

	{bf:U} = ({bf:I}-rho*{bf:M})^(-1) * ({bf:I}-rho*{bf:M}')^(-1)
	
	{bf:Y} = ({bf:I}-lambda*{bf:W})^(-1) * ({bf:I}-lambda*{bf:W}')^(-1)
	
	E(w_i*{bf:y}) = w_i * ({bf:I}-lambda*{bf:W})^(-1) * {bf:X}*{bf:b}
	
	cov(u_i,w_i*{bf:y}) = sigma^2 * w_i*{bf:Y}*w_i'
	
	var(w_i*{bf:y}) = sigma^2 * u_i*({bf:I}-lambda*{bf:W}')^(-1)*w_i'

{pstd}where w_i and u_i denote the ith row of {bf:W} and {bf:U},
respectively.  The limited-information-set predictor for observation i
is given by


	                       cov(u_i,w_i*{bf:y})
	lambda*w_i*{bf:y} + x_i*{bf:b} + -------------- * [w_i*{bf:y} - E(w_i*{bf:y})]
	                         var(w_i*{bf:y})

{pstd}where x_i denotes the ith row of {bf:X}.  Because the formula
involves the sigma^2 term, this predictor is available only for a model
with homoskedastically distributed errors.

{pstd}The reduced-form predictor is based on the information set
{{bf:X},{bf:W}}.  The limited-information-set predictor includes the
linear combination {bf:W}*{bf:y}; thus it is more efficient than the
reduced-form predictor.  Both predictors are unbiased predictors
conditional on their information set.

{pstd}The naive predictor is obtained by treating the values of {bf:y}
on the right-hand side as given, which results in the formula
lambda*{bf:W}*{bf:y} + {bf:X}*{bf:b} for the SAR and SARAR models and
{bf:X}*{bf:b} for the SAR error model.  Note that this predictor is a
special case of the limited-information-set predictor with
cov(u_i,w_i*{bf:y}) = 0 but that this is true only when lambda = rho =
0.

{pstd}The naive predictor ignores the feedback that the neighboring
observations may have on the value of {bf:y} in a given observation.
The reduced-form and limited-information-set predictors factor this
feedback into the computations through the
({bf:I}-lambda*{bf:W})^(-1)*{bf:X}*{bf:b} term.  If you are interested
in how a change to a covariate in an observation affects the entire
system, you should use the reduced-form or the limited-information-set
predictor.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use pollute}{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}
{phang2}{cmd:. spreg ml pollution factories area, id(id) dlmat(cobj) elmat(cobj)}{p_end}

{pstd}Obtain predicted values based on the reduced-form equation{p_end}
{phang2}{cmd:. predict y0}{p_end}

{pstd}Increase {cmd:factories} in observation 50 by 1 and obtain a new set of
predicted values{p_end}
{phang2}{cmd:. replace factories = factories+1 in 50}{p_end}
{phang2}{cmd:. predict y1}{p_end}

{pstd}Compare the two sets of predicted values{p_end}
{phang2}{cmd:. generate deltay = abs(y1-y0)}{p_end}
{phang2}{cmd:. count if deltay!=0}{p_end}

{pstd}Note that a change in one observation resulted in a total of 25 changes.{p_end}


{title:Reference}

{marker KP2007}{...}
{phang}Kelejian, H. H., and I. R. Prucha. 2007.  The relative
efficiencies of various predictors in spatial econometric models
containing spatial lags. {it:Regional Science and Urban Economics} 37:
363-374.


{title:Authors}

{phang}David Drukker{p_end}
{phang}StataCorp{p_end}
{phang}College Station, TX{p_end}
{phang}{browse "mailto:ddrukker@stata.com":ddrukker@stata.com}

{phang}Ingmar Prucha{p_end}
{phang}Department of Economics{p_end}
{phang}University of Maryland{p_end}
{phang}College Park, MD{p_end}
{phang}{browse "mailto:prucha@econ.umd.edu":prucha@econ.umd.edu}

{phang}Rafal Raciborski{p_end}
{phang}StataCorp{p_end}
{phang}College Station, TX{p_end}
{phang}{browse "mailto:rraciborski@stata.com":rraciborski@stata.com}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 13, number 2: {browse "http://www.stata-journal.com/article.html?article=st0292":st0292}{p_end}

{p 7 14 2}Help:  {helpb spreg}, {helpb spivreg} (if installed){p_end}
