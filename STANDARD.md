# openalexPro Ecosystem Standard

**Version:** 0.1 (draft) · **Issue:** [openalexPro_Ecosystem#3](https://github.com/openalexPro/openalexPro_Ecosystem/issues/3)

What a package must do to be part of the openalexPro ecosystem. The goal: **any corpus
works with any consumer**. openalexPro is the reference **writer**, openalexAPI the
reference **reader**. A package belongs to the ecosystem when both accept its output
without special handling.

MUST / SHOULD / MAY as in RFC 2119. Two Claude skills in `.claude/skills/` use this
document: `openalex-ecosystem-standard` checks a package or corpus, and
`openalex-compliance-report` writes a full report to `compliance/<package>.md` for a
package joining the ecosystem. Keep them in step with this document.

---

## 1. Corpus layout

```
<project>/
├── <corpus>/                  the folder a reader is given (openalexPro: parquet/)
│   ├── _dataset.json          dataset marker (§3)
│   └── query=<name>/          one partition per query or source
│       ├── _query.json        per-query record (§4)
│       ├── _query.html        human-readable description (§4)
│       └── *.parquet          works
├── links/                     link table, may be empty (§7)
│   └── query=<name>/*.parquet
└── API/                       openalexAPI's cache (written by the reader, not the writer)
```

- **L1** Data MUST be Parquet files (`*.parquet`) below `<corpus>/`, at any depth.
- **L2** The top partition key MUST be `query=` (Hive style, `query=<name>/`). Deeper
  levels MAY use further keys (openalexPro: `query_l2=`, …).
- **L3** `<name>` is chosen by the writer and has no fixed meaning across the
  ecosystem. It MUST be a valid folder name on all platforms, and it SHOULD be
  meaningful to a user, because readers may show it (L5).
- **L4** Every file in `<corpus>/` that is not works data MUST start with `_`
  (arrow, DuckDB and `**/*.parquet` globs then skip it). No CSV, lookup tables or
  logs without the prefix.
- **L5** The partition keys are part of the data: a record in `query=climate/`
  belongs to the query `climate` (e.g. to compare or filter the queries of one
  project). Readers MAY expose them as columns (Hive partitioning).
  - **L5a** A work can be in several partitions. A reader that deduplicates (S6)
    MUST keep all its partition values (e.g. `query` as a list), not one of them.
  - **L5b** Writers MUST NOT write a data column named like a partition key
    (`query`, `query_l2`, …), so the two never collide.
  - **L5c** Readers MUST accept corpora whose partitions have different depths or
    keys (missing keys are NA).
  - Today openalexAPI reads with `hive_partitioning = false` and ignores the keys
    ([openalexAPI#12](https://github.com/openalexPro/openalexAPI/issues/12)).

## 2. Works schema

- **S1** Every works file MUST have an `id` column and a `title` or `display_name`
  column. Files without them are skipped by openalexAPI.
- **S2** Columns that exist in the OpenAlex works schema MUST keep its names and
  structure (e.g. `primary_location.source.display_name`, `authorships[]`).
- **S3** These columns, when present, SHOULD have these types (openalexAPI casts back
  what it can, and warns):

  | Column | Type |
  |---|---|
  | `publication_year` | integer |
  | `publication_date` | DATE |
  | `cited_by_count` | integer |
  | `fwci` | double |
  | `is_retracted`, `is_paratext` | boolean |
  | `abstract_inverted_index` | `MAP(VARCHAR, BIGINT[])` |

- **S4** A plain-text `abstract` column MAY be written instead of, or as well as,
  `abstract_inverted_index`.
- **S5** Extra columns (not in the OpenAlex schema) MUST be named
  `<prefix>_<name>`, where `<prefix>` is the writer's registered prefix (§5, I5), e.g.
  `zenodo_related`, `policy_fulltext`. Readers MAY ignore them, or serve them as they are.
- **S5a** Reserved names, written by openalexPro without a prefix and known to readers:
  `abstract`, `citation`, `relevance_score`, and `page` (deprecated: written but read
  nowhere, removal tracked in [openalexPro#97](https://github.com/openalexPro/openalexPro/issues/97)). No other writer may use them for anything
  else.
- **S6** `id` MUST be unique within a partition. Duplicates across partitions are
  allowed (readers deduplicate).

## 3. `_dataset.json` — dataset marker

One per `<corpus>/` folder. It identifies the folder as an ecosystem corpus and says who
wrote it.

- **D1** Every writer MUST write it, and only writers write it (readers never create it).
- **D2** Content MUST be deterministic: no timestamps, run ids, host names or absolute
  paths, so rewriting an unchanged corpus leaves it byte-identical (keeps `targets`
  pipelines valid).
- **D3** Required fields:

  ```json
  {
    "standard": "0.1",
    "type": "works",
    "writer": { "package": "openalexImportPolicy", "version": "0.2.0", "prefix": "policy" },
    "partition_keys": ["query"],
    "id_format": "policy:<source>:<document id>"
  }
  ```

  `id_format` is the writer's template for `id` (§5, I2); for OpenAlex records it is
  `"https://openalex.org/<id>"`. A corpus mixing writers lists them per partition under
  `"queries"` instead:
  `{"queries": {"<name>": {"writer": {…}, "id_format": "…"}}}`.
- **D4** Existing corpora are not retrofitted automatically; readers MUST work without
  the file.

## 4. `_query.json` and `_query.html` — per-query provenance

- **Q1** Each `query=<name>/` partition MUST carry `_query.json` describing how its
  records were obtained (query, source, settings). Its content is free-form per source.
- **Q2** It SHOULD be enough to repeat or update the download.
- **Q3** Each partition SHOULD carry `_query.html`: a self-contained, human-readable
  description for methods sections. openalexPro additionally writes
  `_query_oql.txt` / `_query_oql.html`.
- **Q4** Both MUST survive conversion steps (e.g. openalexPro copies `_query.json` into
  the Parquet partition so it outlives `delete_input`).
- **Q5** Unlike `_dataset.json` (D2), `_query.json` and `_query.html` MAY hold
  run-dependent values (start and end times, request counts), so they change on every
  update. Pipelines that track a corpus for changes (e.g. `targets`) SHOULD track its
  `*.parquet` files and `_dataset.json`, not the whole folder.

## 5. Identifiers

- **I1** OpenAlex records: `id` is the OpenAlex URL (`https://openalex.org/W…`).
- **I2** Records from other sources: `id` is `<prefix>:<part>[:<part>…]`. The first
  part MUST be the writer's registered prefix (I5); the parts after it are the writer's
  choice (e.g. `policy:cbd:12345`, `zenodo:<group>:<conceptrecid>`). No part may
  contain `/` (openalexAPI matches IDs on the part after the last `/`).
- **I3** The writer MUST declare its template in `_dataset.json` as `id_format` (D3).
- **I4** `ids` SHOULD carry known external identifiers (`doi`, `<prefix>`).
  `ids.openalex` is set only once the record has been matched to OpenAlex.
- **I5** Prefixes are registered here, one per package that writes into the ecosystem
  (writers, transformers T1, annotators N3), lowercase `[a-z0-9]+`.
  The same prefix names the writer's extra columns (S5). It MUST NOT be a scheme
  name (I7).

  | Prefix | Package | Kind |
  |---|---|---|
  | `oapro` | openalexPro (future extra columns; its IDs stay OpenAlex URLs, I1) | writer |
  | `policy` | openalexImportPolicy | writer |
  | `zenodo` | openalexImportZenodo | writer |
  | `iisd` | openalexImportIISD (planned) | writer |
  | `zotero` | openalexImportZotero (planned) | writer |
  | `snowball` | openalexSnowball | transformer |
  | `snapshot` | openalexSnapshot | transformer |
  | `vectorcomp` | openalexVectorComp | annotator |

  Consumers that write nothing back into the ecosystem (openalexConvert, openalexAPI)
  need no prefix.

- **I6** DOIs, where present, use the OpenAlex form `https://doi.org/<doi>`, lowercase.
- **I7** Identifier schemes, for `ids` keys (I4) and for link ends outside the corpus
  (K4): the lowercase names of DataCite's `relatedIdentifierType` (`ark`, `arxiv`,
  `bibcode`, `doi`, `ean13`, `eissn`, `handle`, `igsn`, `isbn`, `issn`, `istc`,
  `lissn`, `lsid`, `pmid`, `purl`, `upc`, `url`, `urn`, `w3id`) plus `openalex`,
  `orcid`, `ror`. These names are reserved: no writer prefix (I5) may equal one, so a
  `<scheme>:` value is never mistaken for a corpus ID.

## 6. Package requirements

- **P1** Names: `openalexImport<Source>` (writes a corpus from a non-OpenAlex source),
  `openalexExport<Target>` (reads a corpus into another format); other names are
  free.
- **P2** `DESCRIPTION` MUST declare `openalexPro (>= x.y.z)` with a real floor when it
  calls openalexPro, and SHOULD declare the standard version it follows
  (`Config/openalexPro/standard: 0.1`).
- **P3** Import packages export a `<source>_as_corpus(…, out)` function that writes a
  corpus following §1–§5.
- **P4** Import packages MUST have a test that writes a small corpus and runs
  `openalexAPI::prepare_corpus()` on it (skipped when openalexAPI is not installed).
- **P5** Export packages MUST accept any corpus following this standard, not only
  openalexPro output, and MUST NOT require `_dataset.json` (D4).
- **P6** Repository conventions: MUST use the MIT licence and be listed in `repos.tsv`
  (see `ecosystem.md`); SHOULD have a `dev` default branch with `main` for releases,
  a `CITATION.cff` and a pkgdown site.
- **P7** Writer and transformer packages MUST export `<prefix>_example_corpus(out)`:
  it writes a small corpus (with its link table) following §1–§7 to `out` and returns
  `out`, offline — from data shipped in the package, no network, no API key. Tests
  (P4) and the compliance workflow
  ([#4](https://github.com/openalexPro/openalexPro_Ecosystem/issues/4)) check this
  corpus.

## 7. Link table

- **K1** Every writer MUST write `links/query=<name>/*.parquet` next to `<corpus>/`, one
  partition per corpus partition, shaped like OpenAlex `/links`: columns `origin`,
  `target`, `link_type` (an `https://openalex.org/link-types/…` URL, or NA when the
  relation has no OpenAlex type), `origin_in_corpus`, `target_in_corpus` (boolean).
  Extra columns follow S5.
- **K2** The table MAY have zero rows, but the file and its columns MUST exist, so
  readers never have to check whether there is one.
- **K3** Relations already in the works columns (e.g. citations in
  `referenced_works`) need not be repeated here; a writer MAY repeat them so its link
  table is complete on its own. openalexPro does not copy `referenced_works` into it
  (for a snapshot-sized corpus that would be hundreds of millions of rows).
- **K4** `origin` and `target` use one identifier form for everything:
  - a record **in the corpus**: its `id` (§5);
  - **outside** the corpus: a DOI as `https://doi.org/<doi>` (I6), a URL as is, else
    `<scheme>:<identifier>` with a scheme from I7 (e.g. `isbn:9780000000000`,
    `arxiv:2101.00001`, `handle:10419/12345`, `pmid:12345678`).

  Something with no identifier at all is not a link; it stays in a prefixed works
  column (e.g. `zenodo_references`).

## 8. Analysis and processing packages

§1–§7 describe what a writer puts into a corpus. This section covers packages that
work on corpora ([#5](https://github.com/openalexPro/openalexPro_Ecosystem/issues/5)).
A package can be more than one kind.

| Kind | Reads | Writes | Examples |
|---|---|---|---|
| **Consumer** | a corpus | something outside the ecosystem (CSL JSON, BibTeX, Zotero, an API) | openalexConvert, openalexAPI, `openalexExport*` |
| **Transformer** | a corpus or the snapshot | a new corpus | openalexSnowball, openalexSnapshot |
| **Annotator** | a corpus | data about its records, keyed by `id` | openalexVectorComp |

### All kinds

- **A1** Inputs are read-only: a package MUST NOT write into an input corpus. Caches
  and outputs go into sibling folders of `<corpus>/` (as openalexAPI's `API/`).
- **A2** A package MUST accept any corpus following §1–§7, not only openalexPro
  output: IDs of other writers (`zenodo:…`, `policy:cbd:…`), missing optional columns
  (e.g. no `abstract_inverted_index`), prefixed extra columns (ignored or passed
  through), and works in several `query=` partitions (L5a).
- **A3** IDs MUST be matched on the part after the last `/`, case-insensitively (as
  openalexAPI's `id_key()`), never by assuming `https://openalex.org/W…`.

### Transformers

- **T1** A transformer is a writer: its output corpus MUST follow §1–§7, under its own
  registered prefix (I5).
- **T2** Its `_dataset.json` MUST record its inputs in `derived_from`: for each input
  corpus, the path relative to the output and the SHA-256 of the input's
  `_dataset.json` (or `null` when the input has none). Deterministic, as D2.
- **T3** Relations it produces between records (e.g. citation edges) MUST be written
  as the link table (§7), with the matching `link_type`.

### Annotators

- **N1** Annotations MUST be written to `<project>/<prefix>_<name>/query=<name>/*.parquet`,
  next to the corpus, one row per record (or per record and item), keyed by `id`,
  using the corpus's `query=` partitions, so joining is on `id` (and `query`).
  Internal storage (e.g. a vector database) is free; N1 applies to what the package
  hands on.
- **N2** The annotation folder MUST carry a `_dataset.json` with
  `"type": "annotation"`, `writer`, `derived_from` (T2), and the method and its
  settings (e.g. model name and version, parameters). Deterministic, as D2.
- **N3** Annotation columns other than `id` MUST follow S5 (`<prefix>_<name>`).

### Consumers

- **C1** Records that are not OpenAlex works MUST be converted, or reported as skipped
  (count and IDs); never dropped silently.
- **C2** Same as P5: a consumer MUST NOT require `_dataset.json` or openalexPro-only
  columns.

---

## Current compliance (2026-11-27)

| Package | L2 `query=` | L4 `_` files | S5 prefixes | `_dataset.json` | `_query.json` | I2 IDs | K1 links |
|---|---|---|---|---|---|---|---|
| openalexPro | ✓ | ✓ | ✓ (S5a) | ✗ | ✓ | ✓ | ✗ |
| openalexImportZenodo | ✓ | ✓ | to check | ✗ | ✓ | ✓ | ✓ |
| openalexImportPolicy | ✗ `source=` | ✗ `doc_types.csv` | ✗ `fulltext`, `country_iso3`, … | ✗ | ✗ | ✗ `cbd:…` → `policy:cbd:…` | ✗ |
| openalexAPI (reader) | ✗ keys ignored (L5) | ✓ | serves as is | n/a | n/a | ✓ | not read |

## Changes

- **0.1** (2026-11-27) First draft; §8 for analysis and processing packages
  ([#5](https://github.com/openalexPro/openalexPro_Ecosystem/issues/5)). Decisions recorded in
  [#3](https://github.com/openalexPro/openalexPro_Ecosystem/issues/3).
