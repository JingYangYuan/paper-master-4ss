{smcl}
{* *! version 1.0.0  15mar2010}{...}
{cmd:help spmat summarize}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:spmat summarize} {hline 2}}Summarize the spatial-weighting
matrix W contained in an spmat object{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:su:mmarize} {it:objname} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt li:nks}}report links{p_end}
{synopt:{opt det:ail}}display detailed summary of links{p_end}
{p2coldent:* {opt band:ed}}display banded information{p_end}
{p2coldent:* {opt btr:uncate(b B)}}bin truncation{p_end}
{p2coldent:* {opt dtr:uncate(l u)}}diagonal truncation{p_end}
{p2coldent:* {opt vtr:uncate(#)}}value truncation{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* Only one of {cmd:banded}, {cmd:btruncate()}, {cmd:dtruncate()}, or 
{cmd:vtruncate()} may be specified.{p_end}


{title:Description}

{pstd}{opt spmat summarize} summarizes the spatial-weighting
matrix {bf:W} contained in the {cmd:spmat} object {it:objname}.
If the object contains an n x n matrix, the user can optionally
request summary statistics that show whether the matrix can be
stored in a banded form.


{title:Options}

{phang}{opt links} is useful when {it:objname} contains a contiguity or
a normalized-contiguity matrix.  Rather than the default summary of the
values in the spatial-weighting matrix, {cmd:links} causes 
{cmd:spmat summarize} to summarize the number of neighbors.

{phang}{opt detail} requests a tabulation of links for a contiguity or a
normalized-contiguity matrix.  The values of the identifying variable
with the minimum and maximum number of links will be displayed.

{phang}{opt banded} reports the bands for the matrix that already has a
(possibly) banded structure but is stored in an n x n form.

{phang}The truncation options are useful when you want to see summary
statistics calculated on a spatial-weighting matrix after some elements
have been truncated to 0.  {cmd:spmat summarize} with a truncation
option will report the lower and upper band based on a matrix to which
the specified truncation criterion has been applied.  (Note: No data are
actually changed by selecting these options.  These options only specify
that {cmd:spmat summarize} calculate results as if the requested
truncation criterion has been applied.)

{pmore}{opt btruncate(b B)} partitions the values of {bf:W} into {it:B}
bins and truncates to 0 those entries that fall into bin {it:b} or
below.

{pmore}{opt dtruncate(l u)} truncates to 0 the values of {bf:W} that
fall {it:l} diagonals below and {it:u} diagonals above the main
diagonal.  Neither value can be greater than {cmd:floor((cols(W)-1)/4)}.

{pmore}{opt vtruncate(v)} truncates to 0 the values of {bf:W} that
are less than or equal to {it:v}.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}

{pstd}Summarize the contiguity matrix contained in the {cmd:spmat}
object {cmd:cobj}{p_end}
{phang2}{cmd:. spmat summarize cobj, links}{p_end}


{title:Saved results}{marker saved_results}

{pstd}{cmd:spmat summarize} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(b)}}number of rows in {bf:W}{p_end}
{synopt:{cmd:r(n)}}number of columns in {bf:W}{p_end}
{synopt:{cmd:r(lband)}}lower band, if {bf:W} is banded{p_end}
{synopt:{cmd:r(uband)}}upper band, if {bf:W} is banded{p_end}
{synopt:{cmd:r(min)}}minimum of {bf:W}{p_end}
{synopt:{cmd:r(min0)}}minimum element > 0 in {bf:W}{p_end}
{synopt:{cmd:r(mean)}}mean of {bf:W}{p_end}
{synopt:{cmd:r(max)}}maximum of {bf:W}{p_end}
{synopt:{cmd:r(lmin)}}minimum number of neighbors in {bf:W}{p_end}
{synopt:{cmd:r(lmean)}}mean number of neighbors in {bf:W}{p_end}
{synopt:{cmd:r(lmax)}}maximum number of neighbors in {bf:W}{p_end}
{synopt:{cmd:r(ltotal)}}total number of neighbors in {bf:W}{p_end}
{synopt:{cmd:r(eig)}}{cmd:1} if object contains eigenvalues, {cmd:0} otherwise{p_end}
{synopt:{cmd:r(canband)}}{cmd:1} if object can be banded based on {cmd:r(lband)}
and {cmd:r(uband)}, {cmd:0} otherwise{p_end}


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
