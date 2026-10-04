{smcl}
{* *! version 1.0.4  24jan2012}{...}
{cmd:help spivreg}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{hi:spivreg} {hline 2}}Spatial-autoregressive model with
spatial-autoregressive errors and additional endogenous variables{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:spivreg} {depvar} [{it:{help varlist:varlist1}}] {cmd:(}{it:varlist2}
{cmd:=} [{it:varlist_iv}]{cmd:)} {ifin}{cmd:,} {opth id(varname)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth id(varname)}}ID variable{p_end}
{synopt:{cmd:{ul:dl}mat(}{it:objname}{cmd:)}}{helpb spmat:spmat} object used in the
spatial-autoregressive term{p_end}
{synopt:{cmd:{ul:el}mat(}{it:objname}{cmd:)}}{helpb spmat:spmat} object used in the
spatial-error term{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}
{synopt:{opt het:eroskedastic}}use the formula for the heteroskedastic error term{p_end}
{synopt:{cmd:impower(}{it:q}{cmd:)}}use {it:q} powers of matrix {bf:W} in forming the
instrument matrix {bf:H}; default is {cmd:impower(2)}{p_end}
{synopt:{cmdab:l:evel(}{it:#}{cmd:)}}set confidence level; default is
{cmd:level(95)}{p_end}
{synopt :{it:{help spivreg##maximize_options:maximize_options}}}control the
maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {cmd:id()} is required.{p_end}


{title:Description}

{pstd}{cmd:spivreg} estimates the parameters of a cross-sectional
spatial-autoregressive model with spatial-autoregressive disturbances,
which is known as a SARAR model when there are additional endogenous
regressors.

{pstd}A SARAR model includes a weighted average of the dependent
variable, known as a spatial lag, as a right-hand-side variable, and it
allows the disturbance term to depend on a weighted average of the
disturbances corresponding to other units.  The weights may differ for
each observation and are frequently inversely related to the distance
from the current observation.  These weights must be stored in a
spatial-weighting matrix created by {helpb spmat}.

{pstd}{cmd:spivreg} estimates the parameters by generalized spatial
two-stage least squares.


{title:Options}

{phang}{opth id(varname)} specifies a numeric variable that contains a
unique identifier for each observation.  {cmd:id()} is required.

{phang}{cmd:dlmat(}{it:objname}{cmd:)} specifies an {helpb spmat} object
that contains the spatial-weighting matrix {bf:W} to be used in the
spatial-autoregressive term.

{phang}{cmd:elmat(}{it:objname}{cmd:)} specifies an {cmd:spmat} object
that contains the spatial-weighting matrix {bf:M} to be used in the
spatial-error term.

{phang}{opt noconstant} suppresses the constant term in the model.

{phang}{opt heteroskedastic} specifies that {cmd:spivreg} use an
estimator that allows {bf:e} to be heteroskedastically distributed over
the observations.  By default, {cmd:spivreg} uses an estimator that
assumes homoskedasticity.

{phang}{cmd:impower(}{it:q}{cmd:)} specifies how many powers of the
matrix {bf:W} to include in calculating the instrument matrix {bf:H}.
The default is {cmd:impower(2)}.  The allowed values of {it:q} are
integers in the set {c -(}2, 3, ..., 
{cmd:floor(sqrt(}{it:n}{cmd:))}{c )-}.

{phang}{opt level(#)} specifies the confidence level, as a percentage,
for confidence intervals.  The default is {cmd:level(95)} or as set by
{cmd:set level}.

{marker maximize_options}{...}
{phang}{it:maximize_options}:  {opt iter:ate(#)}, [{cmd:no}]{cmd:log},
{opt tr:ace}, {opt grad:ient}, {opt showstep}, {opt showtol:erance},
{opt tol:erance(#)}, {opt ltol:erance(#)}, and {opt from(init_specs)};
see {helpb maximize:[R] maximize}.  These options are seldom used.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use pollute}{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}

{pstd}Estimate the SARAR parameters{p_end}
{phang2}{cmd:. spivreg pollution area (factories = penalties), id(id) dlmat(cobj) elmat(cobj)}{p_end}


{title:Saved results}

{pstd}
{cmd:spivreg} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(rho_2sls)}}initial estimate of rho{p_end}
{synopt:{cmd:e(iterations)}}number of generalized method of moments iterations{p_end}
{synopt:{cmd:e(iterations_2sls)}}number of two-stage least-squares iterations{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if generalized method of moments stage converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(converged_2sls)}}{cmd:1} if two-stage least-squares stage converged, {cmd:0} otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:spivreg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(model)}}{cmd:sarar}, {cmd:sar}, {cmd:sare}, or {cmd:lr}{p_end}
{synopt:{cmd:e(het)}}{cmd:heteroskedastic} or {cmd:homoskedastic}{p_end}
{synopt:{cmd:e(indeps)}}names of independent variables{p_end}
{synopt:{cmd:e(exogr)}}exogenous regressors{p_end}
{synopt:{cmd:e(insts)}}instruments{p_end}
{synopt:{cmd:e(instd)}}instrumented variables{p_end}
{synopt:{cmd:e(constant)}}{cmd:noconstant} or {cmd:hasconstant}{p_end}
{synopt:{cmd:e(H_omitted)}}names of omitted instruments in {bf:H} matrix{p_end}
{synopt:{cmd:e(idvar)}}name of ID variable{p_end}
{synopt:{cmd:e(dlmat)}}name of {cmd:spmat} object used in {cmd:dlmat()}{p_end}
{synopt:{cmd:e(elmat)}}name of {cmd:spmat} object used in {cmd:elmat()}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(delta_2sls)}}initial estimate of beta and lambda{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Acknowledgment} 

{pstd}We gratefully acknowledge financial support from the National
Institutes of Health through the SBIR grants R43 AG027622 and R44
AG027622.


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

{p 7 14 2}Help:  {helpb spivreg postestimation}, {helpb spmat}, {helpb spreg}, {helpb spmap}, {helpb shp2dta}, {helpb mif2dta} (if installed){p_end}
