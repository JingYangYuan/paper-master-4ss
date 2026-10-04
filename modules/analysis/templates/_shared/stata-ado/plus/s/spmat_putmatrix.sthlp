{smcl}
{* *! version 1.0.2  24jan2012}{...}
{cmd:help spmat putmatrix}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 24 27 2}{...}
{p2col:{cmd:spmat putmatrix} {hline 2}}Put a Mata matrix into an spmat object{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:putmat:rix} {it:objname} [{it:matname}]
[{cmd:,} {it:options}]

{synoptset 23}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:id(}{it:varname}|{it:vecname}{cmd:)}}variable or Mata vector containing unique IDs{p_end}
{synopt:{opt eig(vecname)}}Mata vector containing eigenvalues{p_end}
{synopt:{opt idist:ance}}convert distance data to inverse distances{p_end}
{synopt:{opt b:ands(l u)}}lower and upper band of {it:matname}{p_end}
{synopt:{opt norm:alize(norm)}}specify the normalization method{p_end}
{synopt:{opt replace}}replace {it:objname}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}{opt spmat putmatrix} puts Mata matrices into an existing
{cmd:spmat} object {it:objname} or into a new {cmd:spmat} object if
the specified object does not exist.  The optional unique place
identifiers can be provided in the {cmd:id()} option in a Mata vector
{it:vecname} or in a Stata variable {it:varname}.  If {it:objname} does
not exist and you do not specify place identifiers, {cmd:spmat}
{cmd:putmatrix} will create the IDs 1, ..., n.


{title:Options}

{phang}{cmd:id(}{it:varname}|{it:vecname}{cmd:)} specifies a Mata vector
{it:vecname} or a Stata variable {it:varname} that contains unique place
identifiers.

{phang}{opt eig(vecname)} specifies a Mata vector {it:vecname} that
contains the eigenvalues of the matrix.

{phang}{opt idistance} specifies that the Mata matrix contains raw
distances and that the raw distances be converted to inverse
distances.  In other words, {cmd:idistance} specifies that the (i,j)th
element in the Mata matrix be d_ij and that the (i,j)th element in the
spatial-weighting matrix be 1/d_ij, where d_ij is the distance between
units i and j.

{phang}{opt b:ands(l u)} specifies that the Mata matrix {it:matname} be
banded with {it:l} lower and {it:u} upper diagonals.  Neither value can
be greater than {cmd:floor((cols(}{it:matname}{cmd:)-1)/4)}.

{phang}{opt normalize(norm)} specifies one of the three available
normalization techniques: {cmd:row}, {cmdab:min:max}, and
{cmdab:spe:ctral}.  In a row-normalized matrix, each element in row i is
divided by the sum of row i's elements.  In a minmax-normalized matrix,
each element is divided by the minimum of the largest row sum and column
sum of the matrix.  In a spectral-normalized matrix, each element is
divided by the modulus of the largest eigenvalue of the matrix.

{phang}{opt replace} permits {cmd:spmat putmatrix} to overwrite an existing
{cmd:spmat} object.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}
{phang2}{cmd:. spmat getmatrix cobj mymat, id(myid)}{p_end}
{phang2}{cmd:. spmat drop cobj}{p_end}

{pstd}Create the {cmd:spmat} object {cmd:cobj} from the Mata matrix
{cmd:mymat} and the Mata vector {cmd:myid}{p_end}
{phang2}{cmd:. spmat putmatrix cobj mymat, id(myid)}{p_end}


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
