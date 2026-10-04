# Run configured causal identification strategies.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
data_path <- if (is.na(args$data)) file.path(args$out_root, "data", "analysis-data.csv") else args$data
df <- load_data(data_path); roles <- infer_roles(df, args$dict)
mods <- list()
mods$IV <- run_iv_2sls(df, roles)
mods$DID <- run_twfe_did(df, roles)
mods$RDD <- run_rdrobust(df, roles)
mods$IPW <- run_weightit_ipw(df, roles)
table <- export_models(mods, file.path(args$out_root, "tables", "tableA1-causal-robustness.csv"), "Table A1 Causal Robustness", roles$controls, roles$fe, roles$cluster)
summary_path <- write_md(file.path(args$out_root, "reports", "causal-results.md"), "Causal Results", lapply(mods, function(m) paste(capture.output(summary(m)), collapse = "\n")))
