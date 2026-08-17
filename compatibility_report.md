# openalexPro Compatibility Report

**Date:** 2026-08-17
**openalexPro version under test:** 0.10.5 (installed = source `main`)
**openalexSnapshot:** 0.0.2, pinning `openalex-core` at tag **v0.5.0** (`features = ["conversion"]`)
**openalex-snapshot (Rust CLI):** v0.6.0 — parquet-native since 2026-06-29
**R:** 4.6.1 · **pandoc:** 3.10.2 · **platform:** macOS (arm64)

Scope: (1) did recent openalexPro changes break the dependent packages,
(2) does `openalexSnapshot` produce the same parquet schema as `openalexPro`,
(3) does `openalexSnapshot` consume the official OpenAlex parquet download or the
legacy JSON snapshot, and
(4) is the Rust backend still warranted for indexing and extraction.

`openalexASReview` is excluded at the maintainer's request (likely to be retired).

---

## Part 1 — Did recent openalexPro changes break the dependents?

**Verdict: No.** No breakage attributable to openalexPro.

### 1.1 Which packages are actually dependents

| Package | `openalexPro::` calls in `R/` | Declared in DESCRIPTION | Real dependent? |
|---|---|---|---|
| openalexSnowball | 12 | `Imports: openalexPro (>= 0.10.5)` + `import(openalexPro)` | yes |
| openalexConvert | 1 | `Imports: openalexPro` (**no version floor**) | yes |
| openalexSnapshot | 0 | — | no |
| openalexStemCheck | 0 | — | no |
| openalexVectorComp | 0 | — | no |
| openalexASReview | 14 | **not listed at all** | excluded from this report |

### 1.2 API surface check

Every openalexPro symbol referenced by a dependent is still exported, and every
named argument at every call site matches the current formals.

| Package | Symbols used | Exported? | Args match? |
|---|---|---|---|
| openalexConvert | `extract_doi` | yes | yes |
| openalexSnowball | `pro_query`, `pro_request`, `pro_request_parquet`, `read_corpus` | yes | yes |

openalexSnowball's `import(openalexPro)` (full-namespace import) produces **no
masking clashes** — no object it defines shares a name with an openalexPro export.

The 0.10.x **breaking changes** touch nothing either package calls:

* `snapshot_to_parquet()`, `build_corpus_index()`, `lookup_by_id()` moved to
  openalexSnapshot (now error-throwing stubs in openalexPro)
* `pro_request_parquet_R()` and `pro_fetch_R()` removed
* `pro_request_jsonl_R()` / `pro_request_jsonl_parquet()` deprecated

### 1.3 Test suites

**openalexSnowball — PASS.** Exit code 0, no failures, warnings or skips. The run
genuinely exercises the openalexPro path (it converted JSON→Parquet through
`pro_request_parquet()` during the run).

**openalexConvert — 9 failures, none caused by openalexPro.**

All nine are in `tests/testthat/test-001-corpus_csl_pandoc.R` (lines 126, 192,
381) — golden-file comparisons against `tests/fixtures/corpus_bibtex` and
`tests/fixtures/corpus_biblatex`.

Evidence that openalexPro is not the cause:

1. The **CSL-JSON vs fixture** comparison at `test-001-corpus_csl_pandoc.R:47`
   **passes**. That is exactly where `openalexPro::extract_doi()` output lands,
   via `.normalize_doi()` at `R/corpus_to_csljson.R:430`. Generated CSL JSON is
   identical to the stored fixture ⇒ openalexPro's contribution is unchanged.
2. Only the **pandoc-rendered** bibtex/biblatex output differs, in two ways that
   are both pandoc writer changes:
   * escaping/rewrapping — `Bay<U+00F3>n` → `Bay\textless U+00F3\textgreater n`
   * `doi = {…}` now emitted in bibtex (stored fixture has 0 `doi = ` lines;
     the stored CSL fixture already has 66 `"DOI"` entries)
3. The tests self-document the hazard — each carries
   `skip_on_ci()  # exact-text comparison is Pandoc-version sensitive`.
4. `R/extract_doi.R` last changed functionally in `cfe972a`; the only commit
   touching it since (`651d126`) was a lint line-reflow.

**Conclusion:** stale golden fixtures + newer local pandoc (3.10.2), not a
regression. Fix by regenerating the bibtex/biblatex fixtures, or by relaxing the
comparison to be pandoc-version tolerant.

### 1.4 Side findings (not breakage, but worth fixing)

* **`oa_cache_schema()` does not exist.** `NEWS.md` for 0.10.4 advertises it as a
  new function that copies schemas from a snapshot metadata directory. It is
  absent from `R/`, `NAMESPACE` and `man/`.
* **`build_corpus_index` and `lookup_by_id` are exported by both packages.**
  openalexPro exports error-throwing stubs; openalexSnapshot exports the working
  versions. Attaching both produces masking warnings, and — depending on attach
  order — a user can get the stub.
* **openalexConvert has no version floor** on openalexPro
  (`openalexConvert/DESCRIPTION:22`). It will install against 0.4.x.
* **`Additional_repositories:` is inconsistent** — populated in openalexConvert
  and openalexSnapshot, empty in openalexPro and openalexSnowball.
* **openalexSnowball version looks confusing**: source `Version: 0.10.1` while
  requiring `openalexPro (>= 0.10.5)`. Installed copy is 0.1.2 (stale).

---

## Part 2 — Does openalexSnapshot return the same schema as openalexPro?

**Verdict: the declared schemata are identical; the actual output is not.**

### 2.1 Declared schemata — identical (21/21)

openalexPro's bundled `inst/extdata/schemata/*.csv` are byte-identical to
openalexSnapshot's `unified_schema.csv`
(`/Volumes/openalex/openalex-snapshot_metadata/<entity>/schemata/`) for **all 21
entity types** — same column names, same types, same order.

```
authors awards concepts continents countries domains fields funders
institution-types institutions keywords languages licenses publishers sdgs
source-types sources subfields topics work-types works
→ 21/21 identical (0 column diffs, 0 type diffs, same order)
```

The openalexPro bundle is effectively a copy of the snapshot metadata schemata.

### 2.2 Actual parquet output — differs

Compared for `works`:

* **openalexPro:** `pro_request_parquet()` over
  `openalexPro/tests/fixtures/keypaper_json` (2 API pages, 501 records)
* **openalexSnapshot:** `/Volumes/openalex/parquet/works/updated_date=2016-06-24`

> **Provenance of the snapshot side — important.** This corpus was produced by the
> **legacy JSON→parquet conversion**, not by the official parquet download. Evidence:
> no `works_aws/` sibling directory, no `parquet/manifest.json`, and `works/` is dated
> **2026-05-23** — before the parquet-native release of 2026-06-29. See Part 3. The
> differences below therefore describe *openalexPro's API path vs a JSON-converted
> corpus*; the official parquet download may differ again, and has not been tested.

| | openalexPro (API→parquet) | openalexSnapshot (snapshot→parquet) |
|---|---|---|
| columns | **54** | **51** |
| shared columns | 45 | 45 |
| shared but **different type** | **14** | |
| partitioning | `query=…` / `query_l2=…` (hive, from dir depth) | `updated_date=…` (hive) |

#### Columns only in openalexPro (9)

`abstract_inverted_index_v3`, `cited_by_api_url`, `datasets`, `fulltext_origin`,
`grants`, `institution_assertions`, `page`, `type_crossref`, `versions`

#### Columns only in openalexSnapshot (6)

`authors_count`, `awards`, `funders`, `has_content`, `institutions`, `is_xpac`

#### The consequential difference — list columns stored as JSON strings

In the snapshot corpus these are **JSON-encoded VARCHAR**, not native lists:

| column | openalexPro | openalexSnapshot |
|---|---|---|
| `referenced_works` | `VARCHAR[]` | `VARCHAR` — e.g. `'["https://openalex.org/W…"]'` |
| `related_works` | `VARCHAR[]` | `VARCHAR` |
| `indexed_in` | `VARCHAR[]` | `VARCHAR` |
| `corresponding_author_ids` | `VARCHAR[]` | `VARCHAR` |
| `corresponding_institution_ids` | `VARCHAR[]` | `VARCHAR` |

This is the difference most likely to bite: `unnest(referenced_works)` works
directly on openalexPro output but needs an explicit `::VARCHAR[]` cast on
snapshot output. Any citation-graph query written against one corpus will not
run unchanged against the other.

This JSON-string encoding looks like an **artefact of the JSON→parquet conversion**
rather than an inherent property of snapshot data. The officially published parquet
may carry proper `LIST` types here — **untested**, see Part 3.

**Verified mitigations:**

* `snapshot_col::VARCHAR[]` round-trips cleanly — DuckDB strips the JSON quoting
  and yields the same bare OpenAlex IDs.
* `read_parquet([pro, snap], union_by_name = true)` **succeeds** (501 + snapshot
  rows). DuckDB unifies the conflicting columns to `VARCHAR[]`, and `unnest()`
  then works across the union.
* Caveat: `arrow::open_dataset()` — which `read_corpus()` uses — is stricter than
  DuckDB here, so the DuckDB result does not guarantee the arrow path works.

#### Other type differences on shared columns

| column | openalexPro | openalexSnapshot |
|---|---|---|
| `updated_date` | `VARCHAR` | `DATE` |
| `created_date` | `DATE` | `TIMESTAMP` |
| `apc_paid` | `STRUCT(value BIGINT, currency VARCHAR, value_usd BIGINT)` | `…DOUBLE…DOUBLE` |
| `ids` | has `pmcid`; order `openalex,doi,mag,pmid,pmcid` | no `pmcid`; order `openalex,mag,doi,pmid` |
| `open_access` | field order `is_oa,oa_status,oa_url,any_repository_has_fulltext` | `is_oa,oa_status,any_repository_has_fulltext,oa_url` |
| `authorships` | struct field order differs | struct field order differs |
| `primary_location`, `locations`, `best_oa_location` | carry `is_indexed_in_scopus` | carry `id`, `raw_source_name`, `raw_type`, `provenance` |

Both sides append the same two enrichment columns: **`abstract`** and
**`citation`**. openalexPro additionally appends **`page`**.

### 2.3 Why the bundled schema does not close the gap

`.prr_apply_baseline()` (`openalexPro/R/pro_request_parquet.R:267`) overrides a
column **only when DuckDB inferred it as `JSON`**:

```r
if (!grepl("\\bJSON\\b", rt)) next
```

It is a narrow repair for ambiguous columns, not schema enforcement. That is why
14 of the 43 shared columns in openalexPro's own output do not match openalexPro's
own bundled schema. This is the design, not a defect.

**Latent hazard (code-path reading, not reproduced):** the bundle is the
*snapshot* schema applied to *API* data. If a sampled API page has
`referenced_works` all-null, DuckDB infers `JSON`, the baseline fires, and the
column becomes `VARCHAR` (the snapshot type) instead of `VARCHAR[]` — a different
type from other pages of the same query. Six bundle columns (`authors_count`,
`awards`, `funders`, `has_content`, `institutions`, `is_xpac`) also describe
fields the API never returns.

### 2.4 Caveat on the comparison

openalexPro's column set reflects what those two fixture API pages returned. A
query using `select=` returns fewer columns. The 9 "openalexPro-only" columns are
API-model fields, and the 6 "snapshot-only" columns are snapshot-model fields —
these are genuine data-model differences between the two OpenAlex sources, not
configuration drift.

The snapshot side is a **May-2026 JSON-converted corpus** (see the provenance note
in §2.2). That comparison has now been re-run against the official parquet — see
§2.5, which supersedes §2.2 for anyone building on the official download.

### 2.5 Official parquet download — measured (supersedes §2.2)

Downloaded `s3://openalex/data/parquet/works/updated_date=2016-06-24/part_0000.parquet`
(3.6 MB, 2,439 rows) — deliberately the **same partition** as the legacy corpus in
§2.2 — plus `domains` (9 KB).

**The JSON-string list columns were a conversion artefact. Confirmed.**

| column | official parquet | legacy JSON-converted | openalexPro (API) |
|---|---|---|---|
| `referenced_works` | **`VARCHAR[]`** | `VARCHAR` | `VARCHAR[]` |
| `related_works` | **`VARCHAR[]`** | `VARCHAR` | `VARCHAR[]` |
| `indexed_in` | **`VARCHAR[]`** | `VARCHAR` | `VARCHAR[]` |
| `corresponding_author_ids` | **`VARCHAR[]`** | `VARCHAR` | `VARCHAR[]` |
| `corresponding_institution_ids` | **`VARCHAR[]`** | `VARCHAR` | `VARCHAR[]` |
| `institutions` | `STRUCT(...)[]` | `JSON[]` | — |

The official parquet uses **native list types and agrees with openalexPro's API
path**. The `::VARCHAR[]` cast workaround discussed in §2.2 is therefore *only*
needed for the legacy corpus, and becomes unnecessary once the migration in Part 4
lands. This removes the strongest argument for a corpus-normalisation helper.

**Column set:** official works has **49 columns — exactly the bundled `works.csv`
column set**, no additions, no omissions. The legacy corpus's two extra columns are
`abstract` and `citation`, i.e. the enrichment. Nothing else differs by name.

**But 25 of those 49 columns differ in declared type from the bundled schema:**

`ids`, `indexed_in`, `publication_year`, `authorships`, `authors_count`,
`corresponding_author_ids`, `corresponding_institution_ids`, `primary_topic`,
`topics`, `keywords`, `concepts`, `locations_count`, `institutions`,
`countries_distinct_count`, `institutions_distinct_count`, `referenced_works`,
`referenced_works_count`, `related_works`, `abstract_inverted_index`,
`cited_by_count`, `counts_by_year`, `apc_list`, `cited_by_percentile_year`,
`created_date`, `updated_date`

Most are width differences introduced by the old converter (`INTEGER` vs `BIGINT`,
`FLOAT` vs `DOUBLE`). Three are structural:

| column | bundled schema | official parquet |
|---|---|---|
| `ids` | `STRUCT(openalex, mag, doi, pmid)` | `MAP(VARCHAR, VARCHAR)` |
| `abstract_inverted_index` | `MAP(VARCHAR, BIGINT[])` | `VARCHAR` (JSON string) |
| `institutions` | `JSON[]` (legacy) | `STRUCT(...)[]` |

### 2.6 DEFECT — openalexPro's bundled schemata are stale (to fix)

**Status:** open · **Severity:** medium · **Location:**
`openalexPro/inst/extdata/schemata/*.csv`, `openalexPro/R/oa_schema.R`,
`openalexPro/R/pro_request_parquet.R`

**What is wrong.** The 21 bundled schema CSVs are documented as being "inferred from
the complete OpenAlex snapshot" (NEWS 0.10.4, `oa_schema()` docs). They were in fact
inferred from the **legacy JSON-converted** snapshot. They do not describe the
official parquet that OpenAlex now publishes. For `works`, 25 of 49 columns carry the
wrong type — see the tables in §2.5.

**Why it happened.** The bundle was copied from
`/Volumes/openalex/openalex-snapshot_metadata/<entity>/schemata/unified_schema.csv`,
which the old converter wrote. Verified: the bundle is byte-identical to those files
for all 21 entities (§2.1). Upstream then began publishing parquet natively with
different (and more correct) types; the bundle was never regenerated.

**Impact.**

* Anyone treating the bundle as documentation of the OpenAlex parquet schema is
  misled — most consequentially on `abstract_inverted_index` (`MAP` vs `VARCHAR`) and
  `ids` (`STRUCT` vs `MAP`).
* Via `schema = "auto"`, the baseline is applied to **API** data whenever DuckDB
  infers a column as `JSON` (`.prr_apply_baseline()`, `pro_request_parquet.R:267`). A
  stale, snapshot-derived baseline can therefore impose a wrong type on API output —
  e.g. setting `referenced_works` to `VARCHAR` when the API natively yields
  `VARCHAR[]`, producing inconsistent types across pages of one query. Code-path
  reading; not reproduced.
* The 6 columns the bundle carries that the API never returns (`authors_count`,
  `awards`, `funders`, `has_content`, `institutions`, `is_xpac`) are inert but
  misleading.

**Fix — pick one:**

1. **Regenerate from upstream** (preferred if `schema = "auto"` is kept). Derive each
   `<entity>.csv` from `s3://openalex/data/parquet/<entity>/`, e.g.
   `DESCRIBE SELECT * FROM read_parquet('<entity>/**/*.parquet')`, and correct the
   docstring to say "official parquet snapshot" with the snapshot date recorded.
2. **Retire the baseline entirely.** §2.5 shows the official parquet already carries
   correct, unambiguous types, so the ambiguity `schema = "auto"` exists to repair is
   largely a legacy-converter problem. Removing it would delete
   `inst/extdata/schemata/`, `.prr_apply_baseline()`, `.resolve_baseline()` and the
   `schema` argument.

Option 2 is consistent with the Part 4 migration; option 1 is the lower-risk interim
step. Either way the `oa_schema()` documentation must stop claiming the schemata come
from the complete snapshot.

**Related:** the non-existent `oa_cache_schema()` (§1.4) belongs to this same
subsystem — resolve both together.

---

## Part 3 — Input format: JSON snapshot vs official parquet download

**Verdict: `openalexSnapshot` works from the old JSON snapshot. It does not consume
the official parquet download — and the directory layout it expects no longer
exists upstream.**

### 3.1 What openalexSnapshot expects

`snapshot_to_parquet()` performs schema inference over, and conversion of,
`.json.gz` files under `<snapshot_dir>/data/`
(`openalexSnapshot/R/snapshot_to_parquet.R:3`, `:13`; the vignette tree shows
`data/<entity>/updated_date=…/part_000.json.gz`). Its Rust backend is pinned to the
pre-parquet era:

```toml
openalex-core = { git = "https://github.com/openalexPro/openalex-snapshot.git",
                  tag = "v0.5.0", features = ["conversion"] }
```

### 3.2 The Rust CLI has already migrated

`~/GitHub/openalex-snapshot` went **parquet-native at v0.6.0 (2026-06-29)**. From its
`NEWS.md`:

* *"OpenAlex now publishes the snapshot natively in parquet (`s3://openalex/data/parquet/`),
  so the tool is now a parquet-native pipeline: download → verify_download → enrich →
  index → extract. The JSON→parquet `convert` step is obsolete."*
* Deleted the `convert`, `verify_convert`, `schema` and `verify_schema` subcommands
  and ~3,600 lines of JSON-pipeline machinery.
* DuckDB removed entirely; `enrich` is now pure Rust (verified byte-identical to the
  previous DuckDB SQL across a full 142,844-row works partition, ~12× faster);
  binary shrank from ~100 MB+ to ~11 MB.
* v0.6.0 moved the parquet pipeline ops into `openalex-core`
  (`parquetio`, `manifest`, `enrich`, `index`, `extract`) explicitly so that *"the CLI
  and the `openalexPro` R package (via `extendr`) call one shared implementation and
  produce identical results."*
* `openalex-core::conversion` was **retained solely for the R package** — NEWS notes
  the profile/conversion modules are kept "(R package)".

So the R package is parked on a code path the CLI has retired, and the core keeps a
module alive only to serve it. The v0.6.0 refactor appears to have been done *in
anticipation* of the R side migrating; that migration has not happened.

### 3.3 Upstream bucket state (verified live, 2026-08-17)

```
s3://openalex/data/
├── jsonl/     21 datasets + manifest.json   (updated 2026-06-27)
└── parquet/   21 datasets + manifest.json   (updated 2026-06-27)
```

Two consequences:

1. **The parquet snapshot is real and current** — all 21 entity types, with a
   published `manifest.json` (1,158,613 bytes) enabling per-file verification.
2. **The layout openalexSnapshot expects is gone.** It looks for
   `data/<entity>/…json.gz`; upstream is now `data/jsonl/<entity>/updated_date=…/`.
   The old `data/<entity>/` prefix no longer exists. Even staying on the legacy path
   requires a path fix, not merely a re-download.

Sizes for a spot check: `s3://openalex/data/parquet/domains/updated_date=2026-06-26/part_0000.parquet`
is **9,079 bytes** — a cheap way to compare the official parquet schema against the
bundled `domains.csv`.

### 3.4 Implications

* **openalexSnapshot's core purpose is obsolete for new users.** OpenAlex ships
  parquet directly; a JSON→parquet converter is no longer needed to build a corpus.
* **The local `/Volumes/openalex/parquet` corpus is legacy.** It predates the
  parquet-native release and was built by the old converter — which is why Part 2's
  comparison is against JSON-converted data.
* **The package cannot currently reproduce its own documented workflow** end-to-end
  from upstream, because the documented S3 source layout has moved.

---

## Part 4 — Is the Rust implementation still needed?

**Verdict: no. Decision taken — return `openalexSnapshot` to a pure-R/DuckDB
implementation, and move enrichment from download-time to extract-time.**

The R package's job is **index** and **extract**. This part measures whether those
warrant compiled code.

### 4.1 Measurement

R 4.6.1 + `duckdb`, 14-core macOS (arm64), local SSD, 20 M-row synthetic parquet
corpus (4 columns, snappy, 0.59 GB on disk):

```
threads=1   INDEX 20M rows:  0.55 s  ->  36.1 M rows/s
threads=4   INDEX 20M rows:  0.53 s  ->  37.9 M rows/s
threads=8   INDEX 20M rows:  0.52 s  ->  38.2 M rows/s
threads=14  INDEX 20M rows:  0.58 s  ->  34.6 M rows/s

EXTRACT: 0.13 s — 10,000 ids semi-joined against the index, full rows out
```

**The flat thread scaling is the decisive result.** Throughput is identical at 1
thread and at 8: a single DuckDB thread already saturates the pipeline. The work is
parquet decode and write, not computation. Rust's advantage here would come from
rayon fan-out across files — but there is no CPU headroom to fan out into.

*Caveats:* warm page cache, synthetic 4-column schema, local SSD. The real corpus has
deeply nested structs and lives on an external volume, where cold I/O dominates —
which widens the gap in R's favour, not Rust's, since I/O is language-neutral.

### 4.2 "R-only" does not mean R loops

An R implementation issues one statement and lets a C++ engine do the work. DuckDB
supplies `filename` and `file_row_number` natively — essentially the id_block /
file_row_number index the Rust `index` command builds:

```sql
COPY (SELECT id, filename, file_row_number
      FROM read_parquet('works/**/*.parquet', filename = true, file_row_number = true))
TO 'works_id_idx.parquet' (FORMAT parquet, COMPRESSION zstd)
```

Extract is a semi-join against that index. So the real comparison is
**DuckDB / Arrow-C++ vs arrow-rs / parquet-rs** — two mature vectorised columnar
engines. Near parity by construction.

### 4.3 Expected Rust advantage, by pipeline step

Scaled to a ~260 M-row works corpus on an external volume:

| Step | Nature of work | Expected Rust advantage |
|---|---|---|
| `index` | project one VARCHAR column, write index | **~1.0–1.3×** — I/O bound; one thread already saturates |
| `extract` | index lookup → read matched row groups | **~1.0–1.5×** — I/O bound, small result sets |
| `enrich` | per-row string building (abstract from inverted index, citation from nested structs) | **~10×** — upstream NEWS measured 12× vs DuckDB SQL |
| `download` / `verify` | network + hashing (CLI already shells out to `aws s3 sync`) | ~1× — bandwidth bound |

For index and extract, the estimate is **between nothing and ~50% — most likely
under 20% on the external volume.** Both implementations land in the same
minutes-scale bracket for a full works index.

`enrich` was the one place the Rust rewrite genuinely paid off, because per-row
string manipulation is exactly where a compiled language beats a SQL engine.

### 4.4 Decision: enrich on extract, not on download

The current pipeline materialises `abstract` and `citation` for **every** record —
~260 M works — to serve queries that touch a tiny fraction of them. The
`abstract_inverted_index` is already present in the official parquet, so nothing is
lost by deferring reconstruction to the records a user actually pulls, where the cost
is too small to measure.

Consequences:

* **Rust's last advantage disappears.** The trade is no longer "12× slower on a
  once-per-snapshot job" — the expensive step stops existing in batch form.
* **A full-corpus rewrite (hundreds of GB) leaves the refresh cycle.**
* The building blocks already exist in pure R: openalexPro exports
  `oa_works_abstract_sql()` and `oa_works_citation_sql()`, recorded in NEWS 0.10.4 as
  "now implemented in R (behaviour unchanged)".

### 4.5 What is given up, and why the risk is low

The v0.6.0 goal of a single shared implementation producing byte-identical CLI and R
output. The risk is small: the same NEWS entry records the Rust `enrich` as verified
**byte-identical to the previous DuckDB SQL** across a full 142,844-row works
partition. The two agreed, so returning to SQL returns to a validated reference
rather than an untested one.

The CLI is **not** being retired — it remains useful standalone for bulk operations.
The change is that the **R package stops linking `openalex-core`**, which removes the
Rust toolchain requirement, restores a realistic CRAN path, and eliminates the
git-tag pinning problem (currently stuck at v0.5.0, one major step behind).

### 4.6 Target architecture

```
openalexSnapshot (pure R, no compiled code)
  download   ->  aws s3 sync from s3://openalex/data/parquet/  (or leave to the CLI)
  verify     ->  manifest.json: per-file presence + size
  index      ->  DuckDB: id + filename + file_row_number  ->  <corpus>_id_idx.parquet
  extract    ->  DuckDB semi-join on the index
                 + enrich the extracted subset only
                   (oa_works_abstract_sql / oa_works_citation_sql)
```

### 4.7 Validation of the decision — measured

Both open items are now resolved against the real official parquet.

**1. `oa_works_abstract_sql()` runs unmodified on the official parquet. ✅**

The official `abstract_inverted_index` is `VARCHAR` (a JSON string), not `MAP`. The
`abstract_inverted_index::JSON::MAP(VARCHAR, BIGINT[])` cast added in 0.10.4 handles
it, and the expression returns correct reconstructed abstract text. **No changes
needed** to the existing R/DuckDB enrichment for the parquet-native pipeline.

**2. Enrichment throughput (DuckDB, official parquet data):**

```
threads=1  6.43 s for 171,960 rows  ->  26,730 rows/s
threads=8  6.54 s for 171,960 rows  ->  26,303 rows/s
```

*(171,960 non-null `abstract_inverted_index` values; `sum(length(...))` to defeat
projection elimination — a bare `count(*)` lets the optimiser skip the work
entirely and reports absurd rates.)*

**No thread scaling** — DuckDB does not parallelise this lambda/list expression.
Any full-corpus run must fan out across files with multiple connections.

**3. What this means for the decision:**

| workload | rows | DuckDB (measured) | Rust (at the documented 12×) |
|---|---|---|---|
| **extract-time enrich** (typical query) | 10,000 | **0.37 s** | 0.03 s |
| extract-time enrich (large query) | 1,000,000 | ~37 s | ~3 s |
| full-corpus enrich, 1 core | ~260 M | **~2.7 h** | ~13 min |
| full-corpus enrich, 8-way fan-out | ~260 M | ~20–30 min | ~2–3 min |

**The decision is validated.** At extract time the Rust advantage is 0.34 s on a
typical query — below the noise floor of an interactive workflow. Rust only matters
for the full-corpus batch enrich, which enrich-on-extract eliminates.

### 4.8 Remaining implementation note

Reproduce `id_block` semantics exactly if existing indexes are to stay readable;
otherwise plan a one-off index rebuild.

---

## Cross-package defects

Independent of the migration. All verified; ordered by impact.

### D1 — `compatibility_report()` fails without `tictoc` (openalexPro)

**Severity:** medium · `openalexPro/inst/compatibility.qmd`, `openalexPro/DESCRIPTION`

`inst/compatibility.qmd` calls `library(tictoc)`, but **`tictoc` appears nowhere in
openalexPro's DESCRIPTION** — not Imports, not Suggests. The exported
`compatibility_report()` therefore fails at render for any user without tictoc
already installed; it only works locally because tictoc happens to be present.
(`openalexR` and `quarto`, also used by that document, *are* correctly in Suggests.)

**Fix:** add `tictoc` to Suggests, or remove the timing calls from the document.

### D2 — 18 GB of Rust build artifacts are not gitignored (openalexSnapshot)

**Severity:** medium · `openalexSnapshot/.gitignore`

```
18G  openalexSnapshot/src/rust/target
```

Currently **untracked** (`git ls-files src/rust/target` → 0), but `.gitignore`
contains only `src/*.o` — there is no `src/rust/target/` entry, so a single
`git add -A` would commit the whole build tree.

**Fix:** add `src/rust/target/` to `.gitignore` now. The Part 4 migration then allows
deleting all 18 GB outright.

### D3 — `@import openalexPro` is redundant and a standing risk (openalexSnowball)

**Severity:** low-medium · `openalexSnowball/R/openalexSnowball-package.R`,
`openalexSnowball/NAMESPACE`

Every openalexPro call in `openalexSnowball/R/` is already `openalexPro::`-qualified —
a scan for unqualified uses of `pro_query`, `pro_request`, `pro_request_parquet`,
`read_corpus` and `pro_fetch` found **none**. The full-namespace import therefore buys
nothing while creating a collision surface with every future openalexPro export. No
clashes exist today (§1.2), so this is preventive.

**Fix:** delete the `#' @import openalexPro` tag and re-roxygenise.

### D4 — a testthat crash dump is committed (openalexConvert)

**Severity:** low · `openalexConvert/tests/testthat/testthat-problems.rds`

45 KB, dated 2026-05-29, and **tracked in git**. This is testthat's failure-artifact
file, not a fixture.

**Fix:** `git rm` it and add `testthat-problems.rds` to `.gitignore`.

### D5 — placeholder metadata in two DESCRIPTIONs

**Severity:** low · `openalexStemCheck/DESCRIPTION`, `openalexASReview/DESCRIPTION`

```
openalexStemCheck: person("Your", "Name", email = "your.email@example.com")
                   URL:        https://github.com/yourname/openalexStemCheck
                   BugReports: https://github.com/yourname/openalexStemCheck/issues
openalexASReview:  email = "rainer.krug@example.com"
```

StemCheck's URL and BugReports are dead links. Both read as unfinished scaffolding on
r-universe.

Related policy call: openalexASReview lists `person("ChatGPT& codex", "GPT-5",
role = "aut")` and openalexVectorComp lists `"ChatGPT Assistant"` as `ctb`. CRAN
rejects non-person authors, so this needs a decision for any package headed there.

### Also noted (no action required)

* **Name collision.** openalexPro exports `compatibility_report()`, which renders an
  *openalexR* compatibility document — unrelated to this file. Consider renaming the
  function to something like `openalexR_compatibility_report()`, which describes it
  more accurately.
* **openalexASReview** (excluded from this report, slated for retirement) has 14
  `openalexPro::` calls with **openalexPro absent from its DESCRIPTION entirely**. It
  is broken today, not merely at some future openalexPro release.

---

## Part 5 — Version numbering across the package set

**Question:** should every package carry the version of the minimum openalexPro it
requires, to guarantee compatibility?

**Verdict: no.** Keep independent semver per package and express compatibility where R
actually reads it — the `Imports:` constraint.

### 5.1 Why version-mirroring does not work

It conflates two separate things:

* `Version:` — "which release of *me* is this?" (identity and history)
* `Imports: openalexPro (>= x.y.z)` — "what do I need?" (the compatibility contract)

Mirroring produces the *appearance* of a guarantee without the guarantee. Nothing in
`install.packages()`, `pak` or r-universe reads a package's own version to decide
which openalexPro to fetch; only the `Imports:` constraint does. Concretely:

1. **Versions must increase monotonically.** If openalexConvert becomes 0.10.5 because
   it needs openalexPro 0.10.5, then a typo fix requiring no new openalexPro forces a
   bump to 0.10.6 — which now falsely claims a dependency on openalexPro 0.10.6. The
   scheme breaks on the first independent change, i.e. the common case.
2. **All signal about the package's own changes is lost.** A user seeing 0.9 → 0.10
   cannot tell whether anything in that package changed.
3. **Requirements can never be relaxed**, since the version cannot go down.
4. **DOI and release noise.** These packages are Zenodo-archived; every openalexPro
   release would force a citable release of packages that did not change.

The current state already shows the confusion the scheme invites: openalexSnowball is
`Version: 0.10.1` while requiring `openalexPro (>= 0.10.5)` — the numbers look
systematic and are not.

### 5.2 Current state

| Package | Version | openalexPro constraint |
|---|---|---|
| openalexPro | 0.10.5 | — |
| openalexSnowball | 0.10.1 | `>= 0.10.5` ✅ |
| openalexConvert | 0.0.3 | declared, **no floor** ❌ |
| openalexSnapshot | 0.0.2 | none (pins `openalex-core` tag v0.5.0 instead) |
| openalexVectorComp | 0.3.3 | none — not a dependent |
| openalexStemCheck | 0.0.0.9000 | none — not a dependent |
| openalexASReview | 0.0.0.9000 | **undeclared despite 14 calls** ❌ |

### 5.3 Recommended scheme

1. **Independent semver per package**, reflecting only that package's own changes.
2. **Treat the floor as a maintained field.** Whenever a package starts calling
   something new in openalexPro, bump its `openalexPro (>= …)` in the same commit.
   This is the discipline that actually buys compatibility.
3. **If a single known-good set is wanted, make it explicit** rather than encoding it
   in version numbers. Either:
   * an **`openalexverse` meta-package** whose `Imports:` pins the tested minimum of
     every package — one install, one coherent set, and *its* version can legitimately
     be a release-train number; or
   * a **compatibility table** in each README/pkgdown site ("openalexConvert 0.0.3
     tested against openalexPro 0.10.x").
4. **Optional belt-and-braces:** while openalexPro is pre-1.0, an upper bound is
   defensible. R convention discourages `<=` in DESCRIPTION, so implement it as a
   `.onLoad` check on `packageVersion("openalexPro")` with a `cli` warning.

### 5.4 The Part 4 migration simplifies this

The messiest coupling in the set is not an R version constraint at all — it is
openalexSnapshot's `openalex-core` **git tag pin** (`tag = "v0.5.0"`), which silently
drifted a full major version behind the CLI and is the direct cause of the Part 3
breakage. Dropping the Rust dependency removes that coupling entirely, leaving only
ordinary R `Imports:` floors, which are visible, tooling-enforced and trivial to audit.

**Version-mirroring would only be correct for a genuine release train** — every package
re-released in lockstep on every openalexPro release, changed or not (Bioconductor
style). Given these are independently maintained and independently DOI'd, that is not
the model in use.

---

## Recommended follow-ups

Ordered by impact.

1. **Rewrite openalexSnapshot as pure R over DuckDB, parquet-native, with
   enrich-on-extract** (decided — see Part 4). This is the largest item and subsumes
   several below. Drop `extendr` and the `openalex-core` dependency entirely; do not
   bump the pin to v0.6.0. Target architecture in §4.6. This simultaneously fixes the
   retired-code-path problem from Part 3, removes the Rust toolchain requirement, and
   restores a realistic CRAN path.
2. ~~Verify the official parquet schema.~~ **Done — see §2.5.** Official parquet uses
   native `VARCHAR[]` list types and agrees with openalexPro's API path; the JSON-string
   encoding was a legacy-converter artefact.
3. **Regenerate (or retire) openalexPro's bundled schemata** — open defect, full
   write-up and two candidate fixes in **§2.6**. They are documented as inferred from
   the OpenAlex snapshot but were inferred from the *legacy converted* corpus, and
   differ from the official parquet in 25 of 49 works columns. Resolve together with
   the `oa_cache_schema()` item (7).
4. **Document that the legacy and official corpora are not interchangeable** — relevant
   only while legacy corpora remain in use; the difference disappears after the Part 4
   migration.
5. **Add a version floor** to openalexConvert: `openalexPro (>= 0.10.5)` — see Part 5
   for the versioning scheme this fits into.
6. **Resolve the `build_corpus_index` / `lookup_by_id` double export** — drop them
   from openalexPro's `NAMESPACE` (keep the informative error as an internal
   `.Defunct`-style message, or remove entirely).
7. **Fix the `oa_cache_schema()` NEWS entry** — either ship the function or remove
   the claim from `NEWS.md`.
8. **Clear the cross-package defects D1–D5** — undeclared `tictoc`, the ungitignored
   18 GB Rust target, the redundant `@import openalexPro`, the committed
   `testthat-problems.rds`, and the placeholder DESCRIPTION metadata.
9. **Regenerate openalexConvert's bibtex/biblatex fixtures** under pandoc 3.10.2,
   or make the comparison pandoc-tolerant (compare parsed entries, not raw lines).
10. **Update openalexSnapshot's docs for the new S3 layout** (`data/jsonl/…`,
    `data/parquet/…`) if the legacy path is kept alive at all during the migration.
11. ~~Consider a corpus-normalisation helper.~~ **Dropped** — §2.5 shows the official
    parquet already uses native list types, so there is nothing to harmonise once the
    migration lands. Only needed if legacy corpora must stay queryable.
12. **Align `Additional_repositories:`** across all packages distributed off-CRAN.

---

## Reproduction

```bash
# API surface + signature check
Rscript -e 'pro <- getNamespaceExports("openalexPro"); print(sort(pro))'

# dependent test suites
cd openalexSnowball && Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_local()'
cd openalexConvert && Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_local()'

# declared-schema comparison (all 21 entities)
#   openalexPro/inst/extdata/schemata/<entity>.csv
#   vs /Volumes/openalex/openalex-snapshot_metadata/<entity>/schemata/unified_schema.csv

# actual-output comparison
#   openalexPro:      pro_request_parquet(input_json = "openalexPro/tests/fixtures/keypaper_json", ...)
#   openalexSnapshot: /Volumes/openalex/parquet/works/updated_date=2016-06-24/part_0000.parquet
#   then: DESCRIBE SELECT * FROM read_parquet('<file>')

# Part 3 — upstream bucket state (read-only, no credentials needed)
aws s3 ls s3://openalex/data/ --no-sign-request
aws s3 ls s3://openalex/data/parquet/ --no-sign-request
aws s3 ls s3://openalex/data/parquet/domains/ --no-sign-request --recursive --summarize

# Part 3 — Rust core pin vs CLI release
grep openalex-core openalexSnapshot/src/rust/Cargo.toml     # -> tag = "v0.5.0"
git -C ~/GitHub/openalex-snapshot tag                        # -> ... v0.5.0 v0.6.0
sed -n '1,70p' ~/GitHub/openalex-snapshot/NEWS.md            # -> [0.6.0] parquet-native

# Part 3 — provenance of the local corpus
ls -ld /Volumes/openalex/parquet/works /Volumes/openalex/parquet/works_aws
ls /Volumes/openalex/parquet/manifest.json                   # -> absent

# Part 4 — index/extract benchmark (synthetic, self-contained)
#   generate 40 x 500k-row parquet files, then for threads in 1/4/8/14:
#     COPY (SELECT id, filename, file_row_number
#           FROM read_parquet('part_*.parquet', filename=true, file_row_number=true))
#     TO 'idx.parquet' (FORMAT parquet, COMPRESSION zstd)
#   NB: write the index OUTSIDE the globbed directory or the re-read hits a
#       schema mismatch on the next run.
```

# §2.5 / §4.7 — official parquet spot check (3.6 MB + 9 KB)
aws s3 cp s3://openalex/data/parquet/works/updated_date=2016-06-24/part_0000.parquet . --no-sign-request
aws s3 cp s3://openalex/data/parquet/domains/updated_date=2026-06-26/part_0000.parquet . --no-sign-request
#   DESCRIBE SELECT * FROM read_parquet('part_0000.parquet')
#   then enrichment throughput:
#     e <- openalexPro::oa_works_abstract_sql()
#     SELECT sum(length(a)) FROM (SELECT <e> AS a FROM big)
#   NB: use sum(length(...)), not count(*) — the optimiser eliminates the
#       projection entirely and reports ~300M rows/s.
```

Requires `/Volumes/openalex` mounted for Part 2, and network + `aws` CLI for Parts 3
and 2.5. Part 4's index/extract benchmark is self-contained (synthetic data, local disk).
