# Compliance report: openalexImportZenodo

- **Standard:** STANDARD.md 0.1 (draft)
- **Package:** openalexImportZenodo 0.0.0.9000 · openalexPro/openalexImportZenodo @ dev 60f58cd
- **Kind:** writer
- **Date:** 2026-11-27
- **Verdict:** not compliant (7 MUST, 2 SHOULD open)

**Corpus checked:** built with the package's own `zenodo_build()` and
`zenodo_as_corpus()` from the stored IPBES community records (`ipbes_zenodo/raw/`,
567 deposits, 704 links), in a scratch folder. `openalexAPI::prepare_corpus()` builds
a database from it without errors. The existing `ipbes_zenodo/corpus/` (built
2026-11-26) has no `_query.json`; a rebuild with the current code adds it.

## Results

| Rule | Level | Status | Evidence | Fix |
|---|---|---|---|---|
| L1 | MUST | ✓ | `corpus/query=zenodo/data.parquet` | |
| L2 | MUST | ✓ | `query=<name>/` for corpus and links (`R/build.R:84-85`) | |
| L3 | MUST | ✓ | `<name>` checked by `check_name()` | |
| L4 | MUST | ✓ | only `_query.json`, `_query.html` besides Parquet | |
| L5 | MAY | n/a | reader rule | |
| L5a | MUST | n/a | reader rule | |
| L5b | MUST | ✓ | no `query` column in the files (DuckDB shows one only through Hive auto-detection) | |
| L5c | MUST | n/a | reader rule | |
| S1 | MUST | ✓ | `id`, `title`, `display_name` | |
| S2 | MUST | ✓ | OpenAlex names and structures (`authorships`, `primary_location`, `ids`, …) | |
| S3 | SHOULD | ✓ | `publication_year` INTEGER, `publication_date` DATE; others absent | |
| S4 | MAY | ✓ | plain-text `abstract` | |
| S5 | MUST | ✓ | all 21 extra columns are `zenodo_*` | |
| S5a | MUST | ✓ | `abstract` used with its reserved meaning | |
| S6 | MUST | ✓ | 567 rows, 0 duplicate `id`s | |
| D1 | MUST | ✗ | no `_dataset.json` written | write it in `zenodo_build()` / `zenodo_as_corpus()` |
| D2 | MUST | ✗ | (no file) | keep it free of timestamps: `_query.json`'s `started`/`finished` must not go into it |
| D3 | MUST | ✗ | (no file) | `{"standard":"0.1","type":"works","writer":{"package":"openalexImportZenodo","version":…,"prefix":"zenodo"},"partition_keys":["query"],"id_format":"zenodo:<conceptrecid>"}` |
| D4 | MUST | n/a | reader rule | |
| Q1 | MUST | ✓ | `_query.json` copied into each partition (`R/build.R:89`, `write_split()`) | |
| Q2 | SHOULD | ✓ | `source` and `build` settings are enough for `zenodo_update()` | |
| Q3 | SHOULD | ✓ | `_query.html` | |
| Q4 | MUST | ✓ | `zenodo_as_corpus()` copies whole partitions | |
| I1 | MUST | n/a | no OpenAlex records | |
| I2 | MUST | ✓ | all 567 ids are `zenodo:<n>` | |
| I3 | MUST | ✗ | no `id_format` (no `_dataset.json`) | see D3 |
| I4 | SHOULD | ✓ | `ids.doi`, `ids.zenodo` | consider `ids.zenodo` = `zenodo:<n>` instead of the record URL |
| I5 | MUST | ✓ | prefix `zenodo` registered | |
| I6 | SHOULD | ✓ | `https://doi.org/…`, 0 upper-case | |
| P1 | MUST | ✓ | `openalexImport<Source>` | |
| P2 | MUST/SHOULD | ✗ (SHOULD) | does not call openalexPro (no floor needed); no `Config/openalexPro/standard` | add `Config/openalexPro/standard: 0.1` |
| P3 | MUST | ✓ | `zenodo_as_corpus(project_folder, out, name)` (`R/update.R:47`) | |
| P4 | MUST | ✗ | no test runs `openalexAPI::prepare_corpus()` | add one on the fixture corpus; openalexAPI in Suggests |
| P5 | MUST | n/a | not a reader | |
| P6 | MUST/SHOULD | ✗ (SHOULD) | MIT ✓, `repos.tsv` ✓, `dev` ✓; no `CITATION.cff`, no pkgdown site | add both (planned with the first release) |
| K1 | MUST | ✗ | required columns ✓; extra columns `relation`, `relation_declared`, `scheme`, `related_type`, `declared_on` have no prefix | rename to `zenodo_*` |
| K2 | MUST | ✓ / not verified | `parquet_split = "none"` writes a file even with zero rows; numeric and partitioned splits write none | write an empty file with the schema in those modes |
| K3 | MUST | ✗ | 14 citation links between corpus works also in `referenced_works` | drop them from the link table, or the standard allows it (see Notes) |
| K4 | MUST | ✗ | `origin`/`target` outside the corpus are DOI URLs (`https://doi.org/…`) | standard gap, see Notes |
| A1 | MUST | n/a | writer only; reads no corpus (§8) | |
| A2 | MUST | n/a | writer only; reads no corpus (§8) | |
| A3 | MUST | n/a | writer only; reads no corpus (§8) | |
| T1 | MUST | n/a | writer only; reads no corpus (§8) | |
| T2 | MUST | n/a | writer only; reads no corpus (§8) | |
| T3 | MUST | n/a | writer only; reads no corpus (§8) | |
| N1 | MUST | n/a | writer only; reads no corpus (§8) | |
| N2 | MUST | n/a | writer only; reads no corpus (§8) | |
| N3 | MUST | n/a | writer only; reads no corpus (§8) | |
| C1 | MUST | n/a | writer only; reads no corpus (§8) | |
| C2 | MUST | n/a | writer only; reads no corpus (§8) | |

## Onboarding steps

- [x] Writer prefix registered in STANDARD.md I5 (`zenodo`)
- [ ] `Config/openalexPro/standard: 0.1` in DESCRIPTION
- [x] Row in `repos.tsv` (dependency order) and entry in `ecosystem.md`
- [ ] Test running `openalexAPI::prepare_corpus()` on a small corpus (P4)
- [ ] Landing page / org profile / r-universe — only once out of alpha

## Notes

- **K4 is a gap in the standard.** A link to something outside the corpus has no §5 ID;
  a DOI (or another URL) is the natural value. K4 should say: IDs of corpus records
  follow §5, others are a DOI or URL.
- **K3 vs. openalexAPI's `cites:` filter.** Zenodo puts in-corpus citations in
  `referenced_works` *and* the link table, so the link table is complete on its own.
  Decide whether K3 means "must not repeat" or "need not repeat".
- **`_query.json` carries timestamps** (`started`, `finished`). Fine under D2 (which only
  covers `_dataset.json`), but it changes on every update, so `targets` pipelines
  that track the whole folder rebuild. Worth a line in the standard.
