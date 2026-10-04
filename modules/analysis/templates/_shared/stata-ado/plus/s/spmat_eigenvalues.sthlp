{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat eigenvalues}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 26 28 2}{...}
{p2col:{cmd:spmat eigenvalues} {hline 2}}Add eigenvalues of the
spatial-weighting matrix W to an spmat object{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:eig:envalues} {it:objname} [{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt eig:envalues(vecname)}}Mata vector containing eigenvalues{p_end}
{synopt:{opt replace}}replace existing eigenvalues{p_end}
{synoptline}
{p2colreset}{...}

    
{title:Description}

{pstd}{opt spmat eigenvalues} calculates the eigenvalues of the
spatial-weighting matrix {bf:W} contained in the {cmd:spmat} object
{it:objname} and stores them in {it:vecname}.  Having precomputed
eigenvalues in {it:objname} will speed up the estimation command 
{helpb spreg:spreg ml}.


{title:Options}

{phang}{cmd:eigenvalues(}{it:vecname}{cmd:)} stores the user-defined
vector of eigenvalues in the {cmd:spmat} object {it:objname}.
{it:vecname} must be a Mata row vector of length n, where n is the
dimension of the spatial-weighting matrix in the {cmd:spmat} object
{it:objname}.

{phang}{cmd:replace} permits {cmd:spmat eigenvalues} to replace existing
eigenvalues in {it:objname}.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}{p_end}

{pstd}Add eigenvalues to the {cmd:spmat} object {cmd:cobj}{p_end}
{phang2}{cmd:. spmat eigenvalues cobj}{p_end}


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
