# Executable helpers for Paper Analysis 4SS R templates.

default_out_root <- "paper-workspace/04-analysis"

parse_common_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  out <- list(data = NA_character_, plan = NA_character_, dict = NA_character_,
              out_root = default_out_root, run_log = NA_character_,
              slug = "analysis", tasks = "")
  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    if (key %in% c("--data", "--plan", "--dict", "--out-root", "--run-log", "--slug", "--tasks")) {
      value <- if (i + 1 <= length(args)) args[[i + 1]] else ""
      key <- gsub("-", "_", sub("^--", "", key))
      out[[key]] <- value
      i <- i + 2
    } else if (key %in% c("--help", "-h")) {
      cat("Common args: --data --plan --dict --out-root --run-log --slug --tasks\n")
      quit(status = 0)
    } else {
      i <- i + 1
    }
  }
  out
}

ensure_dirs <- function(out_root) {
  dirs <- file.path(out_root, c("data", "scripts", "tables", "figures", "reports",
                               "qual/codebooks", "qual/coded-data", "qual/memos",
                               "qual/anonymized", "qual/reliability"))
  invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))
}

run_log_path <- function(args) {
  if (!is.na(args$run_log) && nzchar(args$run_log)) return(args$run_log)
  file.path(args$out_root, "reports", paste0("run-log-", Sys.Date(), ".md"))
}

log_run <- function(args, step, status, outputs = "-", note = "-") {
  ensure_dirs(args$out_root)
  p <- run_log_path(args)
  if (!file.exists(p)) {
    writeLines(c("# Analysis Run Log", "", "| Date | Step | Status | Outputs | Note |",
                 "|---|---|---|---|---|"), p)
  }
  line <- paste0("| ", Sys.Date(), " | ", step, " | ", status, " | ",
                 paste(outputs, collapse = "<br>"), " | ", note, " |")
  write(line, p, append = TRUE)
}

write_csv_safe <- function(df, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(df, path, row.names = FALSE, fileEncoding = "UTF-8")
  path
}

write_md <- function(path, title, sections) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  lines <- c(paste0("# ", title), "")
  for (nm in names(sections)) lines <- c(lines, paste0("## ", nm), sections[[nm]], "")
  writeLines(lines, path, useBytes = TRUE)
  path
}

task_enabled <- function(args, name) {
  if (!nzchar(args$tasks)) return(TRUE)
  name %in% trimws(strsplit(args$tasks, ",")[[1]])
}

load_data <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") return(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
  if (ext == "tsv") return(utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE))
  if (ext %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) stop("readxl is required for Excel input")
    return(readxl::read_excel(path))
  }
  if (ext == "dta") {
    if (!requireNamespace("haven", quietly = TRUE)) stop("haven is required for Stata input")
    return(haven::read_dta(path))
  }
  if (ext == "sav") {
    if (!requireNamespace("haven", quietly = TRUE)) stop("haven is required for SPSS input")
    return(haven::read_sav(path))
  }
  if (ext == "rds") return(readRDS(path))
  stop(paste("Unsupported data file type:", ext))
}

clean_names_safe <- function(df) {
  names(df) <- gsub("_+", "_", gsub("[^0-9A-Za-z_]+", "_", trimws(tolower(names(df)))))
  names(df) <- gsub("^_|_$", "", names(df))
  df
}

clean_data <- function(df, special_missing = c(-9, -8, -7, -99, -999), winsor = c(.01, .99)) {
  df <- clean_names_safe(as.data.frame(df))
  for (nm in names(df)) {
    if (is.character(df[[nm]])) {
      df[[nm]] <- trimws(df[[nm]])
      df[[nm]][df[[nm]] %in% c("", "nan", "None")] <- NA
    }
    if (is.numeric(df[[nm]])) {
      df[[nm]][df[[nm]] %in% special_missing] <- NA
      if (length(unique(na.omit(df[[nm]]))) > 8) {
        qs <- stats::quantile(df[[nm]], winsor, na.rm = TRUE)
        df[[nm]] <- pmin(pmax(df[[nm]], qs[[1]]), qs[[2]])
      }
    }
  }
  unique(df)
}

infer_roles <- function(df, dict_path = NA_character_) {
  cols <- names(df)
  y <- if ("outcome" %in% cols) "outcome" else cols[[1]]
  x <- if ("treatment" %in% cols) "treatment" else if (length(cols) > 1) cols[[2]] else cols[[1]]
  controls <- intersect(c("age", "gender", "education", "income"), cols)
  fe <- intersect(c("region", "province", "city", "county", "year"), cols)
  cluster <- intersect(c("region", "province", "city", "county", "pid", "id"), cols)
  id <- intersect(c("pid", "id", "unit"), cols)
  time <- intersect(c("year", "time", "wave"), cols)
  list(
    y = y, x = x, controls = setdiff(controls, c(y, x)), fe = setdiff(fe, c(y, x)),
    cluster = ifelse(length(cluster), cluster[[1]], NA_character_),
    id = ifelse(length(id), id[[1]], NA_character_),
    time = ifelse(length(time), time[[1]], NA_character_),
    treat = ifelse("treated" %in% cols, "treated", ifelse("treat" %in% cols, "treat", NA_character_)),
    post = ifelse("post" %in% cols, "post", NA_character_),
    endog = ifelse("endog_x" %in% cols, "endog_x", NA_character_),
    instrument = ifelse("instrument_z" %in% cols, "instrument_z", ifelse("instrument" %in% cols, "instrument", NA_character_)),
    running = ifelse("running_score" %in% cols, "running_score", ifelse("running" %in% cols, "running", NA_character_)),
    mediator = ifelse("mediator" %in% cols, "mediator", NA_character_),
    moderator = ifelse("moderator" %in% cols, "moderator", NA_character_),
    heterogeneity = ifelse("group" %in% cols, "group", NA_character_)
  )
}

write_variable_dictionary <- function(df, roles, source_file, out_root) {
  role_of <- rep("", length(names(df))); names(role_of) <- names(df)
  role_of[roles$y] <- "Y"; role_of[roles$x] <- "X"
  role_of[roles$controls] <- "control"; role_of[roles$fe] <- "fe"
  for (r in c("cluster", "id", "time", "treat", "post", "endog", "instrument", "running", "mediator", "moderator")) {
    v <- roles[[r]]
    if (!is.na(v) && v %in% names(role_of)) role_of[v] <- r
  }
  out <- data.frame(raw_name = names(df), clean_name = names(df), display_name = names(df),
                    role = role_of, dtype = vapply(df, function(x) class(x)[[1]], character(1)),
                    missing = vapply(df, function(x) sum(is.na(x)), integer(1)),
                    source_file = source_file, check.names = FALSE)
  write_csv_safe(out, file.path(out_root, "data", "variable-dictionary.csv"))
}

sample_flow <- function(df, roles, out_root) {
  req <- intersect(c(roles$y, roles$x, roles$controls), names(df))
  before <- nrow(df)
  out <- if (length(req)) df[stats::complete.cases(df[, req, drop = FALSE]), , drop = FALSE] else df
  flow <- data.frame(step = c("raw", "analysis_sample"),
                     rule = c("原始数据", "删除 Y/X/control 缺失"),
                     n_before = c(before, before), n_after = c(before, nrow(out)),
                     dropped = c(0, before - nrow(out)),
                     reason = c("载入原始数据", paste(req, collapse = ", ")))
  write_csv_safe(flow, file.path(out_root, "tables", "sample-flow.csv"))
  out
}

make_table1 <- function(df, vars, out_root, file_name = "table1-descriptives.csv") {
  rows <- lapply(intersect(vars, names(df)), function(v) {
    x <- suppressWarnings(as.numeric(df[[v]]))
    data.frame(variable = v, N = sum(!is.na(df[[v]])),
               mean = ifelse(all(is.na(x)), NA, round(mean(x, na.rm = TRUE), 3)),
               sd = ifelse(all(is.na(x)), NA, round(stats::sd(x, na.rm = TRUE), 3)),
               min = ifelse(all(is.na(x)), NA, round(min(x, na.rm = TRUE), 3)),
               max = ifelse(all(is.na(x)), NA, round(max(x, na.rm = TRUE), 3)))
  })
  write_csv_safe(do.call(rbind, rows), file.path(out_root, "tables", file_name))
}

formula_rhs <- function(vars) if (length(vars)) paste(vars, collapse = " + ") else "1"
fe_terms <- function(fe) if (length(fe)) paste0("factor(", fe, ")") else character()
model_formula <- function(y, x, controls = character(), fe = character()) {
  stats::as.formula(paste(y, "~", formula_rhs(c(x, controls, fe_terms(fe)))))
}

run_ols <- function(df, y, x, controls = character(), fe = character(), cluster = NA_character_) {
  fml <- model_formula(y, x, controls, fe)
  mod <- stats::lm(fml, data = df)
  mod
}

run_logit_ame <- function(df, y, x, controls = character(), fe = character()) {
  mod <- stats::glm(model_formula(y, x, controls, fe), data = df, family = stats::binomial())
  mod
}

run_probit_ame <- function(df, y, x, controls = character(), fe = character()) {
  mod <- stats::glm(model_formula(y, x, controls, fe), data = df, family = stats::binomial(link = "probit"))
  mod
}

run_poisson <- function(df, y, x, controls = character(), fe = character()) {
  stats::glm(model_formula(y, x, controls, fe), data = df, family = stats::poisson())
}

run_panel_fe <- function(df, roles) {
  run_ols(df, roles$y, roles$x, roles$controls, na.omit(c(roles$id, roles$time)), roles$cluster)
}

run_iv_2sls <- function(df, roles) {
  if (is.na(roles$endog) || is.na(roles$instrument)) stop("IV requires endog and instrument")
  stage1 <- run_ols(df, roles$endog, roles$instrument, roles$controls)
  df$endog_hat <- stats::predict(stage1, newdata = df)
  stage2 <- run_ols(df, roles$y, "endog_hat", roles$controls)
  attr(stage2, "first_stage") <- stage1
  stage2
}

run_twfe_did <- function(df, roles) {
  if (is.na(roles$treat) || is.na(roles$post)) stop("DID requires treat and post")
  df$did_term <- df[[roles$treat]] * df[[roles$post]]
  run_ols(df, roles$y, "did_term", c(roles$treat, roles$post, roles$controls), na.omit(c(roles$id, roles$time)), roles$cluster)
}

run_rdrobust <- function(df, roles, cutoff = 0) {
  if (is.na(roles$running)) stop("RDD requires running")
  df$running_centered <- df[[roles$running]] - cutoff
  bw <- stats::sd(df$running_centered, na.rm = TRUE)
  sub <- df[abs(df$running_centered) <= bw, , drop = FALSE]
  sub$above_cutoff <- as.integer(sub$running_centered >= 0)
  sub$rdd_interaction <- sub$above_cutoff * sub$running_centered
  run_ols(sub, roles$y, "above_cutoff", c("running_centered", "rdd_interaction", roles$controls), character(), roles$cluster)
}

run_weightit_ipw <- function(df, roles) {
  if (is.na(roles$treat)) stop("IPW requires treatment")
  ps <- stats::glm(stats::as.formula(paste(roles$treat, "~", formula_rhs(roles$controls))), data = df, family = stats::binomial())
  p <- pmin(pmax(stats::predict(ps, type = "response"), .01), .99)
  w <- df[[roles$treat]] / p + (1 - df[[roles$treat]]) / (1 - p)
  stats::lm(stats::as.formula(paste(roles$y, "~", roles$treat)), data = df, weights = w)
}

run_mediation <- function(df, roles) {
  if (is.na(roles$mediator)) stop("mediation requires mediator")
  list(total = run_ols(df, roles$y, roles$x, roles$controls, roles$fe, roles$cluster),
       path_a = run_ols(df, roles$mediator, roles$x, roles$controls, roles$fe, roles$cluster),
       path_b = run_ols(df, roles$y, roles$mediator, c(roles$x, roles$controls), roles$fe, roles$cluster))
}

run_interaction <- function(df, roles) {
  if (is.na(roles$moderator)) stop("moderation requires moderator")
  df$interaction_term <- df[[roles$x]] * df[[roles$moderator]]
  run_ols(df, roles$y, "interaction_term", c(roles$x, roles$moderator, roles$controls), roles$fe, roles$cluster)
}

run_robustness <- function(df, roles) {
  out <- list(baseline = run_ols(df, roles$y, roles$x, roles$controls, roles$fe, roles$cluster),
              no_fe = run_ols(df, roles$y, roles$x, roles$controls, character(), roles$cluster))
  if (length(roles$controls)) out$no_controls <- run_ols(df, roles$y, roles$x, character(), roles$fe, roles$cluster)
  out
}

stars <- function(p) ifelse(is.na(p), "", ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", ""))))

export_models <- function(models, path, title = "Regression Table", controls = character(), fe = character(), cluster = NA_character_) {
  if (is.null(names(models))) names(models) <- paste0("(", seq_along(models), ")")
  terms <- unique(unlist(lapply(models, function(m) names(stats::coef(m)))))
  terms <- terms[!grepl("^factor\\(|Intercept", terms)]
  rows <- list(c(title, rep("", length(models))), c("变量", names(models)))
  for (term in terms) {
    coef_row <- c(term); stat_row <- c("")
    for (m in models) {
      sm <- summary(m)$coefficients
      if (term %in% rownames(sm)) {
        pcol <- ncol(sm)
        coef_row <- c(coef_row, paste0(sprintf("%.3f", sm[term, 1]), stars(sm[term, pcol])))
        stat_row <- c(stat_row, paste0("(", sprintf("%.3f", sm[term, 3]), ")"))
      } else {
        coef_row <- c(coef_row, "-"); stat_row <- c(stat_row, "-")
      }
    }
    rows <- c(rows, list(coef_row, stat_row))
  }
  for (f in fe) rows <- c(rows, list(c(paste0(f, "固定"), rep("是", length(models)))))
  rows <- c(rows, list(c("观测值", vapply(models, function(m) as.character(stats::nobs(m)), character(1)))))
  rows <- c(rows, list(c("R²", vapply(models, function(m) sprintf("%.3f", summary(m)$r.squared %||% NA_real_), character(1)))))
  note <- "注：*** p<0.001，** p<0.01，* p<0.05；括号内为 t/z 统计值。"
  rows <- c(rows, list(c(note, rep("", length(models)))))
  max_len <- max(vapply(rows, length, integer(1)))
  mat <- do.call(rbind, lapply(rows, function(x) c(x, rep("", max_len - length(x)))))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(mat, path, row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")
  path
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a
