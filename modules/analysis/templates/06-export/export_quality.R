# Export analysis package and enforce quality gates.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
required <- c("data/analysis-data.csv", "data/variable-dictionary.csv", "tables/sample-flow.csv", "tables/table1-descriptives.csv", "tables/table2-main-regression.csv")
missing <- required[!file.exists(file.path(args$out_root, required))]
report <- write_md(file.path(args$out_root, "reports", paste0("analysis-quality-gates-", Sys.Date(), ".md")), "Analysis Quality Gates", c("通过" = ifelse(length(missing), "部分产物缺失。", "所有核心产物存在。"), "缺失" = ifelse(length(missing), paste(missing, collapse = "\n"), "无"), "结论边界" = "只有 run-log 记录为 ok 且产物存在的结果可以进入论文结论。"))
log_run(args, "06-export", ifelse(length(missing), "partial", "ok"), report, "已执行质量门控。")
