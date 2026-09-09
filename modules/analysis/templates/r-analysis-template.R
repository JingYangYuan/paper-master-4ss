# Lightweight index for Paper Analysis 4SS R templates.
#
# Implementation templates now live under flow/subflow directories. This file
# is kept as a migration entrypoint and does not run cleaning, regression,
# causal identification, or export logic directly.

templates <- c(
  "01-init/init.R",
  "02-clean-describe/cleaning.R",
  "03-regression/00-plan-dispatch/plan_dispatch.R",
  "03-regression/01-main-models/main_models.R",
  "03-regression/02-nonlinear/nonlinear_models.R",
  "03-regression/03-panel/panel_models.R",
  "03-regression/04-causal/causal_models.R",
  "03-regression/05-mechanism-heterogeneity/mechanism_heterogeneity.R",
  "03-regression/06-robustness/robustness.R",
  "03-regression/07-regression-export/regression_export.R",
  "04-qual/qual_analysis.R",
  "05-mixed/mixed_methods.R",
  "06-export/export_quality.R"
)

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args || "-h" %in% args) {
  cat("Usage: Rscript r-analysis-template.R [--list]\n")
  cat("Run concrete subflow scripts with their common arguments: --data --plan --dict --out-root --run-log --slug --tasks\n")
  quit(status = 0)
}

cmd <- commandArgs(FALSE)
file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
root <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
cat("Paper Analysis 4SS R templates are split by flow/subflow:\n")
for (item in templates) cat("- ", file.path(root, item), "\n", sep = "")
cat("\nCopy/adapt concrete subflow scripts into paper-workspace/04-analysis/scripts/ before production execution.\n")
