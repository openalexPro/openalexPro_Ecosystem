#' Check an R package source against STANDARD.md
#'
#' Checks the package rules (P1-P7) from `DESCRIPTION`, `NAMESPACE` and the
#' source, works out which kinds of package it is (writer, consumer,
#' transformer, annotator; STANDARD.md section 8), and flags code to review for
#' A1 and A3. Works for any package, in the ecosystem or not.
#'
#' @param path Package source folder.
#' @param kind Kinds to assume instead of detecting them.
#' @param manifest Optional paths to the ecosystem's `repos.tsv` and/or
#'   `compliance/external.tsv`; when given, P6 also checks that the package is
#'   listed in one of them (by package name).
#' @return A data frame of results, as [check_corpus()], with attributes
#'   `package`, `version`, `kind` and `prefix`.
#' @export
check_package <- function(path, kind = NULL, manifest = NULL) {
  path <- normalizePath(path, mustWork = TRUE)
  if (!file.exists(file.path(path, "DESCRIPTION"))) {
    stop("No DESCRIPTION in `", path, "`: not an R package source.", call. = FALSE)
  }
  d <- as.list(read.dcf(file.path(path, "DESCRIPTION"))[1, ])
  pkg <- d$Package
  exports <- namespace_exports(path)
  kind <- kind %||% detect_kind(pkg, exports)
  prefix <- package_prefix(pkg, exports)
  code <- source_lines(file.path(path, "R"))
  code <- code[!grepl("^\\s*#", code$text), , drop = FALSE]
  tests <- source_lines(file.path(path, "tests"))
  is <- function(k) k %in% kind

  deps <- paste(d$Imports %||% "", d$Depends %||% "")
  uses_pro <- grepl("\\bopenalexPro\\b", deps) || any(grepl("openalexPro::", code$text, fixed = TRUE))
  p2 <- if (!uses_pro) res("P2", "n/a", "does not use openalexPro")
  else if (!grepl("openalexPro\\s*\\(\\s*>=", deps)) res("P2", "fail", "uses openalexPro without a version floor", "declare `openalexPro (>= x.y.z)` in Imports")
  else res("P2", "pass", "openalexPro with a version floor")
  p2a <- if (is.null(d[["Config/openalexPro/standard"]])) {
    res("P2a", "fail", "no `Config/openalexPro/standard`", paste0("add `Config/openalexPro/standard: ", standard_version(), "`"))
  } else res("P2a", "pass", paste0("standard ", d[["Config/openalexPro/standard"]]))

  licence_ok <- grepl("^MIT\\b", d$License %||% "")
  listed <- if (!is.null(manifest)) pkg %in% listed_packages(manifest)
  p6 <- if (!licence_ok) res("P6", "fail", paste0("licence `", d$License, "`"), "use MIT")
  else if (isFALSE(listed)) res("P6", "fail", "not in `repos.tsv` or `compliance/external.tsv`", "add a row to one of them")
  else res("P6", "pass", if (isTRUE(listed)) "MIT; listed" else "MIT (listing not checked)")
  pkgdown <- any(file.exists(file.path(path, c("_pkgdown.yml", "_pkgdown.yaml", "pkgdown/_pkgdown.yml", "pkgdown/_pkgdown.yaml"))))
  should <- c(if (!file.exists(file.path(path, "CITATION.cff"))) "no `CITATION.cff`",
              if (!pkgdown) "no pkgdown site (`_pkgdown.yml`)")
  p6a <- if (length(should)) res("P6a", "fail", should, "add them")
  else res("P6a", "pass", "CITATION.cff; pkgdown (dev/main branches not checked)")

  ex_name <- if (!is.null(prefix)) paste0(prefix, "_example_corpus")
  has_ex <- if (!is.null(ex_name)) ex_name %in% exports else any(grepl("_example_corpus$", exports))
  writes_ids <- grep("openalex\\.org/W|\"\\^W|startsWith\\([^)]*openalex\\.org", code$text)
  writes <- grep("write_parquet|COPY \\(|file\\.copy|unlink\\(|file\\.rename", code$text)

  out <- list(
    if (grepl("^openalexImport", pkg) && !is("writer")) res("P1", "fail", "named `openalexImport*` but not a writer", "rename, or write a corpus")
    else if (grepl("^openalexExport", pkg) && !is("consumer")) res("P1", "fail", "named `openalexExport*` but not a consumer", "rename")
    else res("P1", "pass", paste0("`", pkg, "`")),
    p2, p2a,
    if (grepl("^openalexImport", pkg)) {
      fn <- grep("_as_corpus$", exports, value = TRUE)
      if (length(fn)) res("P3", "pass", paste0("`", fn[1], "()`")) else res("P3", "fail", "no `<source>_as_corpus()` exported", "export it")
    } else res("P3", "n/a", "applies to `openalexImport*` packages"),
    if (is("writer")) {
      hit <- grep("prepare_corpus\\(", tests$text)
      if (length(hit)) res("P4", "pass", paste("test:", tests$where[hit[1]]))
      else res("P4", "fail", "no test calls `openalexAPI::prepare_corpus()`", "add one on the example corpus (P7)")
    },
    p6, p6a,
    if (is("annotator")) {
      an <- if (!is.null(prefix)) paste0(prefix, "_example_annotation")
      if (!is.null(an) && an %in% exports) res("P7a", "pass", paste0("`", an, "()`"))
      else res("P7a", "fail", paste0("no `", an %||% "<prefix>_example_annotation", "()` exported"),
               "export it: annotates a given corpus offline, returns the annotation folder")
    },
    if (is("writer") || is("transformer")) {
      if (has_ex) res("P7", "pass", paste0("`", ex_name %||% grep("_example_corpus$", exports, value = TRUE)[1], "()`"))
      else res("P7", "fail", paste0("no `", ex_name %||% "<prefix>_example_corpus", "()` exported"),
               "export it: writes a small compliant corpus offline, returns the corpus folder")
    },
    if (is("writer") || is("transformer") || is("annotator")) {
      if (is.null(prefix)) res("I5", "fail", "no registered prefix for this package", "register one in STANDARD.md I5")
      else res("I5", "pass", paste0("`", prefix, "`"))
    },
    if (!is.null(prefix)) {
      if (prefix %in% standard_schemes()) res("I7", "fail", paste0("`", prefix, "` is a scheme name"), "choose another prefix")
      else res("I7", "pass")
    },
    if (is("consumer") || is("transformer") || is("annotator")) {
      if (length(writes)) res("A1", "manual", paste("review writes for targets inside the input corpus:", show(code$where[writes])))
      else res("A1", "pass", "no file writes found")
    },
    if (is("consumer") || is("transformer") || is("annotator")) {
      if (length(writes_ids)) res("A2", "manual", paste("review id handling that may assume OpenAlex ids:", show(code$where[writes_ids])))
      else res("A2", "manual", "no OpenAlex-only id patterns found; run it on a non-OpenAlex corpus")
    }
  )
  out <- bind(out)
  attr(out, "package") <- pkg
  attr(out, "version") <- d$Version
  attr(out, "kind") <- kind
  attr(out, "prefix") <- prefix
  out
}

namespace_exports <- function(path) {
  f <- file.path(path, "NAMESPACE")
  if (!file.exists(f)) return(character())
  ns <- readLines(f, warn = FALSE)
  ex <- sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", ns, value = TRUE)) |> gsub(pattern = "[\"`]", replacement = "")
  pat <- sub("^exportPattern\\((.*)\\)$", "\\1", grep("^exportPattern\\(", ns, value = TRUE)) |> gsub(pattern = "^[\"']|[\"']$", replacement = "")
  if (length(pat)) {
    defs <- source_lines(file.path(path, "R"))$text
    fns <- sub("^([.A-Za-z][.A-Za-z0-9_]*)\\s*(<-|=)\\s*function.*$", "\\1",
               grep("^[.A-Za-z][.A-Za-z0-9_]*\\s*(<-|=)\\s*function", defs, value = TRUE))
    ex <- c(ex, fns[Reduce(`|`, lapply(pat, grepl, x = fns))])
  }
  unique(ex)
}

# Package names listed in repos.tsv (by directory or repository name) and/or
# compliance/external.tsv (by repository name).
listed_packages <- function(manifest) {
  unlist(lapply(manifest[file.exists(manifest)], function(f) {
    m <- utils::read.delim(f, header = FALSE, comment.char = "#", stringsAsFactors = FALSE, colClasses = "character")
    if (!nrow(m)) return(character())
    repo <- if (ncol(m) >= 2 && any(grepl("github", m[[2]]))) m[[2]] else m[[1]]
    c(m[[1]], sub("\\.git$", "", basename(sub("^git@github.com:", "", repo))))
  }))
}

detect_kind <- function(pkg, exports) {
  reg <- standard_prefixes()
  kk <- read_ext("known_kinds.csv")
  k <- c(reg$kind[reg$package == pkg], unlist(strsplit(kk$kinds[kk$package == pkg], ";")))
  if (grepl("^openalexImport", pkg)) k <- c(k, "writer")
  if (grepl("^openalexExport", pkg)) k <- c(k, "consumer")
  if (!length(k) && any(grepl("_example_corpus$", exports))) k <- "writer"
  unique(k %||% "consumer")
}

package_prefix <- function(pkg, exports) {
  reg <- standard_prefixes()
  p <- reg$prefix[reg$package == pkg]
  if (length(p)) return(p[1])
  ex <- grep("_example_corpus$", exports, value = TRUE)
  if (length(ex)) sub("_example_corpus$", "", ex[1]) else NULL
}

# All lines of the R sources below `dir`, with "file:line" locations.
source_lines <- function(dir) {
  f <- if (dir.exists(dir)) list.files(dir, "\\.[Rr]$", recursive = TRUE, full.names = TRUE) else character()
  if (!length(f)) return(data.frame(where = character(), text = character()))
  do.call(rbind, lapply(f, function(x) {
    l <- readLines(x, warn = FALSE)
    data.frame(where = paste0(basename(dirname(x)), "/", basename(x), ":", seq_along(l)), text = l,
               stringsAsFactors = FALSE)
  }))
}
