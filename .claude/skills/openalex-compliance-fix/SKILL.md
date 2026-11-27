---
name: openalex-compliance-fix
description: Fix an openalexPro ecosystem package so it complies with STANDARD.md — work through the failing rules of its compliance report (MUST first), using openalexStandard's helpers (use_compliance, write_dataset_json, write_links) and re-running compliance_report() until the MUST rules pass, on a claude/ branch (push and PR only when the user asks). Use when the user asks to fix, make compliant, or address the compliance report / issues of a package (e.g. "fix the Zenodo compliance issues", "make openalexImportPolicy compliant").
---

# Fix a package's compliance with STANDARD.md

`STANDARD.md` (root of `~/GitHub/openalexPro_Ecosystem`) is the contract; the checker
and helpers are the R package **openalexStandard** in `pkg/openalexStandard/` of that
repo. Read STANDARD.md and the package's current report first. Published reports:
<https://openalexpro.github.io/openalexPro_Ecosystem/>; open `compliance` issues in the
package repository may cover the same fixes — link them in the PR.

## Setup

1. Work in the package's own clone (`~/GitHub/openalexPro_Ecosystem/<package>`), on a
   new branch `claude/<description>` from an up-to-date `dev`. Never commit to `main`
   or `dev` directly. Leave unrelated local changes alone.
2. Fresh baseline, so you fix what the code actually does today:
   ```r
   pkgload::load_all("~/GitHub/openalexPro_Ecosystem/pkg/openalexStandard")
   # inside the package clone, so the package is "."
   r <- compliance_report(".", repo = "openalexPro/<package>", ref = "<branch>",
                          manifest = c("~/GitHub/openalexPro_Ecosystem/repos.tsv",
                                       "~/GitHub/openalexPro_Ecosystem/compliance/external.tsv"))
   r[r$status == "fail", c("rule", "level", "evidence", "fix")]
   ```

## Order of work

MUST before SHOULD; within that, the order below — each step unblocks the next.

1. **Scaffolding** — `use_compliance(".")` (writers/transformers/annotators need a
   registered prefix; if there is none, stop and ask the user to register one in
   STANDARD.md I5). It adds `Config/openalexPro/standard` (P2), Suggests, a stub of
   `<prefix>_example_corpus()` (P7), `tests/testthat/test-compliance.R` (P4) and the
   PR-check workflow (`fail-on: none`). It never overwrites; read its messages.
   openalexStandard and openalexAPI are on GitHub only: add them to `Remotes:`
   (`openalexPro/openalexPro_Ecosystem/pkg/openalexStandard`, `openalexPro/openalexAPI`),
   or CI cannot install them and the compliance tests are silently skipped.
2. **Example corpus (P7)** — implement the stub: a few records from data shipped in
   `inst/extdata` (no network, no API key), written with the package's own corpus
   writer into `file.path(out, "corpus")` and `file.path(out, "links")`; return the
   corpus folder. Reuse the package's real writing code — the example corpus is only
   useful if it goes through the same path as real corpora.
3. **Corpus rules** — now `compliance_report()` checks the corpus. Fix in the package's
   writer, not in the example:
   - `_dataset.json` (D1–D3, I3): call `openalexStandard::write_dataset_json()` where
     the corpus is written, after the data (it fingerprints them, D5);
     transformers/annotators pass `derived_from` (input folders, or
     `list(source = "openalex-snapshot", release = ...)`).
   - link table (K1–K4): build it as a data frame — `origin`, `target`, `link_type`
     (an OpenAlex link type from `/links`, or NA), `relation` (the DataCite relation, or
     NA), prefixed extras — and write it with
     `openalexStandard::write_links()`; it rejects bad link ends (e.g. a bare ISBN →
     `isbn:<id>`) and unprefixed columns, so fix the mapping until it accepts.
   - layout, columns, ids (L*, S*, I*): rename/prefix in the writer's SQL or code.
   If a writer uses the helpers at run time, openalexStandard moves from Suggests to
   Imports (`usethis::use_package("openalexStandard")`); say so in the PR.
   **Annotators** instead: implement `<prefix>_example_annotation(out, corpus)` (P7a;
   `openalexStandard::standard_example_corpus()` gives a corpus to try it on), write
   `<project>/<prefix>_<annotation>/query=<name>/` keyed by `id`, prefixed columns, and
   `write_dataset_json(type = "annotation", derived_from = corpus, method = list(...))`.
4. **Package rules** — P2 floor, P6 `CITATION.cff` / pkgdown (SHOULD) etc., as the
   report's fixes say.
5. **SHOULD rules** — only after every MUST passes, and only those the user wants now.

After each step: `devtools::document()`, `devtools::test()`, re-run
`compliance_report()`; commit per rule or small group, message
`fix(compliance): <rule> <what>` and `Refs openalexPro/openalexPro_Ecosystem#6` plus any
package issue. Don't touch tests to make them pass; fix the code.

## Stop and ask

- A fix changes the package's output for existing users (renamed columns, new
  partition key, new ID form): breaking — say so, propose a NEWS entry / version bump,
  and ask before doing it (cf. openalexSnowball#24's `edge_format` approach).
- `manual` rules (A1, A2, T3, C1, D4, L5a, L5c, Q2): review and report; don't guess-fix.
- The standard looks wrong for this package: don't work around it — propose an issue
  in openalexPro_Ecosystem.

## Finish

- Final `compliance_report()`: list what passes now and what is still open (and why).
- Push the branch and open a PR into `dev` only when the user asks; the PR body lists
  the rules fixed, the breaking changes, and the remaining open rules.
- Once the MUST rules pass, suggest switching the PR check to `fail-on: must`.
