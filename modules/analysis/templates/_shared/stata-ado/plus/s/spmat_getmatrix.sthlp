{smcl}
{* *! version 1.0.2  24jan2012}{...}
{cmd:help spmat getmatrix}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:spmat getmatrix} {hline 2}}Copy a matrix contained in an
spmat object to a Mata matrix{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:getmat:rix} {it:objname} [{it:matname}] [{cmd:,} {it:options}]

{synoptset 19}{...}
{synopthdr}
{synoptline}
{synopt:{opt id(vecname)}}name of a Mata vector to contain IDs{p_end}
{synopt:{opt eig(vecname)}}name of a Mata vector to contain eigenvalues{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}{opt spmat getmatrix} copies the spatial-weighting matrix {bf:W}
contained in the {cmd:spmat} object {it:objname} to the Mata matrix
{it:matname}.  The place identifiers and the eigenvalues of {cmd:W} can
be optionally saved to Mata vectors.


{title:Options}

{phang}{opt id(vecname)} specifies the name of a Mata vector to
contain IDs.

{phang}{opt eig(vecname)} specifies the name of a Mata vector to contain
eigenvalues.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}

{pstd}Copy the contiguity matrix contained in the {cmd:spmat} object
{cmd:cobj} to the Mata matrix {cmd:mymat}{p_end}
{phang2}{cmd:. spmat getmatrix cobj mymat}{p_end}

{pstd}Copy the eigenvalues contained in the {cmd:spmat} object
{cmd:cobj} to the Mata vector {cmd:myeig}{p_end}
{phang2}{cmd:. spmat getmatrix cobj, eig(myeig)}{p_end}


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
