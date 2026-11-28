# Compliance report: openalexImportZenodo

- **Verdict:** 🟡 compliant (0 MUST, 1 SHOULD to fix)
- **Package:** openalexImportZenodo 0.0.0.9000 &middot; [openalexPro/openalexImportZenodo](https://github.com/openalexPro/openalexImportZenodo) @ dev 55fa6eb
- **Kind:** writer (prefix `zenodo`)
- **Corpus:** built with `zenodo_example_corpus()`
- **Standard:** [STANDARD.md](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md) 0.1 (checker openalexStandard 0.1.0)

🔴 MUST fails · 🟡 SHOULD fails or needs review · 🟢 passes · ⚪ n/a or not checked

## To fix

### 🟡 P6a (SHOULD): CITATION.cff; pkgdown site; dev/main branches

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `CITATION.cff`; no pkgdown site (`_pkgdown.yml`)

**Fix:** add them

<a href="https://github.com/openalexPro/openalexImportZenodo/issues/new?title=Compliance%3A%20P6a%20%28SHOULD%29%20CITATION.cff%3B%20pkgdown%20site%3B%20dev%2Fmain%20branches&body=%2A%2AP6a%2A%2A%20%28SHOULD%29%3A%20CITATION.cff%3B%20pkgdown%20site%3B%20dev%2Fmain%20branches%0A-%20Found%3A%20no%20%60CITATION.cff%60%3B%20no%20pkgdown%20site%20%28%60_pkgdown.yml%60%29%0A-%20Fix%3A%20add%20them%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexImportZenodo%200.0.0.9000%20%40%20dev%2055fa6eb%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexImportZenodo%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #bf8700;border-radius:6px;background:#bf8700;color:#fff;text-decoration:none;font-weight:600">Open issue</a>


## To review

The code cannot check these; a person has to.

- 🟡 **Q2** (SHOULD): _query.json is enough to repeat the download. is `_query.json` enough to repeat the download? (review)

<details markdown="1">
<summary>All 51 rules</summary>

| Rule | Level | Status | Details | Fix |
|---|---|---|---|---|
| L1 | MUST | 🟢 pass | 1 Parquet file(s) |  |
| L2 | MUST | 🟢 pass | 1 `query=` partition(s) |  |
| L3 | MUST | 🟢 pass |  |  |
| L4 | MUST | 🟢 pass |  |  |
| L5a | MUST | ⚪ n/a | applies to consumer, transformer, annotator |  |
| L5b | MUST | 🟢 pass |  |  |
| L5c | MUST | ⚪ n/a | applies to consumer, transformer, annotator |  |
| S1 | MUST | 🟢 pass | 1 works file(s) |  |
| S2 | MUST | 🟢 pass | names and top-level types (nested fields not checked) |  |
| S3 | SHOULD | 🟢 pass |  |  |
| S5 | MUST | 🟢 pass | 21 prefixed extra column(s) |  |
| S5a | MUST | 🟢 pass | reserved: `abstract` (meaning not checked) |  |
| S6 | MUST | 🟢 pass |  |  |
| D1 | MUST | 🟢 pass |  |  |
| D2 | MUST | 🟢 pass |  |  |
| D3 | MUST | 🟢 pass |  |  |
| D4 | MUST | ⚪ n/a | applies to consumer, transformer, annotator |  |
| D5 | MUST | 🟢 pass | sha256:fe7a523f3f0eb0bc5e6233ac0a7c6aaeb2c91afeda259be608c441d3989e915a |  |
| Q1 | MUST | 🟢 pass |  |  |
| Q2 | SHOULD | 🟡 manual | is `_query.json` enough to repeat the download? (review) |  |
| Q3 | SHOULD | 🟢 pass |  |  |
| Q4 | MUST | 🟢 pass | present in the delivered corpus |  |
| I1 | MUST | ⚪ n/a | no OpenAlex ids |  |
| I2 | MUST | 🟢 pass | 7 ids with prefix `zenodo` |  |
| I3 | MUST | 🟢 pass | `zenodo:<conceptrecid, or recid with versions = 'all'>` |  |
| I4 | SHOULD | 🟢 pass |  |  |
| I5 | MUST | 🟢 pass | `zenodo` |  |
| I6 | SHOULD | 🟢 pass |  |  |
| I7 | MUST | 🟢 pass |  |  |
| P1 | MUST | 🟢 pass | `openalexImportZenodo` |  |
| P2 | MUST | ⚪ n/a | does not use openalexPro |  |
| P2a | SHOULD | 🟢 pass | standard 0.1 |  |
| P3 | MUST | 🟢 pass | `zenodo_as_corpus()` |  |
| P4 | MUST | 🟢 pass | test: testthat/test-compliance.R:10 |  |
| P6 | MUST | 🟢 pass | MIT; listed |  |
| P6a | SHOULD | 🟡 fail | no `CITATION.cff`; no pkgdown site (`_pkgdown.yml`) | add them |
| P7 | MUST | 🟢 pass | `zenodo_example_corpus()` |  |
| P7a | MUST | ⚪ n/a | applies to annotator |  |
| K1 | MUST | 🟢 pass | 1 link file(s) |  |
| K2 | MUST | 🟢 pass |  |  |
| K4 | MUST | 🟢 pass | 3 outside end(s), all DOI/URL/`<scheme>:` |  |
| A1 | MUST | ⚪ n/a | applies to consumer, transformer, annotator |  |
| A2 | MUST | ⚪ n/a | applies to consumer, transformer, annotator |  |
| T1 | MUST | ⚪ n/a | applies to transformer |  |
| T2 | MUST | ⚪ n/a | applies to transformer, annotator |  |
| T3 | MUST | ⚪ n/a | applies to transformer |  |
| N1 | MUST | ⚪ n/a | applies to annotator |  |
| N2 | MUST | ⚪ n/a | applies to annotator |  |
| N3 | MUST | ⚪ n/a | applies to annotator |  |
| C1 | MUST | ⚪ n/a | applies to consumer |  |
| API | MUST | 🟢 pass | `prepare_corpus()` builds the database |  |

</details>

## Provenance

Not derived from another corpus.
