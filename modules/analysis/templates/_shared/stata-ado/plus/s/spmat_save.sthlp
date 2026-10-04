{smcl}
{* *! version 1.0.0  15mar2010}{...}
{cmd:help spmat save}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col:{cmd:spmat save} {hline 2}}Save an spmat object in memory
to disk in Stata's native format
{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat} {cmdab:sa:ve} {it:objname} {cmd:using} {it:{help filename}}
[{cmd:, replace}]


{title:Description}

{pstd}{opt spmat save} saves the {cmd:spmat} object {it:objname} in
memory to disk in Stata's native format.  {cmd:replace} requests that
{it:filename} be overwritten if it already exists.


{title:Option}

{phang}{cmd:replace} permits {cmd:spmat save} to overwrite
{it:filename}.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. set memory 50m}{p_end}
{phang2}{cmd:. use pollute}{p_end}
{phang2}{cmd:. spmat contiguity cobj using pollutexy, id(id) normalize(minmax)}{p_end}

{pstd}Save the {cmd:spmat} object {cmd:cobj} to disk{p_end}
{phang2}{cmd:. spmat save cobj using cobj.spmat}{p_end}


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
