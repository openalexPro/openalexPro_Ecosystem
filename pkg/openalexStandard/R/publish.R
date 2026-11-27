#' Publish compliance reports into the report site
#'
#' Used by the ecosystem's compliance workflow. Each folder in `artifacts`
#' holds the output of one [compliance_report()] run plus `target.json`
#' (`repo`, `branch`, `commit`, `private`, `standard`, `checker`, `deps`). The reports
#' are copied to `<site>/<owner>/<repo>/<branch>.md|json` (the redacted version
#' for private repositories), `state` is updated, and `<site>/index.md` is
#' rebuilt from all reports.
#'
#' @param artifacts Folder with one sub-folder per checked repository and branch.
#' @param site The report site folder (`compliance/` in the ecosystem repo).
#' @param state The state file recording what was checked.
#' @return The paths written, invisibly.
#' @export
compliance_publish <- function(artifacts, site = "compliance", state = file.path(site, "state.json")) {
  st <- if (file.exists(state)) jsonlite::read_json(state) else list()
  written <- character()
  for (a in list.dirs(artifacts, recursive = FALSE)) {
    t <- jsonlite::read_json(file.path(a, "target.json"))
    adhoc <- isTRUE(t$adhoc)
    dest <- do.call(file.path, as.list(c(site, if (adhoc) "adhoc", t$repo, branch_file(t$branch))))
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    stem <- if (isTRUE(t$private)) "report_public" else "report"
    if (isTRUE(t$private) && !file.exists(file.path(a, "report_public.md"))) {
      # fail closed: never publish a private repository's full report
      writeLines(c(paste0("# Compliance report: ", t$repo), "", "Not available (private repository)."),
                 paste0(dest, ".md"))
      jsonlite::write_json(list(meta = list(verdict = "error", note = "not available (private repository)")),
                           paste0(dest, ".json"), auto_unbox = TRUE, pretty = TRUE)
      stem <- NULL
    }
    for (e in if (!is.null(stem)) c("md", "json")) {
      f <- file.path(a, paste0(stem, ".", e))
      if (file.exists(f)) {
        file.copy(f, paste0(dest, ".", e), overwrite = TRUE)
        written <- c(written, paste0(dest, ".", e))
      }
    }
    verdict <- if (file.exists(paste0(dest, ".json"))) jsonlite::read_json(paste0(dest, ".json"))$meta$verdict else "error"
    if (!adhoc) st[[paste0(t$repo, "@", t$branch)]] <- list(commit = t$commit, standard = t$standard,
                                               checker = t$checker, deps = t$deps %||% "", verdict = verdict)
  }
  st <- st[order(names(st))]
  jsonlite::write_json(st, state, auto_unbox = TRUE, pretty = TRUE)
  idx <- compliance_index(site, st)
  invisible(c(written, state, idx))
}

# File name for a branch: every character outside [A-Za-z0-9.-] as `_<hex>`, so
# different branches never share a file (`a/b` -> `a_2fb`, `a-b` stays).
branch_file <- function(b) {
  vapply(b, function(x) {
    ch <- strsplit(x, "")[[1]]
    bad <- !grepl("[A-Za-z0-9.-]", ch)
    ch[bad] <- vapply(ch[bad], function(c) paste0("_", paste(sprintf("%02x", as.integer(charToRaw(c))), collapse = "_")), "")
    paste(ch, collapse = "")
  }, "", USE.NAMES = FALSE)
}

#' Write the index page of the report site
#' @param site The report site folder.
#' @param state The parsed state file (a named list, `<owner>/<repo>@<branch>`).
#' @return The path of `index.md`, invisibly.
#' @export
compliance_index <- function(site = "compliance", state = jsonlite::read_json(file.path(site, "state.json"))) {
  rows <- vapply(names(state), function(k) {
    repo <- sub("@.*$", "", k)
    br <- sub("^[^@]*@", "", k)
    j <- file.path(site, repo, paste0(branch_file(br), ".json"))
    m <- if (file.exists(j)) jsonlite::read_json(j)$meta else list()
    v <- m$verdict %||% state[[k]]$verdict %||% "error"
    mark <- paste(verdict_light(list(verdict = v, must_open = m$must_open, should_open = m$should_open)), v)
    where <- if (startsWith(repo, "openalexPro/")) "ecosystem" else "external"
    sprintf("| [%s](https://github.com/%s) | %s | [%s](%s/%s.md) | %s | %s | `%s` | %s |",
            sub("^.*/", "", repo), repo, br, mark, repo, branch_file(br),
            m$must_open %||% "", m$should_open %||% "", substr(state[[k]]$commit %||% "", 1, 7), where)
  }, "")
  txt <- c(
    "---", "title: openalexPro ecosystem compliance", "---", "",
    "# openalexPro ecosystem compliance", "",
    paste0("Packages checked against [STANDARD.md](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md) ",
           "by [openalexStandard](https://github.com/openalexPro/openalexPro_Ecosystem/tree/main/pkg/openalexStandard). ",
           "Re-checked daily at 00:00 UTC when a branch, the standard or the checker changed."), "",
    legend(), "",
    "| Package | Branch | Verdict | MUST open | SHOULD open | Commit | |",
    "|---|---|---|---|---|---|---|",
    rows)
  f <- file.path(site, "index.md")
  writeLines(txt, f, useBytes = TRUE)
  invisible(f)
}
