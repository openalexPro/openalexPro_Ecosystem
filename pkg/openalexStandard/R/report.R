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
  incomplete <- FALSE
  if (any(c("writer", "transformer") %in% kind)) {
    built <- build_example(path, prefix)
    if (is.character(built$corpus)) {
      ck <- if ("transformer" %in% kind) "transformer" else "writer"
      corpus_res <- check_corpus(built$corpus, kind = ck, prefix = prefix, api = api)
      prov <- provenance(built$corpus)
      prov$path <- c(".", rep("(input)", nrow(prov) - 1L))
      note <- paste0("built with `", built$fun, "()`")
    } else {
      note <- built$error
      # an exported example corpus that cannot be built breaks P7 (first row wins)
      if (isTRUE(built$failed)) corpus_res <- res("P7", "fail", built$error, "make it build a corpus offline")
      incomplete <- isTRUE(built$incomplete)
    }
  }
  ann_res <- NULL
  if ("annotator" %in% kind) {
    built <- build_example(path, prefix, "annotation")
    if (is.character(built$corpus)) {
      ann_res <- check_annotation(built$corpus, corpus = built$input)
      note <- paste0("annotation built with `", built$fun, "()`")
    } else {
      note <- built$error
      if (isTRUE(built$failed)) ann_res <- res("P7a", "fail", built$error, "make it annotate a corpus offline")
      incomplete <- incomplete || isTRUE(built$incomplete)
    }
  }
  out <- complete_results(bind(list(corpus_res, ann_res, pk)), kind, note)
  meta <- list(
    package = attr(pk, "package"), version = attr(pk, "version"),
    repo = repo, ref = ref, commit = commit,
    standard = standard_version(),
    checker = as.character(utils::packageVersion("openalexStandard")),
    kind = kind, prefix = prefix, corpus = note,
    must_open = sum(out$level == "MUST" & out$status == "fail"),
    should_open = sum(out$level == "SHOULD" & out$status == "fail"))
  # without the corpus checks (e.g. pkgload missing) there is no verdict
  meta$verdict <- if (meta$must_open > 0) "not compliant" else if (incomplete) "incomplete" else "compliant"
  attr(out, "meta") <- meta
  attr(out, "provenance") <- prov
  if (!is.null(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    write_report(out, file.path(out_dir, "report"), redact = FALSE)
    if (isTRUE(redact)) write_report(out, file.path(out_dir, "report_public"), redact = TRUE)
  }
  invisible(out)
}

build_example <- function(path, prefix, what = c("corpus", "annotation")) {
  what <- match.arg(what)
  if (!requireNamespace("pkgload", quietly = TRUE)) {
    return(list(error = "pkgload not installed: example corpus not built", incomplete = TRUE))
  }
  exports <- namespace_exports(path)
  suffix <- paste0("_example_", what)
  fun <- if (!is.null(prefix)) paste0(prefix, suffix) else grep(paste0(suffix, "$"), exports, value = TRUE)[1]
  if (is.na(fun) || !fun %in% exports) {
    return(list(error = if (what == "corpus") "no example corpus (P7)" else "no example annotation (P7a)"))
  }
  input <- if (what == "annotation") standard_example_corpus(tempfile("input_"))
  out <- tempfile("example_")
  tryCatch({
    env <- suppressMessages(pkgload::load_all(path, quiet = TRUE, export_all = FALSE, helpers = FALSE))$env
    f <- get(fun, envir = env)
    corpus <- suppressMessages(if (what == "corpus") f(out) else f(out, input))
    if (!is.character(corpus) || !dir.exists(corpus)) stop("`", fun, "()` did not return a folder")
    list(corpus = corpus, fun = fun, input = input)
  }, error = function(e) list(error = paste0("`", fun, "()` failed: ", conditionMessage(e)), failed = TRUE))
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
    corpus_rule <- ru$section %in% c("1", "2", "3", "4", "5", "7", "check") || ru$rule %in% c("T1", "T2", "N1", "N2", "N3")
    res(ru$rule, "not verified", if (corpus_rule) note else "not automated")
  })
  do.call(rbind, rows)
}

write_report <- function(r, file, redact = FALSE) {
  m <- attr(r, "meta")
  if (redact) {
    r$evidence <- r$fix <- ""
    m$corpus <- public_note(m$corpus)
  }
  rules <- standard_rules()
  r$summary <- rules$summary[match(r$rule, rules$rule)]
  r$section <- rules$section[match(r$rule, rules$rule)]
  esc <- function(x) gsub("|", "\\|", gsub("\n", " ", x), fixed = TRUE)

  fails <- r[r$status == "fail", , drop = FALSE]
  fails <- fails[order(match(fails$level, c("MUST", "SHOULD", "MAY"))), , drop = FALSE]
  review <- r[r$status == "manual", , drop = FALSE]
  unver <- r[r$status == "not verified", , drop = FALSE]

  head <- c(
    paste0("# Compliance report: ", m$package), "",
    paste0("- **Verdict:** ", verdict_light(m), " ", m$verdict, " (", m$must_open, " MUST, ", m$should_open, " SHOULD to fix)"),
    paste0("- **Package:** ", m$package, " ", m$version,
           if (!is.null(m$repo)) paste0(" &middot; [", m$repo, "](https://github.com/", m$repo, ")"),
           if (!is.null(m$ref)) paste0(" @ ", m$ref),
           if (!is.null(m$commit)) paste0(" ", substr(m$commit, 1, 7))),
    paste0("- **Kind:** ", paste(m$kind, collapse = ", "), if (!is.null(m$prefix)) paste0(" (prefix `", m$prefix, "`)")),
    paste0("- **Corpus:** ", m$corpus),
    paste0("- **Standard:** [STANDARD.md](", std_url(), ") ", m$standard, " (checker openalexStandard ", m$checker, ")"),
    if (redact) c("", "_Private repository: details and fixes are not published._"),
    "", legend())

  fix_part <- if (!nrow(fails)) c("", "## To fix", "", "Nothing: every checked rule passes.") else c(
    "", "## To fix", "",
    if (nrow(fails) > 1 && !is.null(m$repo)) c(button(issue_url(m, fails, redact), paste("Open one issue for all", nrow(fails), "fixes"), fails$level), ""),
    unlist(lapply(seq_len(nrow(fails)), function(i) {
      f <- fails[i, ]
      c(paste0("### ", light(f$status, f$level), " ", f$rule, " (", f$level, "): ", f$summary), "",
        paste0("**Why:** ", section_why(f$section), " ([STANDARD.md ", section_label(f$section), "](", section_url(f$section), "))"), "",
        if (nzchar(f$evidence)) c(paste0("**Found:** ", f$evidence), ""),
        if (nzchar(f$fix)) c(paste0("**Fix:** ", f$fix), ""),
        if (!is.null(m$repo)) c(button(issue_url(m, f, redact), "Open issue", f$level), ""))
    })))

  review_part <- if (nrow(review)) c(
    "## To review", "", "The code cannot check these; a person has to.", "",
    paste0("- ", light("manual"), " **", review$rule, "** (", review$level, "): ", review$summary,
           ifelse(nzchar(review$evidence) & !startsWith(review$evidence, "review:"), paste0(". ", review$evidence), ""))) 

  unver_part <- if (nrow(unver)) {
    g <- split(unver$rule, unver$evidence)
    c("", "## Not checked", "",
      paste0("- ", vapply(names(g), function(e) paste0(length(g[[e]]), " rule(s), ", if (nzchar(e)) e else "not automated"), ""),
             ": ", vapply(g, paste, "", collapse = ", ")))
  }

  table <- c("", "<details markdown=\"1\">", paste0("<summary>All ", nrow(r), " rules</summary>"), "",
    if (redact) c("| Rule | Level | Status |", "|---|---|---|") else c("| Rule | Level | Status | Details | Fix |", "|---|---|---|---|---|"),
    if (redact) sprintf("| %s | %s | %s %s |", r$rule, r$level, light(r$status, r$level), r$status)
    else sprintf("| %s | %s | %s %s | %s | %s |", r$rule, r$level, light(r$status, r$level), r$status, esc(r$evidence), esc(r$fix)),
    "", "</details>")

  prov <- attr(r, "provenance")
  tail <- c("", "## Provenance", "",
            if (redact) "Not published (private repository)." else if (is.null(prov)) "No corpus checked." else if (nrow(prov) == 1) "Not derived from another corpus." else
              paste0("- ", strrep("  ", prov$level), prov$writer %|NA|% "unknown writer", " ", prov$path,
                     ifelse(is.na(prov$checksum), "", paste0(" (checksum: ", prov$checksum, ")"))))
  lines <- c(head, fix_part, "", review_part, unver_part, table, tail)
  # `{{` / `{%` in evidence would be read as Liquid by the Pages build
  lines <- gsub("{([{%])", "&#123;\\1", lines, perl = TRUE)
  writeLines(lines, paste0(file, ".md"), useBytes = TRUE)
  r$summary <- r$section <- NULL
  js <- list(meta = m, results = r, provenance = if (!redact) prov)
  jsonlite::write_json(js, paste0(file, ".json"), auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null")
  invisible(file)
}

# Traffic lights: red = a MUST rule fails, yellow = a SHOULD/MAY rule fails or a rule
# needs review, green = passes, white = n/a or not checked.
light <- function(status, level = "MUST") {
  ifelse(status == "pass", "\U0001F7E2",
  ifelse(status == "fail" & level == "MUST", "\U0001F534",
  ifelse(status %in% c("fail", "manual"), "\U0001F7E1", "\u26AA")))
}
verdict_light <- function(m) {
  if (m$verdict %in% c("error", "incomplete")) return("\u26AA")
  if ((m$must_open %||% 0) > 0) "\U0001F534" else if ((m$should_open %||% 0) > 0) "\U0001F7E1" else "\U0001F7E2"
}
legend <- function() paste0("\U0001F534 MUST fails \u00b7 \U0001F7E1 SHOULD fails or needs review \u00b7 ",
                            "\U0001F7E2 passes \u00b7 \u26AA n/a or not checked")

std_url <- function() "https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md"
sections <- function() read_ext("sections.csv")
section_why <- function(s) { x <- sections(); x$why[match(s, x$section)] }
section_label <- function(s) if (s == "check") "" else paste0("\u00a7", s)
# GitHub heading anchor: lowercase, drop punctuation except `-`/`_`, spaces to `-`.
section_url <- function(s) {
  h <- sections()$heading[match(s, sections()$section)]
  if (is.na(h) || !nzchar(h)) return(std_url())
  paste0(std_url(), "#", gsub(" ", "-", gsub("[^a-z0-9 _-]", "", tolower(h))))
}

# Issue button, coloured by severity: red for MUST, yellow for SHOULD/MAY.
button <- function(url, label, level = "MUST") {
  col <- if (any(level == "MUST")) "#cf222e" else "#bf8700"
  sprintf('<a href="%s" style="display:inline-block;padding:4px 12px;border:1px solid %s;border-radius:6px;background:%s;color:#fff;text-decoration:none;font-weight:600">%s</a>',
          url, col, col, label)
}

# Link to GitHub's new-issue form, pre-filled. Nothing is created until the person
# clicking submits the form. Long bodies are cut to stay within URL limits.
issue_url <- function(m, f, redact) {
  one <- nrow(f) == 1
  title <- if (one) paste0("Compliance: ", f$rule, " (", f$level, ") ", f$summary)
           else paste0("Compliance with STANDARD.md ", m$standard, ": ", nrow(f), " fixes")
  item <- function(x) c(
    paste0("**", x$rule, "** (", x$level, "): ", x$summary),
    if (!redact && nzchar(x$evidence)) paste0("- Found: ", substr(x$evidence, 1, 300)),
    if (!redact && nzchar(x$fix)) paste0("- Fix: ", x$fix),
    paste0("- Rule: ", section_url(x$section)))
  items <- if (one) item(f) else unlist(lapply(seq_len(nrow(f)), function(i) c(paste0("- [ ] ", item(f[i, ])[1]), paste0("  ", item(f[i, ])[-1]))))
  page <- if (!is.null(m$repo) && !is.null(m$ref)) paste0(m$page_url %||% report_site(), "/", m$repo, "/", branch_file(m$ref), ".html")
  body <- c(items, "",
            paste0("Checked: ", m$package, " ", m$version, if (!is.null(m$ref)) paste0(" @ ", m$ref),
                   if (!is.null(m$commit)) paste0(" ", substr(m$commit, 1, 7)),
                   ", STANDARD.md ", m$standard, ", openalexStandard ", m$checker),
            if (!is.null(page)) paste0("Report: ", page))
  body <- paste(body, collapse = "\n")
  if (nchar(body) > 5000) body <- paste0(substr(body, 1, 5000), "\n\n(cut; see the report)")
  enc <- function(x) utils::URLencode(x, reserved = TRUE)
  paste0("https://github.com/", m$repo, "/issues/new?title=", enc(title), "&body=", enc(body), "&labels=compliance")
}

report_site <- function() "https://openalexpro.github.io/openalexPro_Ecosystem"

# The corpus note for a redacted report: only the fixed texts written by
# compliance_report(); anything else (an error message, which can hold paths or
# data) is replaced.
public_note <- function(note) {
  ok <- grepl("^(annotation )?built with `[a-z0-9]+_example_(corpus|annotation)\\(\\)`$", note) ||
    note %in% c("no example corpus (P7)", "no example annotation (P7a)", "not a writer or transformer: no corpus built")
  if (ok) note else "the example corpus could not be built (details not published)"
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
