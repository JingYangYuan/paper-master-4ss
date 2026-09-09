* Paper Analysis 4SS - 01 init template.
* Equivalent CLI parameters: --data --plan --dict --out-root --run-log --slug --tasks

version 16
clear all

global OUT_ROOT "paper-workspace/04-analysis"
global DATA "${OUT_ROOT}/data/analysis-data.dta"
global PLAN "${OUT_ROOT}/reports/analysis-execution-plan.md"
global DICT "${OUT_ROOT}/data/variable-dictionary.csv"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/data"
capture mkdir "${OUT_ROOT}/scripts"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"
capture mkdir "${OUT_ROOT}/qual"
capture mkdir "${OUT_ROOT}/qual/codebooks"
capture mkdir "${OUT_ROOT}/qual/coded-data"
capture mkdir "${OUT_ROOT}/qual/memos"
capture mkdir "${OUT_ROOT}/qual/anonymized"
capture mkdir "${OUT_ROOT}/qual/reliability"

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 01-init | ok | ${OUT_ROOT}/reports | 初始化 paper-workspace/04-analysis。 |" _n
file close flog
