{smcl}
{* *! version 1.0.0 28feb2014}{...}
{cmd:help margte_dgps}
{hline}

{title:Title}

{phang}{cmd:margte_dgps} {hline 2} Marginal treatment effects - data generating processes{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:margte_dgps}, [obs(#), dgp(poly), model(pnorm | ml | ppoly | semil | semip), prblm(inst | supp)]


{marker description}{...}
{title:Description}

{phang}
{cmd:margte_dgps} generates a sample dataset based on a Generalized Roy Model of the returns to college. 
	The default is to generate a parametric normal model. The program was created for understanding 
	the Stata command {helpb margte} and its accompanying Stata Journal article.


{marker options}{...}
{title:Options}

{phang}
{opt obs(#)} specifies the number of observations to generate.
	
{phang}
{opt dgp(poly)} specifies the data generating process to be a parametric polynomial model with 
	a propensity score polynomial of degree 4. Any value other than poly will generate the default 
	model, which is a parametric normal model.
	
{phang}
{opt model(pnorm | ml | ppoly | semil | semip)} specifies that the command {helpb margte} be run,
	implementing the specified model. See {helpb help margte} for a description of the available models.

{phang}
{opt prblm(inst | supp)} specifies that the data generating process be modified to break certain 
	identifying assumptions of the {helpb margte} model. The {it:inst} option generates a correlation 
	between distCol and u0. The {it:supp} option generates a distribution of propensity scores with
	limited common support. See {helpb margte}'s Stata Journal article for more details.
	
{marker examples}{...}
{title:Examples}

{pstd}Generate 5,000 observations from a parametric normal data generating process{p_end}
{phang}{cmd:. margte_dgps}{p_end}

{pstd}Generate 10,000 observations from a parametric polynomial data generating process{p_end}
{phang}{cmd:. margte_dgps, obs(10000) dgp(poly)}{p_end}

{pstd}Estimate a semiparametric LIV model on a parametric normal data generating process{p_end}
{phang}{cmd:. margte_dgps, model(semil)}{p_end}

{pstd}Estimate a parametric normal model on a parametric polynomial data generating process with
	limited common support{p_end}
{phang}{cmd:. margte_dgps, dgp(poly) model(pnorm) prblm(supp)}{p_end}


{marker saved_results}{...}
{title:Saved results}

{pstd}If a model is specified, {cmd: margte_dgps} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(u1)-r(u99)}}mte estimates for u1 to u99{p_end}
{synopt:{cmd:r(ate)}}estimate of the average treatment effect{p_end}
{synopt:{cmd:r({it:parameters})}}estimates of the parameters of the specified model{p_end}


{marker Authors}{...}
{title:Authors}

{p 4 4}Thomas Walstrum{p_end}
{p 4 4}University of Illinois at Chicago{p_end}
{p 4 4}Federal Reserve Bank of Chicago{p_end}
{p 4 4}twalstrum@frbchi.org{p_end}

{p 4 4}Scott Brave{p_end}
{p 4 4}Federal Reserve Bank of Chicago{p_end}
{p 4 4}sbrave@frbchi.org{p_end}


{marker also_see}{...}
{title:Also see}

{psee}Help: {helpb margte}{p_end}
