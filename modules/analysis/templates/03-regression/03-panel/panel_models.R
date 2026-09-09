# Run panel fixed-effect style models after id/time roles are confirmed.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
data_path <- if (!is.na(args$data) && file.exists(args$data)) args$data else file.path(args$out_root, "data", "analysis-data.csv")
if (!file.exists(data_path)) { log_run(args, "03-regression/03-panel", "blocked", "-", paste("缺少数据:", data_path)); quit(status = 2) }
df <- load_data(data_path); roles <- infer_roles(df, args$dict)
if (is.na(roles$id) || is.na(roles$time)) {
  report <- write_md(file.path(args$out_root, "reports", "panel-diagnostics.md"), "Panel Diagnostics", c("阻断" = "缺少 id/time 角色；不得猜测面板结构。"))
  log_run(args, "03-regression/03-panel", "blocked", report, "缺少 id/time。")
  quit(status = 2)
}
mod <- run_panel_fe(df, roles)
table <- export_models(list("(1) TWFE" = mod), file.path(args$out_root, "tables", "tableA-panel-models.csv"), "Table A Panel Models", roles$controls, c(roles$id, roles$time), roles$cluster)
diag <- write_md(file.path(args$out_root, "reports", "panel-diagnostics.md"), "Panel Diagnostics", c("TWFE" = paste(capture.output(summary(mod)), collapse = "\n")))
log_run(args, "03-regression/03-panel", "ok", c(table, diag), "已真实估计双向固定效应近似模型。")
