# Build mixed-methods joint display from real quantitative and qualitative products.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
table2 <- file.path(args$out_root, "tables", "table2-main-regression.csv")
coded <- list.files(file.path(args$out_root, "qual/coded-data"), pattern = "^coded-excerpts-.*\\.csv$", full.names = TRUE)
if (!file.exists(table2) || !length(coded)) {
  report <- write_md(file.path(args$out_root, "reports", paste0("mixed-methods-blockers-", Sys.Date(), ".md")), "Mixed Methods Blockers", c("阻断" = paste0("table2 exists=", file.exists(table2), "; coded data exists=", length(coded) > 0)))
  log_run(args, "05-mixed", "blocked", report, "缺少定量表或质性编码表。")
  quit(status = 2)
}
cd <- utils::read.csv(tail(sort(coded), 1), stringsAsFactors = FALSE)
themes <- unique(cd$code[nzchar(cd$code)])
if (!length(themes)) themes <- "待人工编码主题"
joint <- data.frame(quant_finding = table2, qual_theme = themes, integration = "待基于真实系数方向和编码摘录撰写整合解释", claim_status = "pending-review")
joint_path <- write_csv_safe(joint, file.path(args$out_root, "tables", "mixed-joint-display.csv"))
report <- write_md(file.path(args$out_root, "reports", paste0("mixed-methods-integration-", Sys.Date(), ".md")), "Mixed Methods Integration", c("joint display" = joint_path, "说明" = "本脚本只整合真实产物，不生成未经编码支持的主题结论。"))
log_run(args, "05-mixed", "ok", c(joint_path, report), "已基于真实定量表和质性编码表生成 joint display。")
