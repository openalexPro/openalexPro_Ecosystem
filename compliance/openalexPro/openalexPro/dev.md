# Compliance report: openalexPro

- **Standard:** STANDARD.md 0.1 (checker openalexStandard 0.1.0)
- **Package:** openalexPro 0.19.0.9000 &middot; openalexPro/openalexPro @ dev a6981a0
- **Kind:** writer (prefix `oapro`)
- **Corpus:** no example corpus (P7)
- **Verdict:** not compliant (2 MUST, 1 SHOULD open)

## Results

| Rule | Level | Status | Evidence | Fix |
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
| I5 | MUST | &#x2713; | `oapro` |  |
| I6 | SHOULD | not verified | no example corpus (P7) |  |
| I7 | MUST | &#x2713; |  |  |
| P1 | MUST | &#x2713; | `openalexPro` |  |
| P2 | SHOULD | &#x2717; | no `Config/openalexPro/standard` | add `Config/openalexPro/standard: 0.1` |
| P3 | MUST | not verified | not automated |  |
| P4 | MUST | &#x2717; | no test calls `openalexAPI::prepare_corpus()` | add one on the example corpus (P7) |
| P5 | MUST | n/a | applies to consumer |  |
| P6 | MUST | &#x2713; | MIT; CITATION.cff; pkgdown (dev/main branches not checked) |  |
| P7 | MUST | &#x2717; | no `oapro_example_corpus()` exported | export it: writes a small compliant corpus offline, returns the corpus folder |
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

## Provenance

No corpus checked.
