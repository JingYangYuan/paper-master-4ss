# Anonymize, segment, and scaffold qualitative coding from real text files.

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
find_shared <- function() {
  cmd <- commandArgs(FALSE); file_arg <- sub("^--file=", "", cmd[grep("^--file=", cmd)][1] %||% "")
  p <- if (nzchar(file_arg)) dirname(normalizePath(file_arg, mustWork = FALSE)) else getwd()
  repeat { candidate <- file.path(p, "_shared", "r_common.R"); if (file.exists(candidate)) return(candidate); np <- dirname(p); if (identical(np, p)) stop("Cannot locate templates/_shared/r_common.R"); p <- np }
}
source(find_shared())
args <- parse_common_args(); ensure_dirs(args$out_root)
text_dir <- if (!is.na(args$data)) args$data else "."
files <- if (dir.exists(text_dir)) list.files(text_dir, pattern = "\\.(txt|md)$", full.names = TRUE) else if (file.exists(text_dir)) text_dir else character()
if (!length(files)) {
  report <- write_md(file.path(args$out_root, "qual/memos", paste0("qual-blockers-", Sys.Date(), ".md")), "Qual Blockers", c("阻断" = "缺少可读取的 .txt/.md 文本材料。"))
  log_run(args, "04-qual", "blocked", report, "未发现文本材料。")
  quit(status = 2)
}
rows <- list()
for (f in files) {
  txt <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  txt <- gsub("[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[A-Za-z]{2,}", "[EMAIL]", txt)
  txt <- gsub("\\b1[3-9][0-9]{9}\\b", "[PHONE]", txt)
  anon <- file.path(args$out_root, "qual/anonymized", paste0(tools::file_path_sans_ext(basename(f)), "-anonymized.txt"))
  writeLines(txt, anon, useBytes = TRUE)
  parts <- unlist(strsplit(txt, "\\n\\s*\\n"))
  parts <- parts[nzchar(trimws(parts))]
  for (i in seq_along(parts)) rows[[length(rows) + 1]] <- data.frame(source_id = basename(f), excerpt_id = i, anonymized_excerpt = substr(parts[[i]], 1, 1000), code = "", memo = "")
}
coded <- write_csv_safe(do.call(rbind, rows), file.path(args$out_root, "qual/coded-data", paste0("coded-excerpts-", Sys.Date(), ".csv")))
codebook <- write_csv_safe(data.frame(code = "", definition = "", inclusion = "", exclusion = "", example = ""), file.path(args$out_root, "qual/codebooks", paste0("codebook-", Sys.Date(), ".csv")))
log_run(args, "04-qual", "ok", c(coded, codebook), "已真实去标识化和分段，不伪造主题结论。")
