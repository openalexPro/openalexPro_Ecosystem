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
  ds <- list(standard = "0.1", type = "works",
             writer = list(package = "openalexImportZenodo", version = "0.1.0", prefix = "zenodo"),
             partition_keys = list("query"), id_format = "zenodo:<conceptrecid>")
  if (is("timestamp")) ds$built <- "2026-11-27T10:00:00Z"
  if (!is("no_dataset")) jsonlite::write_json(ds, file.path(corpus, "_dataset.json"), auto_unbox = TRUE)
  writeLines("{}", file.path(corpus, key, "_query.json"))
  writeLines("<html></html>", file.path(corpus, key, "_query.html"))
  if (is("stray")) writeLines("a,b", file.path(corpus, "doc_types.csv"))
  if (!is("no_links")) {
    links <- file.path(root, "links", key)
    dir.create(links, recursive = TRUE)
    outside <- if (is("bare_isbn")) "978-3-947851-03-4" else "isbn:9783947851034"
    DBI::dbExecute(con, sprintf(
      "COPY (SELECT * FROM (VALUES
         ('zenodo:1', 'zenodo:2', 'https://openalex.org/link-types/citation', true, true),
         ('zenodo:1', 'https://doi.org/10.1/y', 'https://openalex.org/link-types/citation', true, false),
         ('zenodo:2', '%s', NULL, true, false))
       t(origin, target, link_type, origin_in_corpus, target_in_corpus)) TO '%s' (FORMAT parquet)",
      outside, file.path(links, "data.parquet")))
  }
  corpus
}

must_fail <- function(r) sort(r$rule[r$level == "MUST" & r$status == "fail"])
