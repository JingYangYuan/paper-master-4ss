{smcl}
{* *! version 1.0.1  5AUG2011}{...}
{cmd:help apcspline postestimation}{right: ({browse "http://www.stata-journal.com/article.html?article=up0057":SJ17-4: st0245_1})}
{vieweralsosee "apcspline" "help apcspline"}{...}
{hline}

{title:Title}

{p2colset 5 33 35 2}{...}
{p2col :{hi:apcspline postestimation} {hline 2}}Postestimation tools for
apcspline{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
The following postestimation commands are available after
{cmd:apcspline}:

{synoptset 17}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
INCLUDE help post_estatic
INCLUDE help post_estatsum
INCLUDE help post_estatvce
INCLUDE help post_svy_estat
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_linktest
INCLUDE help post_lrtest
INCLUDE help post_margins
INCLUDE help post_mfx
INCLUDE help post_nlcom
{synopt :{helpb poisson postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_suest
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} 
[{cmd:,} {it:statistic} {it:options} {opt ra:te(#)} {opt nooff:set}]

{synoptset 11}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt a:ge}}predicted rates as a function of age{p_end}
{synopt :{opt per:iod}}predicted relative risk as a function of period{p_end}
{synopt :{opt y:ear}}is a synonym for {cmd:period}{p_end}
{synopt :{opt coh:ort}}predicted relative risk as a function of cohort{p_end}
{synopt :{opt ir}}incidence rate{p_end}
{synoptline}

{synoptset 11}{...}
{synopthdr}
{synoptline}
{synopt :{opt n}}number of events; the default{p_end}
{synopt :{opt xb}}linear prediction{p_end}
{synopt :{opt stdp}}standard error of the linear prediction{p_end}
{synopt :{opt sc:ore}}first derivative of the log likelihood with respect to
xb{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help esample


{title:Options for predict}

{phang}
{opt age} specifies predicted rates as a function of age.

{phang}
{opt period} specifies predicted relative risk as a function of period.

{phang}
{opt year} is a synonym for {cmd:period}.

{phang}
{opt cohort} specifies predicted relative risk as a function of cohort.

{phang}
{opt ir} calculates the incidence rate exp(xb), which is the predicted
number of events when exposure is 1.

{phang}
{opt n}, the default, calculates the predicted number of events, which
is exp(xb)*exposure if {opt exposure()} was specified.

{phang}
{opt xb} calculates the linear prediction, which is xb + ln(exposure) if
{cmd:exposure()} was specified; see {cmd:nooffset} below.

{phang}
{opt stdp} calculates the standard error of the linear prediction.

{phang}
{opt score} calculates the equation-level score, the derivative of the
log likelihood with respect to the linear prediction.

{phang}
{opt rate(#)} is relevant only if you specified {opt ir} or {opt age}.
It multiplies the predicted rates by {it:#}.  The use of
{cmd:rate(1e5)}, for instance, will yield rates per 100,000.

{phang}
{opt nooffset} is relevant only if you specified {opt exposure()} when
you fit the model.  It modifies the calculations made by {cmd:predict}
so that they ignore the exposure variable; the linear prediction is
treated as xb rather than xb + ln(exposure).


{title:Example}

{phang}{cmd:. apcspline deaths age year cohort, exposure(pyears)}{p_end}
{phang}{cmd:. predict f_age, age rate(1e5)}


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

{p 7 14 2}Help:  {helpb apcspline};{break}
{manhelp glm_postestimation R:glm postestimation},
{manhelp regress_postestimation R:regress postestimation}
{p_end}
