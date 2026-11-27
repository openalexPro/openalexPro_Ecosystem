---
name: openalex-compliance-report
description: Write a compliance report for a package that wants to join (or is in) the openalexPro ecosystem — every rule of STANDARD.md with its status, evidence and fix, plus the onboarding steps still to do (prefix registration, repos.tsv row, docs). Use when the user asks for a "compliance report", wants to add a new package to the ecosystem, or asks what a package still needs to be ecosystem compatible. For a quick check without a report file, use openalex-ecosystem-standard instead.
---

# Ecosystem compliance report

Produces `compliance/<package>.md` in the openalexPro_Ecosystem repo
(`~/GitHub/openalexPro_Ecosystem`). All reports live there, so packages stay free of
extra top-level files and the reports can be compared.

## Steps

1. **Read `STANDARD.md`** (repo root) and note its version. Every rule id in it gets a
   row in the report — none skipped, so a missing row never hides a missing check.
2. **Locate the package**: a folder in the ecosystem root, another local path, or a
   GitHub repo (clone it into the scratchpad, read-only). Record the commit
   (`git rev-parse --short HEAD`) and branch checked.
3. **Classify it**: writer (`openalexImport*`, openalexPro), reader
   (`openalexExport*`, openalexAPI), or both. Rules that do not apply are `n/a` with a
   reason, not left out.
4. **Run the checks** as described in the `openalex-ecosystem-standard` skill: package
   checks on the source, corpus checks on a corpus it writes. To get a corpus, use a
   test fixture, `inst/extdata`, or a small run of its `<source>_as_corpus()` into
   the scratchpad — never write into the package or a user's project. If none is
   possible, mark the corpus rules `not verified` and say why.
5. **Write the report** (template below), then summarise it to the user in a few
   lines: verdict, number of MUST failures, the first thing to fix.

Do not change the package. Fixes go in the report; apply them only if the user asks,
following the package's own branching rules (`claude/<description>` from `dev`).

## Template

```markdown
# Compliance report: <package>

- **Standard:** STANDARD.md <version>
- **Package:** <package> <version> · <repo> @ <branch> <commit>
- **Role:** writer | reader | both
- **Date:** <YYYY-MM-DD>
- **Verdict:** compliant | not compliant (<n> MUST, <m> SHOULD open)

## Results

| Rule | Level | Status | Evidence | Fix |
|---|---|---|---|---|
| L1 | MUST | ✓ / ✗ / n/a / not verified | `R/file.R:42`, or the path checked | what to change |
| … one row per rule id in STANDARD.md, in document order … |

## Onboarding steps

- [ ] Writer prefix registered in STANDARD.md I5 (proposed: `<prefix>`)
- [ ] `Config/openalexPro/standard: <version>` in DESCRIPTION
- [ ] Row in `repos.tsv` (dependency order) and entry in `ecosystem.md`
- [ ] Test running `openalexAPI::prepare_corpus()` on a small corpus (P4)
- [ ] Landing page / org profile / r-universe — only once out of alpha

## Notes

Anything the standard does not cover but should — candidates for an issue in
openalexPro_Ecosystem.
```

A re-run overwrites the report; git history in the ecosystem repo keeps the earlier
ones. Commit it only when the user asks (the ecosystem repo commits to `main`).
