# Run panel models: FE/RE, Hausman, pooled test, TWFE, dynamic GMM, panel IV, long-N, panel nonlinear.

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

# ---- 表A0：面板设定选择检验 ----
tests <- run_hausman(df, roles)
hm <- tests$hausman; bp <- tests$pooled
sel_rows <- list(
  c("检验", "统计量", "自由度", "p 值", "结论口径"),
  c("Breusch-Pagan LM（混合 OLS vs RE）", sprintf("%.3f", bp$statistic), "1", sprintf("%.4f", bp$p.value), "p<0.05 拒绝混合 OLS"),
  c("Hausman（FE vs RE）", sprintf("%.3f", hm$statistic), as.character(hm$parameter), sprintf("%.4f", hm$p.value), "p<0.05 选择 FE")
)
mat <- do.call(rbind, lapply(sel_rows, function(x) c(x, rep("", 5 - length(x)))))
dir.create(file.path(out, "tables"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(mat, file.path(out, "tables", "tableA0-panel-selection.csv"), row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")

# ---- 表A：FE / TWFE ----
fe <- run_panel_fe(df, roles)
fe_i <- run_ols(df, roles$y, roles$x, roles$controls, roles$id, roles$cluster)
mods_a <- list("(1) Individual FE" = fe, "(2) Two-way FE" = fe_i)
tA <- export_models(mods_a, file.path(out, "tables", "tableA-panel-models.csv"), "Table A Panel Models",
                    roles$controls, na.omit(c(roles$id, roles$time)), roles$cluster)

# ---- 表A2：动态面板 ----
dyn <- list()
dyn[["System GMM (plm pgmm)"]] <- tryCatch(run_pgmm(df, roles), error = function(e) NULL)
dyn[["RE (plm)"]] <- tryCatch(run_panel_re(df, roles), error = function(e) NULL)
dyn <- dyn[!vapply(dyn, is.null, logical(1))]
tA2 <- export_models(dyn, file.path(out, "tables", "tableA2-panel-dynamic.csv"), "Table A2 Panel Dynamic",
                     roles$controls, character(), roles$cluster)

# ---- 表A3：长面板 + 面板诊断 ----
long <- run_panel_long(df, roles)
mods_a3 <- list("(1) Driscoll-Kraay SCC" = long, "(2) FE" = fe)
tA3 <- export_models(mods_a3, file.path(out, "tables", "tableA3-panel-longN.csv"), "Table A3 Panel LongN",
                     roles$controls, character(), roles$cluster)
ws <- tryCatch(lmtest::dwtest(stats::lm(stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls)))), data = df)), error = function(e) NULL)
append_rows <- list(c("面板诊断", rep("", 2)), c("Durbin-Watson 统计量", if (is.null(ws)) "." else sprintf("%.4f", ws$statistic), if (is.null(ws)) "." else sprintf("%.4f", ws$p.value)))
con <- file(file.path(out, "tables", "tableA3-panel-longN.csv"), open = "a", encoding = "UTF-8")
writeLines(vapply(append_rows, function(x) paste0('"', paste(x, collapse = '","'), '"'), character(1)), con)
close(con)

# ---- 表A4：面板 IV 与面板非线性 ----
xtiv <- tryCatch(run_xtiv(df, roles), error = function(e) NULL)
pnnl <- tryCatch(run_panel_nl(df, roles), error = function(e) NULL)
mods_a4 <- Filter(Negate(is.null), list("(1) Panel IV FE" = xtiv, "(2) Panel logit FE" = pnnl))
if (length(mods_a4)) {
  tA4 <- export_models(mods_a4, file.path(out, "tables", "tableA4-panel-iv-nonlinear.csv"), "Table A4 Panel IV Nonlinear",
                       roles$controls, NA_character_, roles$cluster)
}

diag <- write_md(file.path(out, "reports", "panel-diagnostics.md"), "Panel Diagnostics",
                 c("设定选择" = paste0("Hausman chi2 = ", sprintf("%.3f", hm$statistic), " (df=", hm$parameter, ", p=", sprintf("%.4f", hm$p.value), "); Breusch-Pagan LM p = ", sprintf("%.4f", bp$p.value)),
                   "估计口径" = "FE/TWFE 用 fixest::feols；RE 与动态 GMM 用 plm；长面板用 sandwich::vcovSCC；面板 IV 用 fixest 的 IV 语法；面板非线性用 fixest::feglm。"))
