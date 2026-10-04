{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat export}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col:{cmd:spmat export} {hline 2}}Save the spatial-weighting matrix W
contained in an spmat object to disk as a space-delimited text file{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:ex:port} {it:objname}
{cmd:using} {it:{help filename}} [{cmd:,} {it:options}]

{synoptset 15}{...}
{synopthdr}
{synoptline}
{synopt:{opt noid}}do not save place IDs{p_end}
{synopt:{opt nlist}}save the matrix as a neighbor list{p_end}
{synopt:{opt replace}}replace {it:filename}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}{opt spmat export} saves the spatial-weighting matrix {bf:W}
contained in the {cmd:spmat} object {it:objname} to disk as a
space-delimited text file.  The first line of the file contains the
number of columns of {bf:W} and, if applicable, the lower and upper
band.  The spatial-weighting matrix is then written row by row, with the
place identifiers recorded in the first column.


{title:Options}

{phang}{cmd:noid} causes {cmd:spmat export} not to save unique place
identifiers, only matrix entries.

{phang}{opt nlist} specifies that the matrix be written in the
neighbor-list format.  The first line of the file will contain the total
number of places and, if the matrix is banded, the lower and upper band.
Each remaining line will list a place ID followed by its neighbor's
place ID, if any.

{phang}{opt replace} permits {cmd:spmat export} to overwrite
{it:filename}.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}

{pstd}Save the {cmd:spmat} object {cmd:cobj} to disk{p_end}
{phang2}{cmd:. spmat export cobj using cobj.txt}{p_end}


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
