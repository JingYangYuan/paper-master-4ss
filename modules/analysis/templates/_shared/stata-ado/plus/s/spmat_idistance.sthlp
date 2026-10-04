{smcl}
{* *! version 1.0.0  15mar2010}{...}
{cmd:help spmat idistance}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:spmat idistance} {hline 2}}Create an spmat object containing
an inverse-distance spatial-weighting matrix W{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:idist:ance} {it:objname} {it:cvarlist}
{ifin}{cmd:,} {opth id(varname)} [{it:options}]

{synoptset 33 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth id(varname)}}ID variable{p_end}
{synopt:{opt df:unction}{cmd:(}{it:function}[{cmd:, miles}]{cmd:)}}specify the distance function{p_end}
{synopt:{opt norm:alize(norm)}}specify the normalization method{p_end}
{synopt:{it:truncmethod}}specify the truncation method{p_end}
{synopt:{opt band:ed}}store the matrix in banded format{p_end}
{synopt:{opt replace}}replace {it:objname}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {cmd:id()} is required.{p_end}
{p 4 6 2}
{it:truncmethod} is one of {cmdab:btr:uncate()}, {cmdab:dtr:uncate()}, or {cmdab:vtr:uncate()}.{p_end}


{title:Description}

{pstd}{opt spmat idistance} puts an inverse-distance spatial-weighting
matrix {cmd:W} into the new {cmd:spmat} object {it:objname}.  Element ij
of {cmd:W} contains the inverse of the distance between points i and j
calculated from the coordinate variables specified in {it:cvarlist}.
Longitude must be specified first if coordinate variables represent
longitude and latitude.


{title:Options}

{phang}{opth id(varname)} specifies a numeric variable that
contains a unique identifier for each observation.  {cmd:id()} is
required.

{phang}{cmd:dfunction(}{it:function}[{cmd:, miles}]{cmd:)} specifies the
distance function.  {it:function} may be one of {opt euc:lidean}
(default), {opt dhav:ersine}, {opt rhav:ersine}, or the Minkowski
distance of order {it:p}, where {it:p} is an integer greater than or
equal to 1.

{pmore}When the default {cmd:dfunction(euclidean)} is specified, a
Euclidean distance measure is applied to the coordinate variable list
{it:cvarlist}.

{pmore}When {cmd:dfunction(rhaversine)} or {cmd:dfunction(dhaversine)}
is specified, the haversine distance measure is applied to the two
coordinate variables {it:cvarlist}.  (The first coordinate variable must
specify longitude, and the second coordinate variable must specify
latitude.)  The coordinates must be in radians when {cmd:rhaversine} is
specified.  The coordinates must be in degrees when {cmd:dhaversine} is
specified.  The haversine distance measure is calculated in kilometers
by default.  Specify {cmd:dfunction(rhaversine, miles)} or
{cmd:dfunction(dhaversine, miles)} if you want the distance returned in
miles.

{pmore}When {opt dfunction(p)} ({it:p} is an integer) is specified, a
Minkowski distance measure of order {it:p} is applied to the coordinate
variable list {it:cvarlist}.

{phang}{opt normalize(norm)} specifies one of the three available
normalization techniques: {cmd:row}, {cmdab:min:max}, and
{cmdab:spe:ctral}.  In a row-normalized matrix, each element in row i is
divided by the sum of row i's elements.  In a minmax-normalized matrix,
each element is divided by the minimum of the largest row sum and column
sum of the matrix.  In a spectral-normalized matrix, each element is
divided by the modulus of the largest eigenvalue of the matrix.

{phang}{it:truncmethod} options specify one of the three available
truncation criteria.  The values of the spatial-weighting matrix {cmd:W}
that meet the truncation criterion will be changed to 0.  Only apply
truncation methods when supported by theory.

{pmore}{opt btruncate(b B)} partitions the value of {cmd:W} into {it:B}
equal-length bins and truncates to 0 entries that fall into bin {it:b}
or below.

{pmore}{opt dtruncate(l u)} truncates to 0 the values of {cmd:W} that
fall {it:l} diagonals below and {it:u} diagonals above the main
diagonal.  Neither value can be greater than {cmd:floor((cols(W)-1)/4)}.

{pmore}{opt vtruncate(v)} truncates to 0 the values of {cmd:W} that are
less than or equal to {it:v}.

{phang}{opt banded} requests that the new matrix be stored in a banded
form.  The banded matrix is constructed without creating the underlying
n x n representation.  Note that without {cmd:banded}, a matrix with
truncated values will still be stored in an n x n form; see {it:Remarks}
in {helpb spmat_tobanded##banded_remarks:spmat tobanded} for details.

{phang}{opt replace} permits {cmd:spmat idistance} to overwrite an
existing {cmd:spmat} object.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use pollute}{p_end}

{pstd}Create the {cmd:spmat} object {cmd:dobj} containing an
inverse-distance matrix{p_end}
{phang2}{cmd:. spmat idistance dobj longitude latitude, id(id) dfunction(dhaversine)}


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
