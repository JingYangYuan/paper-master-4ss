# Run descriptives, baseline OLS, fixed effects, and diagnostics.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
data_path <- if (!is.na(args$data) && file.exists(args$data)) args$data else file.path(args$out_root, "data", "analysis-data.csv")
if (!file.exists(data_path)) { log_run(args, "03-regression/01-main-models", "blocked", "-", paste("缺少数据:", data_path)); quit(status = 2) }
df <- load_data(data_path)
roles <- infer_roles(df, args$dict)
table1 <- make_table1(df, c(roles$y, roles$x, roles$controls), args$out_root)
m1 <- run_ols(df, roles$y, roles$x)
m2 <- run_ols(df, roles$y, roles$x, roles$controls)
m3 <- run_ols(df, roles$y, roles$x, roles$controls, roles$fe, roles$cluster)
table2 <- export_models(list("(1)" = m1, "(2)" = m2, "(3)" = m3), file.path(args$out_root, "tables", "table2-main-regression.csv"), "Table 2 Main Regression", roles$controls, roles$fe, roles$cluster)
summary_path <- write_md(file.path(args$out_root, "reports", "main-models-results.md"),
                         "Main Models Results",
                         c("M1" = paste(capture.output(summary(m1)), collapse = "\n"),
                           "M2" = paste(capture.output(summary(m2)), collapse = "\n"),
                           "M3" = paste(capture.output(summary(m3)), collapse = "\n")))
log_run(args, "03-regression/01-main-models", "ok", c(table1, table2, summary_path), "已真实估计主回归。")
