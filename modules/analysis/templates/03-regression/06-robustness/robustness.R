# Run robustness: inference (wild bootstrap, multiplicity), sensitivity (Oster, sensemakr) and alternatives.

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

# ---- 表A：基准与替代口径 ----
mods <- run_robustness(df, roles)
tA <- export_models(mods, file.path(out, "tables", "tableA-robustness.csv"), "Table A Robustness",
                    roles$controls, roles$fe, roles$cluster)

# ---- 表A-inference：推断稳健性与多重检验校正 ----
wb <- tryCatch(run_wild_boot(df, roles), error = function(e) NULL)
pvals <- vapply(c("age", "gender", "education", "income"), function(v) {
  if (!v %in% names(df)) return(NA_real_)
  fit <- run_ols(df, roles$y, v, c(roles$x, setdiff(roles$controls, v)), roles$fe, roles$cluster)
  tb <- pmfit_table(fit); r <- tb[tb$term == v, ]
  if (nrow(r)) r$p.value[1] else NA_real_
}, numeric(1))
adj <- run_multiplicity(pvals, "holm")
dir.create(file.path(out, "tables"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(data.frame(
  方法 = c("Wild cluster bootstrap", "Romano-Wolf / Westfall-Young", "多重检验校正（Holm）"),
  内容 = c(if (is.null(wb)) "未运行（fwildclusterboot 不可用）" else sprintf("bootstrap p = %.4f，95%% CI [%.4f, %.4f]，reps=%d", wb$p.value, wb$conf.low, wb$conf.high, wb$reps),
           "R 侧无 wyoung/rwolf 等价实现，改用 p.adjust 的 Holm/BH 校正",
           paste(sprintf("%s: p=%.4f -> adj=%.4f", names(pvals), pvals, adj), collapse = "; "))),
  file.path(out, "tables", "tableA-robustness-inference.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# ---- 表A-sensitivity：未观测混淆敏感性 ----
oster <- tryCatch(run_oster(df, roles), error = function(e) NULL)
smk <- tryCatch(run_sensemakr(df, roles), error = function(e) NULL)
utils::write.csv(data.frame(
  方法 = c("Oster delta (robomit)", "Oster beta (robomit)", "sensemakr"),
  内容 = c(if (is.null(oster)) "未运行" else paste(utils::capture.output(print(oster$delta))[1:3], collapse = " "),
           if (is.null(oster)) "未运行" else paste(utils::capture.output(print(oster$beta))[1:3], collapse = " "),
           if (is.null(smk)) "未运行" else sprintf("RV q=1: %.4f；基准协变量强度下的界见日志", tryCatch(smk$sensitivity_stats$rv_q, error = function(e) NA_real_))),
  说明 = c("使用 robomit::o_delta/o_beta", "使用 robomit::o_delta/o_beta", "使用 sensemakr::sensemakr")),
  file.path(out, "tables", "tableA-robustness-sensitivity.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# ---- 表A-alternatives：替代样本窗口、标准误与估计量 ----
alt <- list()
alt[["(1) Baseline"]] <- run_ols(df, roles$y, roles$x, roles$controls, roles$fe, roles$cluster)
if (!is.na(roles$time)) alt[["(2) Subsample (recent)"]] <- run_ols(df[df[[roles$time]] >= stats::median(df[[roles$time]], na.rm = TRUE), , drop = FALSE], roles$y, roles$x, roles$controls, roles$fe, roles$cluster)
alt[["(3) Cluster by id"]] <- run_ols(df, roles$y, roles$x, roles$controls, roles$fe, roles$id)
alt[["(4) No cluster"]] <- run_ols(df, roles$y, roles$x, roles$controls, roles$fe, NA_character_)
alt[["(5) Winsorised"]] <- {
  d <- df
  qs <- stats::quantile(d[[roles$y]], c(.005, .995), na.rm = TRUE)
  d[[roles$y]] <- pmin(pmax(d[[roles$y]], qs[[1]]), qs[[2]])
  run_ols(d, roles$y, roles$x, roles$controls, roles$fe, roles$cluster)
}
alt[["(6) Quantile 0.5"]] <- tryCatch({
  if (!requireNamespace("quantreg", quietly = TRUE)) stop("quantreg required")
  mod <- quantreg::rq(stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls)))), data = df, tau = .5)
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = tryCatch(stats::vcov(mod), error = function(e) NULL), nobs = stats::nobs(mod),
        terms = names(b), model = mod, data = df)
}, error = function(e) NULL)
alt <- Filter(Negate(is.null), alt)
tAlt <- export_models(alt, file.path(out, "tables", "tableA-robustness-alternatives.csv"),
                      "Table A Robustness Alternatives", roles$controls, roles$fe, roles$cluster)

# ---- 不可声称清单 ----
cannot <- write_md(file.path(out, "reports", "cannot-claim-list.md"), "Cannot Claim List",
                   c("不可声称" = "未在本脚本中成功运行的替代变量、替代样本、安慰剂和敏感性分析，不得写入结论。",
                     "本脚本已运行" = paste(names(alt), collapse = "、"),
                     "R 侧生态差异" = "Ramyong 等：R 侧不提供 wyoung/rwolf 的等价实现，多重检验用 p.adjust 的 Holm/BH 校正替代，不得声称与 Stata 的 Romano-Wolf 结果一致。"))
