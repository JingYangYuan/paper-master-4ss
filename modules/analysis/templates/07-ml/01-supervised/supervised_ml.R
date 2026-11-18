# 07-ml/01-supervised：正则化筛变量、样本外预测性能、无监督结构（R 侧实现）
#
# 任务（--tasks 逗号分隔，留空全跑）：
#   regularized         弹性网/Lasso（含岭回归候选）筛变量，报选中清单与惩罚参数
#   predict-regression  连续因变量的样本外预测性能
#   predict-binary      二分类样本外性能、校准与置换重要性
#   structure           PCA 降维与 K-means 聚类
#
# 口径对齐 01-supervised/supervised_ml.py：任务 ID、输出表文件名、CSV 列名、
# 报告文件名（reports/ml-run-01-supervised-<YYYY-MM-DD>.md）一律照 .py，中文列名一字不改。
#
# 候选模型的差别要说清：本机只装了 glmnet + fixest + sandwich + lmtest，
# 未装 ranger / randomForest / xgboost / gbm，故 .py 的「随机森林」「梯度提升（HistGB）」
# 改由 glmnet 系（岭回归 / Lasso / 弹性网）承担，基准仍是 OLS / Logit(MLE)。
# 缺的森林类方法不在这里假装跑过，由 04-ml-export 写进 ml-not-run-list.csv。
#
# 纪律（同 .py，见 phases/07-ml-and-causal-ml.md K6）：
#   - 插补与因子编码在训练折内拟合（pm_enc_fit），再套到测试折，不把测试信息带进训练。
#   - 有 id 按个体分组切分，有时间按时间前后切分，都不按行随机切。
#   - 调参一律在训练折内交叉验证完成；测试集只评估一次。
#   - 跑不动、缺角色、缺包就写阻断说明并落 CSV/MD，不写占位数字、不假装执行过。

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

# --seed / --test-size 不在公共参数里，这里单独取；--tasks 仍由 parse_common_args + task_enabled 管
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

# 变量字典里声明了 control / heterogeneity / instrument 等角色时以字典为准，
# 与 python_common.infer_roles 的优先级一致（r_common::infer_roles 不读字典，故此处补齐）
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

# 与 .py 的 _feature_columns 一致：x + controls + heterogeneity + moderator
pm_features <- function(df, roles) {
  want <- pm_uniq(roles$x, roles$controls, roles$heterogeneity, roles$moderator)
  intersect(want, names(df))
}

pm_num <- function(x) suppressWarnings(as.numeric(x))
pm_is_binary <- function(v) {
  u <- unique(stats::na.omit(pm_num(v)))
  length(u) == 2 && all(u %in% c(0, 1))
}

# 训练折内拟合的插补与因子水平：测试折只许套用，不许重估
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

# 设计矩阵：编码器在 fit_df 上拟合；new_df 的列对齐到训练矩阵
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
  if (ncol(xf) < 1) stop("特征矩阵没有可用列：检查角色变量是否全为常数或全缺失")
  list(x_fit = xf, x_new = xn, terms = colnames(xf), enc = enc)
}

# 项名回落到原始变量名（因子哑变量 "groupB" -> "group"）
pm_term_base <- function(terms, cols) {
  vapply(terms, function(t) {
    hit <- cols[startsWith(t, cols)]
    if (length(hit)) hit[which.max(nchar(hit))] else t
  }, character(1), USE.NAMES = FALSE)
}

pm_split <- function(data, roles, seed, test_size) {
  if (!is.na(roles$id) && roles$id %in% names(data)) {
    units <- unique(as.character(data[[roles$id]]))
    set.seed(seed)
    perm <- sample(units)
    goal <- floor(nrow(data) * test_size)
    counts <- as.integer(table(as.character(data[[roles$id]])))
    names(counts) <- names(table(as.character(data[[roles$id]])))
    pick <- character(0); total <- 0
    for (u in perm) {
      if (total >= goal) break
      pick <- c(pick, u)
      total <- total + counts[[u]]
    }
    m <- as.character(data[[roles$id]]) %in% pick
    return(list(train = data[!m, , drop = FALSE], test = data[m, , drop = FALSE],
                note = sprintf("按 %s 分组切分（同一个体不跨折）", roles$id)))
  }
  if (!is.na(roles$time) && roles$time %in% names(data)) {
    ord <- data[order(data[[roles$time]]), , drop = FALSE]
    k <- floor(nrow(ord) * (1 - test_size))
    return(list(train = ord[seq_len(k), , drop = FALSE],
                test = ord[(k + 1):nrow(ord), , drop = FALSE],
                note = sprintf("按 %s 时间前后切分（不回望未来）", roles$time)))
  }
  set.seed(seed)
  idx <- sample(seq_len(nrow(data)), size = floor(nrow(data) * test_size))
  list(train = data[-idx, , drop = FALSE], test = data[idx, , drop = FALSE],
       note = "按行随机切分（截面数据）")
}

pm_rmse <- function(y, p) sqrt(mean((y - p)^2, na.rm = TRUE))
pm_mae <- function(y, p) mean(abs(y - p), na.rm = TRUE)
pm_r2 <- function(y, p) 1 - sum((y - p)^2, na.rm = TRUE) / sum((y - mean(y, na.rm = TRUE))^2, na.rm = TRUE)
pm_brier <- function(y, p) mean((p - y)^2, na.rm = TRUE)
pm_acc <- function(y, p) mean((p >= 0.5) == (y > 0.5), na.rm = TRUE)
pm_auc <- function(y, p) {
  ok <- !is.na(y) & !is.na(p)
  y <- as.integer(y[ok] > 0.5); p <- p[ok]
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  if (!n1 || !n0) return(NA_real_)
  r <- rank(p)
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
pm_f3 <- function(x) ifelse(is.na(x), "n/a", sprintf("%.3f", x))

# 基准模型：真 OLS / Logit(MLE)，不用正则化近似
pm_lm_fit <- function(x, y, bin = FALSE) {
  X <- as.data.frame(x, check.names = FALSE)
  names(X) <- paste0("V", seq_len(ncol(X)))
  d <- data.frame(.y = y, X, check.names = FALSE)
  if (bin) stats::glm(.y ~ ., data = d, family = stats::binomial()) else stats::lm(.y ~ ., data = d)
}
pm_lm_pred <- function(model, x, bin = FALSE) {
  X <- as.data.frame(x, check.names = FALSE)
  names(X) <- paste0("V", seq_len(ncol(X)))
  suppressWarnings(as.numeric(stats::predict(model, newdata = X,
                                             type = if (bin) "response" else "response")))
}

pm_cv_glmnet <- function(x, y, family, alpha, seed) {
  nf <- max(3, min(5, nrow(x) - 1))
  set.seed(seed)
  tryCatch(
    glmnet::cv.glmnet(x, y, family = family, alpha = alpha, nfolds = nf,
                      standardize = TRUE,
                      type.measure = if (identical(family, "binomial")) "auc" else "mse"),
    error = function(e) {
      glmnet::cv.glmnet(x, y, family = family, alpha = alpha, nfolds = nf,
                        standardize = TRUE, type.measure = "deviance")
    })
}
pm_glmnet_pred <- function(cv, x, family) {
  as.numeric(stats::predict(cv, newx = x, s = "lambda.min",
                            type = if (identical(family, "binomial")) "response" else "link"))
}

# ---- 参数与数据 ----
args <- parse_common_args()
extra <- pm_extra_args(list(seed = "20261024", test_size = "0.3"))
seed <- as.integer(as.numeric(extra$seed))
test_size <- as.numeric(extra$test_size)
ensure_dirs(args$out_root)
data_path <- if (is.na(args$data)) file.path(args$out_root, "data", "analysis-data.csv") else args$data
out <- args$out_root
today <- format(Sys.Date(), "%Y-%m-%d")
tag <- "01-supervised"
slug <- "07-ml/01-supervised"

if (!file.exists(data_path)) {
  msg <- sprintf("缺少分析数据：%s；先跑 02-clean-describe 产出 analysis-data.csv", data_path)
  write_md(file.path(out, "reports", sprintf("ml-blocked-%s-%s.md", tag, today)),
           "ML 执行阻断：01-supervised", list("阻断原因" = msg))
  cat(msg, "\n", file = stderr())
  quit(status = 1)
}

df <- load_data(data_path)
roles <- pm_roles(df, args$dict)
TASKS <- c("regularized", "predict-regression", "predict-binary", "structure")
manifest <- list()
note_man <- function(task, key, value) {
  manifest[[length(manifest) + 1]] <<- data.frame(
    子流程 = tag, 任务 = task, 键 = key, 值 = as.character(value), check.names = FALSE)
}

# ---- 任务 1：正则化筛变量 ----
task_regularized <- function() {
  feats <- pm_features(df, roles)
  y <- roles$y
  if (!length(feats) || !y %in% names(df)) stop("regularized: 缺少角色变量，先补 variable-discovery-pack")
  tau <- df[!is.na(df[[y]]), , drop = FALSE]
  uy <- unique(stats::na.omit(pm_num(tau[[y]])))
  is_bin <- length(uy) == 2 && all(uy %in% c(0, 1))
  fam <- if (is_bin) "binomial" else "gaussian"
  kind <- if (is_bin) "L1 逻辑回归（glmnet，CV 选 λ）" else "弹性网（glmnet，CV 选 α 与 λ，含 Lasso 端点）"
  yy <- if (is_bin) as.integer(pm_num(tau[[y]]) > 0.5) else pm_num(tau[[y]])
  mat <- pm_xmat(tau, feats)

  alphas <- if (is_bin) 1 else c(0.1, 0.5, 0.9, 1)
  fits <- lapply(alphas, function(a) pm_cv_glmnet(mat$x_fit, yy, fam, a, seed))
  cvm <- vapply(fits, function(f) min(f$cvm, na.rm = TRUE), numeric(1))
  best <- which.min(cvm)
  fit <- fits[[best]]
  alpha_used <- alphas[[best]]
  cf <- as.matrix(stats::coef(fit, s = "lambda.min"))
  cf <- cf[rownames(cf) != "(Intercept)", , drop = FALSE]
  base <- pm_term_base(rownames(cf), feats)
  coefs <- as.numeric(cf[, 1])

  var_coef <- tapply(abs(coefs), base, max)
  sel_rows <- do.call(rbind, lapply(names(var_coef), function(v) {
    idx <- which(base == v)
    j <- idx[which.max(abs(coefs[idx]))]
    data.frame(variable = v, coefficient = sprintf("%.3f", coefs[[j]]),
               selected = if (var_coef[[v]] > 1e-8) "是" else "否", model = kind,
               check.names = FALSE)
  }))
  sel_rows <- sel_rows[order(-var_coef[sel_rows$variable]), , drop = FALSE]
  n_sel <- sum(sel_rows$selected == "是")

  path_rows <- data.frame(
    模型 = c(kind, sprintf("候选 α=%s", format(alphas, trim = TRUE))),
    惩罚参数 = c(sprintf("%.5g", fit$lambda.min), vapply(fits, function(f) sprintf("%.5g", f$lambda.min), character(1))),
    l1_ratio = c(sprintf("%s", alpha_used), vapply(alphas, function(a) sprintf("%s", a), character(1))),
    候选特征数 = length(feats),
    选中特征数 = c(n_sel, vapply(fits, function(f) {
      cc <- as.matrix(stats::coef(f, s = "lambda.min"))
      cc <- cc[rownames(cc) != "(Intercept)", , drop = FALSE]
      length(unique(pm_term_base(rownames(cc), feats)[abs(as.numeric(cc[, 1])) > 1e-8]))
    }, integer(1))),
    样本量 = nrow(tau),
    check.names = FALSE)

  # 主表加“任务”列（与 Python 侧合并口径一致）；任务级副本不重复这一列
  sel_main <- data.frame(任务 = "regularized", sel_rows, check.names = FALSE)
  write_csv_safe(sel_main, file.path(out, "tables", "ml-selected-variables.csv"))
  write_csv_safe(sel_rows, file.path(out, "tables", "ml-selected-variables-regularized.csv"))
  write_csv_safe(path_rows, file.path(out, "tables", "ml-regularization-path.csv"))
  write_csv_safe(path_rows, file.path(out, "tables", "ml-regularization-path-regularized.csv"))
  note_man("regularized", "候选 α", paste(alphas, collapse = ", "))
  note_man("regularized", "选中 α", alpha_used)
  note_man("regularized", "lambda.min", sprintf("%.6g", fit$lambda.min))
  note_man("regularized", "CV 折数", max(3, min(5, nrow(mat$x_fit) - 1)))
  note_man("regularized", "样本量", nrow(tau))

  list("表" = paste(c("tables/ml-selected-variables.csv", "tables/ml-regularization-path.csv"), collapse = ", "),
       "摘要" = sprintf("%s，候选 %d 个特征，选中 %d 个；α=%s，λ=%.5g。", kind, length(feats), n_sel,
                       alpha_used, fit$lambda.min),
       "注意" = "选中变量不等于因果相关变量；系数是正则化后的收缩估计，不能直接当效应量读。")
}

# ---- 任务 2/3：样本外预测 ----
task_predict <- function(task) {
  y <- roles$y
  bin <- identical(task, "predict-binary")
  # 二分类任务：若主因变量是连续变量而数据里有 outcome_bin，就改用它
  # （与 03-regression/02-nonlinear 的 bin_y 约定一致，报告里写明换成了哪一列）
  if (bin && !pm_is_binary(df[[y]])) {
    cand <- intersect(c("outcome_bin", "y_bin", "binary"), names(df))
    if (length(cand) && pm_is_binary(df[[cand[[1]]]])) y <- cand[[1]]
  }
  feats <- setdiff(pm_features(df, roles), y)
  if (!length(feats) || !y %in% names(df)) stop(sprintf("%s: 缺少角色变量", task))
  data <- df[!is.na(df[[y]]), , drop = FALSE]
  uy <- unique(stats::na.omit(pm_num(data[[y]])))
  if (bin) {
    if (length(uy) > 2) stop(sprintf("%s: 因变量 %s 取值 %d 类，不是二分类任务（数据里也没有可用的 outcome_bin）", task, y, length(uy)))
    yv <- as.integer(pm_num(data[[y]]) > 0.5)
  } else {
    yv <- pm_num(data[[y]])
  }
  data$.pm_y <- yv
  sp <- pm_split(data, roles, seed, test_size)
  tr <- sp$train; te <- sp$test
  mat <- pm_xmat(tr, feats, te)
  y_tr <- tr$.pm_y; y_te <- te$.pm_y
  fam <- if (bin) "binomial" else "gaussian"

  base_mod <- pm_lm_fit(mat$x_fit, y_tr, bin)
  preds <- list()
  base_name <- paste0("基准", if (bin) " Logit（MLE）" else " OLS")
  preds[[base_name]] <- list(
    train = pm_lm_pred(base_mod, mat$x_fit, bin), test = pm_lm_pred(base_mod, mat$x_new, bin),
    model = base_mod, kind = "lm")
  specs <- list(
    "岭回归（glmnet，CV 选 λ）" = 0,
    "Lasso（glmnet，CV 选 λ）" = 1,
    "弹性网（glmnet，α=0.5，CV 选 λ）" = 0.5)
  fits <- list()
  for (nm in names(specs)) {
    cv <- pm_cv_glmnet(mat$x_fit, y_tr, fam, specs[[nm]], seed)
    fits[[nm]] <- cv
    preds[[nm]] <- list(train = pm_glmnet_pred(cv, mat$x_fit, fam),
                        test = pm_glmnet_pred(cv, mat$x_new, fam), model = cv, kind = "glmnet")
  }

  perf <- list()
  for (nm in names(preds)) {
    p_tr <- preds[[nm]]$train; p_te <- preds[[nm]]$test
    if (bin) {
      perf[[length(perf) + 1]] <- data.frame(
        模型 = nm,
        `样本外 AUC` = pm_f3(pm_auc(y_te, p_te)),
        `样本外 Brier` = pm_f3(pm_brier(y_te, p_te)),
        `样本外准确率` = pm_f3(pm_acc(y_te, p_te)),
        `训练集准确率` = pm_f3(pm_acc(y_tr, p_tr)),
        训练样本 = nrow(tr), 测试样本 = nrow(te), check.names = FALSE)
    } else {
      perf[[length(perf) + 1]] <- data.frame(
        模型 = nm,
        `样本外 RMSE` = pm_f3(pm_rmse(y_te, p_te)),
        `样本外 MAE` = pm_f3(pm_mae(y_te, p_te)),
        `样本外 R2` = pm_f3(pm_r2(y_te, p_te)),
        `训练集 R2` = pm_f3(pm_r2(y_tr, p_tr)),
        训练样本 = nrow(tr), 测试样本 = nrow(te), check.names = FALSE)
    }
  }
  perf <- do.call(rbind, perf)

  calib <- NULL
  if (bin) {
    calib <- list()
    for (nm in names(preds)) {
      p <- preds[[nm]]$test
      qs <- unique(stats::quantile(p, probs = seq(0, 1, length.out = 11), na.rm = TRUE))
      if (length(qs) < 3) {
        br <- rep(1, length(p))
      } else {
        br <- cut(p, qs, include.lowest = TRUE, labels = FALSE)
      }
      for (b in sort(unique(stats::na.omit(br)))) {
        idx <- which(br == b)
        calib[[length(calib) + 1]] <- data.frame(
          模型 = nm, 分箱 = b,
          平均预测概率 = pm_f3(mean(p[idx], na.rm = TRUE)),
          实际正例比例 = pm_f3(mean(y_te[idx], na.rm = TRUE)), check.names = FALSE)
      }
    }
    calib <- do.call(rbind, calib)
  }

  # 置换重要性：对表现最好的 glmnet 模型，逐变量打乱后看样本外指标掉多少
  ml_names <- setdiff(names(preds), grep("^基准", names(preds), value = TRUE))
  if (!length(ml_names)) ml_names <- names(preds)
  score <- vapply(ml_names, function(nm) {
    if (bin) pm_auc(y_te, preds[[nm]]$test) else -pm_rmse(y_te, preds[[nm]]$test)
  }, numeric(1))
  best_name <- ml_names[[which.max(score)]]
  metric_of <- function(p) if (bin) pm_auc(y_te, p) else pm_r2(y_te, p)
  base_metric <- metric_of(preds[[best_name]]$test)
  set.seed(seed)
  imp <- list()
  for (v in feats) {
    deltas <- numeric(5)
    for (r in seq_len(5)) {
      te2 <- te
      te2[[v]] <- sample(te2[[v]])
      m2 <- pm_xmat(tr, feats, te2)$x_new
      p2 <- if (identical(preds[[best_name]]$kind, "glmnet")) {
        pm_glmnet_pred(preds[[best_name]]$model, m2, fam)
      } else {
        pm_lm_pred(preds[[best_name]]$model, m2, bin)
      }
      deltas[[r]] <- base_metric - metric_of(p2)
    }
    imp[[length(imp) + 1]] <- data.frame(
      variable = v, `置换重要性均值` = pm_f3(mean(deltas)),
      `标准差` = pm_f3(stats::sd(deltas)), check.names = FALSE)
  }
  imp <- do.call(rbind, imp)
  imp <- imp[order(-as.numeric(imp$`置换重要性均值`)), , drop = FALSE]

  confusion <- NULL
  if (bin) {
    confusion <- do.call(rbind, lapply(names(preds), function(nm) {
      cls <- as.integer(preds[[nm]]$test >= 0.5)
      tp <- sum(cls == 1 & y_te == 1); fp <- sum(cls == 1 & y_te == 0)
      tn <- sum(cls == 0 & y_te == 0); fn <- sum(cls == 0 & y_te == 1)
      data.frame(模型 = nm, 真阳性 = tp, 假阳性 = fp, 真阴性 = tn, 假阴性 = fn,
                 灵敏度 = pm_f3(if ((tp + fn)) tp / (tp + fn) else NA_real_),
                 特异度 = pm_f3(if ((tn + fp)) tn / (tn + fp) else NA_real_),
                 阈值 = 0.5, check.names = FALSE)
    }))
  }

  write_csv_safe(perf, file.path(out, "tables", "ml-model-performance.csv"))
  write_csv_safe(perf, file.path(out, "tables", sprintf("ml-model-performance-%s.csv", task)))
  if (!is.null(calib)) {
    write_csv_safe(calib, file.path(out, "tables", "ml-calibration.csv"))
    write_csv_safe(calib, file.path(out, "tables", sprintf("ml-calibration-%s.csv", task)))
  }
  write_csv_safe(imp, file.path(out, "tables", "ml-variable-importance.csv"))
  write_csv_safe(imp, file.path(out, "tables", sprintf("ml-variable-importance-%s.csv", task)))
  if (!is.null(confusion)) {
    write_csv_safe(confusion, file.path(out, "tables", "ml-classification-confusion.csv"))
  }

  note_man(task, "因变量", y)
  note_man(task, "折分方式", sp$note)
  note_man(task, "测试集比例", test_size)
  note_man(task, "训练样本", nrow(tr))
  note_man(task, "测试样本", nrow(te))
  note_man(task, "特征数", length(feats))
  note_man(task, "候选模型", paste(names(preds), collapse = " | "))
  note_man(task, "置换重要性所用模型", best_name)

  tabs <- c("tables/ml-model-performance.csv",
            if (!is.null(calib)) "tables/ml-calibration.csv",
            if (!is.null(confusion)) "tables/ml-classification-confusion.csv",
            "tables/ml-variable-importance.csv")
  list("表" = paste(tabs, collapse = ", "),
       "摘要" = sprintf("%s：因变量 %s；折分方式＝%s；特征 %d 个；候选模型 %d 个；置换重要性基准模型＝%s。",
                       task, y, sp$note, length(feats), length(preds), best_name),
       "注意" = "置换重要性衡量模型依赖，不是因果贡献；对外声称请按 C30 写边界。")
}

# ---- 任务 4：PCA 与 K-means ----
pm_silhouette <- function(dmat, labels) {
  lab <- as.integer(factor(labels))
  n <- length(lab)
  if (n > 3000) {  # 轮廓系数是 O(n^2)，大样本抽样子集
    set.seed(123)
    keep <- sort(sample(seq_len(n), 3000))
    lab <- lab[keep]; dmat <- dmat[keep, keep, drop = FALSE]; n <- length(lab)
  }
  d <- as.matrix(dmat)
  res <- numeric(n)
  for (i in seq_len(n)) {
    own <- which(lab == lab[[i]])
    own <- own[own != i]
    a <- if (length(own)) mean(d[i, own]) else 0
    others <- setdiff(unique(lab), lab[[i]])
    b <- if (length(others)) min(vapply(others, function(g) mean(d[i, lab == g]), numeric(1))) else NA_real_
    res[[i]] <- if (is.na(b) || (a == 0 && b == 0)) 0 else (b - a) / max(a, b)
  }
  mean(res, na.rm = TRUE)
}

task_structure <- function() {
  feats <- pm_uniq(roles$controls, roles$x)
  feats <- intersect(feats, names(df))
  if (length(feats) < 2) stop("structure: 候选特征少于 2 个，无法降维或聚类")
  mat <- pm_xmat(df, feats)
  ok <- stats::complete.cases(mat$x_fit)
  x <- mat$x_fit[ok, , drop = FALSE]
  if (nrow(x) < 10) stop("structure: 完整观测少于 10 行，无法降维或聚类")
  xs <- scale(x, center = TRUE, scale = TRUE)
  npc <- min(5, ncol(xs))
  pca <- stats::prcomp(xs, center = FALSE, scale. = FALSE)
  ev <- pca$sdev^2
  ratio <- ev / sum(ev)
  pca_rows <- data.frame(
    主成分 = sprintf("PC%d", seq_len(npc)),
    解释方差比例 = pm_f3(ratio[seq_len(npc)]),
    累计解释方差 = pm_f3(cumsum(ratio)[seq_len(npc)]),
    check.names = FALSE)
  write_csv_safe(pca_rows, file.path(out, "tables", "ml-structure-pca.csv"))

  pre <- pca$x[, seq_len(min(npc, ncol(pca$x))), drop = FALSE]
  dmat <- stats::dist(pre)
  cl_rows <- list(); best <- NULL
  set.seed(seed)
  for (k in c(2, 3, 4, 5)) {
    if (nrow(pre) <= k) next
    km <- stats::kmeans(pre, centers = k, nstart = 10, iter.max = 100)
    sil <- pm_silhouette(dmat, km$cluster)
    cl_rows[[length(cl_rows) + 1]] <- data.frame(
      解数K = k, 组内平方和 = pm_f3(km$tot.withinss), 轮廓系数 = pm_f3(sil),
      最小组占比 = pm_f3(min(km$size) / nrow(pre)), check.names = FALSE)
    if (is.null(best) || (!is.na(sil) && sil > as.numeric(best$`轮廓系数`))) best <- cl_rows[[length(cl_rows)]]
  }
  if (!length(cl_rows)) stop("structure: 样本量不足以聚类")
  cl_rows <- do.call(rbind, cl_rows)
  write_csv_safe(cl_rows, file.path(out, "tables", "ml-structure-cluster.csv"))
  note_man("structure", "特征数", length(feats))
  note_man("structure", "完整观测", nrow(x))
  note_man("structure", "主成分数", npc)
  note_man("structure", "按轮廓系数选 K", best$`解数K`)

  list("表" = "tables/ml-structure-pca.csv, tables/ml-structure-cluster.csv",
       "摘要" = sprintf("PCA 前两主成分累计解释 %s；K 解按轮廓系数选 %s。",
                       pca_rows$`累计解释方差`[[min(2, nrow(pca_rows))]], best$`解数K`),
       "注意" = "主成分与聚类只是造指标、造分组的手段，不构成因子结构或类型学的证据。")
}

# ---- 调度：阻断要落盘，不让进程静默失败 ----
dispatch <- list(
  "regularized" = task_regularized,
  "predict-regression" = function() task_predict("predict-regression"),
  "predict-binary" = function() task_predict("predict-binary"),
  "structure" = task_structure)
results <- list(); done <- character(0)
for (nm in TASKS) {
  if (!task_enabled(args, nm)) next
  results[[nm]] <- tryCatch({ v <- dispatch[[nm]](); done <- c(done, nm); v },
                            error = function(e) list("阻断" = sprintf("%s: %s", class(e)[[1]], conditionMessage(e))))
}

sections <- list("运行口径" = sprintf(
  "数据 `%s`；种子 %d；测试集比例 %s；实际执行任务 %s。R 侧候选模型为 OLS/Logit 基准加 glmnet 系正则化模型（未装 ranger/xgboost，森林类方法未执行）。",
  data_path, seed, test_size, ifelse(length(done), paste(done, collapse = ", "), "无")))
for (nm in TASKS) {
  if (is.null(results[[nm]])) next
  item <- results[[nm]]
  sections[[nm]] <- paste(sprintf("- %s：%s", names(item), unlist(item)), collapse = "\n")
}
sections[["可声称边界"]] <- paste(
  "预测性能支持对样本外预测能力的陈述；变量重要性与选中变量清单不支持因果解释。",
  "因果结论须走 02-causal-ml 并满足其识别假设（C30）。")

report <- file.path(out, "reports", sprintf("ml-run-%s-%s.md", tag, today))
invisible(write_md(report, "ML 执行摘要：01-supervised", sections))
if (length(manifest)) {
  invisible(write_csv_safe(do.call(rbind, manifest),
                           file.path(out, "tables", sprintf("ml-run-manifest-%s.csv", tag))))
}
cat(sprintf("[%s] done: %s | report: %s\n", slug,
            ifelse(length(done), paste(done, collapse = ", "), "none"), report))
