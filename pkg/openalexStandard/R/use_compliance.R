#' Add compliance scaffolding to a package
#'
#' Like the usethis functions: adds what a package needs to be checked against
#' STANDARD.md, and never overwrites an existing file.
#'
#' - `Config/openalexPro/standard` in `DESCRIPTION` (P2a), and openalexStandard
#'   and openalexAPI in Suggests and Remotes (with usethis, if installed; else a
#'   message);
#' - writers and transformers: `R/example_corpus.R` with a stub of
#'   `<prefix>_example_corpus(out)` to fill in (P7), and
#'   `tests/testthat/test-compliance.R` running `expect_compliant_corpus()` and
#'   `openalexAPI::prepare_corpus()` on it (P4);
#' - `.github/workflows/compliance.yml` calling the ecosystem's reusable
#'   `compliance-check` workflow with `fail-on: none`.
#'
#' Run `devtools::document()` afterwards, so the stub is exported.
#'
#' @param path Package source folder.
#' @param prefix The package's registered prefix (I5). Defaults to the one
#'   registered for the package, if any.
#' @param kind Kinds of package, as in [check_package()]; detected by default.
#' @return The paths created or changed, invisibly.
#' @export
use_compliance <- function(path = ".", prefix = NULL, kind = NULL) {
  path <- normalizePath(path, mustWork = TRUE)
  d <- as.list(read.dcf(file.path(path, "DESCRIPTION"))[1, ])
  pkg <- d$Package
  kind <- kind %||% detect_kind(pkg, namespace_exports(path))
  prefix <- prefix %||% package_prefix(pkg, namespace_exports(path))
  writes <- any(c("writer", "transformer") %in% kind)
  if (writes && is.null(prefix)) stop("No registered prefix for ", pkg, "; give `prefix` (register it in STANDARD.md I5).", call. = FALSE)
  done <- character()
  add_file <- function(rel, lines) {
    f <- file.path(path, rel)
    if (file.exists(f)) { message("Exists, left as is: ", rel); return(invisible()) }
    dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
    writeLines(lines, f)
    done <<- c(done, rel)
  }

  if (is.null(d[["Config/openalexPro/standard"]])) {
    append_line(file.path(path, "DESCRIPTION"), paste0("Config/openalexPro/standard: ", standard_version()))
    done <- c(done, "DESCRIPTION")
  }
  sugg <- c("openalexStandard", "openalexAPI", if (writes) "withr")
  have <- trimws(sub("\\(.*$", "", unlist(strsplit(c(d$Suggests, d$Imports, d$Depends, ""), ","))))
  need <- setdiff(sugg, have)
  if (length(need)) {
    if (requireNamespace("usethis", quietly = TRUE)) {
      # openalexStandard and openalexAPI are on GitHub only: also add them to Remotes
      remotes <- c(openalexStandard = "openalexPro/openalexPro_Ecosystem/pkg/openalexStandard",
                   openalexAPI = "openalexPro/openalexAPI")
      usethis::with_project(path, for (s in need) {
        if (s %in% names(remotes)) usethis::use_dev_package(s, "Suggests", remote = remotes[[s]])
        else usethis::use_package(s, "Suggests")
      }, quiet = TRUE)
      done <- unique(c(done, "DESCRIPTION"))
    } else message("Add to Suggests in DESCRIPTION: ", paste(need, collapse = ", "))
  }

  if (writes) {
    fn <- paste0(prefix, "_example_corpus")
    add_file("R/example_corpus.R", c(
      paste0("#' Write a small example corpus (openalexPro ecosystem standard, P7)"),
      "#'",
      "#' Writes a corpus that follows STANDARD.md below the project folder `out`",
      "#' (the corpus folder and its sibling `links/`), offline from data shipped",
      "#' with the package, and returns the path of the corpus folder.",
      "#' @param out Project folder to write into.",
      "#' @return The path of the corpus folder.",
      "#' @export",
      paste0(fn, " <- function(out = tempfile()) {"),
      "  corpus <- file.path(out, \"corpus\")",
      "  # TODO: write a few works from data in inst/extdata to",
      "  #   file.path(corpus, \"query=example\", \"data.parquet\"),",
      "  # with _query.json / _query.html in that folder, then:",
      paste0("  # openalexStandard::write_dataset_json(corpus, \"", pkg, "\", utils::packageVersion(\"", pkg, "\"),"),
      paste0("  #   prefix = \"", prefix, "\", id_format = \"", prefix, ":<id>\")"),
      "  # openalexStandard::write_links(links, file.path(out, \"links\"), \"example\", corpus_ids = ids)",
      paste0("  stop(\"", fn, "() is not implemented yet\")"),
      "}"))
    add_file("tests/testthat/test-compliance.R", c(
      "test_that(\"the example corpus follows the ecosystem standard\", {",
      "  skip_if_not_installed(\"openalexStandard\")",
      paste0("  corpus <- ", fn, "(withr::local_tempdir())"),
      "  openalexStandard::expect_compliant_corpus(corpus, api = FALSE)",
      "})",
      "",
      "test_that(\"openalexAPI can serve the example corpus\", {",
      "  skip_if_not_installed(\"openalexAPI\")",
      paste0("  corpus <- ", fn, "(withr::local_tempdir())"),
      "  expect_no_error(openalexAPI::prepare_corpus(corpus, cache_dir = withr::local_tempdir()))",
      "})"))
  }
  add_file(".github/workflows/compliance.yml", c(
    "# Compliance with the openalexPro ecosystem standard (STANDARD.md).",
    "# Switch fail-on to \"must\" once the package complies.",
    "on:",
    "  pull_request:",
    "    branches: [main, dev]",
    "jobs:",
    "  compliance:",
    "    uses: openalexPro/openalexPro_Ecosystem/.github/workflows/compliance-check.yml@main",
    "    with:",
    "      fail-on: none"))
  rbi <- file.path(path, ".Rbuildignore")
  if (!file.exists(rbi) || !any(readLines(rbi, warn = FALSE) == "^\\.github$")) {
    append_line(rbi, "^\\.github$")
    done <- c(done, ".Rbuildignore")
  }
  if (length(done)) message("Changed: ", paste(unique(done), collapse = ", "))
  if (writes) message("Next: implement ", prefix, "_example_corpus() in R/example_corpus.R, then devtools::document().")
  invisible(unique(done))
}

# Appends a line, adding the missing newline at the end of the file first.
append_line <- function(f, line) {
  old <- if (file.exists(f)) readLines(f, warn = FALSE) else character()
  writeLines(c(old, line), f)
}
