test_that("a compliant corpus passes every MUST rule", {
  r <- check_corpus(make_corpus())
  expect_equal(must_fail(r), character())
  expect_equal(r$status[r$rule == "K4"], "pass")
  expect_equal(r$status[r$rule == "I3"], "pass")
})

test_that("each deviation fails its rule", {
  cases <- list(
    source_key = "L2", stray = "L4", query_col = "L5b", unprefixed = "S5", dup_ids = "S6",
    no_dataset = c("D1", "I3"), timestamp = "D2", no_links = c("K1", "K2"), bare_isbn = "K4")
  for (b in names(cases)) {
    r <- check_corpus(make_corpus(b), api = FALSE)
    expect_true(all(cases[[b]] %in% must_fail(r)), info = paste(b, ":", paste(must_fail(r), collapse = ",")))
  }
})

test_that("expect_compliant_corpus() passes and fails", {
  expect_success(expect_compliant_corpus(make_corpus(), api = FALSE))
  expect_failure(expect_compliant_corpus(make_corpus("bare_isbn"), api = FALSE), "K4")
})

test_that("id_format templates become regexes", {
  expect_true(grepl(openalexStandard:::id_format_regex("zenodo:<id>"), "zenodo:123"))
  rx <- openalexStandard:::id_format_regex("policy:<source>:<document id>")
  expect_true(grepl(rx, "policy:cbd:12:3"))
  expect_false(grepl(rx, "policy:cbd"))
  expect_false(grepl(openalexStandard:::id_format_regex("https://openalex.org/<id>"), "https://openalex.org/a/b"))
})

test_that("transformers need derived_from, and changed inputs are caught", {
  root <- withr::local_tempdir()
  input <- make_corpus(root = file.path(root, "in"))
  out <- make_corpus(root = file.path(root, "out"))
  expect_equal(check_corpus(out, kind = "transformer", api = FALSE)$status[
    check_corpus(out, kind = "transformer", api = FALSE)$rule == "T2"], "fail")
  ds <- jsonlite::read_json(file.path(out, "_dataset.json"))
  ds$derived_from <- list(list(path = "../../in/corpus",
                               sha256 = unname(tools::sha256sum(file.path(input, "_dataset.json")))))
  jsonlite::write_json(ds, file.path(out, "_dataset.json"), auto_unbox = TRUE)
  r <- check_corpus(out, kind = "transformer", api = FALSE)
  expect_equal(r$status[r$rule == "T2"], "pass")
  expect_equal(r$status[r$rule == "T1"], "pass")
  expect_equal(nrow(provenance(out)), 2)
  cat("x", file = file.path(input, "_dataset.json"), append = TRUE)
  r <- check_corpus(out, kind = "transformer", api = FALSE)
  expect_equal(r$status[r$rule == "T2"], "fail")
  expect_equal(provenance(out)$checksum[2], "changed")
})
