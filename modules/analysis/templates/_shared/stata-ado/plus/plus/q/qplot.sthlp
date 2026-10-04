{smcl}
{* 12nov2003/28oct2004/21apr2005/17aug2005/5nov2006/25feb2010/8nov2010/2mar2012/25jul2016}{...}
{cmd:help qplot}{right: ({browse "http://www.stata-journal.com/article.html?article=up0052":SJ16-3: gr42_7})}
{hline}

{p2colset 5 14 16 2}{...}
{p2col: {bf:qplot} {hline 2}}Quantile plots{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2} 
{cmd:qplot}
{varname}
{ifin}
[{cmd:,}
{cmd:over(}{it:varname}{cmd:)}
{cmd:by(}{it:varname}[{cmd:,} {it:suboptions}]{cmd:)}
{cmdab:miss:ing}
{cmd:a(}{it:#}{cmd:)}
{cmdab:mid:point} 
{cmdab:rank:s} 
{cmdab:rev:erse}
{cmdab:trsc:ale(}{it:transformation_syntax}{cmd:)}
{cmdab:x:variable(}{it:varname}{cmd:)} 
{it:graph_options}]

{p 8 17 2}
{cmd:qplot} 
{varlist}
{ifin}
[{cmd:,}
{cmd:by(}{it:varname}[{cmd:,} {it:suboptions}]{cmd:)}
{cmdab:miss:ing}
{cmd:a(}{it:#}{cmd:)}
{cmdab:rank:s}
{cmdab:rev:erse}
{cmdab:trsc:ale(}{it:transformation_syntax}{cmd:)} 
{cmdab:x:variable(}{it:varname}{cmd:)} 
{it:graph_options}]


{title:Description}

{p 4 4 2}{cmd:qplot} produces a plot of the ordered values of one or more
variables against the so-called plotting positions, which are essentially
quantiles of a uniform distribution on [0,1] for the same number of values; or
optionally the so-called unique ranks; or optionally a specified transformation
of either of those; or optionally a specified variable.

{p 4 4 2}For {it:n} values of a variable {it:x} ordered so that

{p 8 8 2}{it:x}[1] <= {it:x}[2] <= ... <= {it:x}[{it:n}-1] <= {it:x}[{it:n}]

{p 4 4 2}the plotting positions are ({it:i} - {it:a}) / ({it:n} - 2{it:a} + 1)
for {it:i} = 1, ..., {it:n} and constant {it:a}.  The unique ranks run 1 to
{it:n}; tied values are allocated different ranks so that each integer is
assigned to a value.

{p 4 4 2}For more than one variable in {it:varlist}, only observations with all
values of {it:varlist} present are shown.

{p 4 4 2}The plot is a scatterplot by default.  It is possible to use
{helpb advanced_options:recast()} to recast the plot as another
{helpb graph_twoway:twoway} type,
such as {cmd:connected}, {cmd:dot}, {cmd:dropline}, {cmd:line}, or {cmd:spike}.


{title:Options}

{p 4 8 2}{cmd:by(}{it:varname}[{cmd:,} {it:suboptions}]{cmd:)} specifies
that calculations be carried out separately for each distinct value of
a specified single variable.  Results will be shown separately in distinct
panels.  See {manhelpi by_option G-3}.

{p 4 8 2}{cmd:over(}{it:varname}{cmd:)} specifies that calculations be
carried out separately for each distinct value of a specified single variable.
Curves will be shown together within the same panel.  {cmd:over()} is only
allowed with a single {it:varname}.

{p 4 8 2}{cmd:missing}, used with {cmd:over()} or {cmd:by()}, permits the use
of nonmissing values of {it:varname} corresponding to missing values for the
variable(s) named by {cmd:over()} and {cmd:by()}.  The default is to ignore
observations with such values.

{p 4 8 2}{cmd:a(}{it:#}{cmd:)} specifies {it:a} in the formula for plotting
position.  The default is {it:a} = 0.5, giving ({it:i} - 0.5)/{it:n}.  Other
choices include {it:a} = 0, giving {it:i}/({it:n} + 1), and {it:a} = 1/3,
giving ({it:i} - 1/3)/({it:n} + 1/3).

{p 4 8 2}{cmd:midpoint} specifies the use of midpoints of plotting position 
intervals.  This option is most appropriate for showing ordered or graded
variables with a relatively small number of distinct values.  {cmd:midpoint}
is allowed only with a single {varname}.  See also
{it:{help qplot##remarks:Remarks}} below.

{p 4 8 2}{cmd:ranks} specifies the use of ranks rather than plotting
positions.

{p 4 8 2}{cmd:reverse} reverses the sort order, so that values decrease from
top left.  Ordered values are plotted against 1 - plotting position or
{it:n} - rank + 1.

{p 4 8 2}{cmd:trscale(}{it:transformation_syntax}{cmd:)} specifies the use of
an alternative transformed scale for plotting positions (or ranks) on the
graph.  Stata syntax should be used with {cmd:@} as placeholder for
untransformed values.  To show percents, specify {cmd:trscale(100 * @)}.  To
show probabilities on an inverse normal scale, specify
{cmd:trscale(invnormal(@))}; on a logit scale, specify {cmd:trscale(logit(@))};
on a folded root scale, specify {cmd:trscale(sqrt(@) - sqrt(1 - @))}; on a
loglog scale, specify {cmd:trscale(-log(-log(@)))}; on a cloglog scale,
specify {cmd:trscale(cloglog( @)))}.  Tools to make associated labels and ticks
easier are available on SSC; see {stata ssc desc mylabels:ssc desc mylabels}.
Alternatively, see Cox (2008).

{p 4 8 2}{opt xvariable(varname)} specifies a preexisting plotting position or
rank variable that should be used as the x-axis variable.
The user takes responsibility.

{p 4 8 2}{it:graph_options} refers to options of {helpb graph} appropriate to
the {it:plottype} specified.
 

{marker remarks}{...}
{title:Remarks: The midpoint option and graded data} 

{p 4 4 2}Ordered or graded variables are often defined in terms of a relatively 
small number of distinct values such as 1 "strongly disagree" through 5 
"strongly agree".  The {cmd:midpoint} option may be useful for such variables,
so each value is plotted at most once versus the midpoint of the corresponding
probability interval.  The plotting position is defined under that option as 

	SUM counts in categories below + (1/2) count in this category
	{hline 61}
                       SUM counts in all categories
		   
{p 4 4 2}With terminology from Tukey (1977, 496-497), this could be
called a "split fraction below".  It is also a "ridit" as defined by
Bross (1958); see also Fleiss, Levin, and Paik (2003, 198-205) or Flora
(1988).  Yet again, it is also the middistribution function of Parzen (1993,
3295) and the grade function of Haberman (1996, 240-241).  The numerator is a
"split count".  Using this numerator rather than 

	SUM counts in categories below 

{p 4 4 2}or 

	SUM counts in categories below + count in this category
	
{p 4 4 2}means that more use is made of the information in the data.  Either
alternative would always mean that some positions are identically 0 or 1,
which tells us nothing about the data.  In addition, there are fewer problems
in showing the distribution on any transformed scale (for example, logit) for
which the transform of 0 or 1 is not plottable.  Using this approach for
graded data was suggested by Cox (2001, 2004).


{title:Examples}

{p 4 8 2}For historical, methodological, and programming discussion and
numerous examples, see Cox (1999, 2005, 2007, 2012).

{p 4 8 2}{cmd:. qplot mpg}{p_end}
{p 4 8 2}{cmd:. qplot mpg, over(foreign) clpattern(l _) recast(line)}{p_end}
{p 4 8 2}{cmd:. qplot mpg, reverse rank recast(spike) xlabel(1 10(10)70 74)}{p_end}
{p 4 8 2}{cmd:. qplot mpg, recast(bar) barwidth(`=1/74') base(0)}

{p 4 4 2}Ecologists often plot abundance data as Whittaker plots
(see, for example, Krebs [1989, 344]):

{p 4 8 2}{cmd:. egen percent = pc(abundance)}{p_end}
{p 4 8 2}{cmd:. qplot percent, rank reverse yscale(log) ytitle("Relative abundance, %")} 

{p 4 4 2}Hydrologists plot discharges in reverse order as flow duration curves,
often with a logarithmic scale for discharge and a normal probability scale 
(see, for example, Dingman [2015, 26]): 

{p 4 8 2}{cmd:. mylabels 1 2 5 10(10)90 95 98 99, myscale(invnormal(@/100)) local(plabels)}{p_end}
{p 4 8 2}{cmd:. qplot discharge, reverse yscale(log) trscale(invnormal(@)) recast(line) xlabel(`plabels') xtitle("exceedance probability, %") ytitle("discharge, m{c -(}sup:3{c )-}/s")} 


{title:References} 

{p 4 8 2}Bross, I. D. J. 1958. How to use ridit analysis. {it:Biometrics}
14: 18-38.

{p 4 8 2}Cox, N. J. 1999. {browse "http://www.stata.com/products/stb/journals/stb51.pdf":Quantile plots, generalized.} {it:Stata Technical Bulletin} 51: 16-18.
Reprinted in {it:Stata Technical Bulletin Reprints}, vol. 9, pp. 113-116.
College Station, TX: Stata Press.

{p 4 8 2}
------. 2001. Plotting graded data: a Tukey-ish approach.
Presentation to UK Stata Users Group meeting, Royal Statistical Society, 
London, 14-15 May.
{browse "http://www.stata.com/meeting/7uk/cox1.pdf"}

{p 4 8 2}
------. 2004. {browse "http://www.stata-journal.com/article.html?article=gr0004":Speaking Stata: Graphing categorical and compositional data.}
{it:Stata Journal} 4: 190-215.

{p 4 8 2}
------. 2005. {browse "http://www.stata-journal.com/article.html?article=gr0018":Speaking Stata: The protean quantile plot.}
{it:Stata Journal} 5: 442-460.

{p 4 8 2}
------. 2007. {browse "http://www.stata-journal.com/article.html?article=gr0027":Stata tip 47: Quantile-quantile plots without programming.}
{it:Stata Journal} 7: 275-279.

{p 4 8 2}
------. 2008. {browse "http://www.stata-journal.com/article.html?article=gr0032":Stata tip 59: Plotting on any transformed scale.}
{it:Stata Journal} 8: 142-145.

{p 4 8 2}
------. 2012. {browse "http://www.stata-journal.com/article.html?article=gr0053":Speaking Stata: Axis practice, or what goes where on a graph.}
{it:Stata Journal} 12: 549-561.

{p 4 8 2}Dingman, S. L. 2015. {it:Physical Hydrology}. 3rd ed.
Long Grove, IL: Waveland Press.

{p 4 8 2}Fleiss, J. L., B. Levin, and M. C. Paik. 2003.
{it:Statistical Methods for Rates and Proportions}. 3rd ed.
Hoboken, NJ: Wiley.

{p 4 8 2}Flora, J. D. 1988. Ridit analysis. In 
{it:Encyclopedia of Statistical Sciences},
ed. S. Kotz and N. L. Johnson, vol. 8, 136-139.
New York: Wiley.

{p 4 8 2}Haberman, S. J. 1996.
{it:Advanced Statistics Volume I: Description of Populations}.
New York: Springer.

{p 4 8 2}Krebs, C. J. 1989. {it:Ecological Methodology}.
New York: Harper and Row.

{p 4 8 2}Parzen, E. 1993. Change {it:PP} plot and continuous sample quantile 
function. {it:Communications in Statistics -- Theory and Methods} 
22: 3287-3304.

{p 4 8 2}Tukey, J. W. 1977. {it:Exploratory Data Analysis}.
Reading, MA: Addison-Wesley.


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break} 
        n.j.cox@durham.ac.uk


{title:Acknowledgment}

{p 4 4 2}Patrick Royston suggested and first implemented what is here the 
{cmd:xvariable()} option.
	 

{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=up0052":gr42_7},{break}
          {it:Stata Journal}, volume 12, number 1: {browse "http://www.stata-journal.com/article.html?article=up0035":gr42_6},{break}
          {it:Stata Journal}, volume 10, number 4: {browse "http://www.stata-journal.com/article.html?article=up0030":gr42_5},{break}
         {it:Stata Journal}, volume 6, number 4: {browse "http://www.stata-journal.com/sjpdf.html?articlenum=up0017":gr42_4},{break}
         {it:Stata Journal}, volume 5, number 3: {browse "http://www.stata-journal.com/sjpdf.html?articlenum=up0012":gr42_3},{break}
         {it:Stata Journal}, volume 4, number 1: {browse "http://www.stata-journal.com/sjpdf.html?articlenum=up0006":gr42_2},{break}
         {it:Stata Technical Bulletin} 61: {browse "http://www.stata.com/products/stb/journals/stb61.pdf":gr42_1},{break}
         {it:Stata Technical Bulletin} 51: {browse "http://www.stata.com/products/stb/journals/stb51.pdf":gr42}
{p_end}

{p 5 14 2}Manual:  {manlink G graph}, {manlink R cumul},
                   {manlink R diagnostic plots}

{p 7 14 2}Help:  {manhelp graph G-2}, {manhelp cumul R}, {manhelp quantile R},
{helpb distplot} (if installed), {helpb mylabels} (if installed)
{p_end}
