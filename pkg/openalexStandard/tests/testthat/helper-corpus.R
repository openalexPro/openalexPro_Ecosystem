# A minimal corpus that follows STANDARD.md, written with DuckDB.
# `break_it` names one deviation, to test that exactly its rule fails.
make_corpus <- function(break_it = NULL, root = withr::local_tempdir(.local_envir = parent.frame())) {
  is <- function(x) identical(break_it, x)
  corpus <- file.path(root, "corpus")
  key <- if (is("source_key")) "source=a" else "query=a"
  dir.create(file.path(corpus, key), recursive = TRUE)
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  extra <- if (is("unprefixed")) "fulltext" else "zenodo_extra"
  ids <- if (is("dup_ids")) "['zenodo:1', 'zenodo:1']" else "['zenodo:1', 'zenodo:2']"
  qcol <- if (is("query_col")) ", 'a' AS query" else ""
  DBI::dbExecute(con, sprintf(
    "COPY (SELECT id, 'T' || id AS title, 'T' || id AS display_name,
            'https://doi.org/10.1/' || replace(id, ':', '') AS doi,
            {'doi': 'https://doi.org/10.1/x', 'zenodo': id} AS ids,
            2020::INTEGER AS publication_year, 'x' AS %s %s
          FROM (SELECT unnest(%s) AS id)) TO '%s' (FORMAT parquet)",
    extra, qcol, ids, file.path(corpus, key, "data.parquet")))
  writeLines("{}", file.path(corpus, key, "_query.json"))
  writeLines("<html></html>", file.path(corpus, key, "_query.html"))
  if (is("stray")) writeLines("a,b", file.path(corpus, "doc_types.csv"))
  if (!is("no_links")) {
    links <- file.path(root, "links", key)
    dir.create(links, recursive = TRUE)
    outside <- if (is("bare_isbn")) "978-3-947851-03-4" else "isbn:9783947851034"
    DBI::dbExecute(con, sprintf(
      "COPY (SELECT * FROM (VALUES
         ('zenodo:1', 'zenodo:2', 'https://openalex.org/link-types/citation', 'Cites', true, true),
         ('zenodo:1', 'https://doi.org/10.1/y', 'https://openalex.org/link-types/citation', 'Cites', true, false),
         ('zenodo:2', '%s', NULL, 'IsSupplementTo', true, false))
       t(origin, target, link_type, relation, origin_in_corpus, target_in_corpus)) TO '%s' (FORMAT parquet)",
      outside, file.path(links, "data.parquet")))
  }
  # _dataset.json last: its `content` fingerprints the data written above (D5)
  ds <- list(standard = "0.1", type = "works",
             writer = list(package = "openalexImportZenodo", version = "0.1.0", prefix = "zenodo"),
             partition_keys = list("query"), id_format = "zenodo:<conceptrecid>",
             content = if (is("bad_content")) "sha256:0" else openalexStandard::content_fingerprint(corpus))
  if (is("timestamp")) ds$built <- "2026-11-27T10:00:00Z"
  if (!is("no_dataset")) jsonlite::write_json(ds, file.path(corpus, "_dataset.json"), auto_unbox = TRUE)
  corpus
}

must_fail <- function(r) sort(r$rule[r$level == "MUST" & r$status == "fail"])

fake_pkg <- function(name, exports = character(), files = list()) {
  d <- withr::local_tempdir(.local_envir = parent.frame())
  writeLines(c(paste0("Package: ", name), "Version: 0.1.0", "License: MIT + file LICENSE",
               "Title: x", "Description: x.", "Encoding: UTF-8"), file.path(d, "DESCRIPTION"))
  writeLines(paste0("export(", exports, ")"), file.path(d, "NAMESPACE"))
  dir.create(file.path(d, "R"))
  for (f in names(files)) {
    dir.create(dirname(file.path(d, f)), recursive = TRUE, showWarnings = FALSE)
    writeLines(files[[f]], file.path(d, f))
  }
  d
}
