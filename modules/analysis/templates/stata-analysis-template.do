* Lightweight index for Paper Analysis 4SS Stata templates.
* The implementation templates now live under flow/subflow directories.
* This file is kept as a migration entrypoint and does not run cleaning,
* regression, causal identification, or export logic directly.

version 16
clear all

local project_root "`c(pwd)'"
if `"`: environment PROJECT_ROOT'"' != "" {
    local project_root "`: environment PROJECT_ROOT'"
}
global OUT_ROOT "`project_root'/paper-workspace/04-analysis"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"
capture mkdir "`project_root'/paper-workspace"
capture mkdir "`project_root'/paper-workspace/04-analysis"
capture mkdir "${OUT_ROOT}/reports"

display "Paper Analysis 4SS Stata templates are split by flow/subflow:"
display "01-init/init.do"
display "02-clean-describe/cleaning.do"
display "03-regression/00-plan-dispatch/plan_dispatch.do"
display "03-regression/01-main-models/main_models.do"
display "03-regression/02-nonlinear/nonlinear_models.do"
display "03-regression/03-panel/panel_models.do"
display "03-regression/04-causal/causal_models.do"
display "03-regression/05-mechanism-heterogeneity/mechanism_heterogeneity.do"
display "03-regression/06-robustness/robustness.do"
display "03-regression/07-regression-export/regression_export.do"
display "04-qual/qual_analysis.do"
display "05-mixed/mixed_methods.do"
display "06-export/export_quality.do"
display "Copy/adapt concrete subflow scripts into paper-workspace/04-analysis/scripts/ before production execution."

capture file open flog using "${RUN_LOG}", write append
if _rc == 0 {
    file write flog "| `c(current_date)' | stata-analysis-template | index | - | 旧入口仅列出流程脚本；未运行模型，真实执行请调用子流程 .do。 |" _n
    file close flog
}
