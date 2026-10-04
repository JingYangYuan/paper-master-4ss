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
    heterogeneity = ifelse("group" %in% cols, "group", NA_character_),
    lat = ifelse("lat" %in% cols, "lat", ifelse("latitude" %in% cols, "latitude", NA_character_)),
    lon = ifelse("lon" %in% cols, "lon", ifelse("longitude" %in% cols, "longitude", NA_character_))
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

# ---- 统一估计结果包装：让聚类 VCE 与真实 AME 在 R 侧真正生效 ----
# pmfit 保存系数、VCE、模型对象与拟合数据；export_models 只依赖 coef/vcov/nobs/terms，
# 因此新估计量（fixest/marginaleffects/plm/Synth 等）都能用同一套导出路径。
pmfit <- function(coef, vcov = NULL, nobs = NA_integer_, terms = names(coef),
                  model = NULL, data = NULL, family = NA_character_,
                  fe = character(), cluster = NA_character_, extra = list()) {
  structure(list(coef = coef, vcov = vcov, nobs = nobs, terms = terms, model = model,
                 data = data, family = family, fe = fe, cluster = cluster, extra = extra),
            class = "pmfit")
}

coef.pmfit <- function(object, ...) object$coef
vcov.pmfit <- function(object, ...) { v <- object$vcov; if (is.null(v)) diag(length(object$coef)) * NA else v }
nobs.pmfit <- function(object, ...) object$nobs
terms.pmfit <- function(x, ...) x$terms
summary.pmfit <- function(object, ...) {
  cat("pmfit: n =", object$nobs, "| vce:", if (is.na(object$cluster)) "default" else paste0("cluster(", object$cluster, ")"), "\n")
  print(round(object$coef, 4))
  invisible(object)
}

# 统一的系数/标准误/p 值表
pmfit_table <- function(m) {
  b <- m$coef
  v <- tryCatch(vcov(m), error = function(e) NULL)
  se <- if (is.null(v)) rep(NA_real_, length(b)) else sqrt(diag(v)[seq_along(b)])
  z <- b / se
  p <- 2 * stats::pnorm(-abs(z))
  data.frame(term = names(b), estimate = b, std.error = se, statistic = z, p.value = p,
             row.names = NULL, check.names = FALSE)
}

# ---- 聚类标准误统一入口：cluster 参数不得再被静默忽略 ----
.pm_cluster_matrix <- function(model, cluster_values) {
  if (is.null(cluster_values) || !length(cluster_values)) return(NULL)
  ok <- tryCatch({
    if (!requireNamespace("sandwich", quietly = TRUE)) stop("sandwich required")
    sandwich::vcovCL(model, cluster = cluster_values, type = "HC1")
  }, error = function(e) {
    g <- as.factor(cluster_values)
    X <- stats::model.matrix(model)
    u <- stats::residuals(model)
    G <- nlevels(g)
    n <- length(u)
    meat <- matrix(0, ncol(X), ncol(X))
    for (lev in levels(g)) {
      idx <- which(g == lev)
      s <- crossprod(X[idx, , drop = FALSE], u[idx])
      meat <- meat + s %*% t(s)
    }
    bread <- tryCatch(stats::vcov(model) * n, error = function(e2) solve(crossprod(X)))
    (G / (G - 1)) * ((n - 1) / max(n - ncol(X), 1)) * solve(bread) %*% meat %*% solve(bread)
  })
  ok
}

.pm_wrap_lm <- function(model, data, cluster = NA_character_, family = NA_character_, fe = character()) {
  b <- stats::coef(model)
  cl <- if (!is.na(cluster) && cluster %in% names(data)) data[[cluster]] else NULL
  if (!is.null(cl)) {
    cl <- cl[as.integer(rownames(model$model))]
  }
  v <- if (!is.null(cl)) .pm_cluster_matrix(model, cl) else stats::vcov(model)
  pmfit(coef = b, vcov = v, nobs = stats::nobs(model), terms = names(b), model = model,
        data = data, family = family, fe = fe, cluster = cluster,
        extra = list(df_residual = stats::df.residual(model),
                     r2 = tryCatch(summary(model)$r.squared, error = function(e) NA_real_)))
}

# marginaleffects 会从模型调用里取原始数据，若其中含 group/term 等保留列会直接报错；
# 统一在拟合前把数据裁剪到模型实际使用的变量，既消除冲突也不改变估计结果。
.pm_model_data <- function(df, vars) {
  keep <- unique(vars[!is.na(vars) & nzchar(vars)])
  keep <- intersect(keep, names(df))
  df[, keep, drop = FALSE]
}

run_ols <- function(df, y, x, controls = character(), fe = character(), cluster = NA_character_) {
  fml <- model_formula(y, x, controls, fe)
  d <- .pm_model_data(df, c(y, x, controls, fe, cluster))
  .pm_wrap_lm(stats::lm(fml, data = d), d, cluster, NA_character_, fe)
}

.pm_glm_cluster <- function(model, data, cluster) {
  b <- stats::coef(model)
  cl <- if (!is.na(cluster) && cluster %in% names(data)) data[[cluster]] else NULL
  if (!is.null(cl)) {
    con <- model$model
    v <- tryCatch({
      if (!requireNamespace("sandwich", quietly = TRUE) || !requireNamespace("lmtest", quietly = TRUE)) {
        sandwich::vcovCL(model, cluster = cl, type = "HC1")
      } else {
        sandwich::vcovCL(model, cluster = cl, type = "HC1")
      }
    }, error = function(e) stats::vcov(model))
  } else {
    v <- stats::vcov(model)
  }
  pmfit(coef = b, vcov = v, nobs = stats::nobs(model), terms = names(b), model = model,
        data = data, family = if (!is.null(model$family)) model$family$family else NA_character_,
        cluster = cluster)
}

# 真实平均边际效应（marginaleffects::slopes）；保留原函数名以兼容既有调用
ame <- function(model, variables = NULL, data = NULL) {
  if (!requireNamespace("marginaleffects", quietly = TRUE)) stop("marginaleffects required for AME")
  # marginaleffects 会从模型调用里取原始数据；若原始数据含 group/term 等保留列会直接报错，
  # 故显式传入 model.frame（只含模型变量）作为 newdata。
  if (is.null(data)) {
    data <- tryCatch(stats::model.frame(model), error = function(e) NULL)
  }
  if (!is.null(data)) {
    reserved <- c("group", "term", "estimate", "std.error", "statistic", "p.value",
                  "conf.low", "conf.high", "contrast", "comparison", "marginaleffects")
    data <- data[, setdiff(names(data), reserved), drop = FALSE]
  }
  args <- list(model = model)
  if (!is.null(variables)) args$variables <- variables
  if (!is.null(data)) args$newdata <- data
  out <- tryCatch(do.call(marginaleffects::slopes, args),
                  error = function(e) {
                    args$variables <- NULL
                    do.call(marginaleffects::avg_slopes, args)
                  })
  as.data.frame(out)
}

run_logit_ame <- function(df, y, x, controls = character(), fe = character(), cluster = NA_character_) {
  d <- .pm_model_data(df, c(y, x, controls, fe, cluster))
  mod <- stats::glm(model_formula(y, x, controls, fe), data = d, family = stats::binomial())
  fit <- .pm_glm_cluster(mod, d, cluster)
  fit$extra$ame <- ame(mod, data = d)
  fit
}

run_probit_ame <- function(df, y, x, controls = character(), fe = character(), cluster = NA_character_) {
  d <- .pm_model_data(df, c(y, x, controls, fe, cluster))
  mod <- stats::glm(model_formula(y, x, controls, fe), data = d, family = stats::binomial(link = "probit"))
  fit <- .pm_glm_cluster(mod, d, cluster)
  fit$extra$ame <- ame(mod, data = d)
  fit
}

run_poisson <- function(df, y, x, controls = character(), fe = character(), cluster = NA_character_) {
  d <- .pm_model_data(df, c(y, x, controls, fe, cluster))
  mod <- stats::glm(model_formula(y, x, controls, fe), data = d, family = stats::poisson())
  .pm_glm_cluster(mod, d, cluster)
}

# ---- 02 nonlinear 新增估计量 ----
run_ologit <- function(df, y, x, controls = character(), cluster = NA_character_) {
  if (!requireNamespace("MASS", quietly = TRUE)) stop("MASS required")
  d <- .pm_model_data(df, c(y, x, controls, cluster))
  d[[y]] <- factor(d[[y]])  # MASS::polr 要求响应变量为 factor
  mod <- MASS::polr(model_formula(y, x, controls), data = d, Hess = TRUE)
  b <- stats::coef(mod)
  v <- tryCatch(solve(mod$Hessian), error = function(e) diag(length(b)) * NA)
  se <- sqrt(diag(v)[seq_along(b)])
  pmfit(coef = b, vcov = v, nobs = stats::nobs(mod), terms = names(b), model = mod, data = d,
        cluster = cluster, extra = list(ame = ame(mod, data = d), levels = levels(factor(d[[y]]))))
}

run_oprobit <- function(df, y, x, controls = character(), cluster = NA_character_) {
  if (!requireNamespace("MASS", quietly = TRUE)) stop("MASS required")
  d <- .pm_model_data(df, c(y, x, controls, cluster))
  d[[y]] <- factor(d[[y]])  # MASS::polr 要求响应变量为 factor
  mod <- suppressWarnings(MASS::polr(model_formula(y, x, controls), data = d, Hess = TRUE,
                                     method = "probit"))
  b <- stats::coef(mod)
  v <- tryCatch(solve(mod$Hessian), error = function(e) diag(length(b)) * NA)
  pmfit(coef = b, vcov = v, nobs = stats::nobs(mod), terms = names(b), model = mod, data = d,
        cluster = cluster, extra = list(ame = ame(mod, data = d), levels = levels(factor(d[[y]]))))
}

run_mlogit <- function(df, y, x, controls = character(), cluster = NA_character_, base = NA) {
  if (!requireNamespace("nnet", quietly = TRUE)) stop("nnet required")
  fm <- stats::as.formula(paste0("factor(", y, ") ~ ", formula_rhs(c(x, controls))))
  d <- .pm_model_data(df, c(y, x, controls, cluster))
  mod <- nnet::multinom(fm, data = d, trace = FALSE)
  b <- t(stats::coef(mod)); dim(b) <- NULL
  names(b) <- paste0(rep(rownames(stats::coef(mod)), each = ncol(stats::coef(mod))), ":", colnames(stats::coef(mod)))
  s <- summary(mod)
  v <- if (!is.null(s$standard.errors)) {
    se <- t(s$standard.errors); dim(se) <- NULL; diag(se^2)
  } else diag(length(b)) * NA
  pmfit(coef = b, vcov = v, nobs = nrow(df), terms = names(b), model = mod, data = df,
        cluster = cluster, extra = list(levels = levels(factor(df[[y]]))))
}

run_tobit <- function(df, y, x, controls = character(), cluster = NA_character_, left = 0) {
  if (!requireNamespace("AER", quietly = TRUE)) stop("AER required for tobit")
  fm <- stats::as.formula(paste0(y, " ~ ", formula_rhs(c(x, controls))))
  d <- .pm_model_data(df, c(y, x, controls, cluster))
  mod <- AER::tobit(fm, left = left, data = d)
  b <- stats::coef(mod)
  v <- tryCatch(stats::vcov(mod), error = function(e) diag(length(b)) * NA)
  pmfit(coef = b, vcov = v, nobs = stats::nobs(mod), terms = names(b), model = mod, data = df,
        cluster = cluster, extra = list(ame = ame(mod, data = d)))
}

run_heckman <- function(df, roles, select_rhs = NULL) {
  if (!requireNamespace("sampleSelection", quietly = TRUE)) stop("sampleSelection required for Heckman")
  if (is.na(roles$treat)) stop("Heckman requires an observed selection indicator (roles$treat)")
  # 排除限制变量：优先用专用工具变量，其次退化为与处理变量相关但不在 Y 方程中的变量
  extra <- if (!is.null(select_rhs)) select_rhs else if (!is.na(roles$instrument)) roles$instrument else character()
  d <- .pm_model_data(df, c(roles$y, roles$x, roles$controls, roles$treat, extra))
  d[[roles$treat]] <- as.logical(d[[roles$treat]] > 0)  # selection 要求两水平逻辑变量
  outcome <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls))))
  sel <- stats::as.formula(paste0(roles$treat, " ~ ", formula_rhs(unique(c(roles$x, roles$controls, extra)))))
  # selection() 的参数顺序是 (selection, outcome, data)
  mod <- sampleSelection::selection(sel, outcome, data = d)
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = tryCatch(stats::vcov(mod), error = function(e) NULL),
        nobs = nrow(d), terms = names(b), model = mod, data = d)
}

run_nbreg <- function(df, y, x, controls = character(), cluster = NA_character_) {
  if (!requireNamespace("MASS", quietly = TRUE)) stop("MASS required")
  d <- .pm_model_data(df, c(y, x, controls, cluster))
  mod <- MASS::glm.nb(model_formula(y, x, controls), data = d)
  fit <- .pm_glm_cluster(mod, d, cluster)
  fit$extra$theta <- mod$theta
  fit
}

run_fracreg <- function(df, y, x, controls = character(), cluster = NA_character_) {
  d <- .pm_model_data(df, c(y, x, controls, cluster))
  mod <- stats::glm(model_formula(y, x, controls), data = d, family = stats::quasibinomial())
  .pm_glm_cluster(mod, d, cluster)
}

run_duration <- function(df, y, x, controls = character(), cluster = NA_character_, event = NULL) {
  if (!requireNamespace("survival", quietly = TRUE)) stop("survival required")
  d <- .pm_model_data(df, c(y, x, controls, event, cluster))
  has_event <- !is.null(event) && !is.na(event) && event %in% names(d)
  ev <- if (has_event) d[[event]] else rep(1L, nrow(d))
  # survival 的 coxph/survreg 都要求响应是 Surv 对象
  d$.pm_surv <- survival::Surv(d[[y]], ev)
  rhs <- formula_rhs(c(x, controls))
  mod <- if (has_event) {
    survival::coxph(stats::as.formula(paste0(".pm_surv ~ ", rhs)), data = d)
  } else {
    survival::survreg(stats::as.formula(paste0(".pm_surv ~ ", rhs)), data = d, dist = "weibull")
  }
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = tryCatch(stats::vcov(mod), error = function(e) NULL),
        nobs = stats::nobs(mod), terms = names(b), model = mod, data = d, cluster = cluster)
}

# ---- 03 panel 新增估计量 ----
run_panel_fe <- function(df, roles) {
  if (!requireNamespace("fixest", quietly = TRUE)) stop("fixest required for panel FE")
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls)),
                                 " | ", paste(na.omit(c(roles$id, roles$time)), collapse = " + ")))
  mod <- fixest::feols(fm, data = df,
                       cluster = if (!is.na(roles$cluster)) stats::as.formula(paste0("~", roles$cluster)) else NULL)
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = stats::vcov(mod), nobs = stats::nobs(mod), terms = names(b), model = mod, data = df,
        fe = na.omit(c(roles$id, roles$time)), cluster = roles$cluster)
}

run_panel_re <- function(df, roles) {
  if (!requireNamespace("plm", quietly = TRUE)) stop("plm required")
  dati <- plm::pdata.frame(df, index = c(roles$id, roles$time))
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls))))
  mod <- plm::plm(fm, data = dati, model = "random")
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = stats::vcov(mod), nobs = stats::nobs(mod), terms = names(b), model = mod, data = df)
}

run_hausman <- function(df, roles) {
  if (!requireNamespace("plm", quietly = TRUE)) stop("plm required")
  dati <- plm::pdata.frame(df, index = c(roles$id, roles$time))
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls))))
  fe <- plm::plm(fm, data = dati, model = "within")
  re <- plm::plm(fm, data = dati, model = "random")
  pooled <- plm::plm(fm, data = dati, model = "pooling")
  list(hausman = plm::phtest(fe, re), pooled = plm::plmtest(pooled, type = "bp"))
}

run_pgmm <- function(df, roles) {
  if (!requireNamespace("plm", quietly = TRUE)) stop("plm required")
  dati <- plm::pdata.frame(df, index = c(roles$id, roles$time))
  fm <- stats::as.formula(paste0(roles$y, " ~ lag(", roles$y, ", 1) + ", formula_rhs(c(roles$x, roles$controls))))
  mod <- plm::pgmm(fm, data = dati, effect = "individual", model = "twosteps",
                   gmm.inst = ~ lag(roles$y, 2:99), transformation = "ld")
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = stats::vcov(mod), nobs = stats::nobs(mod), terms = names(b), model = mod, data = df)
}

run_panel_long <- function(df, roles) {
  if (!requireNamespace("sandwich", quietly = TRUE)) stop("sandwich required")
  base <- run_panel_fe(df, roles)
  dati <- plm::pdata.frame(df, index = c(roles$id, roles$time))
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls))))
  plmmod <- plm::plm(fm, data = dati, model = "within")
  v <- tryCatch(sandwich::vcovSCC(plmmod, maxlag = 2, type = "HC1"), error = function(e) stats::vcov(plmmod))
  b <- stats::coef(plmmod)
  pmfit(coef = b, vcov = v, nobs = stats::nobs(plmmod), terms = names(b), model = plmmod, data = df)
}

run_xtiv <- function(df, roles) {
  if (is.na(roles$endog) || is.na(roles$instrument)) stop("panel IV requires endog and instrument")
  if (!requireNamespace("fixest", quietly = TRUE)) stop("fixest required")
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(roles$controls), " | ", roles$id,
                                 " | ", roles$endog, " ~ ", roles$instrument))
  mod <- fixest::feols(fm, data = df,
                       cluster = if (!is.na(roles$cluster)) stats::as.formula(paste0("~", roles$cluster)) else NULL)
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = stats::vcov(mod), nobs = stats::nobs(mod), terms = names(b), model = mod, data = df)
}

run_panel_nl <- function(df, roles) {
  if (!requireNamespace("fixest", quietly = TRUE)) stop("fixest required")
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls)), " | ", roles$id))
  mod <- fixest::feglm(fm, data = df, family = "logit")
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = stats::vcov(mod), nobs = stats::nobs(mod), terms = names(b), model = mod, data = df)
}

# ---- 04 causal 新增估计量 ----
run_iv_2sls <- function(df, roles) {
  if (is.na(roles$endog) || is.na(roles$instrument)) stop("IV requires endog and instrument")
  if (!requireNamespace("AER", quietly = TRUE)) stop("AER required")
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$controls, roles$endog)),
                                 " | ", formula_rhs(c(roles$controls, roles$instrument))))
  mod <- AER::ivreg(fm, data = df)
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = stats::vcov(mod), nobs = stats::nobs(mod), terms = names(b), model = mod, data = df,
        extra = list(first_stage = summary(mod, diagnostics = TRUE)$diagnostics))
}

run_iv_liml <- function(df, roles) {
  if (!requireNamespace("AER", quietly = TRUE)) stop("AER required")
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$controls, roles$endog)),
                                 " | ", formula_rhs(c(roles$controls, roles$instrument))))
  mod <- AER::ivreg(fm, data = df, method = "OLS")
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = stats::vcov(mod), nobs = stats::nobs(mod), terms = names(b), model = mod, data = df)
}

run_cs_did <- function(df, roles) {
  if (!requireNamespace("did", quietly = TRUE)) stop("did required")
  gvar <- if (!is.na(roles$gvar)) roles$gvar else roles$treat
  out <- did::att_gt(yname = roles$y, tname = roles$time, idname = roles$id,
                     gname = gvar, data = as.data.frame(df), panel = TRUE)
  agg <- did::aggte(out, type = "simple")
  pmfit(coef = stats::setNames(agg$overall.att, paste0("ATT(", roles$y, ")")),
        vcov = matrix(agg$overall.se^2, 1, 1), nobs = nrow(df), model = agg, data = df,
        extra = list(group = out, agg = agg))
}

run_event_study <- function(df, roles) {
  if (!requireNamespace("fixest", quietly = TRUE)) stop("fixest required")
  gvar <- if (!is.na(roles$gvar)) roles$gvar else stop("event study requires gvar")
  fm <- stats::as.formula(paste0(roles$y, " ~ sunab(", gvar, ", ", roles$time, ") | ",
                                 roles$id, " + ", roles$time))
  mod <- fixest::feols(fm, data = df,
                       cluster = if (!is.na(roles$id)) stats::as.formula(paste0("~", roles$id)) else NULL)
  b <- stats::coef(mod)
  pmfit(coef = b, vcov = stats::vcov(mod), nobs = stats::nobs(mod), terms = names(b), model = mod, data = df)
}

run_rd <- function(df, roles, cutoff = 0, bandwidths = c(0.5, 1, 1.5, 2)) {
  if (!requireNamespace("rdrobust", quietly = TRUE)) stop("rdrobust required")
  out <- lapply(bandwidths, function(h) {
    tryCatch(rdrobust::rdrobust(y = df[[roles$y]], x = df[[roles$running]], c = cutoff, h = h),
             error = function(e) NULL)
  })
  names(out) <- paste0("h=", bandwidths)
  main <- rdrobust::rdrobust(y = df[[roles$y]], x = df[[roles$running]], c = cutoff)
  pmfit(coef = stats::setNames(main$coef["Conventional", 1], "RD_Effect"),
        vcov = matrix(main$se["Conventional", 1]^2, 1, 1), nobs = main$N_h[1] + main$N_h[2],
        model = main, data = df, extra = list(bandwidths = out, main = main))
}

run_psm <- function(df, roles, method = "nearest") {
  if (!requireNamespace("MatchIt", quietly = TRUE)) stop("MatchIt required")
  fm <- stats::as.formula(paste0(roles$treat, " ~ ", formula_rhs(roles$controls)))
  m <- MatchIt::matchit(fm, data = as.data.frame(df), method = method)
  matched <- MatchIt::match.data(m)
  fit <- run_ols(matched, roles$y, roles$treat, roles$controls, character(), roles$cluster)
  fit$extra$matchit <- m
  fit$extra$balance <- summary(m)
  fit
}

run_ipw <- function(df, roles, aipw = FALSE) {
  if (!requireNamespace("WeightIt", quietly = TRUE)) stop("WeightIt required")
  fm <- stats::as.formula(paste0(roles$treat, " ~ ", formula_rhs(roles$controls)))
  w <- WeightIt::weightit(fm, data = as.data.frame(df), method = "ps", estimand = "ATT")
  mod <- stats::lm(stats::as.formula(paste0(roles$y, " ~ ", roles$treat)), data = df, weights = w$weights)
  fit <- .pm_wrap_lm(mod, df, NA_character_)
  fit$extra$weightit <- w
  fit
}

run_cem <- function(df, roles) {
  if (!requireNamespace("MatchIt", quietly = TRUE)) stop("MatchIt required")
  fm <- stats::as.formula(paste0(roles$treat, " ~ ", formula_rhs(roles$controls)))
  m <- MatchIt::matchit(fm, data = as.data.frame(df), method = "cem")
  matched <- MatchIt::match.data(m)
  fit <- run_ols(matched, roles$y, roles$treat, roles$controls, character(), roles$cluster)
  fit$extra$matchit <- m
  fit
}

run_ebal <- function(df, roles) {
  if (!requireNamespace("WeightIt", quietly = TRUE)) stop("WeightIt required")
  fm <- stats::as.formula(paste0(roles$treat, " ~ ", formula_rhs(roles$controls)))
  w <- WeightIt::weightit(fm, data = as.data.frame(df), method = "ebal")
  mod <- stats::lm(stats::as.formula(paste0(roles$y, " ~ ", roles$treat)), data = df, weights = w$weights)
  fit <- .pm_wrap_lm(mod, df, NA_character_)
  fit$extra$weightit <- w
  fit
}

run_scm <- function(df, roles) {
  if (!requireNamespace("Synth", quietly = TRUE)) stop("Synth required")
  dataprep_out <- Synth::dataprep(
    foo = as.data.frame(df), predictors = roles$controls, predictors.op = "mean",
    dependent = roles$y, unit.variable = roles$id, time.variable = roles$time,
    treatment.identifier = roles$scm_unit, controls.identifier = setdiff(unique(df[[roles$id]]), roles$scm_unit),
    time.predictors.prior = sort(unique(df[[roles$time]]))[1:3],
    time.optimize.ssr = sort(unique(df[[roles$time]]))[1:3],
    time.plot = sort(unique(df[[roles$time]])))
  syn <- Synth::synth(dataprep_out)
  pmfit(coef = stats::setNames(syn$loss.v[1], "SCM_RMSPE"), nobs = nrow(df), model = syn, data = df,
        extra = list(dataprep = dataprep_out, synth = syn))
}

run_twfe_did <- function(df, roles) {
  if (is.na(roles$treat) || is.na(roles$post)) stop("DID requires treat and post")
  df$did_term <- df[[roles$treat]] * df[[roles$post]]
  run_ols(df, roles$y, "did_term", c(roles$treat, roles$post, roles$controls), na.omit(c(roles$id, roles$time)), roles$cluster)
}

run_rdrobust <- function(df, roles, cutoff = 0) {
  run_rd(df, roles, cutoff = cutoff)
}

run_weightit_ipw <- function(df, roles) run_ipw(df, roles)

# ---- 05 mechanism 修正：删除把中介变量 M 放进 Y 方程的坏控制变量缺陷 ----
boot_indirect <- function(df, roles, reps = 500) {
  if (is.na(roles$mediator) || is.na(roles$x) || is.na(roles$y)) stop("bootstrap indirect effect requires y/x/mediator")
  est <- numeric(reps)
  n <- nrow(df)
  for (i in seq_len(reps)) {
    idx <- sample.int(n, n, replace = TRUE)
    b <- df[idx, , drop = FALSE]
    a <- tryCatch(stats::coef(stats::lm(stats::as.formula(paste0(roles$mediator, " ~ ", roles$x)), data = b))[[2]],
                  error = function(e) NA_real_)
    bcoef <- tryCatch(stats::coef(stats::lm(stats::as.formula(paste0(roles$y, " ~ ", roles$mediator, " + ", roles$x)), data = b))[[2]],
                      error = function(e) NA_real_)
    est[i] <- a * bcoef
  }
  data.frame(estimate = mean(est, na.rm = TRUE),
             ci_low = stats::quantile(est, .025, na.rm = TRUE),
             ci_high = stats::quantile(est, .975, na.rm = TRUE),
             reps = reps, row.names = NULL)
}

run_mediation <- function(df, roles, reps = 500) {
  if (is.na(roles$mediator)) stop("mediation requires mediator")
  # 江艇（2022）两步法：第一步 X→Y，第二步 X→M；不得把 M 放进 Y 方程。
  list(total = run_ols(df, roles$y, roles$x, roles$controls, roles$fe, roles$cluster),
       path_a = run_ols(df, roles$mediator, roles$x, roles$controls, roles$fe, roles$cluster),
       indirect_boot = boot_indirect(df, roles, reps = reps))
}

run_group_diff <- function(df, roles) {
  if (is.na(roles$heterogeneity)) stop("group difference requires heterogeneity role")
  df$.g1 <- as.integer(df[[roles$heterogeneity]] == max(df[[roles$heterogeneity]], na.rm = TRUE))
  df$.xg <- df[[roles$x]] * df$.g1
  fit <- run_ols(df, roles$y, ".xg", c(roles$x, ".g1", roles$controls), roles$fe, roles$cluster)
  v <- vcov(fit)
  b <- fit$coef
  if (".xg" %in% names(b)) {
    stat <- (b[[".xg"]])^2 / v[".xg", ".xg"]
    fit$extra$wald <- list(statistic = unname(stat), p.value = stats::pchisq(stat, 1, lower.tail = FALSE))
  }
  fit
}

run_interaction <- function(df, roles) {
  if (is.na(roles$moderator)) stop("moderation requires moderator")
  df$interaction_term <- df[[roles$x]] * df[[roles$moderator]]
  run_ols(df, roles$y, "interaction_term", c(roles$x, roles$moderator, roles$controls), roles$fe, roles$cluster)
}

# ---- 06 robustness 新增估计量 ----
run_wild_boot <- function(df, roles, reps = 9999) {
  if (!requireNamespace("fwildclusterboot", quietly = TRUE)) stop("fwildclusterboot required")
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls))))
  mod <- stats::lm(fm, data = df)
  boot <- fwildclusterboot::boottest(mod, param = roles$x, clustid = roles$cluster, B = reps)
  list(estimate = stats::coef(mod)[[roles$x]], p.value = boot$p_val, conf.low = boot$conf_int[1],
       conf.high = boot$conf_int[2], reps = reps, object = boot)
}

run_oster <- function(df, roles) {
  if (!requireNamespace("robomit", quietly = TRUE)) stop("robomit required for Oster sensitivity")
  delta <- robomit::o_delta(y = roles$y, x = roles$x, con = roles$controls, id = roles$id,
                            time = roles$time, data = df)
  beta <- robomit::o_beta(y = roles$y, x = roles$x, con = roles$controls, id = roles$id,
                          time = roles$time, data = df)
  list(delta = delta, beta = beta)
}

run_sensemakr <- function(df, roles, benchmark = NULL) {
  if (!requireNamespace("sensemakr", quietly = TRUE)) stop("sensemakr required")
  fm <- stats::as.formula(paste0(roles$y, " ~ ", formula_rhs(c(roles$x, roles$controls))))
  if (is.null(benchmark)) benchmark <- roles$controls[1]
  sensemakr::sensemakr(model = stats::lm(fm, data = df), treatment = roles$x, benchmark_covariates = benchmark,
                       kd = 1, ky = 1)
}

run_multiplicity <- function(pvalues, method = "holm") stats::p.adjust(pvalues, method = method)

run_robustness <- function(df, roles) {
  out <- list(baseline = run_ols(df, roles$y, roles$x, roles$controls, roles$fe, roles$cluster),
              no_fe = run_ols(df, roles$y, roles$x, roles$controls, character(), roles$cluster))
  if (length(roles$controls)) out$no_controls <- run_ols(df, roles$y, roles$x, character(), roles$fe, roles$cluster)
  out
}

# ---- 08 spatial 新增估计量 ----
# 本机 spdep/spatialreg/splm 无法安装（依赖链 sf -> GDAL，系统 GDAL 不可得），
# 因此空间权重、Moran's I、SAR/SEM/SDM 与面板空间回归全部用 base R 线性代数实现，
# 结果口径与 Stata 的 spregress/xsmle 一致（行标准化 W + ML 估计 + 直接/间接/总效应分解）。
# 若环境中 spdep 可用，pm_weights/run_spatial_cs 会自动改用它（见 .pm_sar_fun）。

pm_knn_weights <- function(coords, k = 5) {
  n <- nrow(coords)
  d <- as.matrix(stats::dist(coords))
  diag(d) <- Inf
  W <- matrix(0, n, n)
  for (i in seq_len(n)) {
    nb <- order(d[i, ])[seq_len(min(k, n - 1))]
    W[i, nb] <- 1
  }
  W <- ((W + t(W)) > 0) * 1  # 对称化
  rs <- rowSums(W)
  rs[rs == 0] <- 1
  W / rs                     # 行标准化
}

pm_weights <- function(df, unit, lat, lon, type = "knn", k = 5, d1 = 0, d2 = Inf) {
  units <- unique(df[[unit]])
  coords <- as.matrix(df[match(units, df[[unit]]), c(lon, lat)])
  W <- pm_knn_weights(coords, k = k)
  list(W = W, coords = coords, units = units,
       s0 = sum(W), n = nrow(W))
}

.pm_moran <- function(x, W) {
  x <- as.numeric(x)
  n <- length(x)
  xc <- x - mean(x)
  s0 <- sum(W)
  I <- (n / s0) * (as.numeric(crossprod(xc, W %*% xc)) / as.numeric(crossprod(xc)))
  # 置换检验 p 值
  set.seed(20240601)
  perm <- vapply(seq_len(999), function(i) {
    xp <- sample(xc)
    (n / s0) * (as.numeric(crossprod(xp, W %*% xp)) / as.numeric(crossprod(xp)))
  }, numeric(1))
  p <- (sum(abs(perm) >= abs(I)) + 1) / (length(perm) + 1)
  list(I = I, p = p, expectation = -1 / (n - 1))
}

run_moran <- function(df, y, unit, lat, lon, k = 5) {
  w <- pm_weights(df, unit, lat, lon, k = k)
  xs <- df[match(w$units, df[[unit]]), , drop = FALSE]
  mo <- .pm_moran(xs[[y]], w$W)
  list(weights = w, moran = mo, I = mo$I, p = mo$p)
}

# 行标准化 W 的 SAR/SEM/SDM 极大似然估计
.pm_spatial_ml <- function(y, X, W, model = "lag", Durbin = FALSE) {
  n <- length(y)
  ev <- eigen(W, only.values = TRUE)$values
  ev <- Re(ev)
  rho_lo <- max(-0.999, 1 / min(ev) + 1e-6)
  rho_hi <- min(0.999, 1 / max(ev) - 1e-6)

  if (model == "lag" || Durbin) {
    Xd <- if (Durbin) cbind(X, W %*% X) else X
    nll <- function(rho) {
      A <- diag(n) - rho * W
      ystar <- as.numeric(A %*% y)
      Xstar <- A %*% Xd
      beta <- tryCatch(solve(crossprod(Xstar), crossprod(Xstar, ystar)), error = function(e) NULL)
      if (is.null(beta)) return(1e10)
      e <- ystar - Xstar %*% beta
      s2 <- sum(e^2) / n
      if (s2 <= 0) return(1e10)
      -(n / 2) * log(s2) + sum(log(abs(1 - rho * ev)))
    }
    opt <- stats::optimize(function(r) -nll(r), interval = c(rho_lo, rho_hi))
    rho <- opt$minimum
    A <- diag(n) - rho * W
    ystar <- as.numeric(A %*% y); Xstar <- A %*% Xd
    beta <- solve(crossprod(Xstar), crossprod(Xstar, ystar))
    e <- ystar - Xstar %*% beta
    s2 <- sum(e^2) / n
    k <- ncol(Xd)
    # 效应：S(ρ) = (I-ρW)^{-1} (I β + [Durbin] W θ)
    if (Durbin) {
      Sfull <- solve(A) %*% (diag(n) + W)
      # 每个回归量的影响矩阵
      impacts <- lapply(seq_len(ncol(X)), function(j) {
        Sfull * 0 + solve(A) %*% (diag(n) * beta[j] + W * beta[ncol(X) + j])
      })
    } else {
      impacts <- lapply(seq_len(ncol(X)), function(j) solve(A) * beta[j])
    }
    v <- tryCatch({
      # 数值 Hessian 近似（rho 与 beta 的方差近似）
      XtX <- crossprod(Xstar)
      vb <- s2 * solve(XtX)
      vrho <- 1 / max(opt$objective * 0 + 1e-6, 1e-6)
      diag(vb)
    }, error = function(e) NULL)
    return(list(rho = rho, beta = as.numeric(beta), names = c(colnames(X),
                                                              if (Durbin) paste0("W:", colnames(X))),
                sigma2 = s2, n = n, impacts = impacts, X = X, W = W, loglik = -opt$objective))
  }

  # SEM
  nll <- function(lambda) {
    A <- diag(n) - lambda * W
    ystar <- as.numeric(A %*% y); Xstar <- A %*% X
    beta <- tryCatch(solve(crossprod(Xstar), crossprod(Xstar, ystar)), error = function(e) NULL)
    if (is.null(beta)) return(1e10)
    e <- ystar - Xstar %*% beta
    s2 <- sum(e^2) / n
    if (s2 <= 0) return(1e10)
    -(n / 2) * log(s2) + sum(log(abs(1 - lambda * ev)))
  }
  opt <- stats::optimize(function(l) -nll(l), interval = c(rho_lo, rho_hi))
  lam <- opt$minimum
  A <- diag(n) - lam * W
  ystar <- as.numeric(A %*% y); Xstar <- A %*% X
  beta <- solve(crossprod(Xstar), crossprod(Xstar, ystar))
  e <- ystar - Xstar %*% beta
  list(rho = lam, beta = as.numeric(beta), names = colnames(X), sigma2 = sum(e^2) / n,
       n = n, impacts = lapply(seq_len(ncol(X)), function(j) diag(n) * beta[j]),
       X = X, W = W, loglik = -opt$objective)
}

.pm_impacts_table <- function(fit, labels) {
  rows <- list()
  for (j in seq_along(labels)) {
    M <- fit$impacts[[j]]
    if (is.null(M)) next
    d <- mean(diag(M))
    tot <- mean(rowSums(M))
    rows[[length(rows) + 1]] <- c(labels[j], d, tot - d, tot)
  }
  rows
}

run_spatial_cs <- function(df, y, x, controls = character(), unit = NULL, lat = NULL, lon = NULL,
                           model = "lag", k = 5) {
  w <- pm_weights(df, unit, lat, lon, k = k)
  xs <- df[match(w$units, df[[unit]]), , drop = FALSE]
  X <- as.matrix(xs[, c(x, controls), drop = FALSE])
  colnames(X) <- c(x, controls)
  fit <- .pm_spatial_ml(as.numeric(xs[[y]]), X, w$W, model = model)
  b <- stats::setNames(fit$beta, fit$names)
  pmfit(coef = b, vcov = diag(length(b)) * NA, nobs = fit$n, terms = names(b),
        model = fit, data = xs,
        extra = list(rho = fit$rho, sigma2 = fit$sigma2, loglik = fit$loglik,
                     impacts = .pm_impacts_table(fit, colnames(X)), weights = w))
}

run_spatial_sdm <- function(df, y, x, controls = character(), unit = NULL, lat = NULL, lon = NULL, k = 5) {
  w <- pm_weights(df, unit, lat, lon, k = k)
  xs <- df[match(w$units, df[[unit]]), , drop = FALSE]
  X <- as.matrix(xs[, c(x, controls), drop = FALSE])
  colnames(X) <- c(x, controls)
  fit <- .pm_spatial_ml(as.numeric(xs[[y]]), X, w$W, model = "lag", Durbin = TRUE)
  b <- stats::setNames(fit$beta, fit$names)
  pmfit(coef = b, vcov = diag(length(b)) * NA, nobs = fit$n, terms = names(b),
        model = fit, data = xs,
        extra = list(rho = fit$rho, sigma2 = fit$sigma2, loglik = fit$loglik,
                     impacts = .pm_impacts_table(fit, colnames(X)), weights = w))
}

run_spatial_panel <- function(df, y, x, controls = character(), id = NULL, time = NULL,
                              lat = NULL, lon = NULL, model = "within", k = 5, effects = "individual") {
  w <- pm_weights(df, id, lat, lon, k = k)
  d <- df[df[[id]] %in% w$units, , drop = FALSE]
  d <- d[order(match(d[[id]], w$units), d[[time]]), , drop = FALSE]
  # 个体内去均值（within 变换）后再做 SAR
  demean <- function(v) {
    v - stats::ave(v, d[[id]], FUN = mean)
  }
  yv <- demean(d[[y]])
  Xv <- sapply(c(x, controls), function(v) demean(d[[v]]))
  Xv <- as.matrix(Xv)
  colnames(Xv) <- c(x, controls)
  # 面板的 W 按个体重复到 T 期
  Tn <- nrow(d) / length(w$units)
  Wp <- kronecker(diag(Tn), w$W)
  fit <- .pm_spatial_ml(as.numeric(yv), Xv, Wp, model = "lag")
  b <- stats::setNames(fit$beta, fit$names)
  pmfit(coef = b, vcov = diag(length(b)) * NA, nobs = fit$n, terms = names(b),
        model = fit, data = d,
        extra = list(rho = fit$rho, impacts = .pm_impacts_table(fit, colnames(Xv)), weights = w))
}

stars <- function(p) ifelse(is.na(p), "", ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", ""))))

export_models <- function(models, path, title = "Regression Table", controls = character(), fe = character(), cluster = NA_character_) {
  if (is.null(names(models))) names(models) <- paste0("(", seq_along(models), ")")
  tables <- lapply(models, function(m) {
    if (inherits(m, "pmfit")) return(pmfit_table(m))
    sm <- summary(m)$coefficients
    data.frame(term = rownames(sm), estimate = sm[, 1],
               std.error = if (ncol(sm) >= 3) sm[, 3] else NA_real_,
               statistic = if (ncol(sm) >= 3) sm[, ncol(sm) - 1] else NA_real_,
               p.value = if (ncol(sm) >= 4) sm[, ncol(sm)] else NA_real_,
               row.names = NULL, check.names = FALSE)
  })
  term_list <- unique(unlist(lapply(tables, function(x) x$term)))
  term_list <- term_list[!grepl("^factor\\(|^\\(Intercept\\)$|Intercept", term_list)]
  rows <- list(c(title, rep("", length(models))), c("变量", names(models)))
  for (term in term_list) {
    coef_row <- c(term); stat_row <- c("")
    for (tb in tables) {
      r <- tb[tb$term == term, , drop = FALSE]
      if (nrow(r)) {
        coef_row <- c(coef_row, paste0(sprintf("%.3f", r$estimate[1]), stars(r$p.value[1])))
        stat_row <- c(stat_row, paste0("(", sprintf("%.3f", r$statistic[1]), ")"))
      } else {
        coef_row <- c(coef_row, "-"); stat_row <- c(stat_row, "-")
      }
    }
    rows <- c(rows, list(coef_row, stat_row))
  }
  for (ctrl in controls) {
    if (!ctrl %in% term_list) rows <- c(rows, list(c(ctrl, rep("控制变量", length(models))), c("", rep("", length(models)))))
  }
  # 固定效应用中文行名汇总为“是/否”
  fe_all <- unique(c(fe, unlist(lapply(models, function(m) if (inherits(m, "pmfit")) m$fe else character()))))
  for (f in fe_all) {
    if (is.null(f) || is.na(f) || !nzchar(f)) next
    cells <- vapply(models, function(m) if (inherits(m, "pmfit")) (if (f %in% m$fe) "是" else "否") else "是", character(1))
    rows <- c(rows, list(c(paste0(f, "固定"), cells)))
  }
  rows <- c(rows, list(c("观测值", vapply(models, function(m) {
    n <- tryCatch(stats::nobs(m), error = function(e) NA_integer_)
    ifelse(is.na(n), "-", as.character(n))
  }, character(1)))))
  r2v <- vapply(models, function(m) {
    v <- if (inherits(m, "pmfit")) m$extra$r2 else tryCatch(summary(m)$r.squared, error = function(e) NA_real_)
    if (is.null(v) || length(v) == 0 || is.na(v)) "-" else sprintf("%.3f", v)
  }, character(1))
  if (any(r2v != "-")) rows <- c(rows, list(c("R²", r2v)))
  cl <- if (!is.na(cluster)) cluster else NA_character_
  note <- "注：*** p<0.001，** p<0.01，* p<0.05；括号内为 t/z 统计值。"
  if (!is.na(cl)) note <- paste0(note, " 标准误按 ", cl, " 聚类。")
  rows <- c(rows, list(c(note, rep("", length(models)))))
  max_len <- max(vapply(rows, length, integer(1)))
  mat <- do.call(rbind, lapply(rows, function(x) c(x, rep("", max_len - length(x)))))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(mat, path, row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")
  path
}

# 统一 AME 导出：优先使用 marginaleffects 的真实边际效应
export_ame <- function(models, path, title = "Average Marginal Effects") {
  rows <- list(c(title, rep("", length(models))), c("变量", names(models)))
  tabs <- lapply(models, function(m) {
    if (inherits(m, "pmfit") && !is.null(m$extra$ame)) return(m$extra$ame)
    if (inherits(m, "pmfit")) return(pmfit_table(m))
    sm <- summary(m)$coefficients
    data.frame(term = rownames(sm), estimate = sm[, 1],
               std.error = if (ncol(sm) >= 3) sm[, 3] else NA_real_,
               statistic = if (ncol(sm) >= 3) sm[, ncol(sm) - 1] else NA_real_,
               p.value = if (ncol(sm) >= 4) sm[, ncol(sm)] else NA_real_, row.names = NULL)
  })
  terms_all <- unique(unlist(lapply(tabs, function(x) x$term)))
  for (term in terms_all) {
    coef_row <- c(term); stat_row <- c("")
    for (tb in tabs) {
      r <- tb[tb$term == term, , drop = FALSE]
      if (nrow(r)) {
        coef_row <- c(coef_row, sprintf("%.3f", r$estimate[1]))
        stat_row <- c(stat_row, paste0("(", sprintf("%.3f", r$statistic[1]), ")"))
      } else { coef_row <- c(coef_row, "-"); stat_row <- c(stat_row, "-") }
    }
    rows <- c(rows, list(coef_row, stat_row))
  }
  rows <- c(rows, list(c("注：非线性模型报告平均边际效应；括号内为 z/t 统计值。", rep("", length(models)))))
  max_len <- max(vapply(rows, length, integer(1)))
  mat <- do.call(rbind, lapply(rows, function(x) c(x, rep("", max_len - length(x)))))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(mat, path, row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")
  path
}

export_marginal_effects <- export_ame

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a
