{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat note}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{cmd:spmat note} {hline 2}}Create and manipulate note attached to an spmat
object{p_end}
{p2colreset}{...}


{title:Syntax}

{phang}Create or append text to the note in {it:objname}

{p 8 15 2}{opt spmat note } {it:objname} {cmd:: "}{it:text}{cmd:"}


{phang}Replace the note associated with {it:objname}

{p 8 15 2}{opt spmat note } {it:objname} {cmd:: "}{it:text}{cmd:"} {cmd:, replace}


{phang}Display the note associated with {it:objname}

{p 8 15 2}{opt spmat note} {it:objname}


{phang}Drop the note associated with {it:objname}

{p 8 15 2}{opt spmat note} {it:objname} {cmd:drop}


{title:Description}

{pstd}{opt spmat note} creates and manipulates the note associated with the
{cmd:spmat} object {it:objname}.  Unlike in Stata datasets, {cmd:spmat}
objects can have only one note associated with them.  It is possible to
store multiple comments by repeatedly appending text to the note.


{title:Options}

{phang}{cmd:replace} causes {cmd:spmat note} to overwrite the existing
note with a new one.

{phang}{cmd:drop} causes {cmd:spmat note} to clear the note associated
with {it:objname}.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. spmat use cobj using pollute.spmat}

{pstd}Add a note to the {cmd:spmat} object {cmd:cobj}{p_end}
{phang2}{cmd:. spmat note cobj: "Simulated data for spmat"}{p_end}

{pstd}Display the note{p_end}
{phang2}{cmd:. spmat note cobj}{p_end}
           Simulated data for spmat

{pstd}Append another comment to the note{p_end}
{phang2}{cmd:. spmat note cobj: "- queen contiguity"}{p_end}

{pstd}Display the note{p_end}
{phang2}{cmd:. spmat note cobj}{p_end}
           Simulated data for spmat - queen contiguity

{pstd}Replace the note{p_end}
{phang2}{cmd:. spmat note cobj: `"Is this "queen" contiguity?"', replace}{p_end}
          
{pstd}Display the note{p_end}
{phang2}{cmd:. spmat note cobj}{p_end}
           Is this "queen" contiguity?

{pstd}Drop the note{p_end}
{phang2}{cmd:. spmat note cobj drop}{p_end}


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
