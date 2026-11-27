#' Write `_dataset.json` for a corpus or annotation (STANDARD.md D1-D3, T2, N2)
#'
#' Writes a deterministic marker file: no timestamps, no absolute paths, fixed
#' field order, so an unchanged corpus gets a byte-identical file. Call it after
#' the data are written: it records their fingerprint (`content`, D5).
#'
#' @param dir The corpus (or annotation) folder.
#' @param package,version The writing package and its version.
#' @param prefix The writer's registered prefix (I5).
#' @param id_format The template of `id` (I3), e.g. `"zenodo:<conceptrecid>"`;
#'   `"https://openalex.org/<id>"` for OpenAlex records.
#' @param type `"works"` (a corpus) or `"annotation"`.
#' @param partition_keys The Hive partition keys, top level first.
#' @param derived_from Inputs (transformers, annotators): corpus folders, stored
#'   relative to `dir` with their fingerprint (D5), and/or external sources as
#'   `list(source = "openalex-snapshot", release = "2026-10-28")`.
#' @param method For annotations (N2): a list with the method name, version and
#'   settings.
#' @return The path of the file, invisibly.
#' @export
write_dataset_json <- function(dir, package, version, prefix, id_format = NULL,
                               type = c("works", "annotation"), partition_keys = "query",
                               derived_from = NULL, method = NULL) {
  type <- match.arg(type)
  if (type == "works" && is.null(id_format)) stop("`id_format` is required for a corpus (I3).", call. = FALSE)
  if (prefix %in% standard_schemes()) stop("`", prefix, "` is a scheme name (I7).", call. = FALSE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  if (is.character(derived_from)) derived_from <- as.list(derived_from)
  df <- lapply(derived_from, function(p) {
    if (is.list(p)) return(p[c("source", "release")])
    list(path = rel_path(p, dir), content = content_fingerprint(p))
  })
  ds <- list(standard = standard_version(), type = type,
             writer = list(package = package, version = as.character(version), prefix = prefix),
             partition_keys = as.list(partition_keys), id_format = id_format,
             content = content_fingerprint(dir),
             derived_from = if (length(df)) df, method = method)
  ds <- ds[!vapply(ds, is.null, TRUE)]
  f <- file.path(dir, "_dataset.json")
  jsonlite::write_json(ds, f, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
  invisible(f)
}

# Path of `to` relative to the folder `from_dir`, with `/` separators.
rel_path <- function(to, from_dir) {
  a <- strsplit(normalizePath(to, "/", mustWork = TRUE), "/")[[1]]
  b <- strsplit(normalizePath(from_dir, "/", mustWork = TRUE), "/")[[1]]
  n <- 0L
  while (n < min(length(a), length(b)) && a[n + 1L] == b[n + 1L]) n <- n + 1L
  r <- paste(c(rep("..", length(b) - n), a[seq_along(a) > n]), collapse = "/")
  if (nzchar(r)) r else "."
}

#' Write a link table partition (STANDARD.md K1-K4)
#'
#' Writes `<dir>/query=<name>/data.parquet` with the K1 columns. Checks the
#' identifier form of every link end (K4) and the prefix of extra columns (S5)
#' first, and stops with the offending values. A data frame with no rows still
#' writes a file with the columns (K2).
#'
#' @param links A data frame with `origin`, `target`, `link_type` (an OpenAlex
#'   link-type URL or NA), `relation` (DataCite relation type or NA), and
#'   optionally `origin_in_corpus`, `target_in_corpus` and prefixed extra
#'   columns.
#' @param dir The link table folder (`links/` next to the corpus).
#' @param name The partition name, the same as the corpus partition.
#' @param corpus_ids The `id`s of the corpus; used to fill `*_in_corpus` when
#'   those columns are missing.
#' @param prefix The writer's prefix, for extra columns.
#' @return The path of the file, invisibly.
#' @export
write_links <- function(links, dir, name, corpus_ids = NULL, prefix = NULL) {
  if (!grepl("^[A-Za-z0-9._-]+$", name) || name %in% c(".", "..")) stop("`name` must be a plain folder name (L3).", call. = FALSE)
  links <- as.data.frame(links, stringsAsFactors = FALSE)
  for (c in c("origin", "target", "link_type", "relation")) {
    if (!c %in% names(links)) stop("`links` needs a `", c, "` column (K1).", call. = FALSE)
    links[[c]] <- as.character(links[[c]])
  }
  for (c in c("origin", "target")) {
    ic <- paste0(c, "_in_corpus")
    if (!ic %in% names(links)) {
      if (is.null(corpus_ids)) stop("Give `", ic, "` or `corpus_ids` (K1).", call. = FALSE)
      links[[ic]] <- links[[c]] %in% corpus_ids
    }
    links[[ic]] <- as.logical(links[[ic]])
  }
  bad_lt <- setdiff(links$link_type[!is.na(links$link_type)], link_types())
  if (length(bad_lt)) stop("`link_type` must be an OpenAlex link type or NA (K1): ", show(bad_lt), call. = FALSE)
  extra <- setdiff(names(links), c("origin", "target", "link_type", "relation", "origin_in_corpus", "target_in_corpus"))
  bad_extra <- extra[!has_prefix(extra, prefix)]
  if (length(bad_extra)) stop("Extra columns need the writer prefix (S5): ", show(bad_extra), call. = FALSE)
  rx <- paste0("^(https://doi\\.org/.+|https?://.+|(", paste(link_schemes(), collapse = "|"), "):.+)$")
  ends <- c(links$origin[!links$origin_in_corpus], links$target[!links$target_in_corpus])
  bad <- ends[!grepl(rx, ends)]
  if (length(bad)) {
    stop("Link ends outside the corpus must be a DOI URL, a URL or `<scheme>:<id>` (K4): ", show(bad), call. = FALSE)
  }
  part <- file.path(dir, paste0("query=", name))
  dir.create(part, recursive = TRUE, showWarnings = FALSE)
  f <- file.path(part, "data.parquet")
  con <- duck()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  cols <- c("origin", "target", "link_type", "relation", "origin_in_corpus", "target_in_corpus", extra)
  duckdb::duckdb_register(con, "l", links[, cols, drop = FALSE])
  DBI::dbExecute(con, paste0(
    "COPY (SELECT origin::VARCHAR AS origin, target::VARCHAR AS target, link_type::VARCHAR AS link_type, ",
    "relation::VARCHAR AS relation, ",
    "origin_in_corpus::BOOLEAN AS origin_in_corpus, target_in_corpus::BOOLEAN AS target_in_corpus",
    if (length(extra)) paste0(", ", paste(DBI::dbQuoteIdentifier(con, extra), collapse = ", ")),
    " FROM l) TO ", lit(f), " (FORMAT parquet, COMPRESSION zstd)"))
  invisible(f)
}
