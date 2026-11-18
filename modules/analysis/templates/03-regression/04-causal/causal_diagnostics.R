# =============================================================================
# Paper Analysis 4SS — 因果识别诊断钩子（R，base R 实现）。列名与 .do / .py 严格一致。
#
# 设计原则
#   1) 只用 base R（stats/utils）；可选包用 requireNamespace() 探测，缺包只写 SKIP 不报错。
#   2) 不重估主模型：只补识别设计读数（五个 F、OLS-2SLS、AR、LTZ 阈值、RD 回退）。
#   3) 缺数据/缺列一律写 SKIP 并以正常状态结束，不阻断主流程。
#
# 输出（out/tables/）
#   first_stage_five_f.csv : model,F_standard,F_robust,F_cluster,F_bootstrap,F_effective,N,N_cluster,
#                            ols_coef,ols_se,iv_coef,iv_se,ratio,ar_ci_lo,ar_ci_hi,ar_bounded,
#                            main_ci_type,mu_star_reduced_form
#   bacon_decomp.csv       : term,weight,estimate,note
#   rdd_three_rows.csv     : row,coef,se,p,ci_lo,ci_hi,report_use,bw_selector,h,kernel,p_order,density_p,note
#   diagnostics-skips.csv  : block,reason,detail
#
# 用法
#   Rscript causal_diagnostics.R --data=<csv> --out=paper-workspace/04-analysis \
#       --y=outcome --endog=endog_x --iv="z z2" --controls="ability year" --cluster=region \
#       --running=running --cutoff=0 --treat=treated --reps=200
# =============================================================================

fs_header <- c("model", "F_standard", "F_robust", "F_cluster", "F_bootstrap", "F_effective",
               "N", "N_cluster", "ols_coef", "ols_se", "iv_coef", "iv_se", "ratio",
               "ar_ci_lo", "ar_ci_hi", "ar_bounded", "main_ci_type", "mu_star_reduced_form")
bacon_header <- c("term", "weight", "estimate", "note")
rdd_header <- c("row", "coef", "se", "p", "ci_lo", "ci_hi", "report_use", "bw_selector",
                "h", "kernel", "p_order", "density_p", "note")

write_out <- function(df, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(df, path, row.names = FALSE, fileEncoding = "UTF-8")
}

run_selfcheck <- function() {
  set.seed(20261115)
  n <- 3000; k <- 3
  v <- rnorm(n); c1 <- rnorm(n)
  Z <- sapply(seq_len(k), function(j) rnorm(n) + 0.15 * v)
  d <- as.vector(Z %*% rep(0.15, k)) + 0.7 * v + 0.3 * c1 + rnorm(n)
  y <- 1 * d + 0.7 * v + 0.5 * c1 + rnorm(n)
  W <- cbind(1, c1)
  rz <- function(x) resid_on(x, W)
  yt <- rz(y); dt <- rz(d); Zt <- apply(Z, 2, rz)
  pi <- solve_inv(crossprod(Zt)) %*% crossprod(Zt, dt)
  dh <- as.vector(Zt %*% pi)
  b2 <- sum(dh * yt) / sum(dh * dt)
  H <- rowSums((Zt %*% solve_inv(crossprod(Zt))) * Zt)
  nu <- dt - dh
  zeta <- dt - nu / (1 - H)
  bu <- sum(zeta * yt) / sum(zeta * dt)
  cat(sprintf("自检（真值 1）：2SLS=%.4f  UJIVE=%.4f  2SLS 偏误=%.4f  UJIVE 偏误=%.4f\n",
              b2, bu, b2 - 1, bu - 1))
  cat("说明：无混淆时两者都接近真值；有混淆时都会偏移（UJIVE 修正的是 many-instrument 偏误）。\n")
}

arg_value <- function(args, key, default = "") {
  hit <- grep(paste0("^--", key, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", key, "="), "", hit[1])
}

args <- commandArgs(trailingOnly = TRUE)
out_dir <- arg_value(args, "out", "paper-workspace/04-analysis")
tables <- file.path(out_dir, "tables")
data_path <- arg_value(args, "data", file.path(out_dir, "data", "analysis-data.csv"))
y_name <- arg_value(args, "y", "outcome")
d_name <- arg_value(args, "endog", "endog_x")
ivs <- strsplit(trimws(arg_value(args, "iv", "instrument_z")), "\\s+")[[1]]
ivs <- ivs[nzchar(ivs)]
ctrls <- strsplit(trimws(arg_value(args, "controls", "")), "\\s+")[[1]]
ctrls <- ctrls[nzchar(ctrls)]
cl_name <- arg_value(args, "cluster", "")
run_name <- arg_value(args, "running", "running")
cutoff <- as.numeric(arg_value(args, "cutoff", "0"))
treat_name <- arg_value(args, "treat", "treated")
reps <- as.integer(arg_value(args, "reps", "200"))
alpha <- as.numeric(arg_value(args, "alpha", "0.05"))
selfcheck <- arg_value(args, "selfcheck", "0") == "1"

skips <- data.frame(block = character(), reason = character(), detail = character())

add_skip <- function(block, reason, detail = "") {
  skips <<- rbind(skips, data.frame(block = block, reason = reason, detail = detail))
  message(sprintf("SKIP [%s]: %s %s", block, reason, detail))
}

if (!file.exists(data_path)) {
  write_out(data.frame(matrix(ncol = length(fs_header), nrow = 0, dimnames = list(NULL, fs_header))),
            file.path(tables, "first_stage_five_f.csv"))
  write_out(data.frame(matrix(ncol = length(bacon_header), nrow = 0, dimnames = list(NULL, bacon_header))),
            file.path(tables, "bacon_decomp.csv"))
  write_out(data.frame(matrix(ncol = length(rdd_header), nrow = 0, dimnames = list(NULL, rdd_header))),
            file.path(tables, "rdd_three_rows.csv"))
  add_skip("all", "no_data", data_path)
  write_out(skips, file.path(tables, "diagnostics-skips.csv"))
  quit(save = "no", status = 0)
}

df <- utils::read.csv(data_path, stringsAsFactors = FALSE, check.names = FALSE)
used_cols <- unique(c(y_name, d_name, ivs, ctrls, cl_name, run_name))
chk <- prep(df, used_cols)
if (!chk$ok) {
  add_skip("all", "missing_vars", paste(chk$missing, collapse = ","))
  write_out(data.frame(matrix(ncol = length(fs_header), nrow = 0, dimnames = list(NULL, fs_header))),
            file.path(tables, "first_stage_five_f.csv"))
  write_out(skips, file.path(tables, "diagnostics-skips.csv"))
  quit(save = "no", status = 0)
}
df <- chk$data
if (chk$dropped > 0) message(sprintf("注意：complete.cases 删去 %d 行；三语言一致按整行删除。", chk$dropped))

# --- 工具函数 ---------------------------------------------------------------
solve_inv <- function(A) {
  # 用 solve()；奇异时退回广义逆（base R 有 ginv 在 MASS，未必可用）
  tryCatch(solve(A), error = function(e) {
    s <- svd(A); pos <- s$d > max(s$d) * 1e-10
    s$v[, pos, drop = FALSE] %*% diag(1 / s$d[pos], nrow = sum(pos)) %*% t(s$u[, pos, drop = FALSE])
  })
}

ols_fit <- function(y, X) {
  XtX <- crossprod(X)
  inv <- solve_inv(XtX)
  b <- as.vector(inv %*% crossprod(X, y))
  r <- as.vector(y - X %*% b)
  list(b = b, resid = r, inv = inv, n = length(y), k = ncol(X))
}

sandwich <- function(fit, meat, adj = 1) {
  V <- fit$inv %*% meat %*% fit$inv * adj
  V
}

meat_hc <- function(X, r) {
  crossprod(X * r)
}

# 聚类 meat：用 rowsum 聚合得分，避免 n×G 稠密矩阵（大样本下会爆内存）
meat_cluster <- function(X, r, g) {
  S <- rowsum(X * r, group = as.character(g), reorder = FALSE)
  list(meat = crossprod(S), ncl = nrow(S))
}

# 只保留参与计算的列都完整的行，并统一转成数值
prep <- function(df, cols) {
  cols <- unique(cols[nzchar(cols)])
  miss <- setdiff(cols, names(df))
  if (length(miss)) return(list(ok = FALSE, missing = miss))
  sub <- df[, cols, drop = FALSE]
  num <- suppressWarnings(as.data.frame(lapply(sub, function(x) as.numeric(as.character(x)))))
  bad <- vapply(num, function(x) all(is.na(x)), logical(1))
  if (any(bad)) return(list(ok = FALSE, missing = names(bad)[bad]))
  keep <- stats::complete.cases(num)
  list(ok = TRUE, data = num[keep, , drop = FALSE], dropped = sum(!keep))
}

wald_f <- function(b, V, k) {
  tryCatch(as.numeric(t(b) %*% solve(V, b)) / k, error = function(e) NA_real_)
}

p_norm <- function(z) 2 * (1 - pnorm(abs(z)))

resid_on <- function(v, W) {
  fit <- ols_fit(v, W)
  fit$resid
}

# --- IV ---------------------------------------------------------------------
need <- c(y_name, d_name, ivs, ctrls)
missing <- setdiff(need, names(df))
if (length(missing)) {
  add_skip("iv", "missing_vars", paste(missing, collapse = ","))
  write_out(data.frame(matrix(ncol = length(fs_header), nrow = 0, dimnames = list(NULL, fs_header))),
            file.path(tables, "first_stage_five_f.csv"))
} else {
  y <- as.numeric(df[[y_name]])
  d <- as.numeric(df[[d_name]])
  Zraw <- as.matrix(df[, ivs, drop = FALSE])
  W <- if (length(ctrls)) cbind(1, as.matrix(df[, ctrls, drop = FALSE])) else cbind(1)
  y_t <- resid_on(y, W)
  d_t <- resid_on(d, W)
  Z_t <- apply(Zraw, 2, function(col) resid_on(as.numeric(col), W))
  Z_t <- as.matrix(Z_t)
  n <- length(y_t); k <- ncol(Z_t)

  # 2SLS（FWL 形式）
  pi_fit <- ols_fit(d_t, Z_t)
  pi_hat <- pi_fit$b
  d_hat <- as.vector(Z_t %*% pi_hat)
  iv_b <- sum(d_hat * y_t) / sum(d_hat * d_t)
  u <- y_t - iv_b * d_t
  s2 <- sum(u^2) / max(1, n - k - 1)
  iv_se <- sqrt(s2 / sum(d_hat^2))

  # OLS
  X_ols <- cbind(W, d)
  ols_fit0 <- ols_fit(y, X_ols)
  ols_b <- tail(ols_fit0$b, 1)
  ols_se <- sqrt(tail(diag(ols_fit0$inv), 1) * sum(ols_fit0$resid^2) / max(1, n - ncol(X_ols)))

  # 五个 F
  F_std <- wald_f(pi_hat, diag(k) * (sum(pi_fit$resid^2) / max(1, n - k)) %*% pi_fit$inv, k)
  V_rob <- sandwich(pi_fit, meat_hc(Z_t, pi_fit$resid), n / max(1, n - k))
  F_rob <- wald_f(pi_hat, V_rob, k)
  F_clu <- NA_real_; ncl <- 1; V_eff <- V_rob
  if (nzchar(cl_name) && cl_name %in% names(df)) {
    mc <- meat_cluster(Z_t, pi_fit$resid, df[[cl_name]])
    ncl <- mc$ncl
    V_clu <- sandwich(pi_fit, mc$meat, ncl / max(1, ncl - 1))
    F_clu <- wald_f(pi_hat, V_clu, k)
    V_eff <- V_clu
  }
  Q <- crossprod(Z_t) / n
  F_eff <- as.numeric(t(pi_hat) %*% Q %*% pi_hat) / sum(diag(V_eff %*% Q))

  # bootstrap F（仅单工具）
  F_boot <- NA_real_
  if (k == 1) {
    set.seed(20261115)
    groups <- if (nzchar(cl_name) && cl_name %in% names(df)) df[[cl_name]] else seq_len(n)
    ug <- unique(groups)
    t2 <- numeric(0)
    for (b in seq_len(max(20, min(reps, 1000)))) {
      pick <- sample(ug, length(ug), replace = TRUE)
      idx <- unlist(lapply(pick, function(g) which(groups == g)))
      zz <- Z_t[idx, 1]; dd <- d_t[idx]
      if (stats::var(zz) == 0) next
      bb <- sum(zz * dd) / sum(zz^2)
      rr <- dd - bb * zz
      se_b <- sqrt((sum(rr^2) / max(1, length(idx) - 1)) / sum(zz^2))
      if (se_b > 0) t2 <- c(t2, (bb / se_b)^2)
    }
    F_boot <- if (length(t2)) mean(t2) else NA_real_
  } else {
    add_skip("iv_bootstrap", "multi_instrument", "多工具下 bootstrap F 未定义；改看 effective F 与 AR")
  }

  # AR 区间
  grid <- seq(iv_b - 6 * iv_se, iv_b + 6 * iv_se, length.out = 81)
  accept <- logical(length(grid))
  for (i in seq_along(grid)) {
    yy <- y_t - grid[i] * d_t
    f0 <- ols_fit(yy, Z_t)
    if (k == 1) {
      Vb <- if (ncl > 1) sandwich(f0, meat_cluster(as.matrix(Z_t), f0$resid, df[[cl_name]])$meat,
                                 ncl / (ncl - 1)) else sandwich(f0, meat_hc(as.matrix(Z_t), f0$resid))
      accept[i] <- p_norm(f0$b[1] / sqrt(Vb[1, 1])) > alpha
    } else {
      Vb <- if (ncl > 1) sandwich(f0, meat_cluster(Z_t, f0$resid, df[[cl_name]])$meat,
                                 ncl / (ncl - 1)) else sandwich(f0, meat_hc(Z_t, f0$resid))
      stat <- tryCatch(as.numeric(t(f0$b) %*% solve(Vb, f0$b)), error = function(e) NA_real_)
      accept[i] <- !is.na(stat) && pchisq(stat, df = k, lower.tail = FALSE) > alpha
    }
  }
  ar_lo <- if (any(accept)) min(grid[accept]) else NA_real_
  ar_hi <- if (any(accept)) max(grid[accept]) else NA_real_
  mu_star <- if (k == 1) sum(Z_t[, 1] * y_t) / sum(Z_t[, 1]^2) else NA_real_

  main_ci <- if (!is.na(F_eff) && F_eff < 10) "ar" else if (!is.na(F_eff) && F_eff < 23) "tF_or_ar" else "analytic"

  fs <- data.frame(
    model = "iv_main", F_standard = F_std, F_robust = F_rob, F_cluster = F_clu,
    F_bootstrap = F_boot, F_effective = F_eff, N = n, N_cluster = ncl,
    ols_coef = ols_b, ols_se = ols_se, iv_coef = iv_b, iv_se = iv_se,
    ratio = if (ols_b != 0) iv_b / ols_b else NA_real_,
    ar_ci_lo = ar_lo, ar_ci_hi = ar_hi, ar_bounded = as.integer(any(accept)),
    main_ci_type = main_ci, mu_star_reduced_form = mu_star, stringsAsFactors = FALSE
  )
  write_out(fs, file.path(tables, "first_stage_five_f.csv"))
  message(sprintf("IV 诊断完成：F_std=%.2f F_rob=%.2f F_clu=%.2f F_eff=%.2f",
                  F_std, F_rob, F_clu, F_eff))
}

# --- DiD --------------------------------------------------------------------
if (requireNamespace("bacondecomp", quietly = TRUE)) {
  ok <- FALSE
  if (all(c(y_name, treat_name) %in% names(df))) {
    res_b <- tryCatch({
      td <- bacondecomp::bacon(y ~ treat, data = df, id_var = "id", time_var = "time")
      as.data.frame(td)
    }, error = function(e) NULL)
    if (!is.null(res_b) && nrow(res_b) > 0) {
      write_out(res_b, file.path(tables, "bacon_decomp.csv"))
      ok <- TRUE
    }
  }
  if (!ok) {
    add_skip("did_bacon", "run_failed", "bacondecomp 可用但调用失败；请按包文档调整 id/time 变量名")
    write_out(data.frame(term = "SKIP", weight = NA_real_, estimate = NA_real_,
                         note = "bacondecomp 调用失败；见上一条 SKIP"), file.path(tables, "bacon_decomp.csv"))
  }
} else {
  add_skip("did_bacon", "missing_package", "bacondecomp")
  write_out(data.frame(term = "SKIP", weight = NA_real_, estimate = NA_real_,
                       note = "bacondecomp 未安装；可从 Stata 模板日志人工抄录"),
            file.path(tables, "bacon_decomp.csv"))
}

# --- RDD --------------------------------------------------------------------
if (!(run_name %in% names(df)) || !(y_name %in% names(df))) {
  add_skip("rdd", "missing_vars", run_name)
  write_out(data.frame(row = "SKIP", note = "缺 running/y"), file.path(tables, "rdd_three_rows.csv"))
} else {
  rv <- as.numeric(df[[run_name]]); yv <- as.numeric(df[[y_name]])
  h <- 0.5 * stats::sd(rv, na.rm = TRUE)
  band <- abs(rv - cutoff) <= h
  rc <- rv - cutoff
  dpos <- as.numeric(rv >= cutoff)
  w <- pmax(0, 1 - abs(rc) / h)
  X <- cbind(1, rc, dpos, rc * dpos)[band, , drop = FALSE]
  Y <- yv[band]
  sw <- sqrt(w[band])
  fit <- ols_fit(Y * sw, X * sw)
  V <- sandwich(fit, meat_hc(X * sw, fit$resid), sum(band) / max(1, sum(band) - 4))
  jump <- fit$b[3]; jump_se <- sqrt(V[3, 3])
  n_l <- sum(band & rv < cutoff); n_r <- sum(band & rv >= cutoff)
  tot <- n_l + n_r
  dens_p <- if (tot > 0) stats::binom.test(n_l, tot, 0.5)$p.value else NA_real_
  write_out(data.frame(row = "conventional", coef = jump, se = jump_se,
                       p = p_norm(jump / jump_se),
                       ci_lo = jump - 1.96 * jump_se, ci_hi = jump + 1.96 * jump_se,
                       report_use = "fallback_conventional", bw_selector = "manual_h",
                       h = h, kernel = "triangular", p_order = 1, density_p = dens_p,
                       note = "R base 回退；主报须 rdrobust 的 Robust 行"),
            file.path(tables, "rdd_three_rows.csv"))
  message(sprintf("RD 回退：jump=%.4f se=%.4f h=%.3f 窗内左右=%d/%d", jump, jump_se, h, n_l, n_r))
}

if (!nrow(skips)) skips <- data.frame(block = character(), reason = character(), detail = character())
write_out(skips, file.path(tables, "diagnostics-skips.csv"))
message(sprintf("完成。输出目录：%s", tables))

# --- 自检入口（放到末尾，确保依赖函数已定义） ---
if (selfcheck) {
  run_selfcheck()
  quit(save = "no", status = 0)
}
