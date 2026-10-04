# Run panel fixed-effect style models after id/time roles are confirmed.

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
mod <- run_panel_fe(df, roles)
table <- export_models(list("(1) TWFE" = mod), file.path(args$out_root, "tables", "tableA-panel-models.csv"), "Table A Panel Models", roles$controls, c(roles$id, roles$time), roles$cluster)
diag <- write_md(file.path(args$out_root, "reports", "panel-diagnostics.md"), "Panel Diagnostics", c("TWFE" = paste(capture.output(summary(mod)), collapse = "\n")))
