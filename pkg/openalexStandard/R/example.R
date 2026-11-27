#' A small corpus that follows STANDARD.md
#'
#' Writes three works (`zenodo:` ids, as written by openalexImportZenodo) with
#' `_dataset.json`, `_query.json`, `_query.html` and a link table below the
#' project folder `out`, and returns the corpus folder. Used to test packages
#' that read corpora (A2) and annotators (P7a).
#' @param out Project folder to write into.
#' @return The path of the corpus folder.
#' @export
standard_example_corpus <- function(out = tempfile()) {
  corpus <- file.path(out, "corpus")
  part <- file.path(corpus, "query=example")
  dir.create(part, recursive = TRUE, showWarnings = FALSE)
  con <- duck()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  DBI::dbExecute(con, paste0(
    "COPY (SELECT id, title, title AS display_name, 'https://doi.org/10.5281/' || replace(id, ':', '.') AS doi,
       {'doi': 'https://doi.org/10.5281/' || replace(id, ':', '.'), 'zenodo': id} AS ids,
       2024::INTEGER AS publication_year, abstract, ['zenodo:2'] AS referenced_works
     FROM (VALUES ('zenodo:1', 'Nature and people', 'An assessment of nature''s contributions to people.'),
                  ('zenodo:2', 'Pollinators', 'Pollinators, pollination and food production.'),
                  ('zenodo:3', 'Invasive species', 'Invasive alien species and their control.'))
          t(id, title, abstract) ORDER BY id) TO ", lit(file.path(part, "data.parquet")), " (FORMAT parquet)"))
  jsonlite::write_json(list(source = "openalexStandard::standard_example_corpus()"), file.path(part, "_query.json"),
                       auto_unbox = TRUE)
  writeLines("<p>Example corpus of openalexStandard.</p>", file.path(part, "_query.html"))
  write_links(data.frame(origin = c("zenodo:1", "zenodo:2"), target = c("zenodo:2", "isbn:9783947851034"),
                         link_type = c(link_types()[1], NA), relation = c("Cites", "IsSupplementTo")),
              file.path(out, "links"), "example", corpus_ids = c("zenodo:1", "zenodo:2", "zenodo:3"))
  write_dataset_json(corpus, "openalexStandard", utils::packageVersion("openalexStandard"), "zenodo",
                     "zenodo:<conceptrecid>")
  corpus
}
