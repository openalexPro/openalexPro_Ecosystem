# Shared helpers: rule data, result rows, DuckDB, small file utilities.

ext <- function(f) system.file("extdata", f, package = "openalexStandard", mustWork = TRUE)
read_ext <- function(f) utils::read.csv(ext(f), stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8")

#' Version of STANDARD.md the checks implement
#' @return A string, e.g. `"0.1"`.
#' @export
standard_version <- function() jsonlite::read_json(ext("standard.json"))$standard

#' Rules of STANDARD.md, as known to the checks
#'
#' One row per rule: `rule`, `level` (MUST/SHOULD/MAY), `section`, `kinds`
#' (`;`-separated: writer, consumer, transformer, annotator), `automated`
#' (yes/partly/manual) and a one-line `summary`. The pseudo-rule `API` is
#' openalexAPI's `prepare_corpus()` on the corpus.
#' @return A data frame.
#' @export
standard_rules <- function() read_ext("rules.csv")

#' Registered prefixes (STANDARD.md I5) and identifier schemes (I7)
#' @return `standard_prefixes()`: data frame `prefix`, `package`, `kind`.
#'   `standard_schemes()`: character vector.
#' @export
standard_prefixes <- function() read_ext("prefixes.csv")

#' @rdname standard_prefixes
#' @export
standard_schemes <- function() read_ext("schemes.csv")$scheme

works_fields <- function() read_ext("works_fields.csv")
reserved_columns <- function() read_ext("reserved.csv")

# One result row. `level` defaults to the rule's level in rules.csv.
res <- function(rule, status, evidence = "", fix = "", level = NULL) {
  status <- match.arg(status, c("pass", "fail", "n/a", "not verified", "manual"))
  if (is.null(level)) {
    r <- standard_rules()
    level <- r$level[match(rule, r$rule)]
  }
  data.frame(rule = rule, level = level, status = status,
             evidence = paste(evidence, collapse = "; "), fix = fix,
             stringsAsFactors = FALSE)
}

bind <- function(...) {
  x <- Filter(Negate(is.null), c(...))
  do.call(rbind, x)
}

# Shorten a list of offending values for the evidence column.
show <- function(x, n = 5) {
  x <- unique(x)
  s <- paste0("`", utils::head(x, n), "`", collapse = ", ")
  if (length(x) > n) s <- paste0(s, ", \u2026 (", length(x), " in all)")
  s
}

duck <- function() {
  con <- DBI::dbConnect(duckdb::duckdb())
  DBI::dbExecute(con, "SET enable_progress_bar = false")
  con
}
q <- function(con, sql) DBI::dbGetQuery(con, sql)
lit <- function(x) paste0("'", gsub("'", "''", x, fixed = TRUE), "'")
lit_list <- function(x) paste0("[", paste(lit(x), collapse = ", "), "]")

# Parquet files below `dir`, skipping `_`/`.`-prefixed files and folders (as DuckDB and arrow do).
parquet_files <- function(dir) {
  f <- list.files(dir, "\\.parquet$", recursive = TRUE, full.names = TRUE)
  rel <- substring(f, nchar(dir) + 2)
  f[!grepl("(^|/)[_.]", rel)]
}

# `query=<name>` folders directly below `dir`.
partitions <- function(dir) {
  d <- list.dirs(dir, recursive = FALSE, full.names = FALSE)
  d[grepl("^query=", d)]
}

read_json_or_null <- function(f) {
  if (!file.exists(f)) return(NULL)
  tryCatch(jsonlite::read_json(f), error = function(e) structure(list(), parse_error = conditionMessage(e)))
}

# Does each name start with `<prefix>_`? With `prefix = NULL`, any registered prefix counts.
has_prefix <- function(x, prefix = NULL) {
  pre <- prefix %||% standard_prefixes()$prefix
  if (!length(x)) return(logical())
  Reduce(`|`, lapply(pre, function(p) startsWith(x, paste0(p, "_"))))
}

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

sha256_file <- function(f) unname(tools::sha256sum(f))

# Regex from an id template: `<...>` placeholders match one part (no `/`); the
# last placeholder may also contain `:`.
id_format_regex <- function(fmt) {
  parts <- regmatches(fmt, gregexpr("<[^>]*>", fmt), invert = TRUE)[[1]]
  esc <- gsub("([][{}()+*^$|\\\\.?])", "\\\\\\1", parts)
  n <- length(esc) - 1L
  if (n == 0L) return(paste0("^", esc, "$"))
  ph <- c(rep("[^/:]+", n - 1L), "[^/]+")
  paste0("^", paste0(c(rbind(esc[-length(esc)], ph)), collapse = ""), esc[length(esc)], "$")
}
