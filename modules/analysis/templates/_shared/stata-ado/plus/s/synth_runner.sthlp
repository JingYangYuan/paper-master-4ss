{smcl}
{* 17feb2017}{...}
{cmd:help synth_runner}{right: ({browse "http://www.stata-journal.com/article.html?article=st0500":SJ17-4: st0500})}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi:synth_runner} {hline 2}}Automation for multiple synthetic control estimations{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 20 2}
{cmd:synth_runner} {it:depvar} {it:predictorvars}{cmd:,} 
{{opt tru:nit(#)} {opt trp:eriod(#)}|{opt d(varname)}} [{opt tre:nds} 
{opt pre_limit_mult(real)} 
{opt training_propr(real)} 
{opt gen:_vars} 
{opt noenforce_const_pre_length} 
{opt ci} 
{opt max_lead(int)} 
{opt n_pl_avgs(string)} 
{opt pred_prog(string)} 
{opt det:erministicoutput} 
{opt par:allel} 
{opt pvals1s} 
{opt drop_units_prog(string)} 
{opt xperiod_prog(string)} 
{opt mspeperiod_prog(string)} 
{it:synthsettings}]

{p 4 4 2}
The dataset must be declared as a (balanced) panel using {helpb tsset}.
Variables specified in {it:depvar} and {it:predictorvars} must be numeric
variables; abbreviations are not allowed.  The command {cmd:synth} (available
in Statistical Software Components) is required.  Auxiliary commands for
generating graphs postestimation are shown in the examples below.  Finally,
the version of the package can be found by running {cmd:synth_runner version}
and checking {cmd:r(version)} or viewing the displayed output.

{p 4 8 2}
{marker predoptions}
{it:depvar} specifies the outcome variable.

{p 4 8 2}
{it:predictorvars} specifies the list of predictor variables.  See 
{helpb synth} for more details.


{title:Description}

{p 4 4 2}
{cmd:synth_runner} automates the process of running multiple synthetic control
estimations by {cmd:synth}.  It will run placebo estimates in space
(estimations for the same treatment period but on all the control units).  It
will then provide inference (p-values) comparing the estimated main effect
with the distribution of placebo effects.  It handles the case where several
units receive treatment, possibly at different time periods.  If there are
multiple treatment periods, then effects are centered around the treatment
period to be comparable.  The maximum common number of leads and lags that can
be achieved in the data given the treated units are used for analysis.
{cmd:synth_runner} provides facilities for automatically generating outcome
predictors using a training proportion of the pretreatment period.  It also
provides diagnostics to assess fit.  {cmd:synth_runner} is designed to
accompany {cmd:synth} but not to supersede it.  For more details about single
estimations (variable weights, observation weights,  covariate balance, and
synthetic control outcomes when there are multiple time periods), use
{cmd:synth} directly.  See {helpb synth} and Abadie and Gardeazabal (2003) and
Abadie, Diamond, and Hainmueller (2010, 2015) for more details.


{title:Options}

{p 2 4 2}
There are two methods for specifying the unit and time period of treatment:
either {cmd:trunit()} and {cmd:trperiod()} or {cmd:d()}.
Exactly one of these is required.

{p 4 8 2}
{cmd:trunit(}{it:#}{cmd:)} and {cmd:trperiod(}{it:#}{cmd:)}, used by
{cmd:synth}, can be used when there is a single unit entering treatment.
Because synthetic control methods split time into pretreatment and treated
periods, {cmd:trperiod()} is the first of the treated periods and, slightly
confusingly, also called posttreatment.

{p 4 8 2}
{cmd:d(}varname{cmd:)} specifies a binary variable, which is 1 for treated
units in treated periods and 0 everywhere else.  This allows for multiple
units to undergo treatment, possibly at different times.

{p 4 8 2}
{cmd:trends} will force {cmd:synth} to match on the trends in the outcome
variable.  It does this by scaling each unit's outcome variable so that it is
1 in the last pretreatment period.

{p 4 8 2}
{cmd:pre_limit_mult(}{it:real}{cmd:)} will not include placebo effects in the
pool for inference if the match quality of that control, namely, the
pretreatment root mean squared predictive error (RMSPE), is greater than
{cmd:pre_limit_mult()} times the match quality of the treated unit.  {it:real}
must be greater than or equal to 1.

{p 4 8 2}
{cmd:training_propr(}{it:real}{cmd:)} instructs {cmd:synth_runner} to
automatically generate the outcome predictors.  The default is
{cmd:training_propr(0)}, which is to not generate any (the user then includes
the desired ones in {it:predictorvars}).  If the value is set to a number
greater than 0, then that initial proportion of the pretreatment period is
used as a training period, with the rest being the validation period.  Outcome
predictors for every time in the training period will be added to the
{cmd:synth} commands.  Diagnostics of the fit for the validation period will
be outputted.  If the value is between 0 and 1, there will be at least one
training period and at least one validation period.  If it is set to 1, then
all the pretreatment period outcome variables will be used as predictors.
This will make other covariate predictors redundant.  {it:real} must be
greater than or equal to 0 and less than or equal to 1.

{p 4 8 2}
{cmd:gen_vars} generates variables in the dataset from estimation.  This is
allowed only if there is a single period in which units enter treatment.
These variables are required for the following: 
{helpb single_treatment_graphs} and {helpb effect_graphs}.  If {cmd:gen_vars}
is specified, it will generate the following variables:

{phang2}
{cmd:lead} contains the respective time period relative to treatment.
{cmd:lead}=1 specifies the first period of treatment.  This is to match
Cavallo et al. (2013) and is effectively the offset from the last nontreatment
period.

{phang2}
{it:depvar}{cmd:_synth} contains the unit's synthetic control outcome for that
time period.

{phang2}
{cmd:effect} contains the difference between the unit's outcome and its
synthetic control for that time period.

{phang2}
{cmd:pre_rmspe} contains the pretreatment match quality in terms of RMSPE.  It
is constant for a unit.

{phang2}
{cmd:post_rmspe} contains a measure of the posttreatment effect (jointly over
all posttreatment time periods) in terms of RMSPE.  It is constant for a unit.

{phang2}
{it:depvar}{cmd:_scaled} (if the match was done on trends) is the unit's
outcome variable normalized so that its last pretreatment period outcome is 1.

{phang2}
{it:depvar}{cmd:_scaled_synth} (if the match was done on trends) is the unit's
synthetic control (scaled) outcome variable.

{phang2}
{cmd:effect_scaled} (if the match was done on trends) is the difference
between the unit's scaled outcome and its synthetic control's (scaled) outcome
for that time period.

{p 4 8 2}
{cmd:noenforce_const_pre_length} specifies that maximal histories are desired
at each estimation stage.  When there are multiple periods, estimations at
later treatment dates will have more pretreatment history available.  By
default, these histories are trimmed on the early side so that all estimations
have the same amount of history.

{p 4 8 2}
{cmd:ci} outputs confidence intervals from randomization inference for raw
effect estimates.  These should be used only if the treatment is randomly
assigned (conditional on covariates and interactive fixed effects).  If
treatment is not randomly assigned, then these confidence intervals do not
have the standard interpretation (in contrast to p-values, which do).

{p 4 8 2}
{cmd:max_lead(}{it:int}{cmd:)} will limit the number of posttreatment periods
analyzed.  The default is the maximum number of leads that is available for
all treatment periods.

{p 4 8 2}
{cmd:n_pl_avgs(}{it:string}{cmd:)} controls the number of placebo averages to
compute for inference.  The total possible grows exponentially with the number
of treated events.  The default behavior is to cap the number of averages
computed at 1,000,000 and, if the total is more than that, to sample (with
replacement) the full distribution.  The option {cmd:n_pl_avgs(all)} can be
used to override this behavior and compute all the possible averages.  The
option {cmd:n_pl_avgs(}{it:#}{cmd:)} can be used to specify a specific number
less than the total number of averages possible.

{p 4 8 2}
{cmd:pred_prog(}{it:string}{cmd:)} allows time-contingent predictor sets.  The
user writes a program that takes as input a time period and outputs via
{cmd:r(predictors)} a {cmd:synth}-style predictor string.  If one is not using
{cmd:training_propr()}, then {cmd:pred_prog()} could be used to dynamically
include outcome predictors.  See example 3 for usage details.

{p 4 8 2}
{cmd:deterministicoutput}, when used with {cmd:parallel}, will eliminate
displayed output that would vary depending on the machine (for example, timers
and number of parallel clusters) so that log files can be easily compared
across runs.

{p 4 8 2}
{cmd:parallel} will enable parallel processing if the {cmd:parallel} command
is installed and configured.  Version 1.18.2 is needed at a minimum (available
via {browse "https://github.com/gvegayon/parallel/"}).

{p 4 8 2}
{cmd:pvals1s} outputs one-sided p-values in addition to the two-sided
p-values.

{p 4 8 2}
{cmd:drop_units_prog(}{it:string}{cmd:)} specifies the name of a program that,
when passed the unit to be considered treated, will drop other units that
should not be considered when forming the synthetic control.  This is usually
because they are neighboring or interfering units.  See example 3 for usage
details.

{p 4 8 2}
{cmd:xperiod_prog(}{it:string}{cmd:)} allows for setting {cmd:synth}'s
{cmd:xperiod()} option, which varies with the treatment period.  The
user-written program is passed the treatment period and should return, via
{cmd:r(xperiod)}, a {it:numlist} suitable for {cmd:synth}'s {cmd:xperiod()}
(the period over which generic predictor variables are averaged).  See
{cmd:synth} for more details on the {cmd:xperiod()} option.  See example 3 for
usage details.

{p 4 8 2}
{cmd:mspeperiod_prog(}{it:string}{cmd:)} allows for setting {cmd:synth}'s
{cmd:mspeperiod()} option, which varies with the treatment period.  The
user-written program is passed the treatment period and should return, via
{cmd:r(mspeperiod)}, a {it:numlist} suitable for {cmd:synth}'s
{cmd:mspeperiod()} (the period over which the prediction outcome is
evaluated).  See {cmd:synth} for more details on the {cmd:mspeperiod()}
option.  See example 3 for usage details.

{p 4 8 2}
{it:synthsettings} specifies pass-through options sent to {cmd:synth}.  See
{helpb synth} for more information.  The following are disallowed:
{cmd:counit()}, {cmd:figure}, {cmd:resultsperiod()}.


{title:Examples}

{p 4 4 2}
The following examples use data from the {cmd:synth} package.  Ensure that
{cmd:synth} was installed with ancillary files (for example, {cmd:ssc install}
{cmd:synth, all}).  This panel dataset contains information for 39 
U.S. States for the years 1970-2000 (see Abadie, Diamond, and Hainmueller [2010]
for details).{p_end}
{phang2}{bf:. {stata sysuse smoking}}{p_end}
{phang2}{bf:. {stata tsset state year}}{p_end}

{p 4 8 2}
Example 1 -- Reconstruct the initial {cmd:synth} example plus graphs:{p_end}

{phang2}{bf:. {stata synth_runner cigsale beer(1984(1)1988) lnincome(1972(1)1988) retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) gen_vars}}{p_end}
{phang2}{bf:. {stata single_treatment_graphs, trlinediff(-1) effects_ylabels(-30(10)30) effects_ymax(35) effects_ymin(-35)}}{p_end}
{phang2}{bf:. {stata effect_graphs, trlinediff(-1)}}{p_end}
{phang2}{bf:. {stata pval_graphs}}{p_end}

{pstd}
In this example, {cmd:synth_runner} conducts all the estimations and
inference.  Because there was only a single treatment period, we can save the
output into the dataset.  Then we can create the various graphs.  Note the
option {cmd:trlinediff()} allows the offset of a vertical treatment line.
Likely options include values in the range from (first treatment period - last
posttreatment period) to 0, and the default value is -1 (to match Abadie,
Diamond, and Hainmueller [2010]).

{p 4 8 2}
Example 2 -- Same treatment, but a bit more complicated setup:{p_end}

{phang2}{bf:. {stata capture drop pre_rmspe post_rmspe lead effect cigsale_synth}}{p_end}
{phang2}{bf:. {stata generate byte D = (state==3 & year>=1989)}}{p_end}
{phang2}{bf:. {stata synth_runner cigsale beer(1984(1)1988) lnincome(1972(1)1988) retprice age15to24, trunit(3) trperiod(1989) trends training_propr(`=13/18') gen_vars pre_limit_mult(10)}}{p_end}
{phang2}{bf:. {stata single_treatment_graphs, scaled}}{p_end}
{phang2}{bf:. {stata effect_graphs, scaled}}{p_end}
{phang2}{bf:. {stata pval_graphs}}{p_end}

{pstd}
Again, there is a single treatment period, so output can be saved and merged
back into the dataset.  In this setting, we i) specify the treated units or
periods with a binary variable; ii) generate the outcome predictors
automatically using the initial 13 periods of the pretreatment era (the rest
is the "validation" period); and iii) match on trends.{p_end}

{p 4 8 2}
Example 3 -- Multiple treatments at different time periods:{p_end}

{phang2}{bf:. {stata capture drop D}}{p_end}
{phang2}{bf:. {stata program my_pred, rclass}}{p_end}
{phang3}{bf:{stata args tyear}}{p_end}
{phang3}{bf:{stata return local predictors "beer(`=`tyear'-4'(1)`=`tyear'-1') lnincome(`=`tyear'-4'(1)`=`tyear'-1')" }}{p_end}
{phang2}{bf:{stata end}}{p_end}
{phang2}{bf:. {stata program my_drop_units}}{p_end}
{phang3}{bf:{stata args tunit}}{p_end}
{phang3}{bf:{stata if `tunit'==39 qui drop if inlist(state,21,38)}}{p_end}
{phang3}{bf:{stata if `tunit'==3 qui drop if state==21}}{p_end}
{phang2}{bf:{stata end}}{p_end}
{phang2}{bf:. {stata program my_xperiod, rclass}}{p_end}
{phang3}{bf:{stata args tyear}}{p_end}
{phang3}{bf:{stata return local xperiod "`=`tyear'-12'(1)`=`tyear'-1'"}}{p_end}
{phang2}{bf:{stata end}}{p_end}
{phang2}{bf:. {stata program my_mspeperiod, rclass}}{p_end}
{phang3}{bf:{stata args tyear}}{p_end}
{phang3}{bf:{stata return local mspeperiod "`=`tyear'-12'(1)`=`tyear'-1'"}}{p_end}
{phang2}{bf:{stata end}}{p_end}
{phang2}{bf:. {stata generate byte D = (state==3 & year>=1989) | (state==7 & year>=1988)}}{p_end}
{phang2}{bf:. {stata synth_runner cigsale retprice age15to24, d(D) pred_prog(my_pred) trends training_propr(`=13/18') drop_units_prog(my_drop_units)) xperiod_prog(my_xperiod) mspeperiod_prog(my_mspeperiod)}}{p_end}
{phang2}{bf:. {stata effect_graphs}}{p_end}
{phang2}{bf:. {stata pval_graphs}}{p_end}

{p 8 8 2}
We extend example 2 by considering a control state now to be treated (Georgia
in addition to California).  No treatment actually happened in Georgia in
1987.  Now that we have several treatment periods, we cannot merge in a simple
file.  Some graphs (of {cmd:single_treatment_graphs}) can no longer be made.
We also show how predictors, unit dropping, {cmd:xperiod()}, and
{cmd:mspeperiod()} can be dynamically generated depending on the treatment
year.


{title:Stored results}

{pstd}
{cmd:synth_runner} stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(n_pl)}}number of placebo averages used for comparison{p_end}
{synopt:{cmd:e(pval_joint_post)}}proportion of placebos that have a
posttreatment RMSPE at least as large as the average for the treated
units{p_end}
{synopt:{cmd:e(pval_joint_post_t)}}proportion of placebos that have a ratio of
posttreatment RMSPE over pretreatment RMSPE at least as large as the average
ratio for the treated units{p_end}
{synopt:{cmd:e(avg_pre_rmspe_p)}}proportion of placebos that have a
pretreatment RMSPE at least as large as the average of the treated units; the
farther this measure is from 0 toward 1, the better the relative fit of the
treated units{p_end}
{synopt:{cmd:e(avg_val_rmspe_p)}}when one specifies {cmd:training_propr()},
this is the proportion of placebos that have an RMSPE for the validation period
at least as large as the average of the treated units; the farther this measure
is from 0 toward 1, the better the relative fit of the treated units{p_end}

{syntab:Matrices}
{synopt:{cmd:e(treat_control)}}average treatment outcome (centered around
treatment) and the average of the outcome of those units' synthetic controls
for the pretreatment and posttreatment periods{p_end}
{synopt:{cmd:e(b)}}a vector with the per-period effects (unit's actual outcome
minus the outcome of its synthetic control) for posttreatment periods{p_end}
{synopt:{cmd:e(pvals)}}a vector of the proportions of placebo effects that are
at least as large as the main effect for each posttreatment period{p_end}
{synopt:{cmd:e(pvals_std)}}a vector of the proportions of placebo standardized
effects that are at least as large as the main standardized effect for each
posttreatment period{p_end}
{synopt:{cmd:e(failed_opt_targets)}}errors when constructing the synthetic
controls for nontreated units are handled gracefully; if any are detected, they
will be listed in this matrix (errors when constructing the synthetic control
for treated units will abort the method){p_end}


{title:Development}

{pstd}
If you encounter a bug in the program, please ensure you are running the most
recent version from the 
{browse "https://github.com/bquistorff/synth_runner/":GitHub site}.  If the
problem persists, see whether the bug has been previously reported at 
{browse "https://github.com/bquistorff/synth_runner/issues":https://github.com/bquistorff/synth_runner/issues}.
If not, file a new "issue" there and list i) the steps causing the problem
(with output) and ii) the version of {cmd:synth_runner} used (found from
{cmd:which synth_runner}).{p_end}

{pstd}
Contributions may also be made via a pull request from the GitHub page.{p_end}

{pstd}
To be notified of new releases, subscribe to notifications of {browse "https://github.com/bquistorff/synth_runner/issues/1":this issue}.{p_end}


{title:Citation of synth_runner}

{pstd}
{cmd:synth_runner} is not an official Stata command.  It is a free contribution
to the research community, like a article.  Please cite it as such:

{phang}
Quistorff, B. and S. Galiani. 2017.
{browse "http://www.stata-journal.com/article.html?article=st0500":The synth_runner package: Utilities to automate synthetic control estimation using synth.}
{it:Stata Journal} 17: 834-849.


{title:References}

{phang}
Abadie, A., A. Diamond, and J. Hainmueller. 2010. Synthetic control methods
for comparative case studies: Estimating the effect of California's tobacco
control program. {it:Journal of the American Statistical Association} 
105: 493-505.

{phang}
------. 2015. Comparative politics and the synthetic control method. 
{it:American Journal of Political Science} 59: 495-510.

{phang}
Abadie, A. and J. Gardeazabal. 2003. The economic costs of conflict: A case study of the Basque country. {it:American Economic Review} 93: 113-132.

{phang}
Cavallo, E., S. Galiani, I. Noy, and J. Pantano. 2013. Catastrophic
natural disasters and economic growth. 
{it:Review of Economics and Statistics} 95: 1549-1561.


{title:Authors}

{pstd}
Brian Quistorff{break}
Microsoft AI and Research{break}
Redmond, WA{break}
Brian.Quistorff@microsoft.com{break}
(corresponding author, see Development section for reporting bugs)

{pstd}
Sebastian Galiani{break}
University of Maryland{break}
College Park, MD{break}
galiani@econ.umd.edu


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 4: {browse "http://www.stata-journal.com/article.html?article=st0500":st0500}{p_end}

{p 7 14 2}
Help:  {helpb effect_graphs},
{helpb pval_graphs},
{helpb single_treatment_graphs}
(if installed){p_end}
