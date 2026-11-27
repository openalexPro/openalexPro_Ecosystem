# openalexPro Ecosystem Standard

**Version:** 0.1 (draft) · **Issue:** [openalexPro_Ecosystem#3](https://github.com/openalexPro/openalexPro_Ecosystem/issues/3)

What a package must do to be part of the openalexPro ecosystem. The goal: **any corpus
works with any consumer**. openalexPro is the reference **writer**, openalexAPI the
reference **reader**. A package belongs to the ecosystem when both accept its output
without special handling. (Both are being brought into line with this draft; until
then their reports show where they differ.)

MUST / SHOULD / MAY as in RFC 2119; each rule has one level, the first of these words
in it ("MUST NOT" counts as MUST). Text without a rule id is explanation, not a rule.
The rules are checked by the R package **openalexStandard** (`pkg/openalexStandard/`,
usable in package tests), and the reports are published at
<https://openalexpro.github.io/openalexPro_Ecosystem/> (daily, for every watched
package's `main` and `dev`). Three Claude skills in `.claude/skills/` add what code
cannot do: `openalex-ecosystem-standard` (review), `openalex-compliance-report`
(reports) and `openalex-compliance-fix` (fixing a package). A change to this document
needs the same change in openalexStandard's rule data (`inst/extdata/`); its tests
compare rule ids, levels, prefixes and schemes.

"Partition" means a top-level `query=<name>/` folder throughout.

---

## 1. Corpus layout

```
<project>/
├── <corpus>/                  the folder a reader is given (openalexPro: parquet/)
│   ├── _dataset.json          dataset marker (§3)
│   └── query=<name>/          one partition per query or source
│       ├── _query.json        per-query record (§4)
│       ├── _query.html        human-readable description (§4)
│       └── *.parquet          works (at any depth below the partition)
├── links/                     link table, may be empty (§7)
│   └── query=<name>/*.parquet
└── API/                       openalexAPI's cache (written by the reader, not the writer)
```

- **L1** Data MUST be Parquet files (`*.parquet`, any file name, any compression
  DuckDB reads, text as UTF-8) at any depth below `<corpus>/query=<name>/`.
- **L2** The top partition key MUST be `query=` (Hive style, `query=<name>/`). Deeper
  levels may use further keys (openalexPro: `query_l2=`, …).
- **L3** `<name>` MUST be a valid folder name on all platforms. It is chosen by the
  writer and has no fixed meaning across the ecosystem, but readers may show it, so it
  should mean something to a user.
- **L4** Every file in `<corpus>/` that is not works data MUST start with `_` (or `.`,
  which tools treat the same): arrow, DuckDB and `**/*.parquet` globs then skip it. No
  CSV, lookup tables or logs without the prefix.
- **L5a** A work can be in several partitions. A reader that deduplicates (S6) MUST
  keep all its partition values (e.g. `query` as a list), not one of them.
- **L5b** Writers MUST NOT write a data column named like a partition key (`query`,
  `query_l2`, …), so the two never collide.
- **L5c** Readers MUST accept corpora whose partitions have different depths or keys
  (missing keys are NA).

The partition keys are part of the data: a record in `query=climate/` belongs to the
query `climate`, and readers may expose the keys as columns (Hive partitioning), e.g.
to compare or filter the queries of one project
([openalexAPI#12](https://github.com/openalexPro/openalexAPI/issues/12)).

## 2. Works schema

- **S1** Every works file MUST have an `id` column and a `title` or `display_name`
  column. Files without them are skipped by openalexAPI.
- **S2** Columns that exist in the OpenAlex works schema MUST keep its names and
  structure (e.g. `primary_location.source.display_name`, `authorships[]`). A nested
  field stored as JSON text (VARCHAR), as in the OpenAlex snapshot, keeps the
  structure. The reference is the works schema of openalexPro
  (`inst/extdata/schemata/works.csv`).
- **S3** These columns, when present, SHOULD have these types (openalexAPI casts back
  what it can, and warns):

  | Column | Type |
  |---|---|
  | `publication_year` | integer |
  | `publication_date` | DATE |
  | `cited_by_count` | integer |
  | `fwci` | double |
  | `is_retracted`, `is_paratext` | boolean |
  | `abstract_inverted_index` | `MAP(VARCHAR, BIGINT[])` (JSON text is accepted, S2) |

- **S5** Extra columns (not in the OpenAlex schema) MUST be named `<prefix>_<name>`,
  where `<prefix>` is a registered prefix (I5): the writer's own, or — in a
  transformer's output (T1) — that of the writer the column came from (e.g.
  `zenodo_related`, `policy_fulltext`). Readers may ignore them, or serve them as they
  are.
- **S5a** The reserved names `abstract` (plain text), `citation` (text),
  `relevance_score` (number) and `page` (text; deprecated, read nowhere, removal in
  [openalexPro#97](https://github.com/openalexPro/openalexPro/issues/97)) are written
  without a prefix by openalexPro; other writers MUST NOT use them with another
  meaning or type.
- **S6** `id` MUST be unique within a partition. Duplicates across partitions are
  allowed (readers deduplicate).

A plain-text `abstract` may be written instead of, or as well as,
`abstract_inverted_index`.

## 3. `_dataset.json` — dataset marker

One per `<corpus>/` folder. It identifies the folder as an ecosystem corpus, says who
wrote it, and fingerprints its data.

- **D1** Every writer MUST write it, and only writers write it (readers never create it).
- **D2** Its content MUST be deterministic: no timestamps, run ids, host names or
  absolute paths, so rewriting an unchanged corpus leaves it byte-identical (keeps
  `targets` pipelines valid).
- **D3** It MUST have these fields:

  ```json
  {
    "standard": "0.1",
    "type": "works",
    "writer": { "package": "openalexImportPolicy", "version": "0.2.0", "prefix": "policy" },
    "partition_keys": ["query"],
    "id_format": "policy:<source>:<document id>",
    "content": "sha256:…"
  }
  ```

  - `type` is `works` (a corpus) or `annotation` (N2).
  - `id_format` is the template of `id` (§5): literal text plus placeholders `<…>`;
    each placeholder stands for one part without `/` or `:`, the last one may contain
    `:`. For OpenAlex records it is `"https://openalex.org/<id>"`.
  - `content` is the fingerprint of the data (D5).
  - A corpus mixing writers has `"queries": {"<name>": {"writer": {…}, "id_format": "…"}}`
    **instead of** the top-level `writer` and `id_format`; whoever writes the last
    partition rewrites the file.
  - Transformers and annotators add `derived_from` (T2), annotators `method` (N2).
- **D4** Readers MUST work without the file: existing corpora are not retrofitted.
- **D5** `content` MUST be the fingerprint of the data files: the SHA-256 of one line
  per Parquet file below `<corpus>/`, sorted by relative path, each
  `<relative path>\t<size in bytes>\t<SHA-256 of the file's last 65536 bytes>` (the
  Parquet footer: row counts, schema and column statistics). It changes whenever the
  data change, and not when the corpus is only copied (dates are not part of it).
  `openalexStandard::write_dataset_json()` computes it.

A reader that finds another `standard` version than its own reads the corpus anyway
and warns.

## 4. `_query.json` and `_query.html` — per-query provenance

- **Q1** Each partition MUST carry `_query.json` describing how its records were
  obtained (query, source, settings). Its content is free-form per source.
- **Q2** It SHOULD be enough to repeat or update the download.
- **Q3** Each partition SHOULD carry `_query.html`: a self-contained, human-readable
  description for methods sections.
- **Q4** Both MUST survive conversion steps (e.g. openalexPro copies `_query.json` into
  the Parquet partition so it outlives `delete_input`).

Unlike `_dataset.json`, `_query.json` and `_query.html` may hold run-dependent values
(start and end times, request counts), so they change on every update. Pipelines that
track a corpus for changes (e.g. `targets`) should track `_dataset.json` (its
`content`, D5), not the whole folder.

## 5. Identifiers

- **I1** OpenAlex records MUST have the OpenAlex URL as `id` (`https://openalex.org/W…`).
- **I2** Records from other sources MUST have `<prefix>:<part>[:<part>…]` as `id`. The
  first part is the writer's registered prefix (I5); the parts after it are the
  writer's choice (e.g. `policy:cbd:12345`, `zenodo:1234567`). No part contains `/`
  (readers match ids on the part after the last `/`, case-insensitively), and two ids
  of one corpus differ in more than letter case. A writer that can write several
  versions of one record (e.g. Zenodo's `versions = "all"`) declares in `id_format`
  which id it uses.
- **I3** The writer MUST declare its template in `_dataset.json` as `id_format` (D3).
- **I4** `ids` SHOULD carry known external identifiers. Its keys are those of OpenAlex
  (`openalex`, `doi`, `mag`, `pmid`, `pmcid`), the schemes of I7, and the writer's
  prefix. `ids.openalex` is set only once the record has been matched to OpenAlex.
- **I5** A package that writes into the ecosystem (writers, transformers T1,
  annotators N3) MUST use a prefix registered here (and in openalexStandard's
  `prefixes.csv`): lowercase `[a-z0-9]+`, not a scheme name (I7). The same prefix
  names its extra columns (S5).

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

- **I6** DOIs SHOULD use the OpenAlex form `https://doi.org/<doi>`, lowercase.
- **I7** These identifier schemes are reserved, and no prefix (I5) MUST equal one: the
  lowercase names of DataCite's `relatedIdentifierType` (`ark`, `arxiv`, `bibcode`,
  `doi`, `ean13`, `eissn`, `handle`, `igsn`, `isbn`, `issn`, `istc`, `lissn`, `lsid`,
  `pmid`, `purl`, `upc`, `url`, `urn`, `w3id`) plus `openalex`, `orcid`, `ror`. They
  name `ids` keys (I4) and link ends outside the corpus (K4); `doi`, `url` and
  `openalex` are always written as URLs there, never as `<scheme>:…`.

## 6. Package requirements

- **P1** A package that writes a corpus from a non-OpenAlex source MUST be named
  `openalexImport<Source>`, one that reads a corpus into another format
  `openalexExport<Target>`; other names are free.
- **P2** A package that calls openalexPro MUST declare `openalexPro (>= x.y.z)` in
  `DESCRIPTION`, with the oldest version it works with.
- **P2a** `DESCRIPTION` SHOULD declare the standard version the package follows
  (`Config/openalexPro/standard: 0.1`).
- **P3** Import packages MUST export `<source>_as_corpus(…, out)`, which writes a
  corpus following §1–§5 below the project folder `out` (as P7).
- **P4** Import packages MUST have a test that writes a small corpus and runs
  `openalexAPI::prepare_corpus()` on it (skipped when openalexAPI is not installed).
- **P6** A package MUST use the MIT licence and be listed by package name in
  `repos.tsv` (ecosystem packages) or `compliance/external.tsv` (third-party packages).
- **P6a** A package SHOULD have a `dev` default branch with `main` for releases, a
  `CITATION.cff` and a pkgdown site.
- **P7** Writer and transformer packages MUST export `<prefix>_example_corpus(out)`:
  it writes a small corpus following §1–§7 below the project folder `out` (the corpus
  folder and its sibling `links/`) and returns the path of the corpus folder, offline —
  from data shipped in the package, no network, no API key. Tests (P4) and the
  compliance workflow ([#4](https://github.com/openalexPro/openalexPro_Ecosystem/issues/4))
  check this corpus. Shipped data must allow redistribution (e.g. CC0 metadata); say
  where it comes from in `data-raw/`.
- **P7a** Annotator packages MUST export `<prefix>_example_annotation(out, corpus)`:
  it annotates the corpus `corpus` (any compliant corpus) offline and writes the
  annotation below the project folder `out`, returning its folder.

## 7. Link table

Shaped like OpenAlex's `/links` (`api.openalex.org/links`), so that links from any
source are read the same way.

- **K1** Every writer MUST write `links/query=<name>/*.parquet` next to `<corpus>/`, one
  partition per corpus partition, with the columns
  - `origin`, `target` (K4);
  - `link_type`: an OpenAlex link-type URL `https://openalex.org/link-types/<type>`,
    with `<type>` one of `citation`, `review`, `translation`, `summary`, `retraction`,
    `withdrawal`, `removal`, `volume`, `component`, `data-series`, `part`, or NA when
    the relation has none. Direction as in OpenAlex: the origin cites, reviews,
    translates, summarises, pulls (retraction, withdrawal, removal) or is part of
    (volume, component, data-series, part) the target;
  - `relation`: the relation as a DataCite `relationType` in the stored direction
    (`Cites`, `IsPartOf`, `IsSupplementTo`, …), or NA when the source has none (e.g.
    an OpenAlex citation);
  - `origin_in_corpus`, `target_in_corpus` (boolean).

  Extra columns follow S5 (e.g. `zenodo_relation_declared`).
- **K2** The file and its columns MUST exist even when the table has no rows, so
  readers never have to check whether there is one.
- **K4** `origin` and `target` MUST use one identifier form:
  - a record **in the corpus**: its `id` (§5);
  - **outside** the corpus: a DOI as `https://doi.org/<doi>` (I6), a URL as is
    (OpenAlex works as `https://openalex.org/W…`), else `<scheme>:<identifier>` with a
    scheme from I7 other than `doi`, `url` and `openalex` (e.g. `isbn:9780000000000`,
    `arxiv:2101.00001`, `handle:10419/12345`, `pmid:12345678`).

  Something with no identifier at all is not a link; it stays in a prefixed works
  column (e.g. `zenodo_related`).

Relations already in the works columns (e.g. citations in `referenced_works`) need not
be repeated in the link table; a writer may repeat them so its table is complete on its
own. openalexPro does not copy `referenced_works` into it (for a snapshot-sized corpus
that would be hundreds of millions of rows).

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
  output: ids of other writers (`zenodo:…`, `policy:cbd:…`) matched as in I2 (part
  after the last `/`, case-insensitively, never assuming `https://openalex.org/W…`),
  missing optional columns (e.g. no `abstract_inverted_index`), prefixed extra columns
  (ignored or passed through), works in several partitions (L5a), and no
  `_dataset.json` (D4).

### Transformers

- **T1** A transformer is a writer: its output corpus MUST follow §1–§7 under its own
  registered prefix (I5); extra columns taken over from its inputs keep their prefix
  (S5).
- **T2** Its `_dataset.json` MUST record its inputs in `derived_from`, one entry per
  input: `{"path": "<relative to the output>", "content": "<the input's content, D5>"}`;
  for an input without `_dataset.json`, `content` is computed as in D5. The OpenAlex
  snapshot is recorded as `{"source": "openalex-snapshot", "release": "<date>"}`.
  Deterministic, as D2.
- **T3** Relations it produces between records (e.g. citation edges) MUST be written
  as the link table (§7), with the matching `link_type` and `relation`.

### Annotators

- **N1** Annotations MUST be written to
  `<project>/<prefix>_<annotation>/query=<name>/*.parquet`, next to the corpus, with
  the corpus's partition names, one row per record (or per record and item), keyed by
  `id`, so joining is on `id` (and `query`). Internal storage (e.g. a vector database)
  is free; N1 applies to what the package hands on.
- **N2** The annotation folder MUST carry a `_dataset.json` with `"type": "annotation"`,
  `writer`, `content` (D5), `derived_from` (T2), and `method`: the method and its
  settings (e.g. model name and version, parameters). Deterministic, as D2.
- **N3** Annotation columns other than `id` MUST follow S5 (`<prefix>_<name>`).

### Consumers

- **C1** Records that are not OpenAlex works MUST be converted, or reported as skipped
  (count and ids); never dropped silently.

---

## Current compliance

See the published reports: <https://openalexpro.github.io/openalexPro_Ecosystem/>.

## Changes

- **0.1** (2026-11-27) First draft; §8 for analysis and processing packages
  ([#5](https://github.com/openalexPro/openalexPro_Ecosystem/issues/5)). Decisions recorded in
  [#3](https://github.com/openalexPro/openalexPro_Ecosystem/issues/3). Revised after the
  review of 2026-11-27: data fingerprint (D5) and `derived_from` by content (T2); link
  table with the full OpenAlex link-type list and a `relation` column (K1); one level per
  rule (P2/P2a, P6/P6a); P7a for annotators; L5, S4, Q5, K3, P5, C2 and A3 folded into
  notes or A2.
