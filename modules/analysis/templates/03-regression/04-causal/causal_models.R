# Run configured causal identification strategies.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
data_path <- if (!is.na(args$data) && file.exists(args$data)) args$data else file.path(args$out_root, "data", "analysis-data.csv")
if (!file.exists(data_path)) { log_run(args, "03-regression/04-causal", "blocked", "-", paste("缺少数据:", data_path)); quit(status = 2) }
df <- load_data(data_path); roles <- infer_roles(df, args$dict)
mods <- list(); blockers <- c()
mods$IV <- tryCatch(run_iv_2sls(df, roles), error = function(e) { blockers <<- c(blockers, paste("IV:", e$message)); NULL })
mods$DID <- tryCatch(run_twfe_did(df, roles), error = function(e) { blockers <<- c(blockers, paste("DID:", e$message)); NULL })
mods$RDD <- tryCatch(run_rdrobust(df, roles), error = function(e) { blockers <<- c(blockers, paste("RDD:", e$message)); NULL })
mods$IPW <- tryCatch(run_weightit_ipw(df, roles), error = function(e) { blockers <<- c(blockers, paste("IPW:", e$message)); NULL })
mods <- mods[!vapply(mods, is.null, logical(1))]
if (!length(mods)) {
  report <- write_md(file.path(args$out_root, "reports", "causal-blockers.md"), "Causal Blockers", c("阻断" = paste(blockers, collapse = "\n")))
  log_run(args, "03-regression/04-causal", "blocked", report, "没有可执行的识别策略。")
  quit(status = 2)
}
table <- export_models(mods, file.path(args$out_root, "tables", "tableA1-causal-robustness.csv"), "Table A1 Causal Robustness", roles$controls, roles$fe, roles$cluster)
summary_path <- write_md(file.path(args$out_root, "reports", "causal-results.md"), "Causal Results", lapply(mods, function(m) paste(capture.output(summary(m)), collapse = "\n")))
log_run(args, "03-regression/04-causal", "ok", c(table, summary_path), "已运行可配置的 IV/DID/RDD/IPW。")
