---
name: openalex-compliance-report
description: Write a compliance report for a package that wants to join (or is in) the openalexPro ecosystem — every rule of STANDARD.md with its status, evidence and fix, plus the onboarding steps still to do (prefix registration, repos.tsv row, docs). Use when the user asks for a "compliance report", wants to add a new package to the ecosystem, or asks what a package still needs to be ecosystem compatible. For a quick check without a report file, use openalex-ecosystem-standard instead.
---

# Ecosystem compliance report

Reports are produced by **openalexStandard** (`pkg/openalexStandard/` in the
openalexPro_Ecosystem repo, `~/GitHub/openalexPro_Ecosystem`) and published at
<https://openalexpro.github.io/openalexPro_Ecosystem/>. The `compliance` workflow
re-checks the `main` and `dev` branches of every watched package daily at 00:00 UTC
when the branch, `STANDARD.md` or the checker changed. Watched = the r-package rows of
`repos.tsv` plus `compliance/external.tsv`.

## Ways to get a report

- **A watched package, published:** run the workflow on demand —
  `gh workflow run compliance.yml -R openalexPro/openalexPro_Ecosystem -f repo=<owner/name> -f force=true`
  (any `owner/name` works, also one that is not watched; `-f ref=<branch|tag|commit>`).
  The report lands in `compliance/<owner>/<repo>/<branch>.md` and on the page.
- **Locally, e.g. for a package not yet public or a work-in-progress branch:**
  ```r
  pkgload::load_all("~/GitHub/openalexPro_Ecosystem/pkg/openalexStandard")
  compliance_report("<package source>", out_dir = "<scratchpad>/report",
                    repo = "<owner/name>", ref = "<branch>", commit = "<sha>",
                    manifest = "~/GitHub/openalexPro_Ecosystem/repos.tsv")
  ```
  It builds the package's example corpus (`<prefix>_example_corpus()`, P7) in a
  temporary folder, checks it, and writes `report.md` / `report.json`. Never write into
  the package or a user's project.

## Then add what the code cannot check

The report marks those rules `manual`. Review them as described in the
`openalex-ecosystem-standard` skill (A1, A2, T3, C1, D4, L5a, L5c, Q2), and for
consumers, transformers and annotators run the package on a compliant non-OpenAlex
corpus in the scratchpad (A2). Add your findings under **Notes** of a local report, or
summarise them to the user; do not edit published reports by hand (the next run
overwrites them).

Summarise to the user in a few lines: verdict, number of MUST failures, the first thing
to fix, and — for a package that wants to join — the onboarding steps still open:

- prefix registered in STANDARD.md I5 and openalexStandard's `prefixes.csv`
  (writers, transformers, annotators);
- `Config/openalexPro/standard: <version>` in DESCRIPTION;
- `<prefix>_example_corpus(out)`, offline (P7) and a test running
  `openalexAPI::prepare_corpus()` on it (P4) — writers, transformers;
- `<prefix>_example_annotation(out, corpus)` (P7a) — annotators;
- a row in `repos.tsv` (ecosystem) or `compliance/external.tsv` (third party);
- landing page / org profile / r-universe only once out of alpha.

Do not change the package. Fixes go in the report; apply them only if the user asks,
following the package's own branching rules (`claude/<description>` from `dev`).
