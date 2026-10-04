{smcl}
{* *! version 1.0.11  15jan2019}{...}
{cmd:help lassopack}{right: ({browse "https://doi.org/10.1177/1536867X20909697":SJ20-1: st0594})}
{hline}

{title:Package}

{p2colset 5 16 18 2}{...}
{p2col:{hi:lassopack}}{p_end}
{p2colreset}{...}


{title:Overview}

{pstd}
{cmd:lassopack} is a suite of programs for penalized regression methods
suitable for the high-dimensional setting, where the number of p predictors
may be large and possibly greater than the number of observations.

{pstd}
The package consists of six main programs: 

{pmore}
{helpb lasso2} implements lasso, square-root lasso, elastic net, ridge
regression, adaptive lasso, and postestimation ordinary least squares.  The
lasso (least absolute shrinkage and selection operator; see Tibshirani
[1996]), the square-root lasso (Belloni, Chernozhukov, and Wang 2011), and the
adaptive lasso (Zou 2006) are regularization methods that use L1-norm
penalization to achieve sparse solutions: of the full set of p predictors,
typically most will have coefficients set to ridge regression (Hoerl and
Kennard 1970), which relies on L2-norm penalization; the elastic net (Zou and
Hastie 2005) uses a mix of L1 and L2 penalization.

{pmore}
{helpb cvlasso} supports K-fold cross-validation and rolling cross-validation
for cross-section, panel, and time-series data.

{pmore}
{helpb rlasso} implements theory-driven penalization for the lasso and
square-root lasso for cross-section and panel data.  {cmd:rlasso} uses the
theory-driven penalization methodology of Belloni et al. (2012, 2016), Belloni
and Chernozhukov (2013), and Belloni, Chernozhukov, and Wang (2014) for the
lasso and square-root lasso.

{pmore}
{helpb lassologit}, {helpb cvlassologit}, and {helpb rlassologit} are the
corresponding programs for logistic lasso regression.

{pstd}
For more information, please see our website
{browse "https://statalasso.github.io/"}, 
the help files, and our article below.


{marker references}{...}
{title:References}

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

{marker Hoerl1970}{...}
{phang}
Hoerl, A. E., and R. W. Kennard. 1970. Ridge regression: Applications to
nonorthogonal problems. {it:Technometrics} 12: 69-82.
{browse "https://doi.org/10.2307/1267352"}.

{marker Tib1996}{...}
{phang}
Tibshirani, R. 1996. Regression shrinkage and selection via the lasso.
{it:Journal of the Royal Statistical Society, Series B} 58: 267-288.
{browse "https://doi.org/10.1111/j.2517-6161.1996.tb02080.x"}.

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


{title:Citation of lassopack}

{pstd}
{opt lassopack} is not an official Stata package.  It is a free
contribution to the research community, like an article.  Please cite it
as such:

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


{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 20, number 1: {browse "https://doi.org/10.1177/1536867X20909697":st0594}{p_end}
