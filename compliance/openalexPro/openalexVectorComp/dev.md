# Compliance report: openalexVectorComp

- **Verdict:** 🔴 not compliant (1 MUST, 1 SHOULD to fix)
- **Package:** openalexVectorComp 0.3.6.9000 &middot; [openalexPro/openalexVectorComp](https://github.com/openalexPro/openalexVectorComp) @ dev 025a87d
- **Kind:** annotator (prefix `vectorcomp`)
- **Corpus:** no example annotation (P7a)
- **Standard:** [STANDARD.md](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md) 0.1 (checker openalexStandard 0.1.0)

🔴 MUST fails · 🟡 SHOULD fails or needs review · 🟢 passes · ⚪ n/a or not checked

## To fix

<a href="https://github.com/openalexPro/openalexVectorComp/issues/new?title=Compliance%20with%20STANDARD.md%200.1%3A%202%20fixes&body=-%20%5B%20%5D%20%2A%2AP7a%2A%2A%20%28MUST%29%3A%20Exports%20%60%3Cprefix%3E_example_annotation%28out%2C%20corpus%29%60%0A%20%20-%20Found%3A%20no%20%60vectorcomp_example_annotation%28%29%60%20exported%0A%20%20-%20Fix%3A%20export%20it%3A%20annotates%20a%20given%20corpus%20offline%2C%20returns%20the%20annotation%20folder%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A-%20%5B%20%5D%20%2A%2AP2a%2A%2A%20%28SHOULD%29%3A%20Standard%20version%20declared%0A%20%20-%20Found%3A%20no%20%60Config%2FopenalexPro%2Fstandard%60%0A%20%20-%20Fix%3A%20add%20%60Config%2FopenalexPro%2Fstandard%3A%200.1%60%0A%20%20-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexVectorComp%200.3.6.9000%20%40%20dev%20025a87d%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexVectorComp%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #cf222e;border-radius:6px;background:#cf222e;color:#fff;text-decoration:none;font-weight:600">Open one issue for all 2 fixes</a>

### 🔴 P7a (MUST): Exports `<prefix>_example_annotation(out, corpus)`

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `vectorcomp_example_annotation()` exported

**Fix:** export it: annotates a given corpus offline, returns the annotation folder

<a href="https://github.com/openalexPro/openalexVectorComp/issues/new?title=Compliance%3A%20P7a%20%28MUST%29%20Exports%20%60%3Cprefix%3E_example_annotation%28out%2C%20corpus%29%60&body=%2A%2AP7a%2A%2A%20%28MUST%29%3A%20Exports%20%60%3Cprefix%3E_example_annotation%28out%2C%20corpus%29%60%0A-%20Found%3A%20no%20%60vectorcomp_example_annotation%28%29%60%20exported%0A-%20Fix%3A%20export%20it%3A%20annotates%20a%20given%20corpus%20offline%2C%20returns%20the%20annotation%20folder%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexVectorComp%200.3.6.9000%20%40%20dev%20025a87d%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexVectorComp%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #cf222e;border-radius:6px;background:#cf222e;color:#fff;text-decoration:none;font-weight:600">Open issue</a>

### 🟡 P2a (SHOULD): Standard version declared

**Why:** Packages can be installed and tested together and their output checked automatically. ([STANDARD.md §6](https://github.com/openalexPro/openalexPro_Ecosystem/blob/main/STANDARD.md#6-package-requirements))

**Found:** no `Config/openalexPro/standard`

**Fix:** add `Config/openalexPro/standard: 0.1`

<a href="https://github.com/openalexPro/openalexVectorComp/issues/new?title=Compliance%3A%20P2a%20%28SHOULD%29%20Standard%20version%20declared&body=%2A%2AP2a%2A%2A%20%28SHOULD%29%3A%20Standard%20version%20declared%0A-%20Found%3A%20no%20%60Config%2FopenalexPro%2Fstandard%60%0A-%20Fix%3A%20add%20%60Config%2FopenalexPro%2Fstandard%3A%200.1%60%0A-%20Rule%3A%20https%3A%2F%2Fgithub.com%2FopenalexPro%2FopenalexPro_Ecosystem%2Fblob%2Fmain%2FSTANDARD.md%236-package-requirements%0A%0AChecked%3A%20openalexVectorComp%200.3.6.9000%20%40%20dev%20025a87d%2C%20STANDARD.md%200.1%2C%20openalexStandard%200.1.0%0AReport%3A%20https%3A%2F%2Fopenalexpro.github.io%2FopenalexPro_Ecosystem%2FopenalexPro%2FopenalexVectorComp%2Fdev.html&labels=compliance" style="display:inline-block;padding:4px 12px;border:1px solid #bf8700;border-radius:6px;background:#bf8700;color:#fff;text-decoration:none;font-weight:600">Open issue</a>


## To review

The code cannot check these; a person has to.

- 🟡 **L5a** (MUST): Deduplicating readers keep all partition values
- 🟡 **L5c** (MUST): Readers accept mixed partition depths and keys
- 🟡 **D4** (MUST): Readers work without _dataset.json
- 🟡 **A1** (MUST): Inputs are read-only. review writes for targets inside the input corpus: `R/batch_collect_openai.R:33`, `R/batch_collect_openai.R:106`, `R/batch_openai_helpers.R:435`, `R/batch_openai_helpers.R:440`, `R/batch_openai_helpers.R:441`, … (27 in all)
- 🟡 **A2** (MUST): Accept any compliant corpus. no OpenAlex-only id patterns found; run it on a non-OpenAlex corpus

## Not checked

- 4 rule(s), no example annotation (P7a): T2, N1, N2, N3

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
| I5 | MUST | 🟢 pass | `vectorcomp` |  |
| I6 | SHOULD | ⚪ n/a | applies to writer, transformer |  |
| I7 | MUST | 🟢 pass |  |  |
| P1 | MUST | 🟢 pass | `openalexVectorComp` |  |
| P2 | MUST | ⚪ n/a | does not use openalexPro |  |
| P2a | SHOULD | 🟡 fail | no `Config/openalexPro/standard` | add `Config/openalexPro/standard: 0.1` |
| P3 | MUST | ⚪ n/a | applies to `openalexImport*` packages |  |
| P4 | MUST | ⚪ n/a | applies to writer |  |
| P6 | MUST | 🟢 pass | MIT; listed |  |
| P6a | SHOULD | 🟢 pass | CITATION.cff; pkgdown (dev/main branches not checked) |  |
| P7 | MUST | ⚪ n/a | applies to writer, transformer |  |
| P7a | MUST | 🔴 fail | no `vectorcomp_example_annotation()` exported | export it: annotates a given corpus offline, returns the annotation folder |
| K1 | MUST | ⚪ n/a | applies to writer, transformer |  |
| K2 | MUST | ⚪ n/a | applies to writer, transformer |  |
| K4 | MUST | ⚪ n/a | applies to writer, transformer |  |
| A1 | MUST | 🟡 manual | review writes for targets inside the input corpus: `R/batch_collect_openai.R:33`, `R/batch_collect_openai.R:106`, `R/batch_openai_helpers.R:435`, `R/batch_openai_helpers.R:440`, `R/batch_openai_helpers.R:441`, … (27 in all) |  |
| A2 | MUST | 🟡 manual | no OpenAlex-only id patterns found; run it on a non-OpenAlex corpus |  |
| T1 | MUST | ⚪ n/a | applies to transformer |  |
| T2 | MUST | ⚪ not verified | no example annotation (P7a) |  |
| T3 | MUST | ⚪ n/a | applies to transformer |  |
| N1 | MUST | ⚪ not verified | no example annotation (P7a) |  |
| N2 | MUST | ⚪ not verified | no example annotation (P7a) |  |
| N3 | MUST | ⚪ not verified | no example annotation (P7a) |  |
| C1 | MUST | ⚪ n/a | applies to consumer |  |
| API | MUST | ⚪ n/a | applies to writer, transformer |  |

</details>

## Provenance

No corpus checked.
