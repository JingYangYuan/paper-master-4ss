{smcl}
{* *! version 1.0.4  24jan2012}{...}
{cmd:help spmat}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 14 16 2}{...}
{p2col:{hi:spmat} {hline 2}}Create and manage spatial-weighting matrix objects
(spmat objects){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {it:subcommand} {it:...} [{cmd:,} {it:...}] 

{synoptset 12}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{helpb spmat_contiguity:contiguity}}create an {cmd:spmat} object containing a contiguity
	matrix {bf:W}{p_end}
{synopt:{helpb spmat_idistance:idistance}}create an {cmd:spmat} object containing an
	inverse-distance matrix {bf:W}{p_end}

{synopt:{helpb spmat_summarize:summarize}}summarize an {cmd:spmat} object{p_end}
{synopt:{helpb spmat_note:note}}create or manipulate a note attached to an {cmd:spmat} object{p_end}
{synopt:{helpb spmat_graph:graph}}draw an intensity plot of {bf:W}{p_end}
{synopt:{helpb spmat_lag:lag}}create a spatially lagged variable{p_end}
{synopt:{helpb spmat_eigenvalues:eigenvalues}}add eigenvalues of {bf:W} to an {cmd:spmat} object{p_end}
{synopt:{helpb spmat_drop:drop}}drop an {cmd:spmat} object from memory{p_end}

{synopt:{helpb spmat_save:save}}save an {cmd:spmat} object to disk in Stata's native format{p_end}
{synopt:{helpb spmat_export:export}}save an {cmd:spmat} object to disk as a text file{p_end}
{synopt:{helpb spmat_getmatrix:getmatrix}}copy a matrix from an {cmd:spmat} object to a Mata matrix{p_end}
	
{synopt:{helpb spmat_use:use}}create an {cmd:spmat} object from a file created by
	{cmd:spmat save}{p_end}
{synopt:{helpb spmat_import:import}}create an {cmd:spmat} object from a text file{p_end}
{synopt:{helpb spmat_dta:dta}}create an {cmd:spmat} object from a Stata dataset{p_end}
{synopt:{helpb spmat_putmatrix:putmatrix}}put a Mata matrix into an {cmd:spmat} object{p_end}

{synopt:{helpb spmat_permute:permute}}permute rows and columns of {bf:W}{p_end}
{synopt:{helpb spmat_tobanded:tobanded}}transform an n x n matrix {bf:W} into a
banded b x n matrix {bf:W}{p_end}
{synoptline}


{title:Description}

{pstd}Spatial-weighting matrices are used to model interactions between
spatial units in a dataset.  {opt spmat} is a collection of commands for
creating, importing, manipulating, and saving spatial-weighting
matrices.

{pstd}Spatial-weighting matrices are stored in spatial-weighting matrix
objects ({cmd:spmat} objects).  {cmd:spmat} objects contain additional
information about the data used in constructing spatial-weighting
matrices.  {cmd:spmat} objects are used in fitting spatial models; see
{helpb spreg} (if installed) and {helpb spivreg} (if installed).


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

{p 7 14 2}Help:  {helpb spreg}, {helpb spivreg}, {helpb spmap}, 
{helpb shp2dta}, {helpb mif2dta} (if installed){p_end}
