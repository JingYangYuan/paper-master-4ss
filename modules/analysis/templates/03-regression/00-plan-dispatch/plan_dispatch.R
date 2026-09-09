# Read analysis-execution-plan and create regression dispatch files.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
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
source(find_shared())

args <- parse_common_args()
ensure_dirs(args$out_root)
plan <- if (!is.na(args$plan) && file.exists(args$plan)) args$plan else list.files(file.path(args$out_root, "reports"), pattern = "^analysis-execution-plan.*\\.md$", full.names = TRUE)
plan <- if (length(plan)) tail(sort(plan), 1) else NA_character_
txt <- if (!is.na(plan) && file.exists(plan)) paste(readLines(plan, warn = FALSE), collapse = "\n") else ""
dict_path <- if (!is.na(args$dict) && file.exists(args$dict)) args$dict else file.path(args$out_root, "data", "variable-dictionary.csv")
dict_n <- if (file.exists(dict_path)) nrow(utils::read.csv(dict_path, stringsAsFactors = FALSE)) else 0
cleaning <- list.files(file.path(args$out_root, "reports"), pattern = "^cleaning-report.*\\.md$", full.names = TRUE)
cleaning <- if (length(cleaning)) tail(sort(cleaning), 1) else NA_character_
rules <- list(
  main = c("Y", "X", "control", "fe", "cluster", "weight", "主回归", "描述统计"),
  nonlinear = c("nonlinear", "logit", "probit", "poisson", "tobit", "heckman", "有序", "多分类"),
  panel = c("id", "time", "panel", "FE", "RE", "Hausman", "面板"),
  causal = c("instrument", "treatment", "post", "running", "cutoff", "IV", "DID", "RDD", "PSM", "CEM", "IPW", "SCM"),
  mechanism_heterogeneity = c("mediator", "mechanism", "moderator", "heterogeneity", "threshold", "中介", "机制", "调节", "异质性", "门槛", "交互", "分组"),
  robustness = c("robustness", "placebo", "sensitivity", "替代变量", "替代样本", "替代模型", "稳健性", "安慰剂")
)
rows <- do.call(rbind, lapply(names(rules), function(task) {
  hit <- rules[[task]][vapply(rules[[task]], grepl, logical(1), x = txt, ignore.case = TRUE, fixed = TRUE)]
  data.frame(task = task, run = ifelse(length(hit), "yes", "blocked"), evidence = ifelse(length(hit), paste(hit, collapse = "; "), "analysis-execution-plan 未发现触发角色"), blocker = ifelse(length(hit), "", "缺少变量角色或设计信号；回流变量发现/清洗复核"))
}))
csv_path <- file.path(args$out_root, "reports", "regression-dispatch.csv")
json_path <- file.path(args$out_root, "reports", "regression-dispatch.json")
decision <- file.path(args$out_root, "reports", paste0("model-decision-", Sys.Date(), ".md"))
write_csv_safe(rows, csv_path)
writeLines(paste0('{"plan":"', plan, '","variable_count":', dict_n, ',"cleaning_report":"', cleaning, '","note":"R 模板生成；JSON 详情可由 Python 版本重写。"}'), json_path)
write_md(decision, "Model Decision", c("来源计划" = ifelse(is.na(plan), "未找到 analysis-execution-plan-[date].md", plan), "变量字典与清洗报告" = paste0("变量字典行数：", dict_n, "\n\n清洗报告：", ifelse(is.na(cleaning), "未找到 cleaning-report-[date].md", cleaning)), "模型派发" = paste(rows$task, rows$run, rows$evidence, collapse = "\n"), "阻断" = paste(rows$blocker[rows$blocker != ""], collapse = "\n")))
status <- ifelse(nzchar(txt), "ok", "blocked")
log_run(args, "03-regression/00-plan-dispatch", status, c(csv_path, json_path, decision), "不运行统计模型，只生成 dispatch。")
if (status == "blocked") quit(status = 2)
