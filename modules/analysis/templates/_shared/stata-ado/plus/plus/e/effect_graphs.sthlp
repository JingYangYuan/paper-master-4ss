{smcl}
{* 17feb2017}{...}
{cmd:help effect_graphs}{right: ({browse "http://www.stata-journal.com/article.html?article=st0500":SJ17-4: st0500})}
{hline}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:effect_graphs} {hline 2}}Some graphs for visualizing effects to be run after {help synth_runner}{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 21 2}
{opt effect_graphs} [{cmd:,} {opt scaled} {opt trlinediff(real)} 
{opt tc_gname(string)} 
{opt effect_gname(string)} 
{opt treated_name(string)} 
{opt sc_name(string)} 
{opt tc_ytitle(string)}
{opt effect_ytitle(string)} 
{opt tc_options(string)} 
{opt effect_options(string)}]


{title:Description}

{p 4 4 2}
Creates two graphs after {cmd:synth_runner} estimation.  One plots the outcome
for the unit and its synthetic control, while the other plots the difference
between the two (which for posttreatment is the "effect").


{title:Options}

{p 4 8 2}
{cmd:scaled} can be specified to produce graphs from the {cmd:scaled} (rather
than unscaled) values if {cmd:synth_runner} was estimated using {cmd:scaled}.

{p 4 8 2}
{opt trlinediff(real)} specifies the offset of a vertical treatment line from
the first treatment period.  Likely options include values in the range from
(first treatment period-last posttreatment period) to 0, and the default value
is -1.

{p 4 8 2}
{opt tc_gname(string)} and {opt effect_gname(string)} are used to override the
default names of the graphs.  The defaults are {cmd:tc_gname(tc)} and
{cmd:effect_gname(effect)}.

{p 4 8 2}
{opt treated_name(string)} and {opt sc_name(string)} can be used to override
defaults for the legend on the treatment-control graph.  The defaults are
{cmd:treated_name("Treated")} and {cmd:sc_name("Synthetic Control")},
respectively.

{p 4 8 2}
{opt tc_ytitle(string)} and {opt effect_ytitle(string)} are used to override
the default {cmd:ytitle()} option to {cmd:graph twoway} for the
treatment-control and effect graphs, respectively.  The default for
{cmd:tc_ytitle()} is the label for {it:depvar} if that is supplied.  The
default is {cmd:effect_ytitle("Effect - ")} plus the {cmd:ytitle()} of the
treatment-control graph.

{p 4 8 2}
{opt tc_options(string)} and {opt effect_options(string)} allow additional
options to be specified for the treatment-control and effect graphs,
respectively.  These will be added as extra options to the {cmd:graph twoway}
call.  For example, {cmd:tc_options(title("My graph"))} will specify a title
for the treatment-control graph.


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

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 4: {browse "http://www.stata-journal.com/article.html?article=st0500":st0500}{p_end}

{p 7 14 2}
Help:  {helpb synth_runner}, {helpb pval_graphs}, {helpb single_treatment_graphs} (if installed){p_end}
