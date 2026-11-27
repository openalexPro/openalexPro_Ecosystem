---
name: openalex-ecosystem-standard
description: Check an openalexPro ecosystem package (R package source) or a corpus folder (Parquet works + _dataset.json/_query.json) against STANDARD.md, the ecosystem's corpus and package standard, and report each rule it breaks. Also use when writing or changing a package that writes, reads, transforms or annotates corpora (openalexImport*/openalexExport*, openalexPro, openalexAPI, openalexSnowball, openalexVectorComp, openalexConvert, openalexSnapshot), or when the user asks whether something "follows the standard" or "is ecosystem compatible".
---

# openalexPro ecosystem standard check

The rules live in `STANDARD.md` at the root of the openalexPro_Ecosystem repo
(`~/GitHub/openalexPro_Ecosystem/STANDARD.md`). **Read it first, every time.** Rule
ids (L1, S1, D3, …) come from it, so cite them.

The automatable checks are code: the R package **openalexStandard** in
`pkg/openalexStandard/` of that repo. Use it; do not re-implement its queries.

```r
pkgload::load_all("~/GitHub/openalexPro_Ecosystem/pkg/openalexStandard")  # or library(openalexStandard)
check_corpus("<project>/<corpus>")          # §1–§5, §7, API; kind = "transformer" adds T1/T2
check_annotation("<project>/<prefix>_<name>", corpus = "<project>/<corpus>")  # N1–N3, T2
check_package("<package source>")           # P1–P7a, I5/I7, kind detection, A1/A2 hints
provenance("<corpus or annotation>")        # derived_from chain, fingerprints checked (D5)
content_fingerprint("<corpus>")             # the D5 fingerprint of the data
```

Each returns one row per rule: `rule, level, status (pass/fail/n/a/not verified/manual),
evidence, fix`. Never modify the corpus or package you check; build anything you need
(e.g. a corpus from the package's `<prefix>_example_corpus()`) in the scratchpad.

## What is left for you (status `manual`, or `partly` automated)

Mostly packages that read corpora (§8):

- **A1** (inputs read-only): `check_package()` lists the write calls; read each and
  decide whether its target can be inside the input corpus folder.
- **A2** (accept any compliant corpus): run the package's main reader on a compliant
  non-OpenAlex corpus (e.g. one built by openalexImportZenodo: `zenodo:` ids, no
  `abstract_inverted_index`) in the scratchpad. Errors, or records lost without a
  message, are failures.
- **A2, id handling**: `check_package()` lists suspicious lines (`"^W"`,
  `openalex.org/W`, …); decide which assume OpenAlex ids.
- **T3** (relations as the link table), **C1** (non-OpenAlex records converted or
  reported), **D4** (no `_dataset.json` required), **L5a/L5c** (partition keys), **Q2**
  (`_query.json` enough to repeat the download): read the code.
- **S2/S5a**: the checker compares names and top-level types only (JSON text for a
  nested field is accepted); check nested structure and the meaning of reserved
  columns when in doubt.

## Report

One table, most serious first: rule id, MUST/SHOULD, what was found (file:line or
path), the fix. Then one line: compliant / not compliant with STANDARD.md version X.
For a full report file use the `openalex-compliance-report` skill; to fix a package,
the `openalex-compliance-fix` skill. Report only; change
code only if the user asks.

If the standard and openalexPro, openalexAPI or openalexStandard disagree, say so: the
standard is what gets fixed (and then the checker), through an issue in
openalexPro_Ecosystem, not silently worked around.
