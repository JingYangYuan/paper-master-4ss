# Run mechanism (Jiang Ting two-step), mediation robustness, moderation, group difference and threshold grid.

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

# ---- 表3：机制（江艇两步法）与调节；列序必须与 Stata 完全一致 ----
mech <- run_mediation(df, roles)
mods <- list()
mods[["mech_step1"]] <- mech$total
mods[["mech_m1"]] <- mech$path_a
# 第二个机制渠道（若存在 mediator2）
if ("mediator2" %in% names(df)) {
  mods[["mech_m2"]] <- run_ols(df, "mediator2", roles$x, roles$controls, roles$fe, roles$cluster)
}
mods[["mod_omitted"]] <- run_interaction(df, roles)
df$.cX <- df[[roles$x]] - mean(df[[roles$x]], na.rm = TRUE)
df$.cMOD <- df[[roles$moderator]] - mean(df[[roles$moderator]], na.rm = TRUE)
df$.cJC <- df$.cX * df$.cMOD
mods[["mod_corrected"]] <- run_ols(df, roles$y, roles$moderator, c(roles$x, ".cJC", roles$controls), roles$fe, roles$cluster)
mods[["mod_centered"]] <- run_ols(df, roles$y, ".cJC", c(roles$x, roles$moderator, roles$controls), roles$fe, roles$cluster)
t3 <- export_models(mods, file.path(out, "tables", "table3-mechanism-mediation-moderation.csv"),
                    "Table 3 Mechanism Mediation Moderation", roles$controls, roles$fe, roles$cluster)

# ---- 表3s：中介稳健性（间接效应仅作补充证据，主识别为江艇两步法） ----
ind <- mech$indirect_boot
dir.create(file.path(out, "tables"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(data.frame(
  方法 = c("江艇两步法 第一步 X→Y", "江艇两步法 第二步 X→M", "间接效应 bootstrap（补充证据）"),
  内容 = c(sprintf("系数 %.3f", mech$total$coef[[roles$x]]),
           sprintf("系数 %.3f", mech$path_a$coef[[roles$x]]),
           sprintf("点估计 %.4f，95%% CI [%.4f, %.4f]，reps=%d", ind$estimate, ind$ci_low, ind$ci_high, ind$reps)),
  说明 = c("主识别口径", "主识别口径", "间接效应为补充证据，主识别为江艇两步法；不得据此声称因果中介")),
  file.path(out, "tables", "table3s-mediation-robustness.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# ---- 表4：异质性分组 ----
if (!is.na(roles$heterogeneity)) {
  groups <- sort(unique(stats::na.omit(df[[roles$heterogeneity]])))
  hmods <- list()
  for (g in groups) {
    sub <- df[df[[roles$heterogeneity]] == g, , drop = FALSE]
    if (nrow(sub) > length(roles$controls) + 8) hmods[[paste0(roles$heterogeneity, "=", g)]] <- run_ols(sub, roles$y, roles$x, roles$controls, roles$fe, roles$cluster)
  }
  if (length(hmods)) t4 <- export_models(hmods, file.path(out, "tables", "table4-heterogeneity-threshold-nonlinear.csv"),
                                         "Table 4 Heterogeneity", roles$controls, roles$fe, roles$cluster)
}

# ---- 表4b：组间系数差异 ----
gd <- tryCatch(run_group_diff(df, roles), error = function(e) NULL)
if (!is.null(gd)) {
  t4b <- export_models(list("Group interaction" = gd), file.path(out, "tables", "table4b-group-difference.csv"),
                       "Table 4b Group Difference", roles$controls, roles$fe, roles$cluster)
  w <- gd$extra$wald
  con <- file(file.path(out, "tables", "table4b-group-difference.csv"), open = "a", encoding = "UTF-8")
  if (!is.null(w)) writeLines(c('"交互项 Wald 检验","",""', paste0('"chi2(1)=', sprintf("%.3f", w$statistic), '",,"p=', sprintf("%.4f", w$p.value), '"')), con)
  close(con)
}

# ---- 表4c：门槛网格（分组回归，不依赖外部包） ----
risk <- if ("riskvar" %in% names(df)) "riskvar" else NA_character_
if (!is.na(risk) && !is.na(roles$heterogeneity)) {
  qs <- c(0.2, 0.4, 0.6, 0.8)
  thr_mods <- list()
  for (p in qs) {
    thr <- stats::quantile(df[[risk]], p, na.rm = TRUE)
    lo <- df[df[[risk]] <= thr, , drop = FALSE]
    hi <- df[df[[risk]] > thr, , drop = FALSE]
    if (nrow(lo) > length(roles$controls) + 8) thr_mods[[paste0("p", p * 100, "_low")]] <- run_ols(lo, roles$y, roles$x, roles$controls, roles$fe, roles$cluster)
    if (nrow(hi) > length(roles$controls) + 8) thr_mods[[paste0("p", p * 100, "_high")]] <- run_ols(hi, roles$y, roles$x, roles$controls, roles$fe, roles$cluster)
  }
  if (length(thr_mods)) t4c <- export_models(thr_mods, file.path(out, "tables", "table4c-threshold-grid.csv"),
                                             "Table 4c Threshold Grid", roles$controls, roles$fe, roles$cluster)
}

summary_path <- write_md(file.path(out, "reports", "mechanism-results.md"), "Mechanism Results",
                         lapply(mods, function(m) paste(capture.output(summary(m)), collapse = "\n")))
