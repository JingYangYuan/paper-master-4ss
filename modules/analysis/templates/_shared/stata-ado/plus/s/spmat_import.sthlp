{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat import}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col:{cmd:spmat import} {hline 2}}Create an spmat object from a
text file{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:im:port} {it:objname} {cmd:using} {it:{help filename}}
[{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt noid}}{it:filename} does not contain unique IDs{p_end}
{synopt:{opt nlist}}{it:filename} contains a neighbor list{p_end}
{synopt:{opt geoda}}{it:filename} was created by the GeoDa (TM) software{p_end}
{synopt:{opt idist:ance}}convert distance data to inverse distances{p_end}
{synopt:{opt norm:alize(norm)}}specify the normalization method{p_end}
{synopt:{opt replace}}replace {it:objname}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}{opt spmat import} creates the {cmd:spmat} object {it:objname}
from the text file {it:filename}.

{pstd}By default, {cmd:spmat import} imports data from a space-delimited
text file in which the first line contains the number of columns of the
spatial-weighting matrix and, if applicable, the lower and upper band,
followed by the matrix stored row by row with unique place identifiers
recorded in the first column.


{title:Options}

{phang}{cmd:noid} specifies that the first column of numbers in
{it:filename} does not contain unique place identifiers and that
{cmd:spmat import} should create and use the identifiers 1, ..., n.

{phang}{cmd:nlist} specifies that the text file be in the neighbor-list
format.  The first line of the file must contain the total number of
places and, if the matrix is banded, the lower and upper band.  Each
remaining line lists a place ID followed by its neighbor's place ID, if
any.

{phang} {opt geoda} specifies that {it:filename} be in the {cmd:.gwt} or
{cmd:.gal} format created by the GeoDa (TM) software.

{phang}{opt idistance} tells {cmd:spmat} that the data should be
converted to inverse distances.  The value d will be converted to 1/d
with the exception of the main diagonal, which will contain 0 entries.

{phang}{opt normalize(norm)} specifies one of the three available
normalization techniques: {cmd:row}, {cmdab:min:max}, and
{cmdab:spe:ctral}.  In a row-normalized matrix, each element in row i is
divided by the sum of row i's elements.  In a minmax-normalized matrix,
each element is divided by the minimum of the largest row sum and column
sum of the matrix.  In a spectral-normalized matrix, each element is
divided by the modulus of the largest eigenvalue of the matrix.

{phang}{opt replace} permits {cmd:spmat import} to overwrite an existing
{cmd:spmat} object.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. set memory 50m}{p_end}
{phang2}{cmd:. use pollute}{p_end}
{phang2}{cmd:. spmat contiguity cobj using pollutexy, id(id) normalize(minmax)}{p_end}
{phang2}{cmd:. spmat export cobj using cobj.txt}{p_end}
{phang2}{cmd:. spmat drop cobj}{p_end}

{pstd}Create the {cmd:spmat} object {cmd:cobj} from the file {cmd:cobj.txt}{p_end}
{phang2}{cmd:. spmat import cobj using cobj.txt}{p_end}


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
