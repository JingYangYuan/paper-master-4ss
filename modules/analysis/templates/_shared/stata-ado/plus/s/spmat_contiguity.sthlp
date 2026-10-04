{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat contiguity}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 25 27 2}{...}
{p2col:{cmd:spmat contiguity} {hline 2}}Create an spmat object containing a
contiguity matrix W{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:con:tiguity} {it:objname}
{ifin} {cmd:using} {it:coordinates_file}{cmd:,} {opth id(varname)} [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth id(varname)}}ID variable{p_end}
{synopt:{opt norm:alize(norm)}}normalization method{p_end}
{synopt:{opt rook}}rook contiguity{p_end}
{synopt:{opt band:ed}}banded storage{p_end}
{synopt:{opt replace}}replace {it:objname}{p_end}
{synopt:{cmd:saving(}{it:{help filename}}[{cmd:, replace)}}save neighbor info to a text file{p_end}
{synopt:{opt nomat:rix}}do not create {it:objname}{p_end}
{synopt:{opt tol:erance(#)}}numerical tolerance{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {cmd:id()} is required.{p_end}


{title:Description}

{pstd}{opt spmat contiguity} puts a contiguity matrix {bf:W} into the
new {cmd:spmat} object {it:objname}.  Element ij of {bf:W} is 1 if
points i and j are neighbors and is 0 otherwise.

{pstd}{opt spmat contiguity} uses both the dataset in memory and a
dataset containing the coordinates of polygons.  The coordinates dataset
must be in the format created by {helpb shp2dta} or {helpb mif2dta}.


{title:Options}

{phang}{opth id(varname)} specifies a numeric variable that
contains a unique identifier for each observation. ({cmd:shp2dta} and
{cmd:mif2dta} name this ID variable {cmd:_ID}.) {cmd:id()} is required.

{phang}{opt normalize(norm)} specifies one of the three available
normalization techniques: {cmd:row}, {cmdab:min:max}, and
{cmdab:spe:ctral}.  In a row-normalized matrix, each element in row i is
divided by the sum of row i's elements.  In a minmax-normalized matrix,
each element is divided by the minimum of the largest row sum and column
sum of the matrix.  In a spectral-normalized matrix, each element is
divided by the modulus of the largest eigenvalue of the matrix.

{phang}{opt rook} specifies that only units that share a common border
be considered neighbors (edge or rook contiguity).  The default is queen
contiguity, which treats units that share a common border or a single
common point as neighbors.  Computing rook-contiguity matrices is more
computationally intensive than the default queen-contiguity computation.

{phang}{opt banded} requests that the new matrix be stored in a banded
form.  The banded matrix is constructed without creating the underlying
n x n representation; see {it:Remarks} in 
{helpb spmat_tobanded##banded_remarks:spmat tobanded} for details.

{phang}{opt replace} permits {cmd:spmat contiguity} to overwrite an
existing {cmd:spmat} object.

{phang}{cmd:saving(}{it:{help filename}} [{cmd:, replace}]{cmd:)} saves the
neighbor list to a space-delimited text file.  The first line of the
file contains the number of units and, if applicable, bands; each
remaining line lists a unit identification code followed by the
identification codes of units that share a common border, if any.  You
can read the file back into an {cmd:spmat} object with 
{cmd:spmat import} ..., {cmd:nlist}.  {cmd:replace} allows {it:filename}
to be overwritten if it already exists.

{phang}{cmd:nomatrix} specifies that the {bf:spmat} object {it:objname}
and spatial-weighting matrix {bf:W} not be created.  In conjunction with
{bf:saving()}, this option allows for creating a text file containing a
neighbor list without allocating space for the underlying contiguity
matrix.

{phang}{opt tolerance(#)} specifies the numerical tolerance used in
deciding whether two units are edge neighbors.  The default is
{cmd:tolerance(1e-7)}.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. set memory 50m}{p_end}
{phang2}{cmd:. use pollute}{p_end}

{pstd}Create the {cmd:spmat} object {cmd:cobj} containing a minmax-normalized contiguity matrix{p_end}
{phang2}{cmd:. spmat contiguity cobj using pollutexy, id(id) normalize(minmax)}


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
