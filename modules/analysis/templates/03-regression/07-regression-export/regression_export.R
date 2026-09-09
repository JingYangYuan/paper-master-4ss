# Aggregate real regression products without re-estimating models.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
required <- c("data/analysis-data.csv", "data/variable-dictionary.csv", "tables/sample-flow.csv", "tables/table1-descriptives.csv", "tables/table2-main-regression.csv", "tables/table3-nonlinear-marginal-effects.csv", "tables/table3-mechanism-mediation-moderation.csv", "tables/table4-heterogeneity-threshold-nonlinear.csv", "tables/tableA1-causal-robustness.csv")
missing <- required[!file.exists(file.path(args$out_root, required))]
script_index <- write_md(file.path(args$out_root, "reports", "script-index.md"), "Script Index", c("子流程" = "00-plan-dispatch -> 01-main-models -> 02-nonlinear -> 03-panel -> 04-causal -> 05-mechanism-heterogeneity -> 06-robustness -> 07-regression-export"))
missing_report <- write_md(file.path(args$out_root, "reports", "missing-regression-products.md"), "Missing Regression Products", c("缺失产物" = ifelse(length(missing), paste(missing, collapse = "\n"), "无缺失产物。")))
results <- write_md(file.path(args$out_root, "reports", paste0("regression-results-", Sys.Date(), ".md")), "Regression Results", c("可声称内容" = "只声称 run-log 记录且产物存在的模型结果。", "缺失或阻断" = ifelse(length(missing), paste(missing, collapse = "\n"), "无缺失产物。")))
log_run(args, "03-regression/07-regression-export", ifelse(length(missing), "partial", "ok"), c(script_index, missing_report, results), "未重新估计模型。")
