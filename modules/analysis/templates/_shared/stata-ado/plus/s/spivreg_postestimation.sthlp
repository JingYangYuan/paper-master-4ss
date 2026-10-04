{smcl}
{* *! version 1.0.3  11feb2011}{...}
{cmd:help spivreg postestimation}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}


{title:Title}

{p2colset 5 31 33 2}{...}
{p2col:{hi: spivreg postestimation} {hline 2}}Postestimation tools
for spivreg{p_end}


{title:Description}

{pstd}The following postestimation commands are available after {cmd:spivreg}:

{synoptset 13}{...}
{p2coldent :command}Description{p_end}
{synoptline}
{synopt:{bf:{help estat}}}AIC, BIC, VCE, and estimation sample summary{p_end}
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_lrtest
INCLUDE help post_nlcom
{synopt :{helpb spivreg postestimation##predict:predict}}predicted values{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 15}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt na:ive}}predictions based on the observed values of {bf:y};
the default{p_end}
{synopt :{opt xb}}linear prediction{p_end}
{synoptline}
{p2colreset}{...}


{title:Options for predict}

{phang}{opt naive}, the default, computes predicted values based on the
observed values of {bf:y}, {bf:Y}*{bf:g} + {it:lambda}*{bf:W}*{bf:y} +
{bf:X}*{bf:b}.

{phang}{opt xb} calculates the linear prediction {bf:X}*{bf:b}.


{marker remarks}{...}
{title:Remarks}

{pstd}The predictor computed by the option {bf:naive} will generally be
biased; see {help spivreg postestimation##KP2007:Kelejian and Prucha (2007)}
for an explanation.

{pstd}See {it:{help spreg postestimation##remarks:Remarks}} in 
{helpb spreg postestimation} for a more detailed discussion of biased
and unbiased spatial predictors.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use pollute}{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}
{phang2}{cmd:. spivreg pollution area (factories = penalties), id(id) dlmat(cobj) elmat(cobj)}{p_end}

{pstd}Obtain predicted values based on the observed values of {bf:y}{p_end}
{phang2}{cmd:. predict yhat}{p_end}


{title:Reference}

{marker KP2007}{...}
{phang}Kelejian, H. H., and I. R. Prucha. 2007. The relative
efficiencies of various predictors in spatial econometric models
containing spatial lags.  {it:Regional Science and Urban Economics} 37:
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

{p 7 14 2}Help:  {helpb spivreg}, {helpb spreg} (if installed){p_end}
