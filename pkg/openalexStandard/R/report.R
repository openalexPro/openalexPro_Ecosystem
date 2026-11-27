#' Compliance report for a package
#'
#' Checks a package source with [check_package()]. For writers and
#' transformers it then builds the package's example corpus
#' (`<prefix>_example_corpus()`, STANDARD.md P7) in a temporary folder and
#' checks it with [check_corpus()]. Every rule of STANDARD.md gets one row:
#' rules for other kinds of package are `n/a`, rules that need a review are
#' `manual`, rules that could not be checked are `not verified`.
#'
#' The report is deterministic: it names the package commit, the standard
#' version and the checker version, but no date, so re-checking an unchanged
#' package gives an identical file.
#'
#' @param path Package source folder.
#' @param out_dir Folder to write `report.md` and `report.json` to; `NULL`
#'   writes nothing.
#' @param redact Also write `report_public.md` / `report_public.json` without
#'   evidence and fixes (for private repositories).
#' @param repo,ref,commit Shown in the report header (e.g. `owner/name`,
#'   branch, commit SHA).
#' @param kind,manifest Passed to [check_package()].
#' @param api Run `openalexAPI::prepare_corpus()` on the example corpus.
#' @return The results (a data frame) with attribute `meta`, invisibly.
#' @export
compliance_report <- function(path, out_dir = NULL, redact = FALSE, repo = NULL, ref = NULL,
                              commit = NULL, kind = NULL, manifest = NULL, api = TRUE) {
  pk <- check_package(path, kind = kind, manifest = manifest)
  kind <- attr(pk, "kind")
  prefix <- attr(pk, "prefix")
  corpus_res <- NULL
  prov <- NULL
  note <- "not a writer or transformer: no corpus built"
  if (any(c("writer", "transformer") %in% kind)) {
    built <- build_example(path, prefix)
    if (is.character(built$corpus)) {
      ck <- if ("transformer" %in% kind) "transformer" else "writer"
      corpus_res <- check_corpus(built$corpus, kind = ck, prefix = prefix, api = api)
      prov <- provenance(built$corpus)
      prov$path <- c(".", rep("(input)", nrow(prov) - 1L))
      note <- paste0("built with `", built$fun, "()`")
    } else note <- built$error
  }
  out <- complete_results(bind(list(pk, corpus_res)), kind, note)
  meta <- list(
    package = attr(pk, "package"), version = attr(pk, "version"),
    repo = repo, ref = ref, commit = commit,
    standard = standard_version(),
    checker = as.character(utils::packageVersion("openalexStandard")),
    kind = kind, prefix = prefix, corpus = note,
    must_open = sum(out$level == "MUST" & out$status == "fail"),
    should_open = sum(out$level == "SHOULD" & out$status == "fail"))
  meta$verdict <- if (meta$must_open == 0) "compliant" else "not compliant"
  attr(out, "meta") <- meta
  attr(out, "provenance") <- prov
  if (!is.null(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    write_report(out, file.path(out_dir, "report"), redact = FALSE)
    if (isTRUE(redact)) write_report(out, file.path(out_dir, "report_public"), redact = TRUE)
  }
  invisible(out)
}

build_example <- function(path, prefix) {
  if (!requireNamespace("pkgload", quietly = TRUE)) return(list(error = "pkgload not installed: example corpus not built"))
  exports <- namespace_exports(path)
  fun <- if (!is.null(prefix)) paste0(prefix, "_example_corpus") else grep("_example_corpus$", exports, value = TRUE)[1]
  if (is.na(fun) || !fun %in% exports) {
    return(list(error = "no example corpus (P7)"))
  }
  out <- tempfile("example_")
  tryCatch({
    env <- suppressMessages(pkgload::load_all(path, quiet = TRUE, export_all = FALSE, helpers = FALSE))$env
    corpus <- suppressMessages(get(fun, envir = env)(out))
    if (!is.character(corpus) || !dir.exists(corpus)) stop("`", fun, "()` did not return a corpus folder")
    list(corpus = corpus, fun = fun)
  }, error = function(e) list(error = paste0("`", fun, "()` failed: ", conditionMessage(e))))
}

# One row per rule of the standard, in its order.
complete_results <- function(r, kind, note) {
  rules <- standard_rules()
  r <- r[!duplicated(r$rule), , drop = FALSE]
  rows <- lapply(seq_len(nrow(rules)), function(i) {
    ru <- rules[i, ]
    got <- r[r$rule == ru$rule, , drop = FALSE]
    if (nrow(got)) return(got)
    kinds <- strsplit(ru$kinds, ";")[[1]]
    if (!any(kinds %in% kind)) return(res(ru$rule, "n/a", paste("applies to", paste(kinds, collapse = ", "))))
    if (ru$automated == "manual") return(res(ru$rule, "manual", paste("review:", ru$summary)))
    corpus_rule <- ru$section %in% c("1", "2", "3", "4", "5", "7", "check") || ru$rule %in% c("T1", "T2")
    res(ru$rule, "not verified", if (corpus_rule) note else "not automated")
  })
  do.call(rbind, rows)
}

write_report <- function(r, file, redact = FALSE) {
  m <- attr(r, "meta")
  if (redact) r$evidence <- r$fix <- ""
  icon <- c(pass = "&#x2713;", fail = "&#x2717;", `n/a` = "n/a", `not verified` = "not verified", manual = "manual")
  esc <- function(x) gsub("|", "\\|", gsub("\n", " ", x), fixed = TRUE)
  head <- c(
    paste0("# Compliance report: ", m$package), "",
    paste0("- **Standard:** STANDARD.md ", m$standard, " (checker openalexStandard ", m$checker, ")"),
    paste0("- **Package:** ", m$package, " ", m$version,
           if (!is.null(m$repo)) paste0(" &middot; ", m$repo), if (!is.null(m$ref)) paste0(" @ ", m$ref),
           if (!is.null(m$commit)) paste0(" ", substr(m$commit, 1, 7))),
    paste0("- **Kind:** ", paste(m$kind, collapse = ", "), if (!is.null(m$prefix)) paste0(" (prefix `", m$prefix, "`)")),
    paste0("- **Corpus:** ", m$corpus),
    paste0("- **Verdict:** ", m$verdict, " (", m$must_open, " MUST, ", m$should_open, " SHOULD open)"),
    if (redact) c("", "_Private repository: evidence and fixes are not published._"),
    "", "## Results", "",
    if (redact) c("| Rule | Level | Status |", "|---|---|---|") else c("| Rule | Level | Status | Evidence | Fix |", "|---|---|---|---|---|"))
  rows <- if (redact) sprintf("| %s | %s | %s |", r$rule, r$level, icon[r$status])
          else sprintf("| %s | %s | %s | %s | %s |", r$rule, r$level, icon[r$status], esc(r$evidence), esc(r$fix))
  prov <- attr(r, "provenance")
  tail <- c("", "## Provenance", "",
            if (is.null(prov)) "No corpus checked." else if (nrow(prov) == 1) "Not derived from another corpus." else
              paste0("- ", strrep("  ", prov$level), prov$writer %|NA|% "unknown writer", " ", prov$path,
                     ifelse(is.na(prov$checksum), "", paste0(" (checksum: ", prov$checksum, ")"))))
  writeLines(c(head, rows, tail), paste0(file, ".md"), useBytes = TRUE)
  js <- list(meta = m, results = r, provenance = if (!redact) prov)
  jsonlite::write_json(js, paste0(file, ".json"), auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null")
  invisible(file)
}

`%|NA|%` <- function(a, b) ifelse(is.na(a), b, a)

#' Expect a corpus to comply with STANDARD.md
#'
#' A testthat expectation for package tests: fails when any MUST rule of
#' [check_corpus()] fails, and lists them.
#' @param dir Corpus folder.
#' @param ... Passed to [check_corpus()].
#' @return `dir`, invisibly.
#' @export
expect_compliant_corpus <- function(dir, ...) {
  r <- check_corpus(dir, ...)
  bad <- r[r$level == "MUST" & r$status == "fail", , drop = FALSE]
  msg <- paste0("Corpus does not comply with STANDARD.md ", standard_version(), ":\n",
                paste0("  ", bad$rule, ": ", bad$evidence, collapse = "\n"))
  if (requireNamespace("testthat", quietly = TRUE)) {
    testthat::expect(nrow(bad) == 0, msg)
  } else if (nrow(bad)) stop(msg, call. = FALSE)
  invisible(dir)
}
