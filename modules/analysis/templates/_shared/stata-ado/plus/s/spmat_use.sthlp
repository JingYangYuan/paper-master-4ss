{smcl}
{* *! version 1.0.1  16mar2010}{...}
{cmd:help spmat use}{right: ({browse "http://www.stata-journal.com/article.html?article=st0292":SJ13-2: st0292})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:spmat use} {hline 2}}Load an spmat object into memory
{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:spmat use} {it:objname} {cmd:using} {it:{help filename}} [{cmd:, replace}]


{title:Description}

{pstd}{opt spmat use} creates the {cmd:spmat} object {it:objname} from
the file {it:filename} previously saved with {cmd:spmat save}.


{title:Option}

{phang}{cmd:replace} permits {cmd:spmat use} to overwrite an
existing {cmd:spmat} object.


{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. set memory 50m}{p_end}
{phang2}{cmd:. use pollute}{p_end}
{phang2}{cmd:. spmat contiguity cobj using pollutexy, id(id) normalize(minmax)}{p_end}
{phang2}{cmd:. spmat save cobj using cobj.spmat}{p_end}
{phang2}{cmd:. spmat drop cobj}{p_end}

{pstd}Create the {cmd:spmat} object {cmd:cobj} from the file {cmd:cobj.spmat}{p_end}
{phang2}{cmd:. spmat use cobj using cobj.spmat}{p_end}


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
