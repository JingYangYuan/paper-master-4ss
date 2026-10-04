{smcl}
{* *! version 1.0.1  1aug2011}{...}
{cmd:help grmean}{right: ({browse "http://www.stata-journal.com/article.html?article=up0057":SJ17-4: st0245_1})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:grmean} {hline 2}}Graph routine for calculating and plotting (weighted) means{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:grmean} {it:{help varname:yvar_0}} [{it:{help varname:yvars}}] 
	 {it:{help varname:xvar}} {ifin}
 [{cmd:,} {it:options}]

{synoptset 25}{...}
{synopthdr}
{synoptline}
{synopt :{opth st:andard(varname:var)}}use {it:var} as weights for calculating the means{p_end}
{synopt :{opt nom:ean}}suppress calculation and plotting of means{p_end}
{p2col:{cmd:over(}{it:varname} [{cmd:,} {cmd:total}]{cmd:)}}calculate and plot means separately for over-groups{p_end}
{p2col:{cmd:by(}{it:varlist} [{cmd:,} {it:byopts}]{cmd:)}}repeat plot for by-groups{p_end}
{synopt :{opth "addplot(addplot_option:plot)"}}add other plots to generated graph{p_end}
{synopt :{it:twoway_options}}any of the options documented in 
{manhelp twoway_options G-3:{it:twoway_options}}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{it:yvar} and {it:xvar} may contain time-series operators; see 
{help tsvarlist}.


{title:Description}

{pstd}
{cmd:grmean} directly standardizes means of {it:yvars} for unique values
of {it:xvar varname varlist}, and displays the graph using {cmd:scatter}
for the first {it:yvar} and {cmd:line} for any other {it:yvars}.
Different values of {it:overvar} are plotted with different 
{it:{help markerstyle}s} and corresponding {it:{help linestyle}}s.

{pstd}
Note that the standardization is a weighted mean of the available values
-- the weights are normalized for each value of 
{it:xvar overvar byvars}.  Thus, for instance, if all values of age are
included, the means will be age-standardized, whereas if there is only
one value of age and the weights are only dependent on age, then the
standardized means will be crude means.


{title:Options}

{phang}
{opt standard(var)} uses {it:var} as weights for calculating the means.

{phang}
{opt nomean} suppresses the calculation of directly standardized means.
Instead, multiple {it:yvar} values are plotted exactly.

{phang}
{cmd:over(}{it:varname} [{cmd:, total}]{cmd:)} calculates and plots
means separately for each value of {it:varname}.  A different
{it:markerstyle} is used for each value of {it:varname} for the first
{it:yvar}, and the same {it:linestyle} is used for the same value when
applied to subsequent {it:yvars}.  {cmd:total} adds overall directly
standardized means.

{phang}
{cmd:by(}{it:varlist} [{cmd:,} {it:byopts}]{cmd:)} repeats the plot for
by-groups.

{phang}
{opt addplot(plot)} provides a way to add other plots to the generated
graph; see {manhelpi addplot_option G-3}.

{phang}
{it:twoway_options} are any of the options documented in 
{manhelpi twoway_options G-3}.  These include options for titling the
graph (see {manhelpi title_options G-3}) and options for saving the graph
to disk (see {manhelpi saving_option G-3}).


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}

{pstd}Perform locally weighted regression of {cmd:mpg} on
{cmd:weight}, saving the resulting fit in "smooth"{p_end}
{phang2}{cmd:. lowess mpg weight, by(foreign) generate(smooth) nograph}

{pstd}Use {cmd:grmean} to plot the results{p_end}
{phang2}{cmd:. grmean mpg smooth weight, over(foreign)}

{pstd}Plot age trends in age-standardized rates together with projections, showing different countries
separately for males and females {p_end}
{phang2}{cmd:. grmean rates project year, standard(w_standard) over(country) by(sex)}{p_end}


{title:Author}

{pstd}Peter D. Sasieni{p_end}
{pstd}Centre for Cancer Prevention{p_end}
{pstd}Wolfson Institute of Preventive Medicine{p_end}
{pstd}Queen Mary, University of London{p_end}
{pstd}London, UK {p_end}
{pstd}p.sasieni@qmul.ac.uk{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 4: {browse "http://www.stata-journal.com/article.html?article=up0057":st0245_1},{break}
                    {it:Stata Journal}, volume 12, number 1: {browse "http://www.stata-journal.com/article.html?article=st0245":st0245}{p_end}
