# 07-ml/03-heterogeneity：honest split 下的 CATE、GATES、BLP 与重叠诊断
#
# 一次跑完，无任务分派（对齐 03-heterogeneity/cate_forest.py）：
#   1. 按个体把样本对半分（honest split）：一折训练结果模型，另一折只做推断
#   2. T-learner：处理组/控制组各训一个结果模型，CATE = mu1(x) - mu0(x)
#   3. GATES：按 CATE 分位分组，估各组平均处理效应（验证异质性是否存在）
#   4. BLP：y ~ t + s + t:s（s 为 CATE 中心化），检验 CATE 排序在样本外是否有解释力
#   5. 重叠诊断：倾向得分 AUC、贴边比例、CATE 分布
#
# 口径对齐 cate_forest.py：表名、CSV 列名、报告文件名、报告 6 个节名、收尾打印行一律照 .py。
# 差别（本机未装 ranger/grf，禁止联网装包）：结果模型用 glmnet 替代森林，
# alpha 由 --alpha 指定（默认 1=lasso；ridge 更稳可传 0），具体值写进 manifest 与报告。
#
# 纪律：CATE 是估计量不是事实。可声称范围见报告「可声称边界」一节；
#   GATES/BLP 未显著时不得声称异质性；重叠不足时不得给个体政策建议（C29、C30）。
#   任何一步缺数据、缺列、缺折就写阻断并落盘，不写占位数字。

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

# 设计矩阵：编码器只在训练折上拟合，样本外折只做变换（honest split 的一部分）
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
  if (ncol(xf) < 1) stop("设计矩阵没有可用列：检查协变量是否全为常数或全缺失")
  rownames(xf) <- NULL; if (!is.null(xn)) rownames(xn) <- NULL
  list(x_fit = xf, x_new = xn, terms = colnames(xf), enc = enc)
}

pm_auc <- function(score, y) {
  ok <- stats::complete.cases(score, y)
  score <- score[ok]; y <- y[ok]
  if (length(unique(y)) < 2) return(NA_real_)
  r <- rank(score)
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

pm_hc1 <- function(model) sandwich::vcovHC(model, type = "HC1")
pm_cv_glmnet <- function(x, y, family, alpha, seed) {
  nf <- max(3, min(5, nrow(x) - 1))
  set.seed(seed)
  glmnet::cv.glmnet(x, y, family = family, alpha = alpha, nfolds = nf, standardize = TRUE)
}

# ---- 参数与数据 ----
args <- parse_common_args()
extra <- pm_extra_args(list(seed = "20261024", gates_groups = "5", alpha = "1"))
seed <- as.integer(as.numeric(extra$seed))
gates_groups <- max(2L, as.integer(as.numeric(extra$gates_groups)))
alpha <- suppressWarnings(as.numeric(extra$alpha))
if (is.na(alpha)) alpha <- 1
ensure_dirs(args$out_root)
data_path <- if (is.na(args$data)) file.path(args$out_root, "data", "analysis-data.csv") else args$data
out <- args$out_root
today <- format(Sys.Date(), "%Y-%m-%d")
tag <- "03-heterogeneity"
slug <- "07-ml/03-heterogeneity"
report_path <- file.path(out, "reports", sprintf("ml-run-%s-%s.md", tag, today))
blocked_path <- file.path(out, "reports", sprintf("ml-blocked-%s-%s.md", tag, today))

blocked <- function(msg) {
  invisible(write_md(blocked_path, "ML 执行阻断：03-heterogeneity", list("阻断原因" = msg)))
  cat(sprintf("[%s] 阻断：%s\n", slug, msg), file = stderr())
  quit(status = 1)
}

if (!file.exists(data_path)) {
  blocked(sprintf("缺少分析数据：%s；先跑 02-clean-describe 产出 analysis-data.csv", data_path))
}
df <- load_data(data_path)
roles <- pm_roles(df, args$dict)
y <- roles$y; x <- roles$x
if (is.na(y) || !y %in% names(df)) blocked("角色推断没找到结果变量：检查 --dict 的 y 角色或列名")
if (is.na(x) || !x %in% names(df)) blocked("角色推断没找到处理变量：检查 --dict 的 x 角色或列名")

covariates <- pm_uniq(roles$controls, roles$heterogeneity, roles$moderator,
                      setdiff(roles$fe, c(y, x)))
covariates <- setdiff(covariates[covariates %in% names(df)], c(y, x, roles$id, roles$time))
if (!length(covariates)) blocked("没有可用协变量：controls/heterogeneity/moderator 全空，CATE 无从估计")

need <- c(y, x, covariates)
data <- df[stats::complete.cases(df[, need, drop = FALSE]), , drop = FALSE]
treat <- pm_num(data[[x]])
data <- data[!is.na(treat), , drop = FALSE]
treat <- pm_num(data[[x]])
if (!all(unique(treat) %in% c(0, 1))) {
  blocked(sprintf("处理变量 %s 不是 0/1 二元变量（观测到 %d 个取值）：CATE 需要二值处理", x, length(unique(treat))))
}
if (min(table(treat)) < 20) {
  blocked(sprintf("处理组或对照组样本过少（%s / %s）：不足以分别训练结果模型",
                  sum(treat == 1), sum(treat == 0)))
}

yy <- pm_num(data[[y]])

# ---- honest split：按个体对半分 ----
set.seed(seed)
if (!is.na(roles$id) && roles$id %in% names(data)) {
  units <- unique(as.character(data[[roles$id]]))
  perm <- sample(units)
  half <- rep(c("train", "eval"), length.out = length(perm))
  names(half) <- perm
  fold_of_row <- unname(half[as.character(data[[roles$id]])])
  split_how <- sprintf("按个体（%s）对半分：同一个体只落在一折，避免用同一人的信息估他自己的效应", roles$id)
} else {
  fold_of_row <- sample(rep(c("train", "eval"), length.out = nrow(data)))
  split_how <- "无个体标识，按行随机对半分"
}
tr <- which(fold_of_row == "train"); te <- which(fold_of_row == "eval")

mat <- pm_xmat(data[tr, , drop = FALSE], covariates, data[te, , drop = FALSE])
Xtr <- mat$x_fit; Xte <- mat$x_new

# ---- T-learner ----
fit_arm <- function(idx) {
  pm_cv_glmnet(Xtr[idx, , drop = FALSE], yy[tr][idx], "gaussian", alpha, seed)
}
tr_t <- which(treat[tr] == 1); tr_c <- which(treat[tr] == 0)
m1 <- fit_arm(tr_t); m0 <- fit_arm(tr_c)
mu1 <- as.numeric(stats::predict(m1, newx = Xte, s = "lambda.min"))
mu0 <- as.numeric(stats::predict(m0, newx = Xte, s = "lambda.min"))
cate <- mu1 - mu0

# S-learner（对照）：处理变量进特征并与协变量交互，一步估出效应面
Xs <- cbind(`(Intercept)` = 1, Xtr, t = treat[tr], Xtr * treat[tr])
Xs_e <- cbind(`(Intercept)` = 1, Xte, t = 1, Xte * 1)
Xs_e0 <- cbind(`(Intercept)` = 1, Xte, t = 0, Xte * 0)
ms <- tryCatch(pm_cv_glmnet(Xs, yy[tr], "gaussian", alpha, seed), error = function(e) NULL)
cate_s <- if (!is.null(ms)) {
  as.numeric(stats::predict(ms, newx = Xs_e, s = "lambda.min")) -
    as.numeric(stats::predict(ms, newx = Xs_e0, s = "lambda.min"))
} else {
  rep(NA_real_, length(te))
}

# ---- ml-cate.csv ----
cate_tab <- data.frame(unit_index = seq_along(te), treatment = treat[te],
                       outcome = yy[te], cate = round(cate, 6), check.names = FALSE)
if (!is.na(roles$id) && roles$id %in% names(data)) {
  cate_tab <- cbind(data.frame(id = data[[roles$id]][te], check.names = FALSE,
                               stringsAsFactors = FALSE), cate_tab)
}
invisible(write_csv_safe(cate_tab, file.path(out, "tables", "ml-cate.csv")))

# ---- GATES ----
g <- gates_groups
probs <- seq(0, 1, length.out = g + 1)
brks <- unique(stats::quantile(cate, probs = probs, na.rm = TRUE, type = 7))
if (length(brks) - 1 < g) {
  g <- max(2L, length(brks) - 1)
  warning(sprintf("CATE 取值有并列，GATES 分位组数下调为 %d", g))
}
grp <- base::cut(cate, breaks = brks, include.lowest = TRUE, labels = FALSE)
tg_names <- sprintf("tg%d", 0:(g - 1))
g_names <- sprintf("g%d", 1:(g - 1))
D <- data.frame(y = yy[te])
for (k in seq_len(g)) D[[tg_names[k]]] <- as.numeric(grp == k & treat[te] == 1)
if (g >= 2) for (k in 2:g) D[[g_names[k - 1]]] <- as.numeric(grp == k)
gates_fit <- stats::lm(stats::as.formula(paste("y ~", paste(c(tg_names, g_names), collapse = " + "))),
                       data = D)
gates_v <- pm_hc1(gates_fit)
gates_tab <- do.call(rbind, lapply(seq_len(g), function(k) {
  nm <- tg_names[k]
  b <- stats::coef(gates_fit)[[nm]]
  s <- sqrt(diag(gates_v))[[nm]]
  p <- 2 * stats::pnorm(-abs(b / s))
  data.frame(`GATES 组` = sprintf("第 %d 组（CATE 分位 %d/%d）", k, k, g),
             `组平均处理效应` = pm_f3(b), 标准误 = pm_f3(s), `p 值` = pm_f3(p),
             `组样本` = sum(grp == k, na.rm = TRUE),
             `CATE 均值` = pm_f3(mean(cate[grp == k], na.rm = TRUE)),
             check.names = FALSE)
}))
invisible(write_csv_safe(gates_tab, file.path(out, "tables", "ml-gates.csv")))

# ---- BLP ----
s_c <- cate - mean(cate, na.rm = TRUE)
blp_fit <- stats::lm(yy[te] ~ treat[te] + s_c + treat[te]:s_c)
blp_v <- pm_hc1(blp_fit)
blp_co <- stats::coef(blp_fit); blp_se <- sqrt(diag(blp_v))
pick_blp <- function(term) {
  i <- which(names(blp_co) == term)
  if (!length(i)) return(list(b = NA_real_, s = NA_real_, p = NA_real_))
  b <- blp_co[[i]]; s <- blp_se[[i]]
  list(b = b, s = s, p = 2 * stats::pnorm(-abs(b / s)))
}
b_int <- pick_blp("treat[te]:s_c")
b_t <- pick_blp("treat[te]")
blp_tab <- data.frame(
  项 = c("处理×CATE（异质性信号）", "处理项（ATE 基准）"),
  系数 = c(pm_f3(b_int$b), pm_f3(b_t$b)),
  标准误 = c(pm_f3(b_int$s), pm_f3(b_t$s)),
  `p 值` = c(pm_f3(b_int$p), pm_f3(b_t$p)),
  解读 = c("显著为正说明 CATE 排序在样本外仍有解释力；不显著则不得声称异质性",
           "可与 GATES 加权平均对照"),
  check.names = FALSE)
invisible(write_csv_safe(blp_tab, file.path(out, "tables", "ml-blp-test.csv")))

# ---- 重叠诊断 ----
ps_df <- data.frame(t = treat[te], Xte, check.names = FALSE)
ps_fit <- tryCatch(stats::glm(t ~ ., data = ps_df, family = stats::binomial()),
                   error = function(e) NULL)
ps <- if (!is.null(ps_fit)) as.numeric(stats::predict(ps_fit, type = "response")) else rep(NA_real_, length(te))
auc <- pm_auc(ps, treat[te])
extreme <- mean(ps < 0.05 | ps > 0.95, na.rm = TRUE)
overlap_tab <- data.frame(
  指标 = c("倾向得分 AUC", "贴边比例（e<0.05 或 e>0.95）", "CATE 均值", "CATE 标准差",
           "CATE 最小值／最大值"),
  值 = c(pm_f3(auc), pm_f3(extreme), pm_f3(mean(cate, na.rm = TRUE)),
         pm_f3(stats::sd(cate, na.rm = TRUE)),
         sprintf("%.3f／%.3f", min(cate, na.rm = TRUE), max(cate, na.rm = TRUE))),
  解读 = c("接近 1 说明处理组与对照组可比性差",
           "超过 0.10 时个体层面的 CATE 不可用于政策建议",
           "样本外折的平均处理效应近似",
           "异质性的原始尺度",
           "极值常来自外推，需对照重叠诊断阅读"),
  check.names = FALSE)
invisible(write_csv_safe(overlap_tab, file.path(out, "tables", "ml-overlap.csv")))

# ---- 图：倾向得分按组分布 ----
fig_path <- file.path(out, "figures", "ml-overlap.png")
cjk_font <- NULL
if (capabilities("cairo")) {
  f <- tryCatch(grDevices::pdfFonts(), error = function(e) NULL)
  cand <- c("Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "Source Han Sans SC")
  hit <- cand[cand %in% names(f)]
  if (length(hit)) cjk_font <- hit[[1]]
}
lab <- if (is.null(cjk_font)) {
  list(x = "Propensity score", y = "Count", t1 = "Treated", t0 = "Control",
       main = "Propensity score by group (eval fold)")
} else {
  list(x = "倾向得分", y = "频数", t1 = "处理组", t0 = "对照组",
       main = "倾向得分分布（样本外折）")
}
fig_ok <- tryCatch({
  grDevices::png(fig_path, width = 1600, height = 1000, res = 200,
                 type = if (capabilities("cairo")) "cairo" else "windows",
                 family = if (is.null(cjk_font)) "sans" else cjk_font)
  brk <- seq(0, 1, by = 0.05)
  h1 <- graphics::hist(ps[treat[te] == 1], breaks = brk, plot = FALSE)
  h0 <- graphics::hist(ps[treat[te] == 0], breaks = brk, plot = FALSE)
  ylim <- c(0, max(h1$counts, h0$counts, na.rm = TRUE) * 1.15)
  graphics::plot(h1, col = grDevices::adjustcolor("#C0504D", 0.6), ylim = ylim,
                 xlab = lab$x, ylab = lab$y, main = lab$main, border = "white")
  graphics::plot(h0, col = grDevices::adjustcolor("#4F81BD", 0.6), add = TRUE, border = "white")
  graphics::legend("top", legend = c(lab$t1, lab$t0),
                   fill = c(grDevices::adjustcolor("#C0504D", 0.6),
                            grDevices::adjustcolor("#4F81BD", 0.6)), bty = "n")
  grDevices::dev.off()
  TRUE
}, error = function(e) {
  try(grDevices::dev.off(), silent = TRUE)
  cat(sprintf("图 ml-overlap.png 生成失败：%s\n", conditionMessage(e)), file = stderr())
  FALSE
})

# ---- manifest ----
manifest <- data.frame(
  子流程 = tag,
  任务 = "cate-forest",
  键 = c("折分方式", "训练折行数", "样本外折行数", "GATES 组数", "种子", "协变量个数",
        "结果模型", "glmnet alpha", "λ（处理组）", "λ（对照组）", "倾向得分模型",
        "S-learner CATE 均值", "BLP p（处理×CATE）", "图制品"),
  值 = c(split_how, length(tr), length(te), g, seed, length(covariates),
        "cv.glmnet（未装 ranger/grf，森林类 T-learner 未执行）", alpha,
        sprintf("%.6g", m1$lambda.min), sprintf("%.6g", m0$lambda.min),
        "stats::glm(binomial) 极大似然（等价近乎无惩罚 logistic）",
        pm_f3(mean(cate_s, na.rm = TRUE)), pm_f3(b_int$p),
        ifelse(fig_ok, "figures/ml-overlap.png", "figures/ml-overlap.png（生成失败）")),
  check.names = FALSE)
invisible(write_csv_safe(manifest, file.path(out, "tables", sprintf("ml-run-manifest-%s.csv", tag))))

# ---- 报告 ----
sections <- list(
  "运行口径" = sprintf(
    "数据 `%s`；折分方式＝%s；GATES 组数 %d；种子 %d；协变量 %d 个（%s）；训练折 %d 行、样本外折 %d 行；结果模型 cv.glmnet（alpha=%s），倾向得分 stats::glm(binomial)。",
    data_path, split_how, g, seed, length(covariates),
    paste(covariates, collapse = "、"), length(tr), length(te), alpha),
  "CATE" = sprintf(
    "T-learner：处理组/对照组分别训练结果模型，CATE 为两模型在样本外折上的预测之差。\n均值 %.3f，标准差 %.3f，区间 %.3f–%.3f。\nS-learner 对照（处理变量进特征并交互）：均值 %.3f，标准差 %.3f。",
    mean(cate, na.rm = TRUE), stats::sd(cate, na.rm = TRUE),
    min(cate, na.rm = TRUE), max(cate, na.rm = TRUE),
    mean(cate_s, na.rm = TRUE), stats::sd(cate_s, na.rm = TRUE)),
  "GATES" = paste(sprintf("- %s：%s（标准误 %s，p=%s，组样本 %d，CATE 均值 %s）",
                          gates_tab[["GATES 组"]], gates_tab[["组平均处理效应"]],
                          gates_tab[["标准误"]], gates_tab[["p 值"]],
                          gates_tab[["组样本"]], gates_tab[["CATE 均值"]]), collapse = "\n"),
  "BLP" = sprintf("y ~ t + s + t:s（s 为 CATE 中心化，HC1）。处理×CATE 系数 %s（标准误 %s，p=%s）；处理项 %s（标准误 %s，p=%s）。",
                  pm_f3(b_int$b), pm_f3(b_int$s), pm_f3(b_int$p),
                  pm_f3(b_t$b), pm_f3(b_t$s), pm_f3(b_t$p)),
  "重叠诊断" = paste(sprintf("- %s：%s（%s）", overlap_tab[["指标"]], overlap_tab[["值"]],
                             overlap_tab[["解读"]]), collapse = "\n"),
  "可声称边界" = paste(
    "可声称：不同特征群体的平均效应存在差异（GATES），且该差异在样本外可复现（BLP 显著）。",
    "不可声称：某个个体的效应等于其 CATE；重叠不足时不可给出个体政策建议（C29、C30）。")
)
invisible(write_md(report_path, "ML 执行摘要：03-heterogeneity", sections))

cat(sprintf("[%s] 完成：GATES %d 组；BLP p=%.3f\n", slug, g, b_int$p))
