# Compliance report: openalexImportZenodo

- **Verdict:** not compliant (2 MUST, 2 SHOULD to fix)
- **Package:** openalexImportZenodo 0.0.0.9000 &middot; [openalexPro/openalexImportZenodo](https://github.com/openalexPro/openalexImportZenodo) @ dev 60f58cd
- **Kind:** writer (prefix `zenodo`)
- **Corpus:** no example corpus (P7)
- **Standard:** [STANDARD.md](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md) 0.1 (checker openalexStandard 0.1.0)

## To fix

<a href="https://github.com/openalexPro/openalexImportZenodo/issues/new?title=Compliance%20with%20STANDARD.md%200.1%3A%204%20fixes&body=-%20%5B%20%5D%20%2A%2AP4%2A%2A%20%28MUST%29%3A%20Test%20runs%20openalexAPI%3A%3Aprepare_corpus%28%29%0A%20%20-%20Found%3A%20no%20test%20calls%20%60openalexAPI%3A%3Aprepare_corpus%28%29%60%0A%20%20-%20Fix%3A%20add%20one%20on%20the%20example%20corpus%20%28P7%29%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A-%20%5B%20%5D%20%2A%2AP7%2A%2A%20%28MUST%29%3A%20Exports%20%60%3Cprefix%3E_example_corpus%28out%29%60%0A%20%20-%20Found%3A%20no%20%60zenodo_example_corpus%28%29%60%20exported%0A%20%20-%20Fix%3A%20export%20it%3A%20writes%20a%20small%20compliant%20corpus%20offline%2C%20returns%20the%20corpus%20folder%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A-%20%5B%20%5D%20%2A%2AP2%2A%2A%20%28SHOULD%29%3A%20openalexPro%20floor%3B%20standard%20version%20declared%0A%20%20-%20Found%3A%20no%20%60Config%2FopenalexPro%2Fstandard%60%0A%20%20-%20Fix%3A%20add%20%60Config%2FopenalexPro%2Fstandard%3A%200.1%60%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A-%20%5B%20%5D%20%2A%2AP6%2A%2A%20%28SHOULD%29%3A%20MIT%20licence%3B%20repos.tsv%3B%20dev%2Fmain%3B%20CITATION.cff%3B%20pkgdown%0A%20%20-%20Found%3A%20no%20%60CITATION.cff%60%3B%20no%20pkgdown%20site%20%28%60_pkgdown.yml%60%29%0A%20%20-%20Fix%3A%20add%20them%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexImportZenodo%200.0.0.9000%20%40%20dev%2060f58cd%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexImportZenodo%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #1f883d;border-radius:6px;background:#1f883d;color:#fff;text-decoration:none;font-weight:600">Open one issue for all 4 fixes</a>

### &#x2717; P4 (MUST): Test runs openalexAPI::prepare_corpus()

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no test calls `openalexAPI::prepare_corpus()`

**Fix:** add one on the example corpus (P7)

<a href="https://github.com/openalexPro/openalexImportZenodo/issues/new?title=Compliance%3A%20P4%20%28MUST%29%20Test%20runs%20openalexAPI%3A%3Aprepare_corpus%28%29&body=%2A%2AP4%2A%2A%20%28MUST%29%3A%20Test%20runs%20openalexAPI%3A%3Aprepare_corpus%28%29%0A-%20Found%3A%20no%20test%20calls%20%60openalexAPI%3A%3Aprepare_corpus%28%29%60%0A-%20Fix%3A%20add%20one%20on%20the%20example%20corpus%20%28P7%29%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexImportZenodo%200.0.0.9000%20%40%20dev%2060f58cd%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexImportZenodo%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #1f883d;border-radius:6px;background:#1f883d;color:#fff;text-decoration:none;font-weight:600">Open issue</a>

### &#x2717; P7 (MUST): Exports `<prefix>_example_corpus(out)`

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `zenodo_example_corpus()` exported

**Fix:** export it: writes a small compliant corpus offline, returns the corpus folder

<a href="https://github.com/openalexPro/openalexImportZenodo/issues/new?title=Compliance%3A%20P7%20%28MUST%29%20Exports%20%60%3Cprefix%3E_example_corpus%28out%29%60&body=%2A%2AP7%2A%2A%20%28MUST%29%3A%20Exports%20%60%3Cprefix%3E_example_corpus%28out%29%60%0A-%20Found%3A%20no%20%60zenodo_example_corpus%28%29%60%20exported%0A-%20Fix%3A%20export%20it%3A%20writes%20a%20small%20compliant%20corpus%20offline%2C%20returns%20the%20corpus%20folder%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexImportZenodo%200.0.0.9000%20%40%20dev%2060f58cd%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexImportZenodo%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #1f883d;border-radius:6px;background:#1f883d;color:#fff;text-decoration:none;font-weight:600">Open issue</a>

### &#x2717; P2 (SHOULD): openalexPro floor; standard version declared

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `Config/openalexPro/standard`

**Fix:** add `Config/openalexPro/standard: 0.1`

<a href="https://github.com/openalexPro/openalexImportZenodo/issues/new?title=Compliance%3A%20P2%20%28SHOULD%29%20openalexPro%20floor%3B%20standard%20version%20declared&body=%2A%2AP2%2A%2A%20%28SHOULD%29%3A%20openalexPro%20floor%3B%20standard%20version%20declared%0A-%20Found%3A%20no%20%60Config%2FopenalexPro%2Fstandard%60%0A-%20Fix%3A%20add%20%60Config%2FopenalexPro%2Fstandard%3A%200.1%60%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexImportZenodo%200.0.0.9000%20%40%20dev%2060f58cd%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexImportZenodo%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #1f883d;border-radius:6px;background:#1f883d;color:#fff;text-decoration:none;font-weight:600">Open issue</a>

### &#x2717; P6 (SHOULD): MIT licence; repos.tsv; dev/main; CITATION.cff; pkgdown

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `CITATION.cff`; no pkgdown site (`_pkgdown.yml`)

**Fix:** add them

<a href="https://github.com/openalexPro/openalexImportZenodo/issues/new?title=Compliance%3A%20P6%20%28SHOULD%29%20MIT%20licence%3B%20repos.tsv%3B%20dev%2Fmain%3B%20CITATION.cff%3B%20pkgdown&body=%2A%2AP6%2A%2A%20%28SHOULD%29%3A%20MIT%20licence%3B%20repos.tsv%3B%20dev%2Fmain%3B%20CITATION.cff%3B%20pkgdown%0A-%20Found%3A%20no%20%60CITATION.cff%60%3B%20no%20pkgdown%20site%20%28%60_pkgdown.yml%60%29%0A-%20Fix%3A%20add%20them%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexImportZenodo%200.0.0.9000%20%40%20dev%2060f58cd%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexImportZenodo%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #1f883d;border-radius:6px;background:#1f883d;color:#fff;text-decoration:none;font-weight:600">Open issue</a>


## To review

The code cannot check these; a person has to.

- **Q2** (SHOULD): _query.json is enough to repeat the download

## Not checked

- 29 rule(s), no example corpus (P7): L1, L2, L3, L4, L5b, S1, S2, S3, S4, S5, S5a, S6, D1, D2, D3, Q1, Q3, Q4, Q5, I1, I2, I3, I4, I6, K1, K2, K3, K4, API

<details markdown="1">
<summary>All 54 rules</summary>

| Rule | Level | Status | Details | Fix |
|---|---|---|---|---|
| L1 | MUST | not verified | no example corpus (P7) |  |
| L2 | MUST | not verified | no example corpus (P7) |  |
| L3 | MUST | not verified | no example corpus (P7) |  |
| L4 | MUST | not verified | no example corpus (P7) |  |
| L5 | MAY | n/a | applies to consumer, transformer, annotator |  |
| L5a | MUST | n/a | applies to consumer, transformer, annotator |  |
| L5b | MUST | not verified | no example corpus (P7) |  |
| L5c | MUST | n/a | applies to consumer, transformer, annotator |  |
| S1 | MUST | not verified | no example corpus (P7) |  |
| S2 | MUST | not verified | no example corpus (P7) |  |
| S3 | SHOULD | not verified | no example corpus (P7) |  |
| S4 | MAY | not verified | no example corpus (P7) |  |
| S5 | MUST | not verified | no example corpus (P7) |  |
| S5a | MUST | not verified | no example corpus (P7) |  |
| S6 | MUST | not verified | no example corpus (P7) |  |
| D1 | MUST | not verified | no example corpus (P7) |  |
| D2 | MUST | not verified | no example corpus (P7) |  |
| D3 | MUST | not verified | no example corpus (P7) |  |
| D4 | MUST | n/a | applies to consumer, transformer, annotator |  |
| Q1 | MUST | not verified | no example corpus (P7) |  |
| Q2 | SHOULD | manual | review: _query.json is enough to repeat the download |  |
| Q3 | SHOULD | not verified | no example corpus (P7) |  |
| Q4 | MUST | not verified | no example corpus (P7) |  |
| Q5 | MAY | not verified | no example corpus (P7) |  |
| I1 | MUST | not verified | no example corpus (P7) |  |
| I2 | MUST | not verified | no example corpus (P7) |  |
| I3 | MUST | not verified | no example corpus (P7) |  |
| I4 | SHOULD | not verified | no example corpus (P7) |  |
| I5 | MUST | &#x2713; | `zenodo` |  |
| I6 | SHOULD | not verified | no example corpus (P7) |  |
| I7 | MUST | &#x2713; |  |  |
| P1 | MUST | &#x2713; | `openalexImportZenodo` |  |
| P2 | SHOULD | &#x2717; | no `Config/openalexPro/standard` | add `Config/openalexPro/standard: 0.1` |
| P3 | MUST | &#x2713; | `zenodo_as_corpus()` |  |
| P4 | MUST | &#x2717; | no test calls `openalexAPI::prepare_corpus()` | add one on the example corpus (P7) |
| P5 | MUST | n/a | applies to consumer |  |
| P6 | SHOULD | &#x2717; | no `CITATION.cff`; no pkgdown site (`_pkgdown.yml`) | add them |
| P7 | MUST | &#x2717; | no `zenodo_example_corpus()` exported | export it: writes a small compliant corpus offline, returns the corpus folder |
| K1 | MUST | not verified | no example corpus (P7) |  |
| K2 | MUST | not verified | no example corpus (P7) |  |
| K3 | MAY | not verified | no example corpus (P7) |  |
| K4 | MUST | not verified | no example corpus (P7) |  |
| A1 | MUST | n/a | applies to consumer, transformer, annotator |  |
| A2 | MUST | n/a | applies to consumer, transformer, annotator |  |
| A3 | MUST | n/a | applies to consumer, transformer, annotator |  |
| T1 | MUST | n/a | applies to transformer |  |
| T2 | MUST | n/a | applies to transformer, annotator |  |
| T3 | MUST | n/a | applies to transformer |  |
| N1 | MUST | n/a | applies to annotator |  |
| N2 | MUST | n/a | applies to annotator |  |
| N3 | MUST | n/a | applies to annotator |  |
| C1 | MUST | n/a | applies to consumer |  |
| C2 | MUST | n/a | applies to consumer |  |
| API | MUST | not verified | no example corpus (P7) |  |

</details>

## Provenance

No corpus checked.
