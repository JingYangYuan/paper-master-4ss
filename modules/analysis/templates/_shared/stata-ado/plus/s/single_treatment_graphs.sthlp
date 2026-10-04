{smcl}
{* 17feb2017}{...}
{cmd:help single_treatment_graphs}{right: ({browse "http://www.stata-journal.com/article.html?article=st0500":SJ17-4: st0500})}
{hline}

{title:Title}

{p2colset 5 32 34 2}{...}
{p2col :{hi:single_treatment_graphs} {hline 2}}Some graphs for single treatment period estimations to be run after {help synth_runner}{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 31 2}
{opt single_treatment_graphs} 
[{cmd:,} {opt scaled} {opt raw_gname(string)} 
{opt effects_gname(string)} 
{opt trlinediff(real)} 
{opt do_color(string)} 
{opt effects_ymax(string)}
{opt effects_ymin(string)} 
{opt effects_ylabels(string)} 
{opt treated_name(string)} 
{opt donors_name(string)} 
{opt raw_ytitle(string)}
{opt effects_ytitle(string)}
{opt raw_options(string)} 
{opt effects_options(string)}]


{title:Description}

{p 4 4 2}
Creates two graphs when there is a single unit that has been treated.  The
first graphs the outcome path of all units, while the second graphs the
prediction differences for all units.


{title:Options}

{p 4 8 2}
{cmd:scaled} can be specified to produce graphs from the {cmd:scaled} (rather
than unscaled) values if {cmd:synth_runner} was estimated using {cmd:scaled}.

{p 4 8 2}
{opt raw_gname(string)} and {opt effects_gname(string)} can be used to specify
names for the raw and effects graphs, respectively.  The defaults are
{cmd:raw_gname(raw)} and {cmd:effects_gname(effects)}.

{p 4 8 2}
{opt trlinediff(real)} specifies the offset of a vertical treatment line from
the first treatment period.  Likely options include values in the range from
(first treatment period-last posttreatment period) to 0, and the default value
is {cmd:trlinediff(-1)}.

{p 4 8 2}
{opt do_color(string)} specifies a color for the donor lines.  The default is
{cmd:do_color(bg)} (theme's background color).

{p 4 8 2}
{opt effects_ymax(string)}, {opt effects_ymin(string)}, and 
{opt effects_ylabels(string)} allow customization of the y-axis display for
the effects graph.  {cmd:effects_ymax()} and {cmd:effects_ymin()} optionally
specify the maximum range to show for the y axis.  {cmd:effects_ylabels()}
specifies the labels to be displayed.

{p 4 8 2}
{opt treated_name(string)} and {opt donors_name(string)} can be used to
override defaults for the legend on the graphs.  The defaults are
{cmd:treated_name(Treated)} and {cmd:donors_name(Donors)}, respectively.

{p 4 8 2}
{opt raw_ytitle(string)} and {opt effects_ytitle(string)} are used to override
the default {cmd:ytitle()} option to {cmd:graph twoway} for the raw and
effects graphs, respectively.  The default for {cmd:raw_ytitle()} is the label
for {it:depvar} if that is supplied.  The default is
{cmd:effect_ytitle("Effect - ")} plus the {cmd:ytitle()} of the raw graph.

{p 4 8 2}
{opt raw_options(string)} and {opt effects_options(string)} allow additional
options to be specified for the raw and effects graphs, respectively.  These
will be added as extra options to the {cmd:graph twoway} call.  For example,
{cmd:raw_options(title("My graph"))} will specify a title for the raw graph.


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
Help:  {helpb effect_graphs},
{helpb pval_graphs},
{helpb synth_runner}
(if installed){p_end}
