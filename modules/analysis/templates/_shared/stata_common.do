* Shared helpers for Paper Analysis 4SS Stata templates.
* Copy or include this file before project-specific scripts.

capture mkdir "paper-workspace"
capture mkdir "paper-workspace/04-analysis"
capture mkdir "paper-workspace/04-analysis/data"
capture mkdir "paper-workspace/04-analysis/scripts"
capture mkdir "paper-workspace/04-analysis/tables"
capture mkdir "paper-workspace/04-analysis/figures"
capture mkdir "paper-workspace/04-analysis/reports"
capture mkdir "paper-workspace/04-analysis/qual"
capture mkdir "paper-workspace/04-analysis/qual/codebooks"
capture mkdir "paper-workspace/04-analysis/qual/coded-data"
capture mkdir "paper-workspace/04-analysis/qual/memos"
capture mkdir "paper-workspace/04-analysis/qual/anonymized"
capture mkdir "paper-workspace/04-analysis/qual/reliability"

capture program drop pa_log
program define pa_log
    syntax, Step(string) Status(string) [Outputs(string) Note(string)]
    local log "paper-workspace/04-analysis/reports/run-log-`c(current_date)'.md"
    capture confirm file "`log'"
    if _rc {
        file open fh using "`log'", write replace
        file write fh "# Analysis Run Log" _n _n
        file write fh "| Date | Step | Status | Outputs | Note |" _n
        file write fh "|---|---|---|---|---|" _n
        file close fh
    }
    file open fh using "`log'", write append
    file write fh "| `c(current_date)' | `step' | `status' | `outputs' | `note' |" _n
    file close fh
end

* ---- 顶刊 CSV 宽表导出统一规范 ----
* 所有 esttab 导出语句必须包含：substitute("=" "") nogaps compress replace
* 目的：杜绝 CSV 单元格出现 ="公式" 文本；变量名纯英文，标量行/固定效应行/表注用规范中文。
* 示例：esttab m1 m2 using "table.csv", b(3) t(3) star(* 0.05 ** 0.01 *** 0.001) label ///
*     nogaps compress substitute("=" "") stats(N r2 r2_within, fmt(0 3 3) ///
*     labels("观测值" "R²" "Within R²")) replace

* ---- 依赖守卫：高维固定效应与工具变量命令 ----
capture program drop pa_require
program define pa_require
    syntax, cmd(string)
    capture which `cmd'
    if _rc {
        capture ssc install `cmd'
        capture which `cmd'
        if _rc {
            display as error "pa_require: 缺少依赖命令 `cmd'，请安装后重试。"
            exit 199
        }
    }
end
