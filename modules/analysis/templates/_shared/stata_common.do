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
