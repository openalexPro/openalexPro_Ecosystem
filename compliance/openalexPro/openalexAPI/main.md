# Compliance report: openalexAPI

- **Verdict:** 🔴 not compliant (1 MUST, 1 SHOULD to fix)
- **Package:** openalexAPI 0.1.1 &middot; [openalexPro/openalexAPI](https://github.com/openalexPro/openalexAPI) @ main 7f90007
- **Kind:** consumer
- **Corpus:** not a writer or transformer: no corpus built
- **Standard:** [STANDARD.md](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md) 0.1 (checker openalexStandard 0.1.0)

🔴 MUST fails · 🟡 SHOULD fails or needs review · 🟢 passes · ⚪ n/a or not checked

## To fix

<a href="https://github.com/openalexPro/openalexAPI/issues/new?title=Compliance%20with%20STANDARD.md%200.1%3A%202%20fixes&body=-%20%5B%20%5D%20%2A%2AP2%2A%2A%20%28MUST%29%3A%20openalexPro%20version%20floor%0A%20%20-%20Found%3A%20uses%20openalexPro%20without%20a%20version%20floor%0A%20%20-%20Fix%3A%20declare%20%60openalexPro%20%28%3E%3D%20x.y.z%29%60%20in%20Imports%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A-%20%5B%20%5D%20%2A%2AP2a%2A%2A%20%28SHOULD%29%3A%20Standard%20version%20declared%0A%20%20-%20Found%3A%20no%20%60Config%2FopenalexPro%2Fstandard%60%0A%20%20-%20Fix%3A%20add%20%60Config%2FopenalexPro%2Fstandard%3A%200.1%60%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexAPI%200.1.1%20%40%20main%207f90007%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexAPI%2Fmain.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #cf222e;border-radius:6px;background:#cf222e;color:#fff;text-decoration:none;font-weight:600">Open one issue for all 2 fixes</a>

### 🔴 P2 (MUST): openalexPro version floor

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** uses openalexPro without a version floor

**Fix:** declare `openalexPro (>= x.y.z)` in Imports

<a href="https://github.com/openalexPro/openalexAPI/issues/new?title=Compliance%3A%20P2%20%28MUST%29%20openalexPro%20version%20floor&body=%2A%2AP2%2A%2A%20%28MUST%29%3A%20openalexPro%20version%20floor%0A-%20Found%3A%20uses%20openalexPro%20without%20a%20version%20floor%0A-%20Fix%3A%20declare%20%60openalexPro%20%28%3E%3D%20x.y.z%29%60%20in%20Imports%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexAPI%200.1.1%20%40%20main%207f90007%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexAPI%2Fmain.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #cf222e;border-radius:6px;background:#cf222e;color:#fff;text-decoration:none;font-weight:600">Open issue</a>

### 🟡 P2a (SHOULD): Standard version declared

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `Config/openalexPro/standard`

**Fix:** add `Config/openalexPro/standard: 0.1`

<a href="https://github.com/openalexPro/openalexAPI/issues/new?title=Compliance%3A%20P2a%20%28SHOULD%29%20Standard%20version%20declared&body=%2A%2AP2a%2A%2A%20%28SHOULD%29%3A%20Standard%20version%20declared%0A-%20Found%3A%20no%20%60Config%2FopenalexPro%2Fstandard%60%0A-%20Fix%3A%20add%20%60Config%2FopenalexPro%2Fstandard%3A%200.1%60%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexAPI%200.1.1%20%40%20main%207f90007%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexAPI%2Fmain.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #bf8700;border-radius:6px;background:#bf8700;color:#fff;text-decoration:none;font-weight:600">Open issue</a>


## To review

The code cannot check these; a person has to.

- 🟡 **L5a** (MUST): Deduplicating readers keep all partition values
- 🟡 **L5c** (MUST): Readers accept mixed partition depths and keys
- 🟡 **D4** (MUST): Readers work without _dataset.json
- 🟡 **A1** (MUST): Inputs are read-only. review writes for targets inside the input corpus: `R/corpus.R:39`, `R/corpus.R:49`, `R/corpus.R:287`
- 🟡 **A2** (MUST): Accept any compliant corpus. no OpenAlex-only id patterns found; run it on a non-OpenAlex corpus
- 🟡 **C1** (MUST): Non-OpenAlex records converted or reported

<details markdown="1">
<summary>All 51 rules</summary>

| Rule | Level | Status | Details | Fix |
|---|---|---|---|---|
| L1 | MUST | ⚪ n/a | applies to writer, transformer |  |
| L2 | MUST | ⚪ n/a | applies to writer, transformer |  |
| L3 | MUST | ⚪ n/a | applies to writer, transformer |  |
| L4 | MUST | ⚪ n/a | applies to writer, transformer |  |
| L5a | MUST | 🟡 manual | review: Deduplicating readers keep all partition values |  |
| L5b | MUST | ⚪ n/a | applies to writer, transformer |  |
| L5c | MUST | 🟡 manual | review: Readers accept mixed partition depths and keys |  |
| S1 | MUST | ⚪ n/a | applies to writer, transformer |  |
| S2 | MUST | ⚪ n/a | applies to writer, transformer |  |
| S3 | SHOULD | ⚪ n/a | applies to writer, transformer |  |
| S5 | MUST | ⚪ n/a | applies to writer, transformer |  |
| S5a | MUST | ⚪ n/a | applies to writer, transformer |  |
| S6 | MUST | ⚪ n/a | applies to writer, transformer |  |
| D1 | MUST | ⚪ n/a | applies to writer, transformer |  |
| D2 | MUST | ⚪ n/a | applies to writer, transformer |  |
| D3 | MUST | ⚪ n/a | applies to writer, transformer |  |
| D4 | MUST | 🟡 manual | review: Readers work without _dataset.json |  |
| D5 | MUST | ⚪ n/a | applies to writer, transformer |  |
| Q1 | MUST | ⚪ n/a | applies to writer, transformer |  |
| Q2 | SHOULD | ⚪ n/a | applies to writer, transformer |  |
| Q3 | SHOULD | ⚪ n/a | applies to writer, transformer |  |
| Q4 | MUST | ⚪ n/a | applies to writer, transformer |  |
| I1 | MUST | ⚪ n/a | applies to writer, transformer |  |
| I2 | MUST | ⚪ n/a | applies to writer, transformer |  |
| I3 | MUST | ⚪ n/a | applies to writer, transformer |  |
| I4 | SHOULD | ⚪ n/a | applies to writer, transformer |  |
| I5 | MUST | ⚪ n/a | applies to writer, transformer, annotator |  |
| I6 | SHOULD | ⚪ n/a | applies to writer, transformer |  |
| I7 | MUST | ⚪ n/a | applies to writer, transformer, annotator |  |
| P1 | MUST | 🟢 pass | `openalexAPI` |  |
| P2 | MUST | 🔴 fail | uses openalexPro without a version floor | declare `openalexPro (>= x.y.z)` in Imports |
| P2a | SHOULD | 🟡 fail | no `Config/openalexPro/standard` | add `Config/openalexPro/standard: 0.1` |
| P3 | MUST | ⚪ n/a | applies to `openalexImport*` packages |  |
| P4 | MUST | ⚪ n/a | applies to writer |  |
| P6 | MUST | 🟢 pass | MIT; listed |  |
| P6a | SHOULD | 🟢 pass | CITATION.cff; pkgdown (dev/main branches not checked) |  |
| P7 | MUST | ⚪ n/a | applies to writer, transformer |  |
| P7a | MUST | ⚪ n/a | applies to annotator |  |
| K1 | MUST | ⚪ n/a | applies to writer, transformer |  |
| K2 | MUST | ⚪ n/a | applies to writer, transformer |  |
| K4 | MUST | ⚪ n/a | applies to writer, transformer |  |
| A1 | MUST | 🟡 manual | review writes for targets inside the input corpus: `R/corpus.R:39`, `R/corpus.R:49`, `R/corpus.R:287` |  |
| A2 | MUST | 🟡 manual | no OpenAlex-only id patterns found; run it on a non-OpenAlex corpus |  |
| T1 | MUST | ⚪ n/a | applies to transformer |  |
| T2 | MUST | ⚪ n/a | applies to transformer, annotator |  |
| T3 | MUST | ⚪ n/a | applies to transformer |  |
| N1 | MUST | ⚪ n/a | applies to annotator |  |
| N2 | MUST | ⚪ n/a | applies to annotator |  |
| N3 | MUST | ⚪ n/a | applies to annotator |  |
| C1 | MUST | 🟡 manual | review: Non-OpenAlex records converted or reported |  |
| API | MUST | ⚪ n/a | applies to writer, transformer |  |

</details>

## Provenance

No corpus checked.
