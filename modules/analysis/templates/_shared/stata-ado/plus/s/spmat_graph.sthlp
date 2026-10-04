{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat graph}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:spmat graph} {hline 2}}Draw an intensity plot of the
spatial-weighting matrix W contained in an spmat object{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:gr:aph} {it:objname} [{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{p2col:{cmdab:bl:ocks(}[{cmd:(}{it:stat}{cmd:)}] {it:p}{cmd:)}}plot matrix in
    {it:p} x {it:p} blocks{p_end}
{p2col:{it:twoway_options}}any options other than {cmd:by()}; documented
	in {it:{manhelpi twoway_options G-3}}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{title:Description}

{pstd}{opt spmat graph} draws an intensity plot of the spatial-weighting
matrix {bf:W} contained in the {cmd:spmat} object {it:objname}.  Zero
elements are plotted in white; the remaining elements are partitioned
into 16 bins of equal length and assigned gray-scale colors
{cmd:gs0}-{cmd:gs15}; see {manhelpi colorstyle G}.


{title:Options}

{phang}{cmd:blocks(}[{cmd:(}{it:stat}{cmd:)}] {it:p}{cmd:)} specifies
that the matrix be divided into blocks of size {it:p} and that block
maximums be plotted.  This option is useful when the matrix is large.
To plot a statistic other than the default maximum, you can specify the
optional {it:stat} argument.  For example, to plot block medians, type
{cmd:blocks((p50)} {it:p}{cmd:)}.  The supported statistics include
those returned by {cmd:summarize, detail}; see {manhelp summarize R} for
a complete list.

{phang}{it:twoway_options} are any options other than {cmd:by()}; they
are documented in {it:{manhelpi twoway_options G-3}}.  These include
options for titling the graph (see {manhelpi title_options G-3}) and for
saving the graph to disk (see {manhelpi saving_option G-3}).


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}

{pstd}Plot the contiguity matrix contained in the {cmd:spmat} object
{cmd:cobj} in 5 x 5 blocks{p_end}
{phang2}{cmd:. spmat graph cobj, blocks(5)}


{title:Authors}

{phang}David Drukker{p_end}
{phang}StataCorp{p_end}
{phang}College Station, TX{p_end}
{phang}{browse "mailto:ddrukker@stata.com":ddrukker@stata.com}

{phang}Hua Peng{p_end}
{phang}StataCorp{p_end}
{phang}College Station, TX{p_end}
{phang}{browse "mailto:hpeng@stata.com":hpeng@stata.com}

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

{p 7 14 2}Help:  {helpb spmat}, {helpb spreg}, {helpb spivreg}, 
{helpb spmap}, {helpb shp2dta}, {helpb mif2dta} (if installed){p_end}
