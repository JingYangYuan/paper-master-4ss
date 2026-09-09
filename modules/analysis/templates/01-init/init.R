# Initialize the Paper Analysis 4SS workspace.

find_shared <- function() {
  cmd <- commandArgs(FALSE)
  file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat {
    candidate <- file.path(p, "_shared", "r_common.R")
    if (file.exists(candidate)) return(candidate)
    next_p <- dirname(p)
    if (identical(next_p, p)) stop("Cannot locate templates/_shared/r_common.R")
    p <- next_p
  }
}
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
source(find_shared())

args <- parse_common_args()
ensure_dirs(args$out_root)
report <- file.path(args$out_root, "reports", paste0("analysis-init-", Sys.Date(), ".md"))
write_md(report, "Analysis Init", c(
  "输入" = paste0("data=", ifelse(is.na(args$data), "未指定", args$data), "\n\nplan=", ifelse(is.na(args$plan), "未指定", args$plan)),
  "下一步" = "进入 02-clean-describe，先完成变量发现、清洗报告和 analysis-data.*。"
))
log_run(args, "01-init", "ok", report, "初始化分析输出目录。")
