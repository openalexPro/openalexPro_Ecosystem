# openalexPro Ecosystem

How this directory is organised, and how to work across the packages in it.

**Last updated:** 2026-08-17

---

## Decision: independent clones, not submodules

The package directories are **independent git clones**, coordinated by a manifest
(`repos.tsv`) and a `Makefile`. There is no superproject that tracks package commits.
The same manifest also carries two non-package **support** repositories — see
"The manifest" below.

Submodules were considered and rejected. They earn their keep when a superproject's
job is to record *known-good combinations* of pinned release tags. That is not what
this directory is for — it is a workspace for active, parallel development across
seven independently released, independently DOI-archived packages. In that setting
submodules cost more than they return:

* every package commit needs a second superproject commit to bump the pointer, or the
  superproject sits permanently dirty;
* `git submodule update` leaves submodules on a detached HEAD, which fights the
  `claude/<description>`-branched-off-`dev` workflow;
* it is easy to push a superproject pointing at a submodule commit that was never
  pushed, which is unresolvable for anyone else;
* a clone without `--recursive` silently yields empty directories.

If a reproducible "known-good set" is ever wanted, the right tool is the
`openalexverse` meta-package described in Part 5 of `compatibility_report.md` — an R
package whose `Imports:` pins tested minimums — not a git superproject.

---

## Layout

```
~/GitHub/openalexPro_Ecosystem/  (~/GitHub/openalexPro is a symlink to it)
├── .gitignore                  ignores every cloned repo directory, explicitly
├── repos.tsv                   the manifest
├── Makefile                    the verbs
├── ecosystem.md                this file
├── compatibility_report.md     cross-package audit and migration decisions
├── .git/                       tracks ONLY the files above, never the repos
├── .claude/                    Claude Code settings (see note below)
│
├── openalexPro/                ┐
├── openalexSnapshot/           │
├── openalexConvert/            ├─ R packages: independent clones, ignored here
├── openalexSnowball/           │
├── openalexVectorComp/         ┘
├── openalexStemCheck/          not a git repository (see below)
├── openalexASReview/           no remote; slated for retirement (see below)
│
├── dot-github/                 clone of the org's .github repo (support)
└── openalexpro.github.io/      clone of the Pages landing page (support)
```

The root is a thin git repository: it versions the tooling and the documentation, and
nothing else. It was initialised and given its first commit on 2026-08-17. It has
**no remote yet**.

**This repository has no `dev` branch, by design.** Development happens inside the
individual package repositories; this one only ever carries coordination files, so
commits land directly on `main`. The `claude/<description>`-off-`dev` convention
applies to the packages, not here.

**`.github/` is deliberately not used as a clone directory.** The organisation's
`.github` repository is cloned into `dot-github/` instead. Cloning it into `.github/`
would have taken the one directory name this repository may itself need for workflows
and issue templates, and a hidden directory is easy to miss — `ls` does not show it,
and a `for p in openalex*/` style loop skips it while still matching
`openalexpro.github.io/`. The local directory name and the repository name differ as
a result; `repos.tsv` maps between them and `make clone` handles it transparently.

`.claude/` currently holds only `settings.local.json`, which is covered by the global
ignore file `~/.config/git/ignore` — so the directory is ignored today, but a
non-local `.claude/settings.json` added later *would* be tracked. Decide then whether
that is wanted; it is a reasonable thing to commit deliberately.

---

## The manifest — `repos.tsv`

Four tab-separated columns: `name`, `url`, `branch`, `kind`.

`kind` is one of:

| `kind` | Meaning | Covered by |
|---|---|---|
| `r-package` | an R package | every target |
| `support` | infrastructure repository, not an R package | the git targets only — `status`, `audit`, `clone`, `fetch`, `pull` |

The `kind` column exists because `make install`, `make test` and `make check` run
`R CMD INSTALL` / testthat / `devtools::check` on every row they walk. A Jekyll site
or a profile-README repository is not something `R CMD INSTALL` can do anything with,
so those targets filter on `kind == r-package` rather than tripping over them.

**Order is dependency order** for the `r-package` rows. `make install`, `make test`
and `make check` walk the file top to bottom, so `openalexPro` is first and its
dependents follow. Keep the ordering meaningful; do not sort alphabetically. Keep the
`support` rows at the end, where they are out of the dependency chain.

### The support repositories

| Directory | Repository | What it is |
|---|---|---|
| `dot-github/` | `openalexPro/.github` | Org-wide defaults rendered **inside** GitHub: `profile/README.md` is the banner on <https://github.com/openalexPro>. Can also hold fallback `CONTRIBUTING.md`, `SECURITY.md`, issue/PR templates and workflow templates inherited by every repo in the org that lacks its own. Currently holds only the profile README and a LICENSE. |
| `openalexpro.github.io/` | `openalexPro/openalexpro.github.io` | The org's GitHub Pages site, served at the bare domain <https://openalexpro.github.io/> because of the `<org>.github.io` name. Jekyll (`_config.yml` + `index.md`), built from `main`, root path. |

Two audiences, two surfaces, no overlap: the `.github` repository shapes the org page
on GitHub, `openalexpro.github.io` is the public landing page off it.

### Repositories deliberately absent

| Repository | Why | To include it |
|---|---|---|
| `openalexStemCheck` | **Not a git repository at all** — no history, no remote. Its contents exist only on disk. | `git init`, publish, then add a manifest row. |
| `openalexASReview` | **No remote**, local-only `main`, uncommitted work. Slated for retirement. | Same, if it is kept. |
| `openalex-snapshot` | In the org, but a **Rust CLI**, not part of the R build chain. Lives at `~/GitHub/openalex-snapshot`. | Clone here and add a `support` row, if it is wanted in `make status`. |
| `openalexpro.r-universe.dev` | In the org; r-universe build configuration, rarely edited. | Same. |

`openalexStemCheck` and `openalexASReview` are still listed in `.gitignore` so they
are never accidentally committed into the root repository. `make clone` is the
bootstrap verb — it clones whatever is missing and leaves whatever is present
untouched, so it is safe to re-run at any time.

### Remote URLs

The manifest uses **SSH** throughout, so pushes do not prompt. Some existing local
clones still use HTTPS remotes — `openalexPro` is SSH; the other R packages and both
support repositories are HTTPS. Only `make clone` reads the `url` column, so the
mismatch is harmless day to day.

To normalise an existing clone (a change inside that package, so do it deliberately):

```bash
git -C openalexConvert remote set-url origin git@github.com:openalexPro/openalexConvert.git
```

---

## The Makefile

| Target | What it does | Rows |
|---|---|---|
| `make help` | list targets (default goal) | — |
| `make status` | one line per repo: branch, dirty count, stash count, ahead/behind | all |
| `make audit` | **everything that exists only on this machine** | all |
| `make versions` | each package's `Version:` beside its declared `openalexPro` floor | `r-package` |
| `make clone` | clone anything missing — bootstrap a new machine | all |
| `make fetch` | parallel `fetch --all --prune`; always safe | all |
| `make pull` | **fast-forward only**, skips dirty repositories | all |
| `make install` | `R CMD INSTALL` in manifest (dependency) order | `r-package` |
| `make test` | `testthat::test_local` in manifest order | `r-package` |
| `make check` | `devtools::check` in manifest order | `r-package` |

### Design notes

**`make audit` is the target that earns its keep.** A plain directory listing hides
unpushed commits, never-pushed branches, stashes and broken worktrees. Running it on
2026-08-17 surfaced all of the following, none of which was otherwise visible:

```
  openalexPro: UNPUSHED           claude/decouple-from-rust [ahead 1]
  openalexPro: LOCAL-ONLY branch   claude/drop-prepare-snapshot
  openalexPro: LOCAL-ONLY branch   claude/infer-api-schema-in-rust
  openalexPro: LOCAL-ONLY branch   v0.8.x
  openalexConvert: LOCAL-ONLY branch   claude/fix-and-align
  openalexConvert: UNCOMMITTED        1 file(s)
  openalexSnowball: UNPUSHED           claude/split-tests [ahead 6]
  openalexSnowball: LOCAL-ONLY branch   openalexProLegacy
  openalexSnowball: BROKEN WORKTREE    (git -C openalexSnowball worktree repair|prune)
  openalexVectorComp: STASH              1 entr(y|ies)
```

Run it before any restructuring, and periodically otherwise.

**`make pull` is `--ff-only` and skips dirty repositories.** With unpushed commits and
`claude/*` branches in play, a blanket `git pull` would create merge commits or stop
half-way in a confusing state. Fast-forward-or-report is the only safe default.

**There is no `push` target, by design.** Pushing seven repositories from one command
is how something gets pushed that was not meant to be. Keep pushes manual and
per-repository.

**`make versions` makes the versioning discipline visible.** Part 5 of
`compatibility_report.md` argues for independent semver plus actively maintained
`Imports:` floors. This target is how you check the floors are actually maintained —
it currently reports openalexConvert as `!! declared, NO FLOOR`.

---

## Daily workflow

```bash
make fetch          # cheap, parallel, safe
make status         # where is everything
make audit          # anything at risk of being lost
```

All three cover the support repositories as well as the packages.

Branching convention is unchanged and per package: work on
`claude/<description>` branched from `dev`; never commit directly to `main`. This
applies to the package repositories. The root repository is the exception — see
"Layout": it has no `dev`, and coordination changes commit straight to `main`.

---

## The rename to `openalexPro_Ecosystem` — done 2026-08-17

The directory was renamed on 2026-08-17. `make status`, `make clone` and `make audit`
all report correctly afterwards, and every clone kept its branch, remote and history.

`~/GitHub/openalexPro` now exists as a **symlink to `openalexPro_Ecosystem`**, so it
resolves to the *ecosystem directory*, not to the `openalexPro` package. An old
absolute path such as `~/GitHub/openalexPro/DESCRIPTION` therefore no longer resolves;
the package is at `~/GitHub/openalexPro/openalexPro/DESCRIPTION`. If the symlink was
meant as a compatibility shim for old package paths rather than a short alias for the
workspace, repoint it at `openalexPro_Ecosystem/openalexPro`.

### Outstanding

The root repository was initialised and committed on 2026-08-17. Still pending:

```bash
# no remote yet — nothing here is backed up off this machine
git remote add origin git@github.com:openalexPro/<name>.git && git push -u origin main

# openalexSnowball still carries the dead pre-move worktree (make audit reports it)
git -C openalexSnowball worktree prune
```

`openalexSnapshot/src/rust/target` is also still present at **18 GB**. It is
regenerable Rust build output, is **not** covered by that package's `.gitignore` (see
defect D2 in `compatibility_report.md`), and the Part 4 migration removes the Rust
backend entirely — so it can be deleted whenever convenient.

### What broke on the rename, regardless of tooling

* **Git worktrees.** They store absolute paths. `openalexSnowball` still carries a
  worktree pointing at `/Users/rkrug/GitHub/openalexSnowball/.claude/worktrees/…`, a
  path from *before* the packages were gathered into this directory — dead since then,
  and still reported by `make audit`. Run the `prune` above to clear it. Any worktree
  broken specifically by the rename needs `git worktree repair`.
* **The Claude project directory.** It is keyed by path, so the rename moved the key
  from `~/.claude/projects/-Users-rkrug-GitHub-openalexPro/` to
  `…-openalexPro-Ecosystem/`. **This carried over**: the new key holds the memory files
  and the earlier transcript. The old directory is still on disk and can be removed
  once nothing needs it.
* `.Rproj.user`, IDE state, `.claude/launch.json`, and any absolute paths in local
  configuration. `/Volumes/openalex` is external and unaffected. No stale absolute
  paths to the old location remain in the `Makefile`, `repos.tsv` or the markdown.

---

## Related documents

* `compatibility_report.md` — dependency-breakage verification, schema comparison
  against the official OpenAlex parquet, the decision to drop the Rust backend in
  favour of pure R with enrich-on-extract, cross-package defects, and the version
  numbering scheme.
