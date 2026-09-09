# Run robustness checks.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
data_path <- if (!is.na(args$data) && file.exists(args$data)) args$data else file.path(args$out_root, "data", "analysis-data.csv")
if (!file.exists(data_path)) { log_run(args, "03-regression/06-robustness", "blocked", "-", paste("缺少数据:", data_path)); quit(status = 2) }
df <- load_data(data_path); roles <- infer_roles(df, args$dict)
mods <- run_robustness(df, roles)
table <- export_models(mods, file.path(args$out_root, "tables", "tableA-robustness.csv"), "Table A Robustness", roles$controls, roles$fe, roles$cluster)
cannot <- write_md(file.path(args$out_root, "reports", "cannot-claim-list.md"), "Cannot Claim List", c("不可声称" = "未在本脚本中成功运行的替代变量、替代样本、安慰剂和敏感性分析，不得写入结论。"))
log_run(args, "03-regression/06-robustness", "ok", c(table, cannot), "已真实运行基线稳健性变体。")
