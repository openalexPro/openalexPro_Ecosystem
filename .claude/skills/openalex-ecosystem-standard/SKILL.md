---
name: openalex-ecosystem-standard
description: Check an openalexPro ecosystem package (R package source) or a corpus folder (Parquet works + _dataset.json/_query.json) against STANDARD.md, the ecosystem's corpus and package standard, and report each rule it breaks. Also use when writing or changing a package that writes, reads, transforms or annotates corpora (openalexImport*/openalexExport*, openalexPro, openalexAPI, openalexSnowball, openalexVectorComp, openalexConvert, openalexSnapshot), or when the user asks whether something "follows the standard" or "is ecosystem compatible".
---

# openalexPro ecosystem standard check

The rules live in `STANDARD.md` at the root of the openalexPro_Ecosystem repo
(`~/GitHub/openalexPro_Ecosystem/STANDARD.md`). **Read it first, every time**; this
skill only says how to check. Rule ids (L1, S1, D3, …) come from it, so cite them.

## What to check

Decide from the target:

- **A corpus folder** (contains `*.parquet` below it): check §1–§5 and §7 on the data.
- **A package source** (has `DESCRIPTION`): check §6, then read the code that writes
  (or reads) corpora and check it would produce (or accept) §1–§5. If a sample corpus
  is cheap to make (a test fixture, `inst/extdata`), build one and check it as a corpus.
- **Its kind (§8)**: writer (imports), consumer, transformer, annotator — often more
  than one. Writers and transformers: §1–§7. Every package that reads a corpus: A1–A3.
  Plus T1–T3, N1–N3 or C1–C2 for its kind.
- **An annotation folder** (`_dataset.json` with `"type": "annotation"`): N1–N3.

## Corpus checks (DuckDB from R; never modify the corpus)

```r
con <- DBI::dbConnect(duckdb::duckdb())
f <- list.files(corpus, "\\.parquet$", recursive = TRUE, full.names = TRUE)
```

- L2/L3: top-level subfolders are `query=<name>` with a valid name.
- L4: `list.files(corpus, recursive = TRUE, all.files = TRUE)` — anything not
  `*.parquet` must start with `_`.
- S1: per file, `DESCRIBE SELECT * FROM read_parquet('<f>')` has `id` and
  `title`/`display_name`.
- L5b: no data column is named like a partition key (`query`, `query_l2`, …).
- S3: types of the listed columns (`union_by_name = true` across files; flag columns
  whose type differs between files).
- S6: `count(*) - count(DISTINCT id)` per partition is 0.
- D1–D3: `_dataset.json` exists, parses, has the required fields, and contains no
  timestamp-like value or absolute path. Missing → report, but it is not a reader error (D4).
- Q1/Q3: `_query.json` (required) and `_query.html` (should) in each partition.
- I1/I2/I3: sample `id`s match `^https://openalex\.org/W\d+$` or
  `^[a-z0-9]+(:[^/:]+)+$`; the first part is the writer's registered prefix (I5) and
  the shape matches `id_format` in `_dataset.json`.
- S5/S5a: every column that is not an OpenAlex works field starts with
  `<prefix>_` or is a reserved name.
- K1/K2: `links/query=<name>/*.parquet` exists next to the corpus for every partition,
  with the K1 columns (zero rows is fine).
- The real test: `openalexAPI::prepare_corpus(corpus, cache_dir = tempfile())` succeeds
  (when openalexAPI is installed). Use a temp `cache_dir` so nothing is left in the project.

## Package checks

- P1 name, P2 `openalexPro (>= …)` floor (and `Config/openalexPro/standard`), P3
  `<source>_as_corpus()` exported (import packages), P4 test calling
  `prepare_corpus()`, P5 export packages do not require `_dataset.json` or
  openalexPro-only columns, P6 licence + `repos.tsv` row.
- Grep the writer code for: the partition key it writes, files it puts in the corpus
  folder, whether it writes `_dataset.json` / `_query.json` / `_query.html`, and how it
  forms `id`.

## §8 checks (analysis and processing packages)

Mostly code review; run the package on a non-OpenAlex corpus where you can.

- A1: grep for writes (`write_parquet`, `COPY … TO`, `file.copy`, `unlink`, `dir.create`)
  whose target can be inside the input corpus folder.
- A2: run the package's main reader on a compliant corpus from another writer (e.g. one
  built by openalexImportZenodo, `zenodo:` IDs, no `abstract_inverted_index`) in the
  scratchpad. Errors, or records lost without a message, are failures.
- A3: grep for ID handling that assumes OpenAlex form: `"^W"`, `openalex.org/W`,
  `sub(".*/", …)` followed by a `W` check, `startsWith(id, "https://openalex.org")`.
- T2/N2: `_dataset.json` of the output has `derived_from` (relative path + SHA-256 of
  the input's `_dataset.json`), and N2's method/settings; nothing run-dependent.
- T3: relations written as `links/` with the K1 columns, not as a package-own table.
- N1/N3: annotation output under `<project>/<prefix>_<name>/query=<name>/`, keyed by
  `id`, other columns prefixed.
- C1: feed a corpus with non-OpenAlex records; each is converted or reported.

## Report

One table, most serious first: rule id, MUST/SHOULD, what was found (file:line or
path), the fix. Then one line: compliant / not compliant with STANDARD.md version X.
Report only; change code only if the user asks.

If the standard and openalexPro or openalexAPI disagree, say so: the standard is
what gets fixed, through the issue in openalexPro_Ecosystem, not silently worked around.
