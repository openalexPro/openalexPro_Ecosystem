# Regression tests for the bugs found in the review of 2026-11-27.

test_that("a mixed-writer corpus accepts every writer's prefix", {
  corpus <- make_corpus()
  ds <- list(standard = "0.1", type = "works", partition_keys = list("query"),
             queries = list(a = list(writer = list(package = "openalexImportZenodo", version = "1", prefix = "zenodo"),
                                     id_format = "zenodo:<id>"),
                            b = list(writer = list(package = "openalexPro", version = "1", prefix = "oapro"),
                                     id_format = "https://openalex.org/<id>")),
             content = content_fingerprint(corpus))
  jsonlite::write_json(ds, file.path(corpus, "_dataset.json"), auto_unbox = TRUE)
  expect_equal(must_fail(check_corpus(corpus, api = FALSE)), character())
})

test_that("doi:, url: and openalex: are not link-end schemes (K4)", {
  l <- data.frame(origin = "zenodo:1", target = "doi:10.1/X", link_type = NA, relation = NA)
  expect_error(write_links(l, withr::local_tempdir(), "a", corpus_ids = "zenodo:1"), "K4")
  expect_false("doi" %in% openalexStandard:::link_schemes())
})

test_that("records without id fail I2, not S6, and do not hide K4 membership", {
  root <- withr::local_tempdir()
  corpus <- make_corpus(root = root)
  con <- DBI::dbConnect(duckdb::duckdb()); on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  f <- file.path(corpus, "query=a", "data.parquet")
  DBI::dbExecute(con, sprintf("COPY (SELECT * FROM read_parquet('%s') UNION ALL
    SELECT * REPLACE (NULL::VARCHAR AS id) FROM read_parquet('%s') LIMIT 3) TO '%s.tmp' (FORMAT parquet)", f, f, f))
  file.rename(paste0(f, ".tmp"), f)
  # a link end marked in-corpus that is not a corpus id
  write_links(data.frame(origin = "zenodo:999", target = "zenodo:1", link_type = NA, relation = NA,
                         origin_in_corpus = TRUE, target_in_corpus = TRUE),
              file.path(root, "links"), "a")
  r <- check_corpus(corpus, api = FALSE)
  expect_equal(r$status[r$rule == "I2"], "fail")
  expect_match(r$evidence[r$rule == "I2"], "without `id`")
  expect_equal(r$status[r$rule == "S6"], "pass")
  expect_equal(r$status[r$rule == "K4"], "fail")
})

test_that("an example corpus that fails to build fails P7 and the verdict", {
  skip_if_not_installed("pkgload")
  p <- fake_pkg("openalexImportFoo", c("zenodo_example_corpus", "foo_as_corpus"), files = list(
    "R/ex.R" = c('zenodo_example_corpus <- function(out) stop("boom")', "foo_as_corpus <- function(out) NULL")))
  r <- compliance_report(p, api = FALSE)
  expect_equal(r$status[r$rule == "P7"], "fail")
  expect_equal(attr(r, "meta")$verdict, "not compliant")
})

test_that("use_compliance() copes with a DESCRIPTION without a final newline", {
  p <- fake_pkg("openalexImportFoo", "foo_as_corpus")
  d <- readLines(file.path(p, "DESCRIPTION"))
  cat(paste(d, collapse = "\n"), file = file.path(p, "DESCRIPTION"))  # no final newline
  suppressMessages(use_compliance(p, prefix = "foo"))
  dd <- read.dcf(file.path(p, "DESCRIPTION"))
  expect_equal(unname(dd[1, "Encoding"]), "UTF-8")
  expect_equal(unname(dd[1, "Config/openalexPro/standard"]), standard_version())
})

test_that("write_dataset_json() keeps full precision", {
  d <- withr::local_tempdir()
  write_dataset_json(d, "x", "1", "zenodo", type = "annotation", method = list(threshold = 0.123456789))
  expect_equal(jsonlite::read_json(file.path(d, "_dataset.json"))$method$threshold, 0.123456789)
})
