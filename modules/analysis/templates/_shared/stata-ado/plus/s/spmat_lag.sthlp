{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat lag}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:spmat lag} {hline 2}}Create a spatial lag variable{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat lag} {dtype} {newvar} {it:objname} {varname}


{title:Description}

{pstd}{opt spmat lag} creates a new variable that is a product of the
spatial-weighting matrix contained in the {cmd:spmat} object
{it:objname} and the variable {it:varname}.  Algebraically, 
{cmd:spmat lag} computes {bf:W*y}, where {bf:W} is the spatial-weighting
matrix and {bf:y} is the variable.

{pstd}The default storage type is {cmd:float}.  Specify {cmd:double} for
the {it:type} to store the result in double precision.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use pollute}{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}

{pstd}Create the variable {cmd:pollution_w} containing a spatial lag of variable {cmd:pollution}{p_end}
{phang2}{cmd:. spmat lag double pollution_w cobj pollution}{p_end}


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
