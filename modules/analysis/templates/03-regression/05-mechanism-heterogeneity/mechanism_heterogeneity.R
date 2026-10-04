# Run mediation, moderation, and heterogeneity tests.

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
mods <- list()
mods <- c(mods, run_mediation(df, roles))
mods$moderation <- run_interaction(df, roles)
outputs <- export_models(mods, file.path(args$out_root, "tables", "table3-mechanism-mediation-moderation.csv"), "Table 3 Mechanism Mediation Moderation", roles$controls, roles$fe, roles$cluster)
if (!is.na(roles$heterogeneity)) {
  groups <- unique(stats::na.omit(df[[roles$heterogeneity]]))
  hmods <- list()
  for (g in groups) {
    sub <- df[df[[roles$heterogeneity]] == g, , drop = FALSE]
    if (nrow(sub) > length(roles$controls) + 8) hmods[[paste0(roles$heterogeneity, "=", g)]] <- run_ols(sub, roles$y, roles$x, roles$controls, roles$fe, roles$cluster)
  }
  if (length(hmods)) outputs <- c(outputs, export_models(hmods, file.path(args$out_root, "tables", "table4-heterogeneity-threshold-nonlinear.csv"), "Table 4 Heterogeneity Threshold Nonlinear", roles$controls, roles$fe, roles$cluster))
}
