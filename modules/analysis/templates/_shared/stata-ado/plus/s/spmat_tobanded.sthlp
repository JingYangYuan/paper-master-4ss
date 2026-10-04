{smcl}
{* *! version 1.0.0  15mar2010}{...}
{cmd:help spmat tobanded}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 23 25 2}{...}
{p2col:{cmd:spmat tobanded} {hline 2}}Store a general spatial-weighting 
matrix W in banded form{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:tob:anded} {it:objname1} [{it:objname2}] 
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt btr:uncate(b B)}}bin truncation{p_end}
{p2coldent:* {opt dtr:uncate(l u)}}diagonal truncation{p_end}
{p2coldent:* {opt vtr:uncate(#)}}value truncation{p_end}
{synopt:{opt replace}}replace {it:objname1} or {it:objname2}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* Only one of {cmd:btruncate()}, {cmd:dtruncate()}, or
{cmd:vtruncate()} may be specified.{p_end}


{title:Description}

{pstd}{opt spmat tobanded} replaces the existing {it:objname1} or
creates the new {it:objname2} with the spatial-weighting matrix {bf:W}
stored in a banded form.  By default, {opt spmat tobanded} assumes that
{bf:W} already has a banded structure and attempts to store {bf:W} in a
banded form; see {help spmat_tobanded##banded_remarks:Remarks} below for
a distinction between a banded structure and a banded form.

{pstd}If the matrix cannot be stored in a banded form, 
{cmd:spmat tobanded} returns appropriate summary statistics.


{title:Options}

{phang}Truncate options specify one of the three available truncation
criteria.  The values of {bf:W} that meet the truncation criterion will
be changed to 0.

{pmore}{opt btruncate(b B)} partitions the values of {bf:W} into {it:B}
bins and truncates to 0 entries that fall into bin {it:b} or below.

{pmore}{opt dtruncate(l u)} truncates to 0 the values of {bf:W} that
fall {it:l} diagonals below and {it:u} diagonals above the main
diagonal.  Neither value can be greater than {cmd:floor((cols(W)-1)/4)}.

{pmore}{opt vtruncate(#)} truncates to 0 the values of {bf:W} that are
less than or equal to {it:#}.

{phang}{opt replace} allows {it:objname1} or {it:objname2} to be
overwritten if it already exists.


{marker banded_remarks}{...}
{title:Remarks}

{pstd}Let {bf:W} be the spatial-weighting matrix

            {c TLC}{c -}             {c -}{c TRC}
            {c |} {bf:0}  1  0  0  0 {c |}
            {c |} 1  {bf:0}  1  0  0 {c |}
            {c |} 0  1  {bf:0}  1  0 {c |}
            {c |} 0  0  1  {bf:0}  1 {c |}
            {c |} 0  0  0  1  {bf:0} {c |}
            {c BLC}{c -}             {c -}{c BRC}

{pstd}where we highlight the main diagonal.  Note that all the 1s are
clustered around the main diagonal.  A matrix with nonzero elements in
the diagonals close to the main diagonal and zero elements in all the
diagonals away from the main diagonal is called a banded matrix.  Note
that although this matrix has a banded structure, it is still stored in
a general n x n form.  We can store {bf:W} more efficiently in a banded
form as

            {c TLC}{c -}             {c -}{c TRC}
            {c |} 0  1  1  1  1 {c |}
            {c |} {bf:0}  {bf:0}  {bf:0}  {bf:0}  {bf:0} {c |}
            {c |} 1  1  1  1  0 {c |}
            {c BLC}{c -}             {c -}{c BRC}

{pstd}The row dimension of the banded matrix is {it:b} = (# of diagonals
below the main diagonal + main diagonal + # of diagonals above the main
diagonal).  The elements beyond the upper and lower bands are implied to
be 0 and need not be stored.

{pstd}In general, the spatial-weighting matrix for n places is an
n x n matrix, which implies that memory requirements increase
quadratically with data size.  For example, a spatial-weighting matrix
for n = 50,000 requires (50,000*50,000*8) / 2^30 or 18.63 GB of
storage space.

{pstd}As discussed in Drukker et al. (2013, 2011), many
spatial-weighting matrices can be stored in a banded form b x
n, b << n, if the underlying data have been sorted in an
ascending order from a corner place for a given topography.

{pstd}If we construct a contiguity matrix from the sorted data, most
neighboring observations will cluster around the main diagonal, which
will allow us to store the matrix in a banded form without any loss of
information.

{pstd}If we construct an inverse-distance matrix from the sorted data,
places that are closer to us will be located closer to the main
diagonal, and more distant places will be located farther away from the
main diagonal.  In this case, an inverse-distance matrix can be banded
if we assume that places that lie outside a certain perimeter are to be
treated as nonneighbors.  Truncate options provide three ways to exclude
more distant places from our neighborhood.

{pstd}In either case, the banded matrix will be stored in a banded form,
which will result in substantial savings of storage.  For example, if we
are able to squeeze neighborhood information into the bands of width
500, we can store the 50,000 x 50,000 matrix in a 1,001 x 50,000 form,
which requires only (1,001*50,000*8) / 2^30 or 0.37 GB of memory.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use pollute}{p_end}
{phang2}{cmd:. sort longitude latitude}{p_end}
{phang2}{cmd:. spmat contiguity cobj using c103xy, id(id) norm(minmax)}{p_end}

{pstd}Summarize the matrix contained in the {cmd:spmat} object {cmd:cobj} to see
that it is stored as a 541 x 541 matrix{p_end}
{phang2}{cmd:. spmat summarize cobj, links}{p_end}

{pstd}Try to band the matrix{p_end}
{phang2}{cmd:. spmat tobanded cobj, replace}{p_end}

{pstd}Summarize the matrix to see that it is stored as a
147 x 541 banded matrix{p_end}
{phang2}{cmd:. spmat summarize cobj, links}{p_end}


{title:References}

{phang}Drukker, D. M., H. Peng, I. R. Prucha, and R. Raciborski. 2011. Banded
spatial-weighting matrices.  Working paper, University of Maryland, Department
of Economics.

{phang}------. 2013. Creating and managing spatial-weighting matrices with
the spmat command.  {it:Stata Journal} 13: 242-286.


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
