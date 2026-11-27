test_that("kinds and prefixes are detected", {
  r <- check_package(fake_pkg("openalexImportFoo", "foo_as_corpus"))
  expect_equal(attr(r, "kind"), "writer")
  expect_null(attr(r, "prefix"))
  expect_equal(r$status[r$rule == "I5"], "fail")
  expect_equal(r$status[r$rule == "P7"], "fail")
  r <- check_package(fake_pkg("openalexSnowball"))
  expect_equal(attr(r, "kind"), "transformer")
  expect_equal(attr(r, "prefix"), "snowball")
  r <- check_package(fake_pkg("someReader"))
  expect_equal(attr(r, "kind"), "consumer")
})

test_that("P2 floor, P6 manifest and SHOULD levels", {
  p <- fake_pkg("someReader", files = list("R/a.R" = "f <- function() openalexPro::pro_query()"))
  r <- check_package(p)
  expect_equal(r$status[r$rule == "P2"], "fail")
  expect_equal(r$level[r$rule == "P2"], "MUST")
  m <- withr::local_tempfile(lines = "otherPkg\turl\tdev\tr-package")
  expect_equal(check_package(p, manifest = m)$status[check_package(p, manifest = m)$rule == "P6"], "fail")
})

test_that("A3 flags OpenAlex-only id handling for review", {
  p <- fake_pkg("someReader", files = list("R/a.R" = 'x <- grepl("^W", id)'))
  expect_equal(check_package(p)$status[check_package(p)$rule == "A2"], "manual")
})

test_that("compliance_report() builds the example corpus and writes the report", {
  skip_if_not_installed("pkgload")
  helper <- readLines(test_path("helper-corpus.R"))
  p <- fake_pkg("openalexImportFoo", c("zenodo_example_corpus", "foo_as_corpus"), files = list(
    "R/ex.R" = c(helper, "zenodo_example_corpus <- function(out) make_corpus(root = out)",
                 "foo_as_corpus <- function(out) NULL")))
  out <- withr::local_tempdir()
  r <- compliance_report(p, out, redact = TRUE, api = FALSE)
  m <- attr(r, "meta")
  expect_equal(nrow(r), nrow(standard_rules()))
  expect_equal(r$status[r$rule == "K4"], "pass")
  expect_true(all(file.exists(file.path(out, c("report.md", "report.json", "report_public.md", "report_public.json")))))
  expect_false(any(grepl("isbn", readLines(file.path(out, "report_public.md")))))
  # deterministic
  before <- readLines(file.path(out, "report.md"))
  compliance_report(p, out, api = FALSE)
  expect_equal(readLines(file.path(out, "report.md")), before)
})

test_that("P3 is n/a outside openalexImport* packages", {
  expect_equal(check_package(fake_pkg("openalexPro"))$status[check_package(fake_pkg("openalexPro"))$rule == "P3"], "n/a")
  expect_equal(check_package(fake_pkg("openalexImportFoo"))$status[check_package(fake_pkg("openalexImportFoo"))$rule == "P3"], "fail")
})

test_that("redacted reports leak no error text, paths or provenance; publish fails closed", {
  skip_if_not_installed("pkgload")
  p <- fake_pkg("openalexImportFoo", c("zenodo_example_corpus", "foo_as_corpus"), files = list(
    "R/ex.R" = c('zenodo_example_corpus <- function(out) stop("boom at /secret/path")',
                 "foo_as_corpus <- function(out) NULL")))
  out <- withr::local_tempdir()
  compliance_report(p, out, redact = TRUE, api = FALSE, repo = "o/r", ref = "dev")
  pub <- c(readLines(file.path(out, "report_public.md")), readLines(file.path(out, "report_public.json")))
  expect_false(any(grepl("secret|boom", pub)))
  expect_true(any(grepl("secret", readLines(file.path(out, "report.md")))))
  # publish: private target without a public report gets a stub, never the full report
  art <- withr::local_tempdir(); site <- withr::local_tempdir()
  dir.create(file.path(art, "x"))
  file.copy(file.path(out, c("report.md", "report.json")), file.path(art, "x"))
  jsonlite::write_json(list(repo = "o/r", branch = "dev", commit = "abc", private = TRUE, standard = "s", checker = "c"),
                       file.path(art, "x", "target.json"), auto_unbox = TRUE)
  compliance_publish(art, site)
  expect_false(any(grepl("secret", readLines(file.path(site, "o", "r", "dev.md")))))
})
