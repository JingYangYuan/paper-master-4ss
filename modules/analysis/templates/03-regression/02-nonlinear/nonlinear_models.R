# Run nonlinear models and export marginal-effect-style tables.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
data_path <- if (!is.na(args$data) && file.exists(args$data)) args$data else file.path(args$out_root, "data", "analysis-data.csv")
if (!file.exists(data_path)) { log_run(args, "03-regression/02-nonlinear", "blocked", "-", paste("缺少数据:", data_path)); quit(status = 2) }
df <- load_data(data_path); roles <- infer_roles(df, args$dict)
mods <- list(); blockers <- c()
yvals <- unique(stats::na.omit(df[[roles$y]]))
if (all(yvals %in% c(0, 1))) {
  mods$Logit <- tryCatch(run_logit_ame(df, roles$y, roles$x, roles$controls, roles$fe), error = function(e) { blockers <<- c(blockers, paste("Logit:", e$message)); NULL })
  mods$Probit <- tryCatch(run_probit_ame(df, roles$y, roles$x, roles$controls, roles$fe), error = function(e) { blockers <<- c(blockers, paste("Probit:", e$message)); NULL })
}
if (min(df[[roles$y]], na.rm = TRUE) >= 0) mods$Poisson <- tryCatch(run_poisson(df, roles$y, roles$x, roles$controls, roles$fe), error = function(e) { blockers <<- c(blockers, paste("Poisson:", e$message)); NULL })
mods <- mods[!vapply(mods, is.null, logical(1))]
if (!length(mods)) {
  report <- write_md(file.path(args$out_root, "reports", "nonlinear-blockers.md"), "Nonlinear Blockers", c("阻断" = paste(blockers, collapse = "\n")))
  log_run(args, "03-regression/02-nonlinear", "blocked", report, "未能估计非线性模型。")
  quit(status = 2)
}
table <- export_models(mods, file.path(args$out_root, "tables", "table3-nonlinear-marginal-effects.csv"), "Table 3 Nonlinear Marginal Effects", roles$controls, roles$fe, roles$cluster)
summary_path <- write_md(file.path(args$out_root, "reports", "nonlinear-models-results.md"), "Nonlinear Models Results", lapply(mods, function(m) paste(capture.output(summary(m)), collapse = "\n")))
log_run(args, "03-regression/02-nonlinear", "ok", c(table, summary_path), "已真实估计非线性模型；表格用于边际效应/预测概率复核。")
