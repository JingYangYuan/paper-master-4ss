{smcl}
{* 17feb2017}{...}
{cmd:help pval_graphs}{right: ({browse "http://www.stata-journal.com/article.html?article=st0500":SJ17-3: st0500})}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:pval_graphs} {hline 2}}Some graphs for inference to be run after {help synth_runner}{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 19 2}
{opt pval_graphs} 
[{cmd:,} 
{opt pvals_gname(string)} 
{opt pvals_std_gname(string)} 
{opt xtitle(string)} 
{opt ytitle(string)} 
{opt pvals_options(string)} 
{opt pvals_std_options(string)}]


{title:Description}

{p 4 4 2}
Creates plots of the p-values per period for posttreatment periods for both
raw and standardized effects.


{title:Options}

{p 4 8 2}
{opt pvals_gname(string)} and {opt pvals_std_gname(string)} can be used to
specify names for the plain and standardized graphs, respectively.  The
defaults are {cmd:pvals_gname(pvals)} and {cmd:pvals_std_gname(pvals_std)}.

{p 4 8 2}
{opt xtitle(string)} is used to override the default {cmd:xtitle()} option to
{cmd:graph twoway}.  The default is
{cmd:xtitle("Number of periods after event (Leads)")}.

{p 4 8 2}
{opt ytitle(string)} is used to override the default {cmd:ytitle()} option to
{cmd:graph twoway}.  The default is 
{cmd:ytitle("Probability that this would happen by chance")}.

{p 4 8 2}
{opt pvals_options(string)} and {opt pvals_std_options(string)} allow
additional options to be specified for the plain and standardized graphs,
respectively.  These will be added as extra options to the {cmd:graph twoway}
call.  For example, {cmd:pvals_options(title("My graph"))} will specify a
title for the plain graph.


{title:Authors}

{pstd}
Brian Quistorff{break}
Microsoft AI and Research{break}
Redmond, WA{break}
Brian.Quistorff@microsoft.com{break}

{pstd} 
Sebastian Galiani{break}
University of Maryland{break}
College Park, MD{break}
galiani@econ.umd.edu


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 3: {browse "http://www.stata-journal.com/article.html?article=st0500":st0500}{p_end}

{p 7 14 2}
Help:  {helpb effect_graphs}, {helpb synth_runner}, {helpb single_treatment_graphs} (if installed){p_end}
