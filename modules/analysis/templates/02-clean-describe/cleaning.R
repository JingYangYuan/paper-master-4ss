# Read, clean, describe, and save analysis data.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
if (is.na(args$data) || !file.exists(args$data)) {
  report <- write_md(file.path(args$out_root, "reports", paste0("cleaning-report-", Sys.Date(), ".md")), "Cleaning Report", c("阻断" = "缺少 --data 或数据文件不存在。"))
  log_run(args, "02-clean-describe", "blocked", report, "缺少可执行数据输入。")
  quit(status = 2)
}
raw <- load_data(args$data)
cleaned <- clean_data(raw)
roles <- infer_roles(cleaned, args$dict)
dict_path <- write_variable_dictionary(cleaned, roles, args$data, args$out_root)
sample <- sample_flow(cleaned, roles, args$out_root)
data_path <- file.path(args$out_root, "data", "analysis-data.csv")
write_csv_safe(sample, data_path)
table1 <- make_table1(sample, c(roles$y, roles$x, roles$controls), args$out_root)
report <- write_md(file.path(args$out_root, "reports", paste0("cleaning-report-", Sys.Date(), ".md")),
                   "Cleaning Report",
                   c("数据输入" = args$data,
                     "样本" = paste0("raw N=", nrow(raw), "; analysis N=", nrow(sample)),
                     "变量角色" = paste(capture.output(str(roles)), collapse = "\n"),
                     "清洗规则" = "列名标准化、特殊缺失码转 NA、数值变量 1%/99% 缩尾、去重、删除 Y/X/control 缺失。"))
log_run(args, "02-clean-describe", "ok", c(data_path, dict_path, table1, report), "已真实读取、清洗并生成描述统计。")
