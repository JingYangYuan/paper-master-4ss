* Paper Analysis 4SS - 02 clean and describe executable Stata template.
* Equivalent CLI parameters: --data --plan --dict --out-root --run-log --slug --tasks

version 16
clear all
set more off

local project_root : env PROJECT_ROOT
if "`project_root'" != "" cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global DATA "${OUT_ROOT}/data/analysis-data.dta"
global RAW_DATA "${DATA}"
global Y "outcome"
global X "treatment"
global C "age gender education income"
global ID "pid"
global TIME "year"
global CLUSTER "region"
global RUN_LOG "${OUT_ROOT}/reports/run-log-`c(current_date)'.md"

capture mkdir "${OUT_ROOT}"
capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/data"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"
capture confirm file "${RUN_LOG}"
if _rc {
    file open flog using "${RUN_LOG}", write replace
    file write flog "# Analysis Run Log" _n _n
    file write flog "| Date | Step | Status | Outputs | Note |" _n
    file write flog "|---|---|---|---|---|" _n
    file close flog
}

capture confirm file "${RAW_DATA}"
if _rc {
    file open flog using "${RUN_LOG}", write append
    file write flog "| `c(current_date)' | 02-clean-describe | blocked | - | 缺少 ${RAW_DATA}。 |" _n
    file close flog
    exit 2
}

use "${RAW_DATA}", clear

* 特殊缺失码、去重、缩尾。
foreach v of varlist _all {
    capture confirm numeric variable `v'
    if !_rc {
        quietly replace `v' = . if inlist(`v', -9, -8, -7, -99, -999)
    }
}
duplicates drop
capture which winsor2
if !_rc {
    foreach v of varlist _all {
        capture confirm numeric variable `v'
        if !_rc capture winsor2 `v', cuts(1 99) replace
    }
}

gen byte analysis_sample = 1
foreach v in $Y $X $C {
    capture confirm variable `v'
    if !_rc replace analysis_sample = 0 if missing(`v')
}

preserve
clear
input str30 step str80 rule n_before n_after dropped str120 reason
"raw" "原始数据" . . . "载入原始数据"
"analysis_sample" "删除Y/X/control缺失" . . . "按宏变量生成分析样本"
end
export delimited using "${OUT_ROOT}/tables/sample-flow.csv", replace
restore

keep if analysis_sample == 1
save "${OUT_ROOT}/data/analysis-data.dta", replace
export delimited using "${OUT_ROOT}/data/analysis-data.csv", replace

file open fd using "${OUT_ROOT}/data/variable-dictionary.csv", write replace
file write fd "raw_name,clean_name,display_name,role,dtype,missing,source_file" _n
foreach v of varlist _all {
    quietly count if missing(`v')
    local miss = r(N)
    local role ""
    if "`v'" == "$Y" local role "Y"
    if "`v'" == "$X" local role "X"
    if strpos(" $C ", " `v' ") local role "control"
    if "`v'" == "$ID" local role "id"
    if "`v'" == "$TIME" local role "time"
    if "`v'" == "$CLUSTER" local role "cluster"
    file write fd "`v',`v',`v',`role',`: type `v'',`miss',${RAW_DATA}" _n
}
file close fd

estpost summarize $Y $X $C, detail
esttab using "${OUT_ROOT}/tables/table1-descriptives.csv", ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") replace

capture pwcorr $Y $X $C, star(0.05)
capture estpost correlate $Y $X $C, matrix
capture esttab using "${OUT_ROOT}/tables/table1c-correlation.csv", replace

capture histogram $Y, name(hist_y, replace) normal
capture graph export "${OUT_ROOT}/figures/dist-${Y}.png", replace width(1600)
capture graph twoway (scatter $Y $X) (lfit $Y $X), name(scatter_yx, replace)
capture graph export "${OUT_ROOT}/figures/scatter-${Y}-${X}.png", replace width(1600)

file open flog using "${RUN_LOG}", write append
file write flog "| `c(current_date)' | 02-clean-describe | ok | analysis-data.csv<br>variable-dictionary.csv<br>table1-descriptives.csv | 已真实清洗并描述数据。 |" _n
file close flog
