* Paper Analysis 4SS - 04 qualitative analysis Stata index.
* Stata records coding artifacts; text anonymization is better handled by Python/R.

version 16
clear all

local project_root : env PROJECT_ROOT
if "`project_root'" != "" cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"

capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/qual"
capture mkdir "${OUT_ROOT}/qual/codebooks"
capture mkdir "${OUT_ROOT}/qual/coded-data"
capture mkdir "${OUT_ROOT}/qual/memos"
capture mkdir "${OUT_ROOT}/qual/reliability"
capture mkdir "${OUT_ROOT}/reports"
capture confirm file "${RUN_LOG}"
if _rc {
    file open flog using "${RUN_LOG}", write replace
    file write flog "# Analysis Run Log" _n _n
    file write flog "| Date | Step | Status | Outputs | Note |" _n
    file write flog "|---|---|---|---|---|" _n
    file close flog
}

file open fc using "${OUT_ROOT}/qual/codebooks/codebook-`c(current_date)'.csv", write replace
file write fc "code,definition,inclusion,exclusion,example" _n
file close fc

file open fd using "${OUT_ROOT}/qual/coded-data/coded-excerpts-`c(current_date)'.csv", write replace
file write fd "source_id,excerpt_id,anonymized_excerpt,code,memo" _n
file close fd

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 04-qual | ok | qual/codebooks<br>qual/coded-data | Stata 生成编码结构；文本去标识化请优先运行 Python/R 版本。 |" _n
file close flog
