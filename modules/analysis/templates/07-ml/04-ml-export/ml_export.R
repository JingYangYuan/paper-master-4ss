# 07-ml/04-ml-export：把前三段 ML 结果合成一张宽表、方法说明草稿与未执行清单
#
# 只读表，不重算：本脚本不加载 analysis-data.csv，也不拟合任何模型。
# 输入：tables/ml-model-performance*.csv、ml-causal-estimates*.csv、ml-gates.csv、
#       ml-blp-test.csv、ml-overlap.csv、ml-selected-variables*.csv、ml-regularization-path*.csv、
#       ml-run-manifest-*.csv、reports/ml-run-*.md
# 输出：
#   tables/ml-wide-table.csv       统一口径的估计/指标长表（与 Python 侧同列）：
#                                  子流程/任务/方法或组/指标/数值/样本量/来源表/备注
#   reports/ml-methods-note.md     方法说明草稿：折分方案、超级参数、样本外指标、可声称边界
#   tables/ml-not-run-list.csv     未执行清单（缺包、缺表、被阻断的条目一律列明，不含占位数字）
#
# 纪律：本段只搬运数字，不产生新估计。任何一段没跑、表里没有的条目，进 ml-not-run-list.csv，
#   不在宽表里填 0 或 "n/a 当结果"。方法说明草稿是给人改的稿子，不是可投稿定稿。

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

pm_f3 <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  ifelse(is.na(x), NA_character_, sprintf("%.3f", x))
}
pm_int <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  ifelse(is.na(x), NA_character_, formatC(round(x), format = "d", big.mark = ""))
}
pm_pick <- function(d, name) if (name %in% names(d)) d[[name]] else rep(NA, nrow(d))
pm_first_col <- function(d, cand) {
  hit <- intersect(cand, names(d))
  if (!length(hit)) return(rep(NA, nrow(d)))
  d[[hit[[1]]]]
}

args <- parse_common_args()
ensure_dirs(args$out_root)
out <- args$out_root
tables_dir <- file.path(out, "tables")
reports_dir <- file.path(out, "reports")
slug <- "07-ml/04-ml-export"

read_tab <- function(fname) {
  p <- file.path(tables_dir, fname)
  if (!file.exists(p)) return(NULL)
  tryCatch(utils::read.csv(p, stringsAsFactors = FALSE, check.names = FALSE,
                           fileEncoding = "UTF-8-BOM"),
           error = function(e) NULL)
}

rows <- list()
# 宽表口径与 Python 侧一致：长表，一行一个“指标”，列为
#   子流程 / 任务 / 方法或组 / 指标 / 数值 / 样本量 / 来源表 / 备注
add_row <- function(sub, task, item, coef = NA, se = NA, p = NA, r2 = NA, rmse = NA,
                    auc = NA, acc = NA, n = NA, source = NA, note = NA) {
  metrics <- list(`处理变量系数` = coef, `标准误` = se, `p 值` = p,
                  `样本外 R2` = r2, `样本外 RMSE` = rmse,
                  `样本外 AUC` = auc, `样本外准确率` = acc)
  for (metric in names(metrics)) {
    v <- metrics[[metric]]
    if (length(v) != 1 || is.na(v)) next
    rows[[length(rows) + 1]] <<- data.frame(
      子流程 = sub, 任务 = task, `方法或组` = item, 指标 = metric,
      数值 = pm_f3(v), 样本量 = pm_int(n), 来源表 = source, 备注 = note,
      check.names = FALSE)
  }
  invisible(NULL)
}

miss <- list()
note_miss <- function(sub, item, why, how) {
  miss[[length(miss) + 1]] <<- data.frame(
    子流程 = sub, 项目 = item, 状态 = "未执行", 原因 = why, 补齐方式 = how,
    check.names = FALSE)
}

# ---- 01 监督学习 ----
# 01 段各任务写同一张 ml-model-performance.csv（后写覆盖先写），故优先读 -<任务ID>.csv 留档；
# 若只有主表，则按列集合判断该表属于回归型还是二分类型。
perf_of <- function(task, need_col) {
  d <- read_tab(sprintf("ml-model-performance-%s.csv", task))
  if (!is.null(d) && need_col %in% names(d)) return(d)
  d <- read_tab("ml-model-performance.csv")
  if (!is.null(d) && need_col %in% names(d)) return(d)
  NULL
}
perf_reg <- perf_of("predict-regression", "样本外 R2")
perf_bin <- perf_of("predict-binary", "样本外 AUC")
if (is.null(perf_reg) && is.null(perf_bin)) {
  note_miss("01-supervised", "全部监督学习表", "找不到 ml-model-performance*.csv：01 段未跑",
            "先跑 templates/07-ml/01-supervised/supervised_ml.R")
} else {
  if (!is.null(perf_reg)) for (i in seq_len(nrow(perf_reg))) {
    add_row("01-supervised", "predict-regression", as.character(perf_reg[[1]][i]),
            r2 = perf_reg[["样本外 R2"]][i], rmse = perf_reg[["样本外 RMSE"]][i],
            n = pm_first_col(perf_reg, c("测试样本", "训练样本"))[i],
            source = "ml-model-performance-predict-regression.csv",
            note = sprintf("MAE %s；训练集 R2 %s", pm_f3(perf_reg[["样本外 MAE"]][i]),
                           pm_f3(perf_reg[["训练集 R2"]][i])))
  }
  if (!is.null(perf_bin)) for (i in seq_len(nrow(perf_bin))) {
    add_row("01-supervised", "predict-binary", as.character(perf_bin[[1]][i]),
            auc = perf_bin[["样本外 AUC"]][i], acc = perf_bin[["样本外准确率"]][i],
            n = pm_first_col(perf_bin, c("测试样本", "训练样本"))[i],
            source = "ml-model-performance-predict-binary.csv",
            note = sprintf("Brier %s；训练集准确率 %s", pm_f3(perf_bin[["样本外 Brier"]][i]),
                           pm_f3(perf_bin[["训练集准确率"]][i])))
  }
}
regpath <- read_tab("ml-regularization-path.csv")
if (!is.null(regpath)) {
  for (i in seq_len(nrow(regpath))) {
    add_row("01-supervised", "regularized", as.character(regpath[["模型"]][i]),
            n = regpath[["样本量"]][i], source = "ml-regularization-path.csv",
            note = sprintf("λ=%s；l1_ratio=%s；候选 %s 个特征，选中 %s 个",
                           pm_f3(regpath[["惩罚参数"]][i]), pm_f3(regpath[["l1_ratio"]][i]),
                           regpath[["候选特征数"]][i], regpath[["选中特征数"]][i]))
  }
}
sel <- read_tab("ml-selected-variables-regularized.csv")
if (!is.null(sel) && "selected" %in% names(sel)) {
  picked <- sel[as.character(sel$selected) %in% c("是", "TRUE", "True", "1"), , drop = FALSE]
  add_row("01-supervised", "regularized", "Lasso 选中变量清单",
          n = nrow(sel), source = "ml-selected-variables-regularized.csv",
          note = sprintf("选中 %d 个：%s", nrow(picked),
                         paste(utils::head(as.character(picked$variable), 12), collapse = ", ")))
}
# 注意：r_common.R 在被 source 时会用它的 %||% 覆盖本文件顶部定义的那个，
# 且它对 data.frame 会报 'length = n' in coercion to 'logical(1)'；故这里只用显式 NULL 判断。
imp <- read_tab("ml-variable-importance-predict-regression.csv")
if (is.null(imp)) imp <- read_tab("ml-variable-importance.csv")
if (!is.null(imp)) {
  add_row("01-supervised", "predict-regression", "置换重要性（前 5）",
          n = nrow(imp), source = "ml-variable-importance.csv",
          note = paste(sprintf("%s=%s", utils::head(imp[[1]], 5),
                               pm_f3(utils::head(imp[["置换重要性均值"]], 5))), collapse = "; "))
}

# ---- 02 因果 ML（列集随任务不同，逐列判存在） ----
est <- read_tab("ml-causal-estimates.csv")
if (is.null(est)) {
  note_miss("02-causal-ml", "全部因果 ML 估计", "tables/ml-causal-estimates.csv 不存在：02 段未跑",
            "先跑 templates/07-ml/02-causal-ml/causal_ml.R")
} else {
  for (i in seq_len(nrow(est))) {
    model <- as.character(est[["模型"]][i])
    task <- if (grepl("PDS|基准：全部候选", model)) "pds-controls" else
      if (grepl("DML", model)) "dml-plr" else
        if (grepl("2SLS", model)) "iv-lasso" else
          if (grepl("基准 OLS", model)) "dml-plr" else "unknown"
    extra <- c(
      if (!is.na(pm_pick(est, "控制变量数")[i])) sprintf("控制变量 %s 个", pm_pick(est, "控制变量数")[i]),
      if (!is.na(pm_pick(est, "第一阶段 F")[i])) sprintf("第一阶段 F %s", pm_f3(pm_pick(est, "第一阶段 F")[i])),
      if (!is.na(pm_pick(est, "聚类层级")[i])) sprintf("标准误 %s", pm_pick(est, "聚类层级")[i]),
      if (!is.na(pm_pick(est, "备注")[i])) as.character(pm_pick(est, "备注")[i]))
    add_row("02-causal-ml", task, model,
            coef = pm_pick(est, "处理变量系数")[i], se = pm_pick(est, "标准误")[i],
            p = pm_pick(est, "p 值")[i], n = pm_pick(est, "观测值")[i],
            source = "ml-causal-estimates.csv",
            note = paste(extra[!is.na(extra)], collapse = "；"))
  }
}
folds <- read_tab("ml-crossfit-folds.csv")
if (!is.null(folds)) {
  b <- suppressWarnings(as.numeric(folds[["折系数"]]))
  rng <- suppressWarnings(as.numeric(range(b, na.rm = TRUE)))
  add_row("02-causal-ml", "dml-plr", "交叉拟合折间系数范围",
          note = sprintf("最小 %.3f，最大 %.3f，极差 %.3f（折间波动过大说明 nuisance 不稳定）",
                         rng[[1]], rng[[2]], rng[[2]] - rng[[1]]),
          source = "ml-crossfit-folds.csv")
}

# ---- 03 异质性 ----
gates <- read_tab("ml-gates.csv")
if (is.null(gates)) {
  note_miss("03-heterogeneity", "GATES/BLP/CATE 全部结果",
            "tables/ml-gates.csv 不存在：03 段未跑", "先跑 templates/07-ml/03-heterogeneity/cate_forest.R")
} else {
  for (i in seq_len(nrow(gates))) {
    add_row("03-heterogeneity", "gates", as.character(gates[["GATES 组"]][i]),
            coef = gates[["组平均处理效应"]][i], se = gates[["标准误"]][i],
            p = gates[["p 值"]][i], n = gates[["组样本"]][i],
            source = "ml-gates.csv",
            note = sprintf("该组 CATE 均值 %s", pm_f3(gates[["CATE 均值"]][i])))
  }
}
blp <- read_tab("ml-blp-test.csv")
if (!is.null(blp)) {
  for (i in seq_len(nrow(blp))) {
    add_row("03-heterogeneity", "blp", as.character(blp[["项"]][i]),
            coef = blp[["系数"]][i], se = blp[["标准误"]][i], p = blp[["p 值"]][i],
            source = "ml-blp-test.csv", note = as.character(blp[["解读"]][i]))
  }
}
ov <- read_tab("ml-overlap.csv")
if (!is.null(ov)) {
  for (i in seq_len(nrow(ov))) {
    v <- suppressWarnings(as.numeric(ov[["值"]][i]))
    add_row("03-heterogeneity", "overlap", as.character(ov[["指标"]][i]),
            coef = if (is.na(v)) NA else v, source = "ml-overlap.csv",
            note = if (is.na(v)) paste0("值 ", ov[["值"]][i], "；", as.character(ov[["解读"]][i]))
            else as.character(ov[["解读"]][i]))
  }
} else if (!is.null(gates)) {
  note_miss("03-heterogeneity", "重叠诊断", "tables/ml-overlap.csv 缺失：CATE 不可用于个体政策建议",
            "重跑 03 段生成 ml-overlap.csv")
}

wide <- if (length(rows)) do.call(rbind, rows) else
  data.frame(子流程 = character(0), 任务 = character(0), `方法或组` = character(0),
             指标 = character(0), 数值 = character(0), 样本量 = character(0),
             来源表 = character(0), 备注 = character(0), check.names = FALSE)
invisible(write_csv_safe(wide, file.path(tables_dir, "ml-wide-table.csv")))

# ---- 超级参数与折分方案：从各段 manifest 汇总 ----
man_files <- list.files(tables_dir, pattern = "^ml-run-manifest-", full.names = TRUE)
man <- if (length(man_files)) {
  do.call(rbind, lapply(man_files, function(f) {
    d <- tryCatch(utils::read.csv(f, stringsAsFactors = FALSE, check.names = FALSE,
                                  fileEncoding = "UTF-8-BOM"), error = function(e) NULL)
    if (is.null(d) || !all(c("子流程", "键", "值") %in% names(d))) NULL else d
  }))
} else NULL
man_md <- if (!is.null(man)) {
  paste(sprintf("- %s · %s · %s：%s", man[["子流程"]], man[["任务"]], man[["键"]], man[["值"]]),
        collapse = "\n")
} else {
  "没有找到 tables/ml-run-manifest-*.csv：超级参数与折分方案无从记录，属于阻断项。"
}

# ---- 未执行清单：缺包、缺表、报告里的阻断 ----
pkgs <- c("ranger", "grf", "randomForest", "xgboost", "gbm", "cobalt")
absent <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(absent)) {
  note_miss("01–03",
            paste(sprintf("%s（未安装）", paste(absent, collapse = "、")), collapse = ""),
            "本机未装，禁止联网安装；森林类 T-learner、因果森林、SHAP 归因、协变量平衡诊断因此无法执行",
            "换到装了上述包的机器重跑；本机用 glmnet 近似替代，替代口径已在各段报告写明")
}
note_miss("02-causal-ml", "histgb nuisance 学习器",
          "sklearn HistGradientBoostingRegressor 在 R 侧无对应物；02 段改用 glmnet（--learner lasso/ridge/enet）",
          "如需与 .py 逐位对齐，用 python 侧结果直接比对，不要声称两者相同")
note_miss("02-causal-ml", "PLIV（部分线性 IV-DML）",
          "未实现：需在 DML 框架内再做工具变量正交化，超出本段 --learner 变体范围",
          "在 02 段新增任务后重跑，同时补 md-selected-variables 里工具变量来源")
note_miss("02-causal-ml", "弱工具稳健推断（Anderson–Rubin）",
          "未实现：当前只报 2SLS 点估计与第一阶段 F",
          "第一阶段 F 明显偏小时，进入 04-causal 做 AR 置信集")
note_miss("03-heterogeneity", "honest CATE 置信区间",
          "grf 未安装；当前 CATE 只有点估计，未给单位级区间",
          "装 grf 后跑 causal_forest；或按 GATES 组区间下行到群体结论")
if (!is.null(ov)) {
  high_auc <- suppressWarnings(as.numeric(ov[["值"]][ov[["指标"]] == "倾向得分 AUC"]))
  ext <- suppressWarnings(as.numeric(ov[["值"]][grepl("贴边比例", ov[["指标"]])]))
  if (length(high_auc) && !is.na(high_auc) && high_auc > 0.8) {
    note_miss("03-heterogeneity", "个体层面 CATE 的使用",
              sprintf("倾向得分 AUC=%.3f，处理组与对照组可比性差", high_auc),
              "只报 GATES 组效应，不写个体政策含义")
  }
  if (length(ext) && !is.na(ext) && ext > 0.10) {
    note_miss("03-heterogeneity", "重叠不足时的外推",
              sprintf("贴边比例=%.3f 超过 0.10 的经验阈值", ext),
              "截尾重估或在报告中明确限定解释范围")
  }
}
run_reports <- list.files(reports_dir, pattern = "^ml-run-", full.names = TRUE)
blocked_lines <- unlist(lapply(run_reports, function(f) {
  txt <- tryCatch(readLines(f, warn = FALSE, encoding = "UTF-8"), error = function(e) character(0))
  hit <- grep("阻断", txt, value = TRUE)
  if (length(hit)) sprintf("%s：%s", basename(f), trimws(hit)) else character(0)
}))
if (length(blocked_lines)) {
  note_miss("01–03", "报告中记录的阻断", paste(blocked_lines, collapse = " | "),
            "按各段报告「阻断原因」逐条修复后重跑对应子流程")
}
not_run <- if (length(miss)) do.call(rbind, miss) else
  data.frame(子流程 = character(0), 项目 = character(0), 状态 = character(0),
             原因 = character(0), 补齐方式 = character(0), check.names = FALSE)
invisible(write_csv_safe(not_run, file.path(tables_dir, "ml-not-run-list.csv")))

# ---- 方法说明草稿 ----
# 只把真正带样本外指标的条目写进方法说明，系数型条目另行指向宽表
perf_cols <- c("样本外 R2", "样本外 RMSE", "样本外 AUC", "样本外准确率")
oos <- if (nrow(wide) && any(wide$指标 %in% perf_cols)) {
  w2 <- wide[wide$指标 %in% perf_cols, , drop = FALSE]
  paste(c(sprintf("- %s · %s · %s · %s：%s",
                  w2$子流程, w2$任务, w2[["方法或组"]], w2$指标, w2$数值),
          "", "其余条目是系数型结果，没有样本外预测指标，见 tables/ml-wide-table.csv 的对应行。"),
        collapse = "\n")
} else {
  "没有可用的样本外指标：前三段未产出 ml-model-performance*.csv。"
}
sections <- list(
  "折分方案" = paste(
    "交叉验证只用于选超参数，样本外指标取自留出折；同一体不跨折（honest split 用于 CATE）。",
    "各段实际设置如下（取自 tables/ml-run-manifest-*.csv）：", man_md, sep = "\n\n"),
  "超级参数" = paste(
    "glmnet 的正则化强度由 5 折交叉验证按 lambda.min 选取，标准化开关为 TRUE；",
    "惩罚类型 alpha 由各段 --alpha/--learner 决定并记录在 manifest（lasso=1、ridge=0、弹性网=0.5）。",
    "未做嵌套交叉验证：超参数在训练折内选，样本外折没有参与选参，这是最低限度的防泄漏口径；",
    "若审稿要求，应改为嵌套 CV 并重报。"),
  "样本外指标" = oos,
  "可声称边界" = paste(
    "可声称：在给定折分与超参数下，ML 估计与基准 OLS/2SLS 的方向和量级关系；GATES 显示的群体效应差异。",
    "不可声称：ML 修正了内生性（PDS/DML 只处理正则化偏误，识别仍靠控制集条件外生）；",
    "个体效应等于其 CATE；置换重要性等于因果重要性；未执行清单里的方法被跑过。",
    "数值一律来自 tables/ml-wide-table.csv，引用时同时给出该表行与来源表名。"),
  "待补" = if (nrow(not_run)) {
    paste(sprintf("- %s · %s：%s（补齐方式：%s）", not_run[["子流程"]], not_run[["项目"]],
                  not_run[["原因"]], not_run[["补齐方式"]]), collapse = "\n")
  } else {
    "无。"
  })
invisible(write_md(file.path(reports_dir, "ml-methods-note.md"), "ML 方法说明（草稿）", sections))

manifest <- data.frame(
  子流程 = "04-ml-export", 任务 = "export",
  键 = c("输入表数", "宽表行数", "未执行条目数", "宽表文件", "未执行清单", "方法说明"),
  值 = c(length(list.files(tables_dir, pattern = "\\.csv$")), nrow(wide), nrow(not_run),
        "tables/ml-wide-table.csv", "tables/ml-not-run-list.csv",
        "reports/ml-methods-note.md"), check.names = FALSE)
invisible(write_csv_safe(manifest, file.path(tables_dir, "ml-run-manifest-04-ml-export.csv")))

# ---- 主清单：与 Python 侧同列（子流程/表/状态/行数/阻断说明），逐表报产出状态 ----
expected <- list(
  "01-supervised" = c("ml-regularization-path.csv", "ml-model-performance.csv", "ml-variable-importance.csv",
                      "ml-calibration.csv", "ml-selected-variables.csv",
                      "ml-structure-pca.csv", "ml-structure-cluster.csv"),
  "02-causal-ml" = c("ml-causal-estimates.csv", "ml-pds-selected-variables.csv", "ml-crossfit-folds.csv"),
  "03-heterogeneity" = c("ml-cate.csv", "ml-gates.csv", "ml-blp-test.csv", "ml-overlap.csv"))
canon <- do.call(rbind, lapply(names(expected), function(sub) {
  do.call(rbind, lapply(expected[[sub]], function(nm) {
    p <- file.path(tables_dir, nm)
    ok <- file.exists(p)
    n <- if (ok) nrow(utils::read.csv(p, stringsAsFactors = FALSE, check.names = FALSE,
                                      fileEncoding = "UTF-8-BOM")) else 0
    data.frame(子流程 = sub, 表 = nm, 状态 = if (ok) "已产出" else "未产出", 行数 = n,
               阻断说明 = if (ok) "" else "上游脚本未生成该表；不得把缺失表的结论写入正文。",
               check.names = FALSE)
  }))
}))
invisible(write_csv_safe(canon, file.path(tables_dir, "ml-run-manifest.csv")))

cat(sprintf("[%s] 完成：宽表 %d 行；未执行条目 %d 条；方法说明 reports/ml-methods-note.md\n",
            slug, nrow(wide), nrow(not_run)))
