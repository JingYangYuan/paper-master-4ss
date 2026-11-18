# 07-ml/02-causal-ml：PDS 挑控制、DML 部分线性模型、Lasso 挑工具变量
#
# 任务（--tasks 逗号分隔，留空全跑）：
#   pds-controls  后双重选择（Belloni-Chernozhukov-Hansen 2014）：glmnet 分别对 Y 方程、
#                 X 方程做 Lasso 选控制，取并集再 OLS，与「全部候选控制」并表
#   dml-plr       部分线性 DML（Chernozhukov et al. 2018）：glmnet nuisance + K 折交叉拟合，
#                 报点估计、HC1 标准误、基准 OLS 并列、折间系数范围
#   iv-lasso      Lasso 筛工具变量后做 2SLS，报第一阶段 F
#
# 口径对齐 02-causal-ml/causal_ml.py：任务 ID、输出表文件名、CSV 列名、
# 报告文件名（reports/ml-run-02-causal-ml-<YYYY-MM-DD>.md）一律照 .py，中文列名一字不改。
# 差别：本机未装 histgb（sklearn），DML 的 nuisance 学习器改用 glmnet（--learner lasso/ridge/enet），
# 未装的森林类 nuisances 由 04-ml-export 写进 ml-not-run-list.csv，不在这里假装跑过。
#
# 纪律（同 .py，见 phases/07-ml-and-causal-ml.md §5）：
#   - 交叉拟合一折一系数，全折汇总报点估计与折间波动；只报一次拟合的 DML 等于没做。
#   - 每次 ML 估计都必须与「同一控制集下的基准 OLS/2SLS」并表，差异要解释。
#   - 控制集由 Lasso 选出，不等于外生性成立；PDS/DML 只解决正则化偏误（C28、C30）。
#   - 缺依赖、缺角色就写阻断，不写占位数字。

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE)
  file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat {
    candidate <- file.path(p, "_shared", "r_common.R")
    if (file.exists(candidate)) return(candidate)
    np <- dirname(p)
    if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R")
    p <- np
  }
}
source(find_shared())

# ---- 本地小工具：不改 _shared/ 下的任何文件 ----
pm_extra_args <- function(defaults) {
  a <- commandArgs(trailingOnly = TRUE)
  out <- defaults
  i <- 1
  while (i <= length(a)) {
    if (grepl("^--", a[[i]])) {
      key <- gsub("-", "_", sub("^--", "", a[[i]]))
      if (key %in% names(defaults) && i + 1 <= length(a) && !grepl("^--", a[[i + 1]])) {
        out[[key]] <- a[[i + 1]]
        i <- i + 2
        next
      }
    }
    i <- i + 1
  }
  out
}

pm_read_dict_roles <- function(path) {
  if (is.na(path) || !nzchar(path) || !file.exists(path)) return(NULL)
  d <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
                error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(NULL)
  var_col <- intersect(c("clean_name", "raw_name", "variable"), names(d))[1]
  role_col <- intersect(c("role", "variable_role"), names(d))[1]
  if (is.na(var_col) || is.na(role_col)) return(NULL)
  var <- trimws(as.character(d[[var_col]]))
  role <- tolower(trimws(as.character(d[[role_col]])))
  ok <- nzchar(var) & nzchar(role)
  var <- var[ok]; role <- role[ok]
  ex <- function(key) unique(var[role == key])
  gr <- function(key) unique(var[grepl(key, role, fixed = TRUE)])
  list(y = ex("y"), x = ex("x"), control = gr("control"), fe = ex("fe"),
       heterogeneity = gr("heterogeneity"), moderator = gr("moderator"),
       instrument = gr("instrument"), id = ex("id"), time = gr("time"),
       cluster = gr("cluster"))
}

pm_roles <- function(df, dict_path = NA_character_) {
  r <- infer_roles(df, dict_path)
  d <- pm_read_dict_roles(dict_path)
  if (!is.null(d)) {
    pick <- function(v, fallback) { v <- v[v %in% names(df)]; if (length(v)) v[[1]] else fallback }
    r$y <- pick(setdiff(d$y, r$x), r$y)
    r$x <- pick(d$x, r$x)
    ctrl <- setdiff(d$control[d$control %in% names(df)], c(r$y, r$x))
    if (length(ctrl)) r$controls <- ctrl
    r$heterogeneity <- pick(setdiff(d$heterogeneity, c(r$y, r$x)), r$heterogeneity)
    r$moderator <- pick(d$moderator, r$moderator)
    r$instrument <- pick(d$instrument, r$instrument)
    r$cluster <- pick(d$cluster, r$cluster)
    r$id <- pick(d$id, r$id)
    r$time <- pick(d$time, r$time)
    fe <- setdiff(d$fe[d$fe %in% names(df)], c(r$y, r$x))
    if (length(fe)) r$fe <- fe
  }
  r
}

pm_uniq <- function(...) {
  v <- unique(as.character(unlist(list(...))))
  v[!is.na(v) & nzchar(v)]
}
pm_num <- function(x) suppressWarnings(as.numeric(x))
pm_f3 <- function(x) ifelse(is.na(x), "n/a", sprintf("%.3f", x))

pm_enc_fit <- function(d) {
  lapply(d, function(v) {
    if (is.numeric(v)) {
      f <- stats::median(v, na.rm = TRUE)
      list(kind = "num", fill = if (is.na(f)) 0 else f)
    } else {
      ch <- as.character(v)
      lv <- sort(unique(ch[!is.na(ch)]))
      tb <- sort(table(ch), decreasing = TRUE)
      list(kind = "fac", levels = if (length(lv)) lv else "NA_level",
           fill = if (length(tb)) names(tb)[[1]] else "NA_level")
    }
  })
}

pm_enc_apply <- function(d, enc) {
  for (nm in names(enc)) {
    if (!nm %in% names(d)) d[[nm]] <- NA
    e <- enc[[nm]]
    if (identical(e$kind, "num")) {
      v <- pm_num(d[[nm]]); v[is.na(v)] <- e$fill; d[[nm]] <- v
    } else {
      ch <- as.character(d[[nm]]); ch[is.na(ch)] <- e$fill
      ch[!ch %in% e$levels] <- e$fill
      d[[nm]] <- factor(ch, levels = e$levels)
    }
  }
  d[, names(enc), drop = FALSE]
}

# 设计矩阵：编码器在传入的数据上拟合（交叉拟合时每次只用训练折的数据）
pm_xmat <- function(fit_df, cols, new_df = NULL) {
  enc <- pm_enc_fit(fit_df[, cols, drop = FALSE])
  build <- function(dd) {
    mm <- stats::model.matrix(~ ., data = pm_enc_apply(dd, enc))
    mm[, colnames(mm) != "(Intercept)", drop = FALSE]
  }
  xf <- build(fit_df)
  xn <- if (is.null(new_df)) NULL else build(new_df)
  if (!is.null(xn)) {
    add <- setdiff(colnames(xf), colnames(xn))
    for (nm in add) xn <- cbind(xn, stats::setNames(matrix(0, nrow(xn), 1), nm))
    xn <- xn[, colnames(xf), drop = FALSE]
  }
  if (ncol(xf) < 1) stop("设计矩阵没有可用列：检查控制变量是否全为常数或全缺失")
  list(x_fit = xf, x_new = xn, terms = colnames(xf), enc = enc)
}

# 交叉拟合折号：有 id 按个体分组（同一个体不跨折），否则按行分组
pm_folds <- function(data, roles, k, seed) {
  set.seed(seed)
  if (!is.na(roles$id) && roles$id %in% names(data)) {
    units <- unique(as.character(data[[roles$id]]))
    perm <- sample(units)
    assign <- ((seq_along(perm) - 1) %% k) + 1
    names(assign) <- perm
    return(unname(assign[as.character(data[[roles$id]])]))
  }
  sample(rep(seq_len(k), length.out = nrow(data)))
}

pm_lasso_select <- function(x, y, seed, nfolds = 5) {
  set.seed(seed)
  nf <- max(3, min(nfolds, nrow(x) - 1))
  fit <- glmnet::cv.glmnet(x, y, family = "gaussian", alpha = 1, nfolds = nf, standardize = TRUE)
  cf <- as.matrix(stats::coef(fit, s = "lambda.min"))
  cf <- cf[rownames(cf) != "(Intercept)", , drop = FALSE]
  list(selected = rownames(cf)[abs(cf[, 1]) > 1e-10], lambda = fit$lambda.min,
       coef = stats::setNames(as.numeric(cf[, 1]), rownames(cf)))
}

pm_cv_glmnet <- function(x, y, family, alpha, seed) {
  nf <- max(3, min(5, nrow(x) - 1))
  set.seed(seed)
  glmnet::cv.glmnet(x, y, family = family, alpha = alpha, nfolds = nf, standardize = TRUE)
}

# HC1 稳健标准误：DML 与 GATES/BLP 一律用它，不用经典方差
pm_hc1 <- function(model) sandwich::vcovHC(model, type = "HC1")

# 从 pmfit（run_ols 的返回）里取处理变量的一行
pm_coef_row <- function(fit, term) {
  tb <- pmfit_table(fit)
  i <- which(tb$term == term)
  if (!length(i)) stop(sprintf("回归里没有处理变量项 %s：检查角色变量是否为常数或被完全共线吸收", term))
  list(coef = tb$estimate[[i]], se = tb$std.error[[i]], statistic = tb$statistic[[i]],
       p = tb$p.value[[i]], n = as.integer(nobs(fit)))
}

# ---- 参数与数据 ----
args <- parse_common_args()
extra <- pm_extra_args(list(seed = "20261024", folds = "5", learner = "lasso",
                            iv_candidates = ""))
seed <- as.integer(as.numeric(extra$seed))
folds <- as.integer(as.numeric(extra$folds))
learner <- as.character(extra$learner)
if (!learner %in% c("lasso", "ridge", "enet")) {
  learner <- "lasso"
}
alpha_nuisance <- switch(learner, lasso = 1, ridge = 0, enet = 0.5)
ensure_dirs(args$out_root)
data_path <- if (is.na(args$data)) file.path(args$out_root, "data", "analysis-data.csv") else args$data
out <- args$out_root
today <- format(Sys.Date(), "%Y-%m-%d")
tag <- "02-causal-ml"
slug <- "07-ml/02-causal-ml"

if (!file.exists(data_path)) {
  msg <- sprintf("缺少分析数据：%s；先跑 02-clean-describe 产出 analysis-data.csv", data_path)
  write_md(file.path(out, "reports", sprintf("ml-blocked-%s-%s.md", tag, today)),
           "ML 执行阻断：02-causal-ml", list("阻断原因" = msg))
  cat(msg, "\n", file = stderr())
  quit(status = 1)
}

df <- load_data(data_path)
roles <- pm_roles(df, args$dict)
TASKS <- c("pds-controls", "dml-plr", "iv-lasso")
manifest <- list()
note_man <- function(task, key, value) {
  manifest[[length(manifest) + 1]] <<- data.frame(
    子流程 = tag, 任务 = task, 键 = key, 值 = as.character(value), check.names = FALSE)
}
# 三个任务的列集不同（.py 各自写同一张表，后写覆盖先写）。
# 这里既保留 .py 的列名，又不丢信息：任务内先写 -<任务ID>.csv，全部跑完再把各任务行并成
# 主表 ml-causal-estimates.csv（列取并集，缺项留空），避免最后一个任务覆盖前两个。
est_all <- list()
write_est <- function(rows, task) {
  d <- do.call(rbind, rows)
  invisible(write_csv_safe(d, file.path(out, "tables", sprintf("ml-causal-estimates-%s.csv", task))))
  est_all[[length(est_all) + 1]] <<- d
  d
}

# ---- 任务 1：PDS（后双重选择） ----
task_pds <- function() {
  controls <- intersect(roles$controls, names(df))
  if (!length(controls)) stop("pds-controls: 没有候选控制变量（--dict 的 control 角色为空）")
  y <- roles$y; x <- roles$x
  data <- df[stats::complete.cases(df[, c(y, x, controls), drop = FALSE]), , drop = FALSE]
  mat <- pm_xmat(data, controls)
  sel_y <- pm_lasso_select(mat$x_fit, pm_num(data[[y]]), seed)
  sel_x <- pm_lasso_select(mat$x_fit, pm_num(data[[x]]), seed)
  col2var <- function(sel) {
    hit <- vapply(sel, function(t) {
      cand <- controls[startsWith(t, controls)]
      if (length(cand)) cand[which.max(nchar(cand))] else t
    }, character(1), USE.NAMES = FALSE)
    unique(hit)
  }
  var_y <- col2var(sel_y$selected); var_x <- col2var(sel_x$selected)
  union <- sort(unique(c(var_y, var_x)))

  cl <- roles$cluster
  rows <- list()
  for (spec in list(list(label = "基准：全部候选控制变量", regs = controls),
                    list(label = "PDS：并集控制集", regs = union))) {
    fit <- run_ols(data, y, x, controls = spec$regs, fe = character(),
                   cluster = if (is.na(cl)) NA_character_ else cl)
    r <- pm_coef_row(fit, x)
    rows[[length(rows) + 1]] <- data.frame(
      模型 = spec$label,
      处理变量系数 = pm_f3(r$coef),
      标准误 = pm_f3(r$se),
      `t 值` = pm_f3(r$statistic),
      `p 值` = pm_f3(r$p),
      控制变量数 = length(spec$regs),
      观测值 = r$n,
      聚类层级 = if (is.na(cl)) "HC1" else cl,
      check.names = FALSE)
  }
  est <- write_est(rows, "pds-controls")

  sel_rows <- data.frame(
    variable = controls,
    selected_by = ifelse(controls %in% var_y, "Y 方程", ""),
    pred_X = ifelse(controls %in% var_x, "是", ""),
    in_union = ifelse(controls %in% union, "是", "否"),
    check.names = FALSE)
  # 主表加“任务”列（与 Python 侧合并口径一致）；任务级副本不重复这一列
  sel_main <- data.frame(任务 = "pds-controls", sel_rows, check.names = FALSE)
  write_csv_safe(sel_main, file.path(out, "tables", "ml-pds-selected-variables.csv"))
  write_csv_safe(sel_rows, file.path(out, "tables", "ml-pds-selected-variables-pds-controls.csv"))

  note_man("pds-controls", "候选控制变量数", length(controls))
  note_man("pds-controls", "Y 方程选中", length(var_y))
  note_man("pds-controls", "X 方程选中", length(var_x))
  note_man("pds-controls", "并集", length(union))
  note_man("pds-controls", "λ_Y", sprintf("%.6g", sel_y$lambda))
  note_man("pds-controls", "λ_X", sprintf("%.6g", sel_x$lambda))
  note_man("pds-controls", "标准误", if (is.na(cl)) "HC1" else paste0("cluster(", cl, ")"))

  list("表" = "tables/ml-causal-estimates.csv, tables/ml-pds-selected-variables.csv",
       "摘要" = sprintf("候选控制 %d 个；Y 方程选中 %d 个；X 方程选中 %d 个；并集 %d 个；λ_Y=%.4g，λ_X=%.4g。",
                       length(controls), length(var_y), length(var_x), length(union),
                       sel_y$lambda, sel_x$lambda),
       "注意" = "并集控制集只能降低正则化偏误，不证明条件外生性成立（C28）。")
}

# ---- 任务 2：DML 部分线性模型 ----
task_dml <- function() {
  controls <- intersect(roles$controls, names(df))
  if (!length(controls)) stop("dml-plr: 没有候选控制变量")
  y <- roles$y; x <- roles$x
  data <- df[stats::complete.cases(df[, c(y, x, controls), drop = FALSE]), , drop = FALSE]
  data <- data[order(seq_len(nrow(data))), , drop = FALSE]
  mat <- pm_xmat(data, controls)
  yy <- pm_num(data[[y]]); dd <- pm_num(data[[x]])
  fold <- pm_folds(data, roles, folds, seed)

  y_res <- rep(NA_real_, nrow(data)); d_res <- rep(NA_real_, nrow(data))
  per_fold <- list()
  for (k in seq_len(folds)) {
    tr <- which(fold != k); te <- which(fold == k)
    if (!length(tr) || !length(te)) next
    my <- pm_cv_glmnet(mat$x_fit[tr, , drop = FALSE], yy[tr], "gaussian", alpha_nuisance, seed)
    md <- pm_cv_glmnet(mat$x_fit[tr, , drop = FALSE], dd[tr], "gaussian", alpha_nuisance, seed)
    y_res[te] <- yy[te] - as.numeric(stats::predict(my, newx = mat$x_fit[te, , drop = FALSE], s = "lambda.min"))
    d_res[te] <- dd[te] - as.numeric(stats::predict(md, newx = mat$x_fit[te, , drop = FALSE], s = "lambda.min"))
    bf <- stats::coef(stats::lm(y_res[te] ~ d_res[te]))[[2]]
    per_fold[[length(per_fold) + 1]] <- data.frame(
      折 = k, 折系数 = pm_f3(bf), 折样本 = length(te), check.names = FALSE)
  }
  ok <- stats::complete.cases(y_res, d_res)
  if (sum(ok) < 10) stop("dml-plr: 交叉拟合后的残差样本不足，无法估计")
  fit <- stats::lm(y_res[ok] ~ d_res[ok])
  V <- pm_hc1(fit)
  theta <- stats::coef(fit)[[2]]
  se <- sqrt(diag(V))[[2]]

  cl <- roles$cluster
  base <- run_ols(data, y, x, controls = controls, fe = character(),
                  cluster = if (is.na(cl)) NA_character_ else cl)
  br <- pm_coef_row(base, x)
  per_fold <- do.call(rbind, per_fold)
  frange <- range(as.numeric(per_fold$折系数))

  rows <- list(
    data.frame(模型 = "基准 OLS（全部控制）", 处理变量系数 = pm_f3(br$coef), 标准误 = pm_f3(br$se),
               观测值 = br$n, 备注 = sprintf("控制变量 %d 个", length(controls)), check.names = FALSE),
    data.frame(模型 = sprintf("DML-PLR（%s，%d 折交叉拟合）", learner, folds),
               处理变量系数 = pm_f3(theta), 标准误 = pm_f3(se), 观测值 = sum(ok),
               备注 = sprintf("Neyman 正交 + 交叉拟合；标准误 HC1；折间系数范围 %.3f–%.3f",
                             frange[[1]], frange[[2]]),
               check.names = FALSE))
  write_est(rows, "dml-plr")
  write_csv_safe(per_fold, file.path(out, "tables", "ml-crossfit-folds.csv"))
  write_csv_safe(per_fold, file.path(out, "tables", "ml-crossfit-folds-dml-plr.csv"))

  note_man("dml-plr", "折数", folds)
  note_man("dml-plr", "nuisance 学习器", sprintf("%s（glmnet α=%s）", learner, alpha_nuisance))
  note_man("dml-plr", "折间系数范围", sprintf("%.3f–%.3f", frange[[1]], frange[[2]]))
  note_man("dml-plr", "样本量", sum(ok))

  list("表" = "tables/ml-causal-estimates.csv, tables/ml-crossfit-folds.csv",
       "摘要" = sprintf("DML 点估计 %.3f（HC1 标准误 %.3f），基准 OLS %.3f；折间系数范围 %.3f–%.3f。",
                       theta, se, br$coef, frange[[1]], frange[[2]]),
       "注意" = "两列差异若无机制解释，不得写成「ML 校正了内生性」（C30）。")
}

# ---- 任务 3：IV-lasso ----
task_iv <- function() {
  y <- roles$y; x <- roles$x
  cand <- character(0)
  if (!is.na(extra$iv_candidates) && nzchar(extra$iv_candidates)) {
    cand <- trimws(strsplit(extra$iv_candidates, ",")[[1]])
  } else if (!is.na(roles$instrument) && nzchar(roles$instrument)) {
    cand <- names(df)[startsWith(names(df), roles$instrument)]
  }
  if (!length(cand)) cand <- names(df)[grepl("^instrument", names(df))]
  cand <- setdiff(intersect(cand, names(df)), c(y, x, roles$cluster, roles$id))
  if (!length(cand)) {
    stop("iv-lasso: 找不到工具变量候选；用 --iv-candidates 显式指定（列名以 instrument 开头）")
  }
  controls <- setdiff(intersect(roles$controls, names(df)), c(y, x))
  data <- df[stats::complete.cases(df[, c(y, x, cand, controls), drop = FALSE]), , drop = FALSE]
  yy <- pm_num(data[[y]]); dd <- pm_num(data[[x]])

  zmat <- pm_xmat(data, cand)
  sel <- pm_lasso_select(zmat$x_fit, dd, seed)
  if (!length(sel$selected)) stop("iv-lasso: 第一阶段的 Lasso 未选中任何工具变量候选")
  Zsel <- zmat$x_fit[, sel$selected, drop = FALSE]

  # 第一阶段 F（HC1 Wald）：与 .py 一致，只用工具变量、不含控制变量
  m1 <- stats::lm(dd ~ Zsel)
  V1 <- pm_hc1(m1)
  b1 <- stats::coef(m1)[-1]
  V1s <- V1[-1, -1, drop = FALSE]
  f_first <- tryCatch(as.numeric(t(b1) %*% solve(V1s) %*% b1 / length(b1)), error = function(e) NA_real_)
  f_first_ctrl <- NA_real_
  if (length(controls)) {
    xc0 <- pm_xmat(data, controls)$x_fit
    m1c <- stats::lm(dd ~ cbind(Zsel, xc0))
    V1c <- pm_hc1(m1c)
    b1c <- stats::coef(m1c)[2:(1 + ncol(Zsel))]
    V1cs <- V1c[2:(1 + ncol(Zsel)), 2:(1 + ncol(Zsel)), drop = FALSE]
    f_first_ctrl <- tryCatch(as.numeric(t(b1c) %*% solve(V1cs) %*% b1c / length(b1c)),
                             error = function(e) NA_real_)
  }

  # 手写 2SLS：外生 [常数, 控制]，内生 x，工具 Zsel
  W <- cbind(`(Intercept)` = 1, if (length(controls)) pm_xmat(data, controls)$x_fit else matrix(0, nrow(data), 0))
  Zfull <- cbind(W, Zsel)
  dhat <- as.numeric(Zfull %*% solve(crossprod(Zfull), crossprod(Zfull, dd)))
  Xh <- cbind(dhat, W)
  bh <- solve(crossprod(Xh), crossprod(Xh, yy))
  u <- yy - as.numeric(cbind(dd, W) %*% bh)
  bread <- solve(crossprod(Xh))
  meat <- crossprod(Xh * u)  # sum u_i^2 x_i x_i'
  Vb <- bread %*% meat %*% bread
  coef_x <- bh[[1]]; se_x <- sqrt(Vb[1, 1])

  rows <- list(data.frame(
    模型 = "2SLS（Lasso 挑 IV）", 处理变量系数 = pm_f3(coef_x), 标准误 = pm_f3(se_x),
    `第一阶段 F` = pm_f3(f_first), 选中工具变量数 = length(sel$selected),
    观测值 = nrow(data),
    备注 = sprintf("选中：%s%s；λ=%.4g；含控制变量 %d 个；加入控制后的第一阶段 F=%s",
                 paste(sel$selected[seq_len(min(8, length(sel$selected)))], collapse = ", "),
                 if (length(sel$selected) > 8) " …" else "", sel$lambda, length(controls),
                 pm_f3(f_first_ctrl)),
    check.names = FALSE))
  write_est(rows, "iv-lasso")

  note_man("iv-lasso", "工具变量候选数", length(cand))
  note_man("iv-lasso", "选中工具变量数", length(sel$selected))
  note_man("iv-lasso", "第一阶段 F（仅工具变量）", pm_f3(f_first))
  note_man("iv-lasso", "第一阶段 F（含控制变量）", pm_f3(f_first_ctrl))
  note_man("iv-lasso", "控制变量数", length(controls))

  list("表" = "tables/ml-causal-estimates.csv",
       "摘要" = sprintf("在 %d 个候选里选中 %d 个工具变量，第一阶段 F=%.3f（含控制变量时 %.3f）；2SLS 点估计 %.3f（稳健标准误 %.3f）。",
                       length(cand), length(sel$selected), f_first, f_first_ctrl, coef_x, se_x),
       "注意" = "第一阶段 F 不达标时退回 03-regression/04-causal，不用 ML 硬凑工具变量。")
}

# ---- 调度：阻断要落盘 ----
dispatch <- list("pds-controls" = task_pds, "dml-plr" = task_dml, "iv-lasso" = task_iv)
results <- list(); done <- character(0)
for (nm in TASKS) {
  if (!task_enabled(args, nm)) next
  results[[nm]] <- tryCatch({ v <- dispatch[[nm]](); done <- c(done, nm); v },
                            error = function(e) list("阻断" = sprintf("%s: %s", class(e)[[1]], conditionMessage(e))))
}

sections <- list("运行口径" = sprintf(
  "数据 `%s`；折数 %d；nuisance 学习器 %s（glmnet α=%s）；种子 %d；实际执行 %s。",
  data_path, folds, learner, alpha_nuisance, seed,
  ifelse(length(done), paste(done, collapse = ", "), "无")))
for (nm in TASKS) {
  if (is.null(results[[nm]])) next
  item <- results[[nm]]
  sections[[nm]] <- paste(sprintf("- %s：%s", names(item), unlist(item)), collapse = "\n")
}
sections[["识别前提"]] <- paste(
  "PDS 与 DML 都只在给定识别假设下成立：控制集须满足条件外生性；",
  "DML 只处理高维控制带来的正则化偏误，不解决遗漏变量；IV-lasso 不解决工具变量的排他性。")

if (length(est_all)) {
  cols <- unique(unlist(lapply(est_all, names)))
  merged <- do.call(rbind, lapply(est_all, function(d) {
    for (nm in setdiff(cols, names(d))) d[[nm]] <- NA
    d[, cols, drop = FALSE]
  }))
  invisible(write_csv_safe(merged, file.path(out, "tables", "ml-causal-estimates.csv")))
}

report <- file.path(out, "reports", sprintf("ml-run-%s-%s.md", tag, today))
invisible(write_md(report, "ML 执行摘要：02-causal-ml", sections))
if (length(manifest)) {
  invisible(write_csv_safe(do.call(rbind, manifest),
                           file.path(out, "tables", sprintf("ml-run-manifest-%s.csv", tag))))
}
cat(sprintf("[%s] done: %s | report: %s\n", slug,
            ifelse(length(done), paste(done, collapse = ", "), "none"), report))
