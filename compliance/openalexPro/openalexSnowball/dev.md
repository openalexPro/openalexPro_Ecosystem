# Compliance report: openalexSnowball

- **Verdict:** 🔴 not compliant (1 MUST, 1 SHOULD to fix)
- **Package:** openalexSnowball 0.15.6.9000 &middot; [openalexPro/openalexSnowball](https://github.com/openalexPro/openalexSnowball) @ dev d630a02
- **Kind:** transformer (prefix `snowball`)
- **Corpus:** no example corpus (P7)
- **Standard:** [STANDARD.md](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md) 0.1 (checker openalexStandard 0.1.0)

🔴 MUST fails · 🟡 SHOULD fails or needs review · 🟢 passes · ⚪ n/a or not checked

## To fix

<a href="https://github.com/openalexPro/openalexSnowball/issues/new?title=Compliance%20with%20STANDARD.md%200.1%3A%202%20fixes&body=-%20%5B%20%5D%20%2A%2AP7%2A%2A%20%28MUST%29%3A%20Exports%20%60%3Cprefix%3E_example_corpus%28out%29%60%0A%20%20-%20Found%3A%20no%20%60snowball_example_corpus%28%29%60%20exported%0A%20%20-%20Fix%3A%20export%20it%3A%20writes%20a%20small%20compliant%20corpus%20offline%2C%20returns%20the%20corpus%20folder%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A-%20%5B%20%5D%20%2A%2AP2a%2A%2A%20%28SHOULD%29%3A%20Standard%20version%20declared%0A%20%20-%20Found%3A%20no%20%60Config%2FopenalexPro%2Fstandard%60%0A%20%20-%20Fix%3A%20add%20%60Config%2FopenalexPro%2Fstandard%3A%200.1%60%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexSnowball%200.15.6.9000%20%40%20dev%20d630a02%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexSnowball%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #cf222e;border-radius:6px;background:#cf222e;color:#fff;text-decoration:none;font-weight:600">Open one issue for all 2 fixes</a>

### 🔴 P7 (MUST): Exports `<prefix>_example_corpus(out)`

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `snowball_example_corpus()` exported

**Fix:** export it: writes a small compliant corpus offline, returns the corpus folder

<a href="https://github.com/openalexPro/openalexSnowball/issues/new?title=Compliance%3A%20P7%20%28MUST%29%20Exports%20%60%3Cprefix%3E_example_corpus%28out%29%60&body=%2A%2AP7%2A%2A%20%28MUST%29%3A%20Exports%20%60%3Cprefix%3E_example_corpus%28out%29%60%0A-%20Found%3A%20no%20%60snowball_example_corpus%28%29%60%20exported%0A-%20Fix%3A%20export%20it%3A%20writes%20a%20small%20compliant%20corpus%20offline%2C%20returns%20the%20corpus%20folder%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexSnowball%200.15.6.9000%20%40%20dev%20d630a02%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexSnowball%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #cf222e;border-radius:6px;background:#cf222e;color:#fff;text-decoration:none;font-weight:600">Open issue</a>

### 🟡 P2a (SHOULD): Standard version declared

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `Config/openalexPro/standard`

**Fix:** add `Config/openalexPro/standard: 0.1`

<a href="https://github.com/openalexPro/openalexSnowball/issues/new?title=Compliance%3A%20P2a%20%28SHOULD%29%20Standard%20version%20declared&body=%2A%2AP2a%2A%2A%20%28SHOULD%29%3A%20Standard%20version%20declared%0A-%20Found%3A%20no%20%60Config%2FopenalexPro%2Fstandard%60%0A-%20Fix%3A%20add%20%60Config%2FopenalexPro%2Fstandard%3A%200.1%60%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexSnowball%200.15.6.9000%20%40%20dev%20d630a02%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexSnowball%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #bf8700;border-radius:6px;background:#bf8700;color:#fff;text-decoration:none;font-weight:600">Open issue</a>


## To review

The code cannot check these; a person has to.

- 🟡 **L5a** (MUST): Deduplicating readers keep all partition values
- 🟡 **L5c** (MUST): Readers accept mixed partition depths and keys
- 🟡 **D4** (MUST): Readers work without _dataset.json
- 🟡 **Q2** (SHOULD): _query.json is enough to repeat the download
- 🟡 **A1** (MUST): Inputs are read-only. review writes for targets inside the input corpus: `R/pro_snowball_extract_edges.R:65`, `R/pro_snowball_extract_edges.R:77`, `R/pro_snowball_extract_edges.R:103`, `R/pro_snowball_get_nodes.R:88`, `R/pro_snowball_get_nodes.R:111`, … (16 in all)
- 🟡 **A2** (MUST): Accept any compliant corpus. no OpenAlex-only id patterns found; run it on a non-OpenAlex corpus

## Not checked

- 29 rule(s), no example corpus (P7): L1, L2, L3, L4, L5b, S1, S2, S3, S5, S5a, S6, D1, D2, D3, D5, Q1, Q3, Q4, I1, I2, I3, I4, I6, K1, K2, K4, T1, T2, API
- 1 rule(s), not automated: T3

<details markdown="1">
<summary>All 51 rules</summary>

| Rule | Level | Status | Details | Fix |
|---|---|---|---|---|
| L1 | MUST | ⚪ not verified | no example corpus (P7) |  |
| L2 | MUST | ⚪ not verified | no example corpus (P7) |  |
| L3 | MUST | ⚪ not verified | no example corpus (P7) |  |
| L4 | MUST | ⚪ not verified | no example corpus (P7) |  |
| L5a | MUST | 🟡 manual | review: Deduplicating readers keep all partition values |  |
| L5b | MUST | ⚪ not verified | no example corpus (P7) |  |
| L5c | MUST | 🟡 manual | review: Readers accept mixed partition depths and keys |  |
| S1 | MUST | ⚪ not verified | no example corpus (P7) |  |
| S2 | MUST | ⚪ not verified | no example corpus (P7) |  |
| S3 | SHOULD | ⚪ not verified | no example corpus (P7) |  |
| S5 | MUST | ⚪ not verified | no example corpus (P7) |  |
| S5a | MUST | ⚪ not verified | no example corpus (P7) |  |
| S6 | MUST | ⚪ not verified | no example corpus (P7) |  |
| D1 | MUST | ⚪ not verified | no example corpus (P7) |  |
| D2 | MUST | ⚪ not verified | no example corpus (P7) |  |
| D3 | MUST | ⚪ not verified | no example corpus (P7) |  |
| D4 | MUST | 🟡 manual | review: Readers work without _dataset.json |  |
| D5 | MUST | ⚪ not verified | no example corpus (P7) |  |
| Q1 | MUST | ⚪ not verified | no example corpus (P7) |  |
| Q2 | SHOULD | 🟡 manual | review: _query.json is enough to repeat the download |  |
| Q3 | SHOULD | ⚪ not verified | no example corpus (P7) |  |
| Q4 | MUST | ⚪ not verified | no example corpus (P7) |  |
| I1 | MUST | ⚪ not verified | no example corpus (P7) |  |
| I2 | MUST | ⚪ not verified | no example corpus (P7) |  |
| I3 | MUST | ⚪ not verified | no example corpus (P7) |  |
| I4 | SHOULD | ⚪ not verified | no example corpus (P7) |  |
| I5 | MUST | 🟢 pass | `snowball` |  |
| I6 | SHOULD | ⚪ not verified | no example corpus (P7) |  |
| I7 | MUST | 🟢 pass |  |  |
| P1 | MUST | 🟢 pass | `openalexSnowball` |  |
| P2 | MUST | 🟢 pass | openalexPro with a version floor |  |
| P2a | SHOULD | 🟡 fail | no `Config/openalexPro/standard` | add `Config/openalexPro/standard: 0.1` |
| P3 | MUST | ⚪ n/a | applies to `openalexImport*` packages |  |
| P4 | MUST | ⚪ n/a | applies to writer |  |
| P6 | MUST | 🟢 pass | MIT; listed |  |
| P6a | SHOULD | 🟢 pass | CITATION.cff; pkgdown (dev/main branches not checked) |  |
| P7 | MUST | 🔴 fail | no `snowball_example_corpus()` exported | export it: writes a small compliant corpus offline, returns the corpus folder |
| P7a | MUST | ⚪ n/a | applies to annotator |  |
| K1 | MUST | ⚪ not verified | no example corpus (P7) |  |
| K2 | MUST | ⚪ not verified | no example corpus (P7) |  |
| K4 | MUST | ⚪ not verified | no example corpus (P7) |  |
| A1 | MUST | 🟡 manual | review writes for targets inside the input corpus: `R/pro_snowball_extract_edges.R:65`, `R/pro_snowball_extract_edges.R:77`, `R/pro_snowball_extract_edges.R:103`, `R/pro_snowball_get_nodes.R:88`, `R/pro_snowball_get_nodes.R:111`, … (16 in all) |  |
| A2 | MUST | 🟡 manual | no OpenAlex-only id patterns found; run it on a non-OpenAlex corpus |  |
| T1 | MUST | ⚪ not verified | no example corpus (P7) |  |
| T2 | MUST | ⚪ not verified | no example corpus (P7) |  |
| T3 | MUST | ⚪ not verified | not automated |  |
| N1 | MUST | ⚪ n/a | applies to annotator |  |
| N2 | MUST | ⚪ n/a | applies to annotator |  |
| N3 | MUST | ⚪ n/a | applies to annotator |  |
| C1 | MUST | ⚪ n/a | applies to consumer |  |
| API | MUST | ⚪ not verified | no example corpus (P7) |  |

</details>

## Provenance

No corpus checked.
