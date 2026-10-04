# Run causal identification: IV/2SLS/LIML, DID/TWFE, event study, CS-DID, RDD, PSM/CEM/IPW/entropy, SCM.

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

# ---- 表A1：主结果（IV、DID） ----
mods_a1 <- list(
  "IV/2SLS" = run_iv_2sls(df, roles),
  "DID/TWFE" = run_twfe_did(df, roles)
)
tA1 <- export_models(mods_a1, file.path(out, "tables", "tableA1-causal-robustness.csv"),
                     "Table A1 Causal Robustness", roles$controls, roles$fe, roles$cluster)

# ---- 表A1a：IV 诊断 ----
iv <- run_iv_2sls(df, roles)
liml <- tryCatch(run_iv_liml(df, roles), error = function(e) NULL)
iv_diag <- iv$extra$first_stage
rows <- list(c("诊断项", "统计量", "p 值"))
if (!is.null(iv_diag)) {
  for (i in seq_len(nrow(iv_diag))) {
    rows <- c(rows, list(c(rownames(iv_diag)[i], sprintf("%.4f", iv_diag[i, 1]), sprintf("%.4f", iv_diag[i, 4]))))
  }
}
rows <- c(rows, list(c("注：Weak instruments / Wu-Hausman / Sargan 由 AER::ivreg 的 diagnostics 输出。", "", "")))
mat <- do.call(rbind, lapply(rows, function(x) c(x, rep("", 3 - length(x)))))
dir.create(file.path(out, "tables"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(mat, file.path(out, "tables", "tableA1a-iv-diagnostics.csv"), row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")

# ---- 表A1b：事件研究 ----
es <- tryCatch(run_event_study(df, roles), error = function(e) NULL)
csdid <- tryCatch(run_cs_did(df, roles), error = function(e) NULL)
mods_a1b <- Filter(Negate(is.null), list("Sun-Abraham event study" = es, "Callaway-Sant'Anna ATT" = csdid))
if (length(mods_a1b)) {
  tA1b <- export_models(mods_a1b, file.path(out, "tables", "tableA1b-did-event-study.csv"),
                        "Table A1b DID Event Study", character(), character(), roles$id)
}

# ---- 表A1c：DID 诊断与平行趋势敏感性 ----
csdid_full <- tryCatch({
  did::att_gt(yname = roles$y, tname = roles$time, idname = roles$id,
              gname = if (!is.na(roles$gvar)) roles$gvar else roles$treat,
              data = as.data.frame(df), panel = TRUE)
}, error = function(e) NULL)
write_md(file.path(out, "reports", "did-diagnostics.md"), "DID Diagnostics",
         c("CS-DID 分组-时期 ATT" = if (is.null(csdid_full)) "未运行" else paste(capture.output(print(csdid_full$att)), collapse = " "),
           "平行趋势敏感性" = "event study 的事前系数联合检验与 CS-DID 的 pre-treatment ATT 是平行趋势证据；honestdid/Rambachan-Roth 的等价实现不在本清单内，故 R 侧不报告 M 敏感性。"))
utils::write.csv(data.frame(项目 = c("Bacon 分解", "平行趋势敏感性", "CS-DID pre-treatment ATT"),
                            内容 = c("bacondecomp 的 R 等价实现不在清单内，使用 did::att_gt 的组-时 ATT 与 Sun-Abraham 事件研究作为替代证据",
                                   "event study 事前系数联合检验",
                                   if (is.null(csdid_full)) "未运行" else "见 did-diagnostics.md")),
                file.path(out, "tables", "tableA1c-did-diagnostics.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# ---- 表A1d：RDD ----
rd <- tryCatch(run_rd(df, roles), error = function(e) NULL)
if (!is.null(rd)) {
  tA1d <- export_models(list("RD main" = rd), file.path(out, "tables", "tableA1d-rd.csv"),
                        "Table A1d RD", character(), character(), roles$cluster)
  write_md(file.path(out, "reports", "rd-bandwidths.md"), "RD Bandwidth Sensitivity",
           stats::setNames(vapply(names(rd$extra$bandwidths), function(h) {
             b <- rd$extra$bandwidths[[h]]
             if (is.null(b)) "未收敛" else sprintf("coef=%.3f, se=%.3f", b$coef["Conventional", 1], b$se["Conventional", 1])
           }, character(1)), names(rd$extra$bandwidths)))
}

# ---- 表A1e：匹配与加权 ----
psm <- tryCatch(run_psm(df, roles), error = function(e) NULL)
ipw <- tryCatch(run_ipw(df, roles), error = function(e) NULL)
cem <- tryCatch(run_cem(df, roles), error = function(e) NULL)
ebal <- tryCatch(run_ebal(df, roles), error = function(e) NULL)
mods_a1e <- Filter(Negate(is.null), list("IPW ATET" = ipw, "PSM ATT" = psm, "CEM" = cem, "Entropy balance" = ebal))
if (length(mods_a1e)) {
  tA1e <- export_models(mods_a1e, file.path(out, "tables", "tableA1e-matching.csv"),
                        "Table A1e Matching", character(), character(), roles$cluster)
}
bal_rows <- list(c("方法", "匹配后平衡性"))
for (nm in names(Filter(Negate(is.null), list(psm = psm, cem = cem, ebal = ebal)))) {
  m <- get(nm)
  bal <- tryCatch(paste(utils::capture.output(print(m$extra$matchit$balance)), collapse = " "), error = function(e) NULL)
  if (is.null(bal)) bal <- tryCatch(paste(utils::capture.output(print(m$extra$weightit$ps)), collapse = " "), error = function(e) "平衡性摘要不可用")
  bal_rows <- c(bal_rows, list(c(nm, substr(bal, 1, 300))))
}
mat <- do.call(rbind, lapply(bal_rows, function(x) c(x, rep("", 2 - length(x)))))
utils::write.csv(mat, file.path(out, "tables", "matching-balance.csv"), row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")

# ---- 表A1f：合成控制 ----
scm <- tryCatch(run_scm(df, roles), error = function(e) NULL)
if (!is.null(scm)) {
  tA1f <- export_models(list("Synthetic control" = scm), file.path(out, "tables", "tableA1f-scm.csv"),
                        "Table A1f SCM", character(), character(), NA_character_)
}

summary_path <- write_md(file.path(out, "reports", "causal-results.md"), "Causal Results",
                         lapply(Filter(Negate(is.null), list(IV = iv, LIML = liml, EventStudy = es, CSDID = csdid, RD = rd, PSM = psm, IPW = ipw, CEM = cem, Ebal = ebal, SCM = scm)),
                                function(m) paste(capture.output(summary(m)), collapse = "\n")))
