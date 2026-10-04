{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat dta}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:spmat dta} {hline 2}}Create an spmat object from a
rectangular Stata dataset{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat dta} {it:objname} {varlist} {ifin} [{cmd:,} {it:options}]


{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opth id(varname)}}variable containing unique IDs{p_end}
{synopt:{opt idist:ance}}convert distance data to inverse distances{p_end}
{synopt:{opt norm:alize(norm)}}normalization method{p_end}
{synopt:{opt replace}}replace {it:objname}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}{opt spmat dta} creates the {cmd:spmat} object {it:objname} from a
Stata dataset containing the entries of an n x n spatial-weighting
matrix.  The number of variables in {it:varlist} must equal the number
of observations in the dataset.


{title:Options}

{phang}{opth id(varname)} specifies that the unique place identifiers be
contained in {it:varname}.  The default is to create an identifying
vector containing 1, ..., n.

{phang}{opt idistance} tells {cmd:spmat} that the data are to be
converted to inverse distances.  The value d will be converted to 1/d
with the exception of the main diagonal, which will contain 0 entries.

{phang}{opt normalize(norm)} specifies one of the three available
normalization techniques: {cmd:row}, {cmdab:min:max}, and
{cmdab:spe:ctral}.  In a row-normalized matrix, each element in row i is
divided by the sum of row i's elements.  In a minmax-normalized matrix,
each element is divided by the minimum of the largest row sum and column
sum of the matrix.  In a spectral-normalized matrix, each element is
divided by the modulus of the largest eigenvalue of the matrix.

{phang}{opt replace} permits {cmd:spmat dta} to overwrite an existing
{cmd:spmat} object.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}
{phang2}{cmd:. spmat export cobj using cobj.txt}{p_end}
{phang2}{cmd:. spmat drop cobj}{p_end}
{phang2}{cmd:. insheet using cobj.txt, delimiter(" ") clear}{p_end}
{phang2}{cmd:. rename v1 id}{p_end}

{pstd}Create the {cmd:spmat} object {cmd:cobj} containing a contiguity matrix
stored in the variables {cmd:v2-v542}{p_end}
{phang2}{cmd:. spmat dta cobj v*, id(id) replace}{p_end}


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
