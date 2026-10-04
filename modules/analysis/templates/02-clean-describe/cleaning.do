* Paper Analysis 4SS - 02 clean and describe executable Stata template.
* Equivalent CLI parameters: --data --plan --dict --out-root --run-log --slug --tasks

version 16
clear all
set more off

local project_root : env PROJECT_ROOT
if "`project_root'" != "" & fileexists("`project_root'") cd "`project_root'"
global OUT_ROOT "paper-workspace/04-analysis"
global DATA "${OUT_ROOT}/data/analysis-data.dta"
global RAW_DATA "${DATA}"
global Y "outcome"
global X "treatment"
global C "age gender education income"
global ID "pid"
global TIME "year"
global CLUSTER "region"

capture mkdir "${OUT_ROOT}"
capture mkdir "paper-workspace"
capture mkdir "${OUT_ROOT}"
capture mkdir "${OUT_ROOT}/data"
capture mkdir "${OUT_ROOT}/tables"
capture mkdir "${OUT_ROOT}/figures"
capture mkdir "${OUT_ROOT}/reports"

capture log close _all
log using "${OUT_ROOT}/reports/cleaning.log", replace text

use "${RAW_DATA}", clear

* 特殊缺失码、去重、缩尾。
ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    qui replace `v' = . if inlist(`v', -9, -8, -7, -99, -999)
}
duplicates drop

* 连续变量缩尾：仅对 $Y $X $C 角色变量、排除 0/1 虚拟变量，执行 1%/99% 双侧缩尾
foreach v in $Y $X $C {
    qui summarize `v'
    if !(r(min) == 0 & r(max) == 1) {
        winsor2 `v', cuts(1 99) replace
    }
}

gen byte analysis_sample = 1
foreach v in $Y $X $C {
    replace analysis_sample = 0 if missing(`v')
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
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") nogaps compress substitute("=" "") replace

pwcorr $Y $X $C, star(0.05)
estpost correlate $Y $X $C, matrix
esttab using "${OUT_ROOT}/tables/table1c-correlation.csv", nogaps compress substitute("=" "") replace

histogram $Y, name(hist_y, replace) normal
graph export "${OUT_ROOT}/figures/dist-${Y}.png", replace width(1600)
graph twoway (scatter $Y $X) (lfit $Y $X), name(scatter_yx, replace)
graph export "${OUT_ROOT}/figures/scatter-${Y}-${X}.png", replace width(1600)

capture log close _all
