# Run nonlinear models and export marginal-effect tables.
# 覆盖：二元 logit/probit AME、Poisson/NB 计数、有序 logit/probit、多分类 logit、
#       Tobit、Heckman 样本选择、fractional logit、Weibull/Cox 持续时间模型。

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
out <- args$out_root

bin_y <- if ("outcome_bin" %in% names(df)) "outcome_bin" else roles$y
ord_y <- if ("outcome_ord" %in% names(df)) "outcome_ord" else roles$y
multi_y <- if ("outcome_multi" %in% names(df)) "outcome_multi" else roles$y
count_y <- if ("outcome_count" %in% names(df)) "outcome_count" else roles$y
prop_y <- if ("prop_outcome" %in% names(df)) "prop_outcome" else roles$y
cens_y <- if ("duration" %in% names(df)) "duration" else roles$y
dur_y <- cens_y
dur_fail <- if ("event" %in% names(df)) "event" else NA_character_

# ---- 表3：二元与计数模型的真实平均边际效应 ----
mods <- list(
  "Logit AME" = run_logit_ame(df, bin_y, roles$x, roles$controls, roles$fe, roles$cluster),
  "Probit AME" = run_probit_ame(df, bin_y, roles$x, roles$controls, roles$fe, roles$cluster),
  "Poisson ME" = run_poisson(df, count_y, roles$x, roles$controls, roles$fe, roles$cluster)
)
t3 <- export_ame(mods, file.path(out, "tables", "table3-nonlinear-marginal-effects.csv"), "Table 3 Nonlinear Marginal Effects")

# ---- 表3b：有序与多分类 ----
mods_3b <- list(
  "Ordered logit" = run_ologit(df, ord_y, roles$x, roles$controls, roles$cluster),
  "Ordered probit" = run_oprobit(df, ord_y, roles$x, roles$controls, roles$cluster),
  "Multinomial logit" = run_mlogit(df, multi_y, roles$x, roles$controls, roles$cluster)
)
t3b <- export_models(mods_3b, file.path(out, "tables", "table3b-ordered-multinomial.csv"),
                     "Table 3b Ordered Multinomial", roles$controls, character(), roles$cluster)

# ---- 表3c：删失与样本选择 ----
mods_3c <- list(
  "Tobit" = run_tobit(df, cens_y, roles$x, roles$controls, roles$cluster),
  "Heckman" = run_heckman(df, roles),
  "Fractional logit" = run_fracreg(df, prop_y, roles$x, roles$controls, roles$cluster)
)
t3c <- export_models(mods_3c, file.path(out, "tables", "table3c-censored-selection.csv"),
                     "Table 3c Censored Selection", roles$controls, character(), roles$cluster)

# ---- 表3d：计数、比例与持续时间 ----
mods_3d <- list(
  "Negative binomial" = run_nbreg(df, count_y, roles$x, roles$controls, roles$cluster),
  "Fractional logit" = run_fracreg(df, prop_y, roles$x, roles$controls, roles$cluster),
  "Weibull duration" = run_duration(df, dur_y, roles$x, roles$controls, roles$cluster, event = NULL),
  "Cox duration" = if (!is.na(dur_fail)) run_duration(df, dur_y, roles$x, roles$controls, roles$cluster, event = dur_fail) else NULL
)
mods_3d <- mods_3d[!vapply(mods_3d, is.null, logical(1))]
t3d <- export_models(mods_3d, file.path(out, "tables", "table3d-count-fractional-duration.csv"),
                     "Table 3d Count Fractional Duration", roles$controls, character(), roles$cluster)

# ---- 表3e：非线性诊断 ----
diag_rows <- list(c("诊断项", "logit", "probit", "ordered logit", "ordered probit", "multinomial", "poisson", "nbreg"))
gof <- function(m) {
  ll <- tryCatch(as.numeric(stats::logLik(m)), error = function(e) NA_real_)
  k <- tryCatch(as.numeric(attr(stats::logLik(m), "df")), error = function(e) NA_real_)
  n <- tryCatch(as.numeric(stats::nobs(m)), error = function(e) NA_real_)
  data.frame(aic = ifelse(is.na(ll), NA_real_, -2 * ll + 2 * k),
             bic = ifelse(is.na(ll) || is.na(n), NA_real_, -2 * ll + k * log(n)),
             row.names = NULL)
}
llm <- list(
  run_logit_ame(df, bin_y, roles$x, roles$controls, character(), roles$cluster),
  run_probit_ame(df, bin_y, roles$x, roles$controls, character(), roles$cluster),
  run_ologit(df, ord_y, roles$x, roles$controls, roles$cluster),
  run_oprobit(df, ord_y, roles$x, roles$controls, roles$cluster),
  run_mlogit(df, multi_y, roles$x, roles$controls, roles$cluster),
  run_poisson(df, count_y, roles$x, roles$controls, character(), roles$cluster),
  run_nbreg(df, count_y, roles$x, roles$controls, roles$cluster)
)
fmtc <- function(x) if (is.na(x) || is.null(x)) "." else sprintf("%9.3f", x)
diag_rows <- c(diag_rows, list(c("AIC", vapply(llm, function(m) fmtc(gof(m$model)$aic), character(1)))))
diag_rows <- c(diag_rows, list(c("BIC", vapply(llm, function(m) fmtc(gof(m$model)$bic), character(1)))))
# 二元模型的分类正确率与 AUC
class_rate <- function(m, y) {
  pr <- tryCatch(stats::predict(m$model, type = "response"), error = function(e) NULL)
  if (is.null(pr)) return(NA_real_)
  mean((pr >= 0.5) == as.integer(y > 0.5))
}
auc_of <- function(m, y) {
  pr <- tryCatch(stats::predict(m$model, type = "response"), error = function(e) NULL)
  if (is.null(pr)) return(NA_real_)
  r <- rank(pr); n1 <- sum(y > 0.5); n0 <- length(y) - n1
  if (n1 == 0 || n0 == 0) return(NA_real_)
  (sum(r[y > 0.5]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
diag_rows <- c(diag_rows, list(c("分类正确率", sprintf("%9.4f", class_rate(llm[[1]], df[[bin_y]])),
                                 sprintf("%9.4f", class_rate(llm[[2]], df[[bin_y]])), "", "", "", "", "")))
diag_rows <- c(diag_rows, list(c("AUC", sprintf("%9.4f", auc_of(llm[[1]], df[[bin_y]])), "", "", "", "", "", "")))
diag_rows <- c(diag_rows, list(c("过度离散 theta (nbreg)", rep("", 6), fmtc(llm[[7]]$extra$theta))))
diag_rows <- c(diag_rows, list(c("注：R 侧用 MASS::polr/nnet::multinom/glm.nb、AER::tobit、sampleSelection::heckman、survival。分类正确率与 AUC 仅对二元模型适用。", rep("", 7))))
mat <- do.call(rbind, lapply(diag_rows, function(x) c(x, rep("", 8 - length(x)))))
dir.create(file.path(out, "tables"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(mat, file.path(out, "tables", "table3e-nonlinear-diagnostics.csv"), row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")

summary_path <- write_md(file.path(out, "reports", "nonlinear-models-results.md"), "Nonlinear Models Results",
                         lapply(c(mods, mods_3b, mods_3c, mods_3d), function(m) paste(capture.output(summary(m)), collapse = "\n")))
