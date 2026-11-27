# The rule data must match STANDARD.md (only when run inside the ecosystem repo).
std <- function() {
  f <- normalizePath(test_path("../../../../STANDARD.md"), mustWork = FALSE)
  if (!file.exists(f)) skip("STANDARD.md not found (not run inside openalexPro_Ecosystem)")
  readLines(f, encoding = "UTF-8")
}

test_that("rule ids match STANDARD.md", {
  s <- std()
  ids <- unique(unlist(regmatches(s, gregexpr("(?<=^- \\*\\*|^  - \\*\\*)[A-Z][0-9]+[a-z]?(?=\\*\\*)", s, perl = TRUE))))
  expect_setequal(setdiff(standard_rules()$rule, "API"), ids)
})

test_that("prefixes and schemes match STANDARD.md", {
  s <- paste(std(), collapse = "\n")
  i5 <- regmatches(s, regexpr("(?s)\\*\\*I5\\*\\*.*?\\n- \\*\\*I6", s, perl = TRUE))
  pre <- sub("^\\s*\\| `([a-z0-9]+)`.*$", "\\1", grep("^\\s*\\| `[a-z0-9]+`", strsplit(i5, "\n")[[1]], value = TRUE))
  expect_setequal(standard_prefixes()$prefix, pre)
  i7 <- regmatches(s, regexpr("(?s)\\*\\*I7\\*\\*.*?\\n\\n", s, perl = TRUE))
  sch <- setdiff(gsub("`", "", unlist(regmatches(i7, gregexpr("`[a-z0-9]+`", i7)))), "ids")
  expect_setequal(standard_schemes(), sch)
  expect_equal(standard_version(), sub("^\\*\\*Version:\\*\\* ([0-9.]+).*$", "\\1", grep("^\\*\\*Version", std(), value = TRUE)))
})

test_that("section headings exist in STANDARD.md", {
  h <- sub("^#+ ", "", grep("^## ", std(), value = TRUE))
  s <- openalexStandard:::sections()
  expect_true(all(stats::na.omit(s$heading) %in% h))
})
