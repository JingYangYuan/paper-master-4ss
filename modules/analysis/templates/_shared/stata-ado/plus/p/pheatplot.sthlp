{smcl}
{* *! version 1.1.0  E Brini, ST Borgen, NT Borgen 02july2024}{...}
{cmd:help pheatplot}{right: ({browse "https://doi.org/10.1177/1536867X251322962":SJ25-1: gr0099})}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:pheatplot} {hline 2}}Visualizing statistical significance across coefficients{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:pheatplot} {varname} [{cmd:,} {it:options}]

{marker options}{...}
{synoptset 37 tabbed}{...}
{synopthdr :options}
{synoptline}
{p2coldent : {opt threshold(#)}}set the critical threshold value; default is
{cmd:threshold(.10)}{p_end}
{p2coldent : {opth interaction(varname)}}specify the interaction variable,
if any{p_end}
{p2coldent : {opt frame(newframename)}}specify the name of the frame
that holds coefficients, standard errors, {it:p}-values, and confidence
intervals{p_end}
{p2coldent : {opt pn:ame(name)}}provide a name for the heat plot of the
{it:p}-values{p_end}
{p2coldent : {opt bn:ame(name)}}provide a name for the heat plot of the coefficients{p_end}
{p2coldent : {opt heatoptsp(options)}}pass options along to the heat plot 
of the {it:p}-values{p_end}
{p2coldent : {opt heatoptsb(options)}}pass options along to the heat plot 
of the coefficients{p_end}
{p2coldent : {cmd:pvalues(off)}}remove the numeric display of
{it:p}-values from heat plot of {it:p}-values{p_end}
{p2coldent : {opt savet:able(filename[, save_options])}}save a table holding results{p_end}
{p2coldent : {cmdab:saveg:raph(}{it:filename}{cmd:.}{it:suffix}[{cmd:, replace}]{cmd:)}}export to a file the heat plot of {it:p}-values{p_end}
{p2coldent : {opt hexplot}}request that hexagon plots be used instead of heat plots{p_end}
{p2coldent : {opt differences}}request that heat plot of differences between
coefficients be displayed{p_end}
{p2coldent : {opt mono}}request that heat plots be shown in grayscale color palette{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:pheatplot} is a postestimation command that calculates pairwise
comparisons of estimates using {helpb lincom} and provides a heat plot by
color to visualize the {it:p}-values of the difference between the categories
of a factor variable or their interaction effects.  It can be used after any
single-equation estimation command that allows for factor-variable notation
and the use of the postestimation command {helpb lincom}.  The categorical
variable that will be compared is placed after the command name, followed by
options.  In the previous regression model, the categorical variable must be
included using factor-variable notation ({it:{help fvvarlist}}).

{pstd}
See {help pheatplot#ref:Brini, Borgen, and Borgen (2025)} for descriptions and
examples of the {cmd:pheatplot} command.


{title:Options}

{phang}
{opt threshold(#)} sets the critical threshold value, with the color gradient
differing below and above this threshold.  This allows the user to identify
and communicate whether differences are statistically significant at specific
levels while simultaneously avoiding strict cutoff values.  The default is
{cmd:threshold(.10)}.

{phang}
{opth interaction(varname)} specifies the interaction variable, if any.
Interactions must be included using factor-variable operators 
({it:{help fvvarlist}}).

{phang}
{opt frame(newframename)} specifies the name of the frame that holds
coefficients, standard errors, {it:p}-values, and confidence intervals.
Specifying {cmd:frame()} will return a frame after the program ends.

{phang}
{opt pname(name)} provides a name for the heat plot of the {it:p}-values.

{phang}
{opt bname(name)} provides a name for the heat plot of the coefficients.

{phang}
{opt heatoptsp(options)} affects rendition of the {it:p}-value plot.  Options
specified here are passed along to the heat plot of the {it:p}-values.  See
{cmd:heatplot} {help heatplot:{it:options}} for a list of available
options.

{phang}
{opt heatoptsb(options)} affects the rendition of the plot of differences
between coefficients.  Options specified here are passed along to the heat
plot of the differences between coefficients.  See {cmd:heatplot}
{help heatplot:{it:options}} for a list of available options.  Use of
{cmd:heatoptsb()} requires that the option {opt differences} be specified.

{phang}
{cmd:pvalues(off)} removes the numeric display of {it:p}-values in the heat
plot of the {it:p}-values.  This option should be used in combination with
{cmd:heatoptsp(values())} if the user wants to customize the display of
{it:p}-values.

{phang}
{opt savetable(filename[, save_options])} saves a table in {cmd:.docx} format
that includes the difference between coefficients and the standard errors and
{it:p}-values from testing whether there are statistically significant
differences between the coefficients.  The {it:save_options} from
{cmd:putdocx} can be used to {cmd:replace} an existing file or {cmd:append}
the active file to the end of an existing file.  See {cmd:putdocx begin}
{help putdocx begin##saveopts:{it:save_options}} for a list of available options.

{phang}
{cmd:savegraph(}{it:filename}{cmd:.}{it:suffix}[{cmd:, replace}]{cmd:)}
exports the heat plot of {it:p}-values to a file.  {it:suffix} can be (with
output format in parentheses) {cmd:ps} (PostScript), {cmd:eps} (Encapsulated
PostScript), {cmd:svg} (Scalable Vector Graphics), {cmd:emf} (Enhanced
Metafile), {cmd:pdf} (Portable Document Format), {cmd:png} (Portable Network
Graphics), {cmd:tif} (Tagged Image File Format), {cmd:gif} (Graphics
Interchange Format), or {cmd:jpg} (Joint Photographic Experts Group).

{phang}
{opt hexplot} requests that hexagon plots be used instead of heat plots.  The
default is that the community-contributed command {cmd:heatplot} is used
rather than {cmd:hexplot}.

{phang}
{opt differences} requests that a heat plot of differences between
coefficients be displayed.  The default is that the plot of differences
between coefficients is not shown.

{phang}
{opt mono} requests that the heat plots be shown in grayscale color palette.


{title:Examples}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse nlsw88}{p_end}
{phang2}{cmd:. drop if inlist(occupation,9,10,12)}

{pstd}
Test differences in occupation indicator variables{p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation}

{pstd}
Test difference in union effects by occupation{p_end}
{phang2}{cmd:. regress wage i.occupation##i.union}{p_end}
{phang2}{cmd:. pheatplot occupation, interaction(i.union)}

{pstd}
Test difference in age effects by occupation{p_end}
{phang2}{cmd:. regress wage i.occupation##c.age}{p_end}
{phang2}{cmd:. pheatplot occupation, interaction(c.age)}

{pstd}
Test differences in occupation indicator variables after a logistic regression
model{p_end}
{phang2}{cmd:. logit union i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation}

{pstd}
Test differences in occupation indicator variables after {helpb margins}{p_end}
{phang2}{cmd:. logit union i.occupation}{p_end}
{phang2}{cmd:. margins, dydx(occupation) post}{p_end}
{phang2}{cmd:. pheatplot occupation}

{pstd}
Change the threshold cutoff value{p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation, threshold(.05)}

{pstd}
Request that the graph be shown using a grayscale color palette{p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation, mono}

{pstd}
Use alternative color palettes{p_end}
{phang2}{cmd:. regress wage i.occupation}{p_end}
{phang2}{cmd:. pheatplot occupation, heatoptsp(colors(Blues))}

{pstd}
Customize the look of the graph using {cmd:heatoptsp()}{p_end}
{phang2}{cmd:. use http://www.stata-press.com/data/mlmus2/gcse, clear}{p_end}
{phang2}{cmd:. regress gcse i.school}{p_end}
{phang2}{cmd:. pheatplot school, pvalues(off) heatoptsp(scale(0.7) ramp(scale(.7) legend(symysize(.5) symxsize(.5)) space(12) right label(#10) subtitle(P-value) format(%9.2f)) ylabel(2(3)65, nogrid) xlabel(1(3)64, nogrid))}


{title:Stored results}

{pstd}
{cmd:pheatplot} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(pvalues)}}matrix holding {it:p}-values{p_end}
{synopt:{cmd:r(differences)}}matrix holding differences between coefficients{p_end}


{title:Version requirements}

{pstd}
The {cmd:pheatplot} command requires Stata 17.0 or later.


{title:Package dependencies}

{pstd}
{cmd:pheatplot} uses {helpb heatplot} (Jann 2019) to visualize the statistical
significance of differences between coefficients.  To install this command,
type 

{phang2}
{cmd:. ssc install heatplot}

{pstd}
To use the {cmd:pheatplot} command, users also need the {cmd:colrspace} and
{cmd:colorpalette} commands (Jann 2023).

{phang2}
{cmd:. ssc install colrspace}{p_end}
{phang2}
{cmd:. ssc install palette}


{marker ref}{...}
{title:Reference}

{phang}
Brini, E., S. T. Borgen, and N. T. Borgen. 2025. Avoiding the eyeballing
fallacy: Visualizing statistical differences between estimates using
the pheatplot command. {it:Stata Journal} 25: 77-96.
{browse "https://doi.org/10.1177/1536867X251322962"}.

{phang}
Jann, B. 2019. heatplot: Stata module to create heat plots and hexagon plots.
Statistical Software Components S458598, Department of Economics,
Boston College. {browse "https://ideas.repec.org/c/boc/bocode/s458598.html"}.

{phang}
------. 2023. Color palettes for Stata graphics: An update. 
{it:Stata Journal} 23: 336–385.
{browse "https://doi.org/10.1177/1536867X231175264"}.


{title:Authors}

{p 4 4 2}
Elisa Brini{break}
University of Florence{break}
Florence, Italy{break}
and{break}
University of Oslo{break}
Oslo, Norway{break}
elisa.brini@unifi.it{p_end}

{p 4 4 2}
Solveig T. Borgen{break}
University of Oslo{break}
Oslo, Norway{break}
s.t.borgen@sosgeo.uio.no{p_end}

{p 4 4 2}
Nicolai T. Borgen{break}
University of Oslo{break}
Oslo, Norway{break}
n.t.borgen@isp.uio.no{p_end}


{marker see}{...}
{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 25, number 1: {browse "https://doi.org/10.1177/1536867X251322962":gr0099}{p_end}
