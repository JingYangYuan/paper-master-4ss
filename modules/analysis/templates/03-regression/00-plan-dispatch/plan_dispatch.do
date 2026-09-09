* Paper Analysis 4SS - 03 regression / 00 plan dispatch.
* Equivalent CLI parameters: --data --plan --dict --out-root --run-log --slug --tasks
* This subflow reads analysis-execution-plan metadata and writes dispatch files; it must not estimate models.

version 16
clear all

global OUT_ROOT "paper-workspace/04-analysis"
global PLAN "${OUT_ROOT}/reports/analysis-execution-plan.md"
global DISPATCH "${OUT_ROOT}/reports/regression-dispatch.csv"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"

capture mkdir "${OUT_ROOT}/reports"
file open fd using "${DISPATCH}", write replace
file write fd "task,run,evidence,blocker" _n
file write fd "main,blocked,Stata 模板不解析 Markdown,请根据 analysis-execution-plan 手动标记" _n
file write fd "nonlinear,blocked,Logit Probit Poisson Tobit Heckman 有序 多分类,缺少已确认角色时不得运行" _n
file write fd "panel,blocked,FE RE Hausman id time 面板,缺少 id/time 时不得猜测面板结构" _n
file write fd "causal,blocked,IV DID RDD PSM CEM IPW SCM,仅按计划触发" _n
file write fd "mechanism_heterogeneity,blocked,中介 机制 调节 异质性 门槛 交互 分组,仅按变量角色触发" _n
file write fd "robustness,blocked,稳健性 安慰剂 敏感性,只执行 dispatch 明确任务" _n
file close fd

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 03-regression/00-plan-dispatch | template | ${DISPATCH} | 不运行统计模型；请根据 analysis-execution-plan 完成派发。 |" _n
file close flog
