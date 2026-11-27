#' Check an annotation folder against STANDARD.md (N1-N3, T2)
#'
#' @param dir The annotation folder, `<project>/<prefix>_<name>/`.
#' @param corpus Optional: the corpus it annotates. When given, the partitions
#'   and `id`s of the annotation must exist in it.
#' @return A data frame of results, as [check_corpus()].
#' @export
check_annotation <- function(dir, corpus = NULL) {
  dir <- normalizePath(dir, mustWork = TRUE)
  ds <- read_json_or_null(file.path(dir, "_dataset.json"))
  prefix <- ds$writer$prefix
  files <- parquet_files(dir)
  con <- duck()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  n1 <- c(
    if (!is.null(prefix) && !startsWith(basename(dir), paste0(prefix, "_"))) paste0("folder is not `", prefix, "_<name>`"),
    if (!length(files)) "no Parquet files",
    if (length(files) && !length(partitions(dir))) "no `query=<name>/` partitions")
  cols <- if (length(files)) unique(unlist(lapply(files, function(f) {
    q(con, paste0("DESCRIBE SELECT * FROM read_parquet(", lit(f), ", hive_partitioning = false)"))$column_name
  })))
  if (length(files) && !"id" %in% cols) n1 <- c(n1, "no `id` column")
  if (!is.null(corpus) && length(files) && "id" %in% cols) {
    corpus <- normalizePath(corpus, mustWork = TRUE)
    extra_p <- setdiff(partitions(dir), partitions(corpus))
    if (length(extra_p)) n1 <- c(n1, paste("partitions not in the corpus:", show(extra_p)))
    cf <- parquet_files(corpus)
    miss <- q(con, paste0(
      "SELECT DISTINCT id FROM read_parquet(", lit_list(files), ", union_by_name = true, hive_partitioning = false) ",
      "WHERE id IS NULL OR id NOT IN (SELECT id FROM read_parquet(", lit_list(cf), ", union_by_name = true, hive_partitioning = false) WHERE id IS NOT NULL) ORDER BY id LIMIT 6"))$id
    if (length(miss)) n1 <- c(n1, paste("ids not in the corpus:", show(miss)))
  }

  n2 <- if (is.null(ds)) "no `_dataset.json`" else c(
    if (!identical(ds$type, "annotation")) "`type` is not \"annotation\"",
    if (is.null(ds$writer$package) || is.null(ds$writer$prefix)) "no `writer` (package, version, prefix)",
    if (is.null(ds$derived_from)) "no `derived_from`",
    if (is.null(ds$method)) "no `method` (name, version, settings)",
    if (is.null(ds$content)) "no `content` fingerprint (D5)"
    else if (!identical(ds$content, content_fingerprint(dir))) "`content` does not match the data (D5)")
  bad_cols <- setdiff(cols, c("id", "query"))
  bad_cols <- bad_cols[!has_prefix(bad_cols, prefix)]

  bind(
    list(if (length(n1)) res("N1", "fail", n1, "write `<project>/<prefix>_<name>/query=<name>/*.parquet` keyed by `id`")
         else res("N1", "pass"),
         if (length(n2)) res("N2", "fail", n2, "write `_dataset.json` with type, writer, derived_from, method")
         else res("N2", "pass"),
         if (length(bad_cols)) res("N3", "fail", paste("columns without the writer prefix:", show(bad_cols)), "prefix them")
         else res("N3", "pass")),
    if (!is.null(ds)) check_derived_from(ds, dir, "transformer")
  )
}

#' Where a corpus or annotation comes from
#'
#' Follows `derived_from` in `_dataset.json` back to the sources, and checks each
#' recorded `content` fingerprint against the input's current data (D5).
#' @param dir A corpus or annotation folder.
#' @return A data frame: `level` (0 = `dir`), `path`, `writer`, `checksum`
#'   (`ok`, `changed`, `none`, `missing`, `external`).
#' @export
provenance <- function(dir) {
  out <- list()
  walk <- function(d, lvl, status) {
    ds <- read_json_or_null(file.path(d, "_dataset.json"))
    out[[length(out) + 1L]] <<- data.frame(
      level = lvl, path = d, writer = ds$writer$package %||% NA_character_,
      checksum = status, stringsAsFactors = FALSE)
    if (lvl > 20) return(invisible())
    for (e in ds$derived_from) {
      st <- derived_status(e, d)
      if (!is.null(e$source)) {
        out[[length(out) + 1L]] <<- data.frame(level = lvl + 1L, path = paste(e$source, e$release %||% ""),
                                              writer = NA_character_, checksum = "external", stringsAsFactors = FALSE)
      } else {
        st <- if (st == "ok") "ok" else if (grepl("not found", st)) "missing" else if (grepl("no `content`", st)) "none" else "changed"
        walk(normalizePath(file.path(d, e$path), mustWork = FALSE), lvl + 1L, st)
      }
    }
  }
  walk(normalizePath(dir, mustWork = TRUE), 0L, NA_character_)
  do.call(rbind, out)
}
