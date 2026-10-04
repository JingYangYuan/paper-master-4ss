# Spatial models: weights, Moran's I, cross-section SAR/SEM/SDM, panel spatial, direct/indirect/total effects.
#
# 本机 spdep/spatialreg/splm 依赖链需要 sf -> GDAL，而系统 GDAL 不可得，故本模板的空间权重、
# Moran's I 与 SAR/SEM/SDM 全部由 _shared/r_common.R 的 base R 线性代数实现（行标准化 K 近邻 W
# + 极大似然 + 直接/间接/总效应分解），不引入外部空间依赖。

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

unit <- if ("pid" %in% names(df)) "pid" else roles$id
lat <- if (!is.na(roles$lat)) roles$lat else stop("spatial requires a latitude variable (lat/latitude)")
lon <- if (!is.na(roles$lon)) roles$lon else stop("spatial requires a longitude variable (lon/longitude)")
y <- roles$y; x <- roles$x; controls <- roles$controls

dir.create(file.path(out, "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out, "reports"), recursive = TRUE, showWarnings = FALSE)

# ---- 表S1：权重矩阵与全局 Moran's I ----
mo <- run_moran(df, y, unit, lat, lon, k = 5)
w <- mo$weights
xs <- df[match(w$units, df[[unit]]), , drop = FALSE]
utils::write.csv(data.frame(
  项目 = c("权重矩阵类型", "行标准化方式", "空间单元数", "平均邻居数", "全局 Moran's I", "Moran's I p 值", "坐标系统"),
  内容 = c("K 近邻（k=5）+ 对称化 + 行标准化（base R 线性代数，不依赖 sf/spdep）",
           "行标准化（W / rowSums(W)）",
           as.character(w$n),
           sprintf("%.2f", mean(rowSums(w$W > 0))),
           sprintf("%.4f", mo$I),
           sprintf("%.4f", mo$p),
           "平面坐标。若为经纬度，应先换算为公里距离或改用地理坐标口径。")),
  file.path(out, "tables", "tableS1-spatial-weights.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# ---- 表S2：截面空间回归与效应分解 ----
ols <- run_ols(xs, y, x, controls, character(), NA_character_)
sar <- run_spatial_cs(df, y, x, controls, unit, lat, lon, model = "lag", k = 5)
sem <- run_spatial_cs(df, y, x, controls, unit, lat, lon, model = "error", k = 5)
sdm <- run_spatial_sdm(df, y, x, controls, unit, lat, lon, k = 5)
tS2 <- export_models(list("OLS" = ols, "SAR (lag)" = sar, "SEM (error)" = sem, "SDM" = sdm),
                     file.path(out, "tables", "tableS2-spatial-cross-section.csv"),
                     "Table S2 Spatial Cross Section", controls, character(), NA_character_)

# ---- 表S3：面板空间回归 ----
pan <- tryCatch(run_spatial_panel(df, y, x, controls, roles$id, roles$time, lat, lon,
                                  model = "within", k = 5, effects = "individual"),
                error = function(e) NULL)
if (!is.null(pan)) {
  tS3 <- export_models(list("Spatial panel FE (SAR)" = pan), file.path(out, "tables", "tableS3-spatial-panel.csv"),
                       "Table S3 Spatial Panel", controls, character(), NA_character_)
}

# ---- 表S3b：直接/间接/总效应 ----
eff_rows <- list(c("效应", "直接效应", "间接效应", "总效应"))
add_impacts <- function(fit, label) {
  imp <- fit$extra$impacts
  if (is.null(imp)) return(invisible(NULL))
  for (row in imp) {
    eff_rows[[length(eff_rows) + 1]] <<- c(paste0(label, " ", row[[1]]),
                                           sprintf("%.4f", as.numeric(row[[2]])),
                                           sprintf("%.4f", as.numeric(row[[3]])),
                                           sprintf("%.4f", as.numeric(row[[4]])))
  }
}
add_impacts(sar, "SAR")
add_impacts(sdm, "SDM")
mat <- do.call(rbind, lapply(eff_rows, function(r) c(r, rep("", 4 - length(r)))))
utils::write.csv(mat, file.path(out, "tables", "tableS3b-spatial-effects.csv"), row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")

# ---- 空间诊断报告 ----
write_md(file.path(out, "reports", "spatial-diagnostics.md"), "Spatial Diagnostics",
         c("权重矩阵来源" = "K 近邻（k=5）由坐标 lat/lon 直接构造，对称化后行标准化；由 base R 线性代数实现，不依赖 sf/spdep/GDAL。",
           "坐标单位" = "按平面坐标处理。若原始为经纬度，应先换算为公里距离或使用地理坐标口径。",
           "Moran's I 结论" = sprintf("全局 Moran's I = %.4f，置换检验 p = %.4f（999 次置换）。p<0.05 表示存在显著空间自相关，应使用空间回归而非普通 OLS。", mo$I, mo$p),
           "空间参数" = sprintf("SAR rho = %.4f；SEM lambda = %.4f；SDM rho = %.4f。", sar$extra$rho, sem$extra$rho, sdm$extra$rho),
           "直接/间接/总效应解释" = "直接效应为本单元 X 变动对本单元 Y 的影响（影响矩阵对角线均值）；间接效应（空间溢出）为经权重矩阵传导到其他单元的影响（总效应减直接效应）；总效应为影响矩阵行和的均值。三者含空间滞后反馈项，不等同于非空间模型系数。",
           "截面与面板口径" = "表S2 使用个体层面截面；表S3 使用面板 within 变换后的 SAR。两者权矩阵均由个体坐标构造，可直接比较截面与面板的空间依赖强度。"))
