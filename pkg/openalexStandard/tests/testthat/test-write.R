test_that("write_dataset_json() and write_links() produce a compliant corpus", {
  root <- withr::local_tempdir()
  corpus <- make_corpus(root = root)
  unlink(c(file.path(corpus, "_dataset.json"), file.path(root, "links")), recursive = TRUE)
  write_dataset_json(corpus, "openalexImportZenodo", "0.1.0", "zenodo", "zenodo:<conceptrecid>")
  write_links(data.frame(origin = c("zenodo:1", "zenodo:1"), target = c("zenodo:2", "isbn:9783947851034"),
                         link_type = "https://openalex.org/link-types/citation", relation = "Cites"),
              file.path(root, "links"), "a", corpus_ids = c("zenodo:1", "zenodo:2"))
  expect_equal(must_fail(check_corpus(corpus, api = FALSE)), character())
  # deterministic
  before <- readLines(file.path(corpus, "_dataset.json"))
  write_dataset_json(corpus, "openalexImportZenodo", "0.1.0", "zenodo", "zenodo:<conceptrecid>")
  expect_equal(readLines(file.path(corpus, "_dataset.json")), before)
})

test_that("write_links() refuses bad link ends and unprefixed columns, and writes empty tables", {
  d <- withr::local_tempdir()
  l <- data.frame(origin = "zenodo:1", target = "978-3-947851-03-4", link_type = NA, relation = NA)
  expect_error(write_links(l, d, "a", corpus_ids = "zenodo:1"), "K4")
  l$target <- "isbn:978"; l$declared <- "x"
  expect_error(write_links(l, d, "a", corpus_ids = "zenodo:1", prefix = "zenodo"), "S5")
  empty <- data.frame(origin = character(), target = character(), link_type = character(), relation = character())
  f <- write_links(empty, d, "b", corpus_ids = character())
  expect_true(file.exists(f))
})

test_that("derived_from is relative and checks out", {
  root <- withr::local_tempdir()
  input <- make_corpus(root = file.path(root, "in"))
  out <- make_corpus(root = file.path(root, "out"))
  write_dataset_json(out, "openalexSnowball", "0.1.0", "snowball", "zenodo:<id>", derived_from = input)
  ds <- jsonlite::read_json(file.path(out, "_dataset.json"))
  expect_equal(ds$derived_from[[1]]$path, "../../in/corpus")
  r <- check_corpus(out, kind = "transformer", api = FALSE)
  expect_equal(r$status[r$rule == "T2"], "pass")
})

test_that("use_compliance() scaffolds without overwriting", {
  p <- fake_pkg("openalexImportFoo", "foo_as_corpus")
  expect_error(use_compliance(p), "prefix")
  writeLines("x", file.path(p, "R", "example_corpus.R"))
  suppressMessages(done <- use_compliance(p, prefix = "foo"))
  expect_true(all(c("DESCRIPTION", "tests/testthat/test-compliance.R", ".github/workflows/compliance.yml") %in% done))
  expect_equal(readLines(file.path(p, "R", "example_corpus.R")), "x")
  expect_true(any(grepl("Config/openalexPro/standard", readLines(file.path(p, "DESCRIPTION")))))
  expect_length(suppressMessages(use_compliance(p, prefix = "foo")), 0)
})

test_that("write_links() refuses link types outside the OpenAlex list and bad names", {
  d <- withr::local_tempdir()
  l <- data.frame(origin = "zenodo:1", target = "zenodo:2", link_type = "https://openalex.org/link-types/cites",
                  relation = "Cites")
  expect_error(write_links(l, d, "a", corpus_ids = c("zenodo:1", "zenodo:2")), "K1")
  l$link_type <- NA
  expect_error(write_links(l, d, "../x", corpus_ids = c("zenodo:1", "zenodo:2")), "L3")
})

test_that("derived_from records content, and external sources", {
  root <- withr::local_tempdir()
  input <- make_corpus(root = file.path(root, "in"))
  out <- make_corpus(root = file.path(root, "out"))
  write_dataset_json(out, "x", "1", "snowball", "zenodo:<id>",
                     derived_from = list(input, list(source = "openalex-snapshot", release = "2026-10-28")))
  ds <- jsonlite::read_json(file.path(out, "_dataset.json"))
  expect_equal(ds$derived_from[[1]]$content, content_fingerprint(input))
  expect_equal(ds$derived_from[[2]]$source, "openalex-snapshot")
  expect_true(all(provenance(out)$checksum[-1] %in% c("ok", "external")))
})

test_that("standard_example_corpus() is compliant and branch file names do not collide", {
  expect_equal(must_fail(check_corpus(standard_example_corpus(withr::local_tempdir()), api = FALSE)), character())
  expect_false(openalexStandard:::branch_file("a/b") == openalexStandard:::branch_file("a-b"))
})
