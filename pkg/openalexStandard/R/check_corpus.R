#' Check a corpus folder against STANDARD.md
#'
#' Runs every automatable corpus rule of STANDARD.md (sections 1-5 and 7, and T1/T2 for
#' transformers) on a corpus folder and its sibling link table. The corpus is
#' only read, never changed.
#'
#' @param dir The corpus folder: the folder a reader is given, with
#'   `query=<name>/` partitions and `_dataset.json`.
#' @param links The link table folder (K1). Defaults to `links/` next to `dir`.
#' @param kind `"writer"` or `"transformer"`; transformers are also checked for
#'   T1 and T2.
#' @param prefix The writer's prefix (I5), or the prefixes of all writers of a
#'   mixed corpus. Defaults to the prefix(es) in `_dataset.json`.
#' @param api Also run `openalexAPI::prepare_corpus()` (pseudo-rule `API`) when
#'   openalexAPI is installed.
#' @return A data frame with one row per rule: `rule`, `level`, `status`
#'   (pass, fail, n/a, not verified, manual), `evidence`, `fix`.
#' @export
check_corpus <- function(dir, links = file.path(dirname(dir), "links"),
                         kind = c("writer", "transformer"), prefix = NULL, api = TRUE) {
  kind <- match.arg(kind)
  dir <- normalizePath(dir, mustWork = TRUE)
  files <- parquet_files(dir)
  ds <- read_json_or_null(file.path(dir, "_dataset.json"))
  prefix <- prefix %||% ds$writer$prefix %||% unique(unlist(lapply(ds$queries, function(x) x$writer$prefix)))

  if (!length(files)) {
    out <- res("L1", "fail", paste0("no Parquet files below `", basename(dir), "/`"),
               "write the works as `query=<name>/*.parquet`")
    rest <- setdiff(corpus_rule_ids(kind), "L1")
    return(bind(list(out), lapply(rest, res, status = "not verified", evidence = "no data (L1)")))
  }

  con <- duck()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  schemas <- lapply(files, function(f) q(con, paste0("DESCRIBE SELECT * FROM read_parquet(", lit(f), ", hive_partitioning = false)"))[, 1:2])
  names(schemas) <- substring(files, nchar(dir) + 2)

  # a transformer passes on columns and ids of other writers with their prefix (S5, T1)
  taken <- if (kind == "transformer") NULL else prefix
  out <- bind(
    list(res("L1", "pass", paste(length(files), "Parquet file(s)"))),
    check_layout(dir, files, schemas),
    check_schema(con, dir, files, schemas, taken),
    check_dataset_json(ds, dir),
    check_query_files(dir),
    check_ids(con, files, schemas, ds, prefix, own_ids = kind != "transformer"),
    check_links(con, dir, links, files, schemas, taken),
    check_derived_from(ds, dir, kind)
  )
  if (kind == "transformer") {
    bad <- out$rule[out$level == "MUST" & out$status == "fail"]
    out <- bind(list(out), list(if (length(bad)) {
      res("T1", "fail", paste("output breaks", paste(bad, collapse = ", ")), "see those rules")
    } else res("T1", "pass", "output corpus passes \u00a71\u2013\u00a77")))
  }
  bind(list(out), list(check_api(dir, api)))
}


corpus_rule_ids <- function(kind) {
  r <- standard_rules()
  ids <- r$rule[r$section %in% c("1", "2", "3", "4", "5", "7", "check") &
                  grepl("writer", r$kinds) & r$rule != "P7"]
  ids <- setdiff(ids, c("I5", "I7", "Q2"))
  c(ids, "I5", "I7", "Q2", "D5", if (kind == "transformer") c("T1", "T2"))
}

check_layout <- function(dir, files, schemas) {
  top <- list.files(dir, all.files = FALSE, no.. = TRUE)
  top <- top[!grepl("^[_.]", top)]
  bad_top <- top[!grepl("^query=", top)]
  names_ <- sub("^query=", "", partitions(dir))
  invalid <- names_[!nzchar(names_) | grepl('[<>:"/\\\\|?*[:cntrl:]]', names_) |
                      grepl("[. ]$", names_) |
                      toupper(sub("\\..*$", "", names_)) %in% c("CON", "PRN", "AUX", "NUL", paste0("COM", 1:9), paste0("LPT", 1:9))]
  all_files <- list.files(dir, recursive = TRUE, all.files = TRUE)
  stray <- all_files[!grepl("\\.parquet$", all_files) & !grepl("^[_.]", basename(all_files))]
  keys <- unique(c("query", sub("=.*$", "", unlist(regmatches(names(schemas), gregexpr("[^/]+=[^/]*", names(schemas)))))))
  cols <- unique(unlist(lapply(schemas, `[[`, "column_name")))
  clash <- intersect(cols, keys)
  list(
    if (length(bad_top)) res("L2", "fail", paste("top level not `query=<name>`:", show(bad_top)),
                             "put every partition in `query=<name>/`")
    else res("L2", "pass", paste(length(partitions(dir)), "`query=` partition(s)")),
    if (length(invalid)) res("L3", "fail", paste("invalid folder names:", show(invalid)), "rename the partitions")
    else res("L3", "pass"),
    if (length(stray)) res("L4", "fail", paste("non-data files without `_`:", show(stray)), "prefix them with `_`")
    else res("L4", "pass"),
    if (length(clash)) res("L5b", "fail", paste("data column named like a partition key:", show(clash)),
                           "rename the column (with the writer prefix)")
    else res("L5b", "pass")
  )
}

type_class <- function(t) {
  ifelse(grepl("^MAP\\(", t), "MAP", ifelse(grepl("\\[\\]$", t), "LIST",
         ifelse(grepl("^STRUCT\\(", t), "STRUCT", "SCALAR")))
}

check_schema <- function(con, dir, files, schemas, prefix) {
  no_works <- names(schemas)[!vapply(schemas, function(d) {
    "id" %in% d$column_name && any(c("title", "display_name") %in% d$column_name)
  }, TRUE)]
  all <- unique(do.call(rbind, schemas))
  cols <- unique(all$column_name)
  wf <- works_fields()
  # S2: top-level type class of OpenAlex columns
  base <- wf[!is.na(wf$type) & wf$field %in% cols, ]
  s2 <- unlist(lapply(seq_len(nrow(base)), function(i) {
    t <- unique(all$column_type[all$column_name == base$field[i]])
    # a VARCHAR on either side is a JSON-serialised form (e.g. the snapshot's
    # abstract_inverted_index), which readers accept
    if (base$type[i] == "VARCHAR") return(if (any(type_class(t) != "SCALAR")) base$field[i])
    t <- t[t != "VARCHAR"]
    if (length(t) && !all(type_class(t) == type_class(base$type[i]))) base$field[i]
  }))
  # S3: listed types
  want <- list(
    publication_year = "^(TINYINT|SMALLINT|INTEGER|BIGINT|HUGEINT|U(TINY|SMALL|BIG)?INT(EGER)?)$",
    cited_by_count = "^(TINYINT|SMALLINT|INTEGER|BIGINT|HUGEINT|U(TINY|SMALL|BIG)?INT(EGER)?)$",
    fwci = "^(FLOAT|DOUBLE|DECIMAL.*)$",
    publication_date = "^DATE$",
    is_retracted = "^BOOLEAN$", is_paratext = "^BOOLEAN$",
    abstract_inverted_index = "^MAP\\(VARCHAR, BIGINT\\[\\]\\)$")
  s3 <- unlist(lapply(names(want), function(cn) {
    t <- unique(all$column_type[all$column_name == cn])
    if (length(t) && !all(grepl(want[[cn]], t))) paste0(cn, " (", paste(t, collapse = "/"), ")")
  }))
  rsv <- reserved_columns()
  extras <- setdiff(cols, c(wf$field, rsv$column, "id"))
  wrong_prefix <- extras[!has_prefix(extras, prefix)]
  rsv_used <- intersect(cols, rsv$column)
  rsv_bad <- unlist(lapply(rsv_used, function(cn) {
    t <- unique(all$column_type[all$column_name == cn])
    w <- rsv$type[rsv$column == cn]
    ok <- if (w == "DOUBLE") grepl("^(FLOAT|DOUBLE|DECIMAL.*|INTEGER|BIGINT)$", t) else t == w
    if (!all(ok)) paste0(cn, " (", paste(t, collapse = "/"), ")")
  }))
  okf <- files[!names(schemas) %in% no_works]
  dup <- if (length(okf)) q(con, paste0(
    "SELECT regexp_extract(filename, '/query=([^/]+)/', 1) AS p, count(id) - count(DISTINCT id) AS d ",
    "FROM read_parquet(", lit_list(okf), ", filename = true, union_by_name = true, hive_partitioning = false) ",
    "GROUP BY 1 HAVING d > 0")) else data.frame(p = character(), d = numeric())
  list(
    if (length(no_works)) res("S1", "fail", paste("files without `id` + `title`/`display_name`:", show(no_works)),
                              "add the columns, or move the file out of the corpus")
    else res("S1", "pass", paste(length(files), "works file(s)")),
    if (length(s2)) res("S2", "fail", paste("OpenAlex columns with another structure:", show(s2)),
                        "use the OpenAlex structure (see openalexPro's works schema)")
    else res("S2", "pass", "names and top-level types (nested fields not checked)"),
    if (length(s3)) res("S3", "fail", show(s3), "cast to the listed type") else res("S3", "pass"),
    if ("abstract" %in% cols) res("S4", "pass", "plain-text `abstract`") else res("S4", "n/a", "no `abstract` column"),
    if (length(wrong_prefix)) res("S5", "fail", paste("extra columns without the writer prefix:", show(wrong_prefix)),
                                  paste0("rename to `", prefix %||% "<prefix>", "_<name>`"))
    else res("S5", "pass", if (length(extras)) paste(length(extras), "prefixed extra column(s)") else "no extra columns"),
    if (length(rsv_bad)) res("S5a", "fail", paste("reserved column with another type:", show(rsv_bad)),
                             "rename the column (with the writer prefix)")
    else res("S5a", "pass", if (length(rsv_used)) paste("reserved:", show(rsv_used), "(meaning not checked)") else "none used"),
    if (nrow(dup)) res("S6", "fail", paste0("duplicate `id`s in ", show(paste0(dup$p, ": ", dup$d))),
                       "deduplicate within each partition")
    else res("S6", "pass")
  )
}

check_dataset_json <- function(ds, dir) {
  if (is.null(ds)) {
    return(list(res("D1", "fail", "no `_dataset.json`", "write it (STANDARD.md D3)"),
                res("D2", "not verified", "no `_dataset.json`"),
                res("D3", "not verified", "no `_dataset.json`"),
                res("D5", "not verified", "no `_dataset.json`")))
  }
  if (!is.null(attr(ds, "parse_error"))) {
    return(list(res("D1", "fail", paste("`_dataset.json` does not parse:", attr(ds, "parse_error")), "write valid JSON"),
                res("D2", "not verified"), res("D3", "not verified"), res("D5", "not verified")))
  }
  vals <- as.character(unlist(ds))
  run_dep <- vals[grepl("\\d{4}-\\d{2}-\\d{2}[T ]\\d{2}:\\d{2}", vals) | grepl("^(/|~|[A-Za-z]:[\\\\/])", vals)]
  need <- function(x) {
    m <- c(if (is.null(x$writer$package)) "writer.package", if (is.null(x$writer$version)) "writer.version",
           if (is.null(x$writer$prefix)) "writer.prefix", if (is.null(x$id_format)) "id_format")
    m
  }
  miss <- c(if (is.null(ds$standard)) "standard", if (is.null(ds$type)) "type",
            if (is.null(ds$partition_keys)) "partition_keys",
            if (is.null(ds$content)) "content",
            if (!is.null(ds$type) && !ds$type %in% c("works", "annotation")) "type (works or annotation)",
            if (!is.null(ds$queries) && (!is.null(ds$writer) || !is.null(ds$id_format))) "queries replaces writer/id_format",
            if (is.null(ds$queries)) need(ds) else unlist(lapply(names(ds$queries), function(n) {
              m <- need(ds$queries[[n]]); if (length(m)) paste0("queries.", n, ".", m)
            })))
  fp <- content_fingerprint(dir)
  d5 <- if (is.null(ds$content)) res("D5", "fail", "no `content` fingerprint", "write it with `openalexStandard::write_dataset_json()`")
  else if (!identical(ds$content, fp)) res("D5", "fail", paste0("`content` ", ds$content, " but the data give ", fp),
                                           "rewrite `_dataset.json` after writing the data")
  else res("D5", "pass", fp)
  list(
    d5,
    res("D1", "pass"),
    if (length(run_dep)) res("D2", "fail", paste("run-dependent values:", show(run_dep)),
                             "remove timestamps and absolute paths")
    else res("D2", "pass"),
    if (length(miss)) res("D3", "fail", paste("missing:", show(miss)), "add the required fields")
    else res("D3", "pass")
  )
}

check_query_files <- function(dir) {
  p <- partitions(dir)
  no_json <- p[!file.exists(file.path(dir, p, "_query.json"))]
  bad_json <- setdiff(p, no_json)
  bad_json <- bad_json[vapply(bad_json, function(x) !is.null(attr(read_json_or_null(file.path(dir, x, "_query.json")), "parse_error")), TRUE)]
  no_html <- p[!file.exists(file.path(dir, p, "_query.html"))]
  q1 <- c(no_json, bad_json)
  list(
    if (length(q1)) res("Q1", "fail", paste("partitions without a valid `_query.json`:", show(q1)),
                        "write `_query.json` into each partition")
    else res("Q1", "pass"),
    res("Q2", "manual", "is `_query.json` enough to repeat the download? (review)"),
    if (length(no_html)) res("Q3", "fail", paste("partitions without `_query.html`:", show(no_html)),
                             "write `_query.html`")
    else res("Q3", "pass"),
    if (length(q1)) res("Q4", "fail", "the delivered corpus lacks `_query.json` (Q1)", "copy it through every step")
    else res("Q4", "pass", "present in the delivered corpus"),
    res("Q5", "pass", "run-dependent values allowed")
  )
}

check_ids <- function(con, files, schemas, ds, prefix, own_ids = TRUE) {
  okf <- files[vapply(schemas, function(d) "id" %in% d$column_name, TRUE)]
  cols <- unique(unlist(lapply(schemas, `[[`, "column_name")))
  src <- paste0("read_parquet(", lit_list(okf), ", union_by_name = true, hive_partitioning = false, filename = true)")
  oa <- q(con, paste0("SELECT count(*) FILTER (WHERE id LIKE 'https://openalex.org/%') AS n_oa, ",
                      "count(*) FILTER (WHERE id LIKE 'https://openalex.org/%' AND NOT regexp_full_match(id, 'https://openalex\\.org/W[0-9]+')) AS bad_oa, ",
                      "count(*) FILTER (WHERE id IS NULL) AS n_null, count(DISTINCT id) - count(DISTINCT lower(id)) AS n_case, ",
                      "count(*) AS n FROM ", src))
  other <- q(con, paste0("SELECT id FROM ", src, " WHERE id NOT LIKE 'https://openalex.org/%' AND ",
                         "NOT regexp_full_match(id, '[a-z0-9]+:[^/]+') ORDER BY id LIMIT 6"))$id
  pre <- q(con, paste0("SELECT DISTINCT split_part(id, ':', 1) AS p FROM ", src,
                       " WHERE id NOT LIKE 'https://openalex.org/%' AND regexp_full_match(id, '[a-z0-9]+:[^/]+')"))$p
  reg <- standard_prefixes()$prefix
  i2_bad <- c(if (oa$n_null > 0) paste(oa$n_null, "record(s) without `id`"),
              if (oa$n_case > 0) paste(oa$n_case, "id(s) differing from another only in letter case"),
              if (length(other)) paste("not `<prefix>:<part>`:", show(other)),
              if (own_ids && !is.null(prefix) && length(setdiff(pre, prefix))) paste("first part is not the writer prefix:", show(setdiff(pre, prefix))),
              if (length(setdiff(pre, reg))) paste("unregistered prefix:", show(setdiff(pre, reg))))
  # I3: id_format
  fmts <- if (!is.null(ds$queries)) unique(unlist(lapply(ds$queries, `[[`, "id_format"))) else ds$id_format
  i3 <- if (is.null(ds)) res("I3", "fail", "no `_dataset.json`, so no `id_format`", "declare `id_format` (D3)")
  else if (is.null(fmts)) res("I3", "fail", "no `id_format` in `_dataset.json`", "declare `id_format` (D3)")
  else {
    rx <- paste(vapply(fmts, id_format_regex, ""), collapse = "|")
    nm <- q(con, paste0("SELECT id FROM ", src, " WHERE NOT regexp_matches(id, ", lit(rx), ") ORDER BY id LIMIT 6"))$id
    if (length(nm)) res("I3", "fail", paste0("ids not matching `", paste(fmts, collapse = "` / `"), "`: ", show(nm)),
                        "fix the ids or `id_format`")
    else res("I3", "pass", paste0("`", paste(fmts, collapse = "`, `"), "`"))
  }
  doi <- if ("doi" %in% cols) q(con, paste0("SELECT doi FROM ", src, " WHERE doi IS NOT NULL AND ",
                                            "(NOT starts_with(doi, 'https://doi.org/') OR doi <> lower(doi)) ORDER BY doi LIMIT 6"))$doi
  list(
    if (oa$n_oa == 0) res("I1", "n/a", "no OpenAlex ids")
    else if (oa$bad_oa > 0) res("I1", "fail", paste(oa$bad_oa, "OpenAlex ids not `https://openalex.org/W<n>`"), "use the full OpenAlex URL")
    else res("I1", "pass", paste(oa$n_oa, "OpenAlex ids")),
    if (oa$n == oa$n_oa) res("I2", "n/a", "only OpenAlex ids")
    else if (length(i2_bad)) res("I2", "fail", i2_bad, "ids are `<prefix>:<part>...` with the writer's registered prefix, no `/`")
    else res("I2", "pass", paste(oa$n - oa$n_oa, "ids with prefix", show(pre))),
    i3,
    if ("ids" %in% cols) res("I4", "pass") else res("I4", "fail", "no `ids` column", "add `ids` with known external identifiers"),
    if (is.null(prefix)) res("I5", "not verified", "writer prefix unknown (no `writer.prefix` in `_dataset.json`)")
    else if (!all(prefix %in% reg)) res("I5", "fail", paste(show(setdiff(prefix, reg)), "not registered"), "register it in STANDARD.md I5")
    else res("I5", "pass", show(prefix)),
    if (!"doi" %in% cols) res("I6", "n/a", "no `doi` column")
    else if (length(doi)) res("I6", "fail", paste("DOIs not lowercase `https://doi.org/...`:", show(doi)), "normalise the DOIs")
    else res("I6", "pass"),
    if (is.null(prefix)) res("I7", "not verified", "writer prefix unknown")
    else if (any(prefix %in% standard_schemes())) res("I7", "fail", paste(show(intersect(prefix, standard_schemes())), "is a scheme name"), "choose another prefix")
    else res("I7", "pass")
  )
}

check_links <- function(con, dir, links, files, schemas, prefix) {
  if (!dir.exists(links)) {
    return(list(res("K1", "fail", paste0("no `", basename(links), "/` next to the corpus"), "write the link table (K1)"),
                res("K2", "fail", "no link table", "write it, also with zero rows"),
                res("K3", "pass", "repeating works-column relations is allowed"),
                res("K4", "not verified", "no link table")))
  }
  links <- normalizePath(links)
  lf <- parquet_files(links)
  missing_part <- setdiff(partitions(dir), partitions(links))
  empty_part <- partitions(links)[vapply(partitions(links), function(p) !length(parquet_files(file.path(links, p))), TRUE)]
  k2 <- c(if (length(missing_part)) paste("no link partition for", show(missing_part)),
          if (length(empty_part)) paste("link partition without a Parquet file:", show(empty_part)))
  if (!length(lf)) {
    return(list(res("K1", "fail", "no link files", "write the link table"),
                res("K2", "fail", k2 %||% "no link files", "write a file even with zero rows"),
                res("K3", "pass", "repeating works-column relations is allowed"),
                res("K4", "not verified", "no link files")))
  }
  ls <- unique(do.call(rbind, lapply(lf, function(f) q(con, paste0("DESCRIBE SELECT * FROM read_parquet(", lit(f), ", hive_partitioning = false)"))[, 1:2])))
  req <- c(origin = "VARCHAR", target = "VARCHAR", link_type = "VARCHAR", relation = "VARCHAR",
           origin_in_corpus = "BOOLEAN", target_in_corpus = "BOOLEAN")
  miss <- names(req)[!names(req) %in% ls$column_name]
  wrong <- names(req)[names(req) %in% ls$column_name &
                        !vapply(names(req), function(n) all(ls$column_type[ls$column_name == n] == req[[n]]), TRUE)]
  extra <- setdiff(ls$column_name, names(req))
  bad_extra <- extra[!has_prefix(extra, prefix)]
  bad_lt <- if ("link_type" %in% ls$column_name) q(con, paste0(
    "SELECT DISTINCT link_type FROM read_parquet(", lit_list(lf), ", union_by_name = true, hive_partitioning = false) ",
    "WHERE link_type IS NOT NULL AND link_type NOT IN (", paste(lit(link_types()), collapse = ", "), ") ORDER BY 1"))$link_type
  k1 <- c(if (length(miss)) paste("missing columns:", show(miss)),
          if (length(wrong)) paste("wrong types:", show(wrong)),
          if (length(bad_lt)) paste("`link_type` not an OpenAlex link type or NA:", show(bad_lt)),
          if (length(bad_extra)) paste("extra columns without the writer prefix:", show(bad_extra)))
  k4 <- if (length(miss)) res("K4", "not verified", "required columns missing (K1)") else {
    schemes <- paste(link_schemes(), collapse = "|")
    src <- paste0("read_parquet(", lit_list(lf), ", union_by_name = true, hive_partitioning = false)")
    okf <- files[vapply(schemas, function(d) "id" %in% d$column_name, TRUE)]
    ids <- paste0("(SELECT DISTINCT id FROM read_parquet(", lit_list(okf), ", union_by_name = true, hive_partitioning = false) WHERE id IS NOT NULL)")
    outside_rx <- paste0("^(https://doi\\.org/.+|https?://.+|(", schemes, "):.+)$")
    ends <- paste0("SELECT origin AS v, origin_in_corpus AS inc FROM ", src,
                   " UNION ALL SELECT target, target_in_corpus FROM ", src)
    bad_out <- q(con, paste0("SELECT v, count(*) AS n FROM (", ends, ") WHERE NOT inc AND (v IS NULL OR NOT regexp_matches(v, ",
                             lit(outside_rx), ")) GROUP BY v ORDER BY n DESC, v"))
    bad_in <- q(con, paste0("SELECT DISTINCT v FROM (", ends, ") e WHERE inc AND (v IS NULL OR v NOT IN ", ids, ") ORDER BY v LIMIT 6"))$v
    n_out <- q(con, paste0("SELECT count(*) AS n FROM (", ends, ") WHERE NOT inc"))$n
    form <- function(v) ifelse(grepl("^https://doi\\.org/", v), "doi", ifelse(grepl("^https?://", v), "url", sub(":.*$", "", v)))
    if (nrow(bad_out) || length(bad_in)) {
      res("K4", "fail", c(
        if (nrow(bad_out)) paste(sum(bad_out$n), "outside end(s) not a DOI, URL or `<scheme>:<id>`, e.g.", show(bad_out$v)),
        if (length(bad_in)) paste("ends marked in corpus but not a corpus `id`:", show(bad_in))),
        "write outside ends as `https://doi.org/...`, a URL, or `<scheme>:<identifier>` (I7)")
    } else res("K4", "pass", paste(n_out, "outside end(s), all DOI/URL/`<scheme>:`"))
  }
  list(
    if (length(k1)) res("K1", "fail", k1, "use the K1 columns; prefix extra columns") else res("K1", "pass", paste(length(lf), "link file(s)")),
    if (length(k2)) res("K2", "fail", k2, "write one link partition per corpus partition, also with zero rows")
    else res("K2", "pass"),
    res("K3", "pass", "repeating works-column relations is allowed"),
    k4
  )
}

check_derived_from <- function(ds, dir, kind) {
  if (kind == "writer") return(NULL) # T2 applies to transformers and annotators only
  df <- ds$derived_from
  if (is.null(df)) return(list(res("T2", "fail", "no `derived_from` in `_dataset.json`", "record the input corpora (T2)")))
  st <- vapply(df, derived_status, "", dir = dir)
  bad <- st[!st %in% c("ok", "external")]
  list(if (length(bad)) res("T2", "fail", bad, "rebuild from the current inputs, or fix `derived_from`")
       else res("T2", "pass", paste(length(df), "input(s), fingerprints match")))
}

# Status of one `derived_from` entry: "ok", "external" (e.g. the OpenAlex snapshot,
# recorded by source and release), or why it does not check out.
derived_status <- function(e, dir) {
  if (!is.null(e$source)) return(if (!is.null(e$release)) "external" else paste0("`", e$source, "` without `release`"))
  if (is.null(e$path)) return("entry without `path` or `source`")
  if (grepl("^(/|~|[A-Za-z]:)", e$path)) return(paste0("absolute path `", e$path, "`"))
  p <- file.path(dir, e$path)
  if (!dir.exists(p)) return(paste0("input `", e$path, "` not found"))
  if (is.null(e$content)) return(paste0("no `content` recorded for `", e$path, "`"))
  if (!identical(content_fingerprint(p), e$content)) return(paste0("input `", e$path, "` changed since (fingerprint differs)"))
  "ok"
}

check_api <- function(dir, api) {
  if (!isTRUE(api)) return(res("API", "not verified", "skipped (`api = FALSE`)"))
  if (!requireNamespace("openalexAPI", quietly = TRUE)) return(res("API", "not verified", "openalexAPI not installed"))
  msg <- tryCatch({
    suppressMessages(openalexAPI::prepare_corpus(dir, cache_dir = tempfile("oaapi_")))
    NULL
  }, error = function(e) conditionMessage(e))
  if (is.null(msg)) res("API", "pass", "`prepare_corpus()` builds the database")
  else res("API", "fail", paste("`prepare_corpus()` fails:", msg), "make the corpus readable by openalexAPI")
}
