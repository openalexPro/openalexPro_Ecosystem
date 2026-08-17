# openalexPro ecosystem — multi-repo helper
#
# The repo directories are independent git clones, NOT submodules.
# This Makefile + repos.tsv are the whole coordination layer.
#
# repos.tsv marks each row r-package or support. The git targets cover every
# row; install/test/check cover the r-package rows only.
#
#   make help      list targets
#   make status    one line per package: branch, dirty, stash, ahead/behind
#   make audit     anything that exists ONLY on this machine
#   make versions  package version vs declared openalexPro floor
#
# Deliberately absent: a `push` target. Pushing five repos from one command
# is how you push something you did not mean to. Keep pushes manual.

SHELL    := /bin/bash
MANIFEST := repos.tsv

.DEFAULT_GOAL := help

.PHONY: help status audit versions clone fetch pull install test check

help:
	@echo "openalexPro ecosystem"
	@echo ""
	@echo "  make status     branch / dirty / stash / ahead-behind, per package"
	@echo "  make audit      local-only branches, unpushed commits, stashes, broken worktrees"
	@echo "  make versions   package Version: vs its declared openalexPro floor"
	@echo ""
	@echo "  make clone      clone anything missing (bootstrap a new machine)"
	@echo "  make fetch      parallel fetch --all --prune (always safe)"
	@echo "  make pull       fast-forward only; skips dirty repos"
	@echo ""
	@echo "  make install    R CMD INSTALL, in manifest (= dependency) order"
	@echo "  make test       testthat::test_local, in manifest order"
	@echo "  make check      devtools::check, in manifest order"
	@echo ""
	@echo "  install/test/check skip 'support' rows (dot-github, the Pages site)."
	@echo "  Repos are independent clones. There is no push target by design."

## ---------------------------------------------------------------- inspection

status:
	@printf '%-22s %-26s %-8s %-7s %s\n' REPO BRANCH DIRTY STASH TRACKING; \
	while read -r name url branch kind; do \
	  [[ "$$name" == \#* || -z "$$name" ]] && continue; \
	  if [[ ! -d "$$name/.git" ]]; then \
	    printf '%-22s %s\n' "$$name" "ABSENT (run: make clone)"; continue; \
	  fi; \
	  cur=$$(git -C "$$name" branch --show-current); \
	  dirty=$$(git -C "$$name" status --porcelain | wc -l | tr -d ' '); \
	  stash=$$(git -C "$$name" stash list | wc -l | tr -d ' '); \
	  track=$$(git -C "$$name" status -sb | head -1 | grep -o '\[.*\]' || true); \
	  printf '%-22s %-26s %-8s %-7s %s\n' "$$name" "$$cur" "$$dirty" "$$stash" "$$track"; \
	done < $(MANIFEST)

# Everything that would be lost if this machine died. Run before restructuring.
audit:
	@found=0; \
	while read -r name url branch kind; do \
	  [[ "$$name" == \#* || -z "$$name" ]] && continue; \
	  [[ -d "$$name/.git" ]] || continue; \
	  while IFS='|' read -r b u t; do \
	    if [[ -z "$$u" ]]; then \
	      echo "  $$name: LOCAL-ONLY branch   $$b"; found=1; \
	    elif [[ "$$t" == *ahead* ]]; then \
	      echo "  $$name: UNPUSHED           $$b $$t"; found=1; \
	    fi; \
	  done < <(git -C "$$name" for-each-ref \
	             --format='%(refname:short)|%(upstream:short)|%(upstream:track)' refs/heads); \
	  n=$$(git -C "$$name" stash list | wc -l | tr -d ' '); \
	  [[ "$$n" != "0" ]] && { echo "  $$name: STASH              $$n entr(y|ies)"; found=1; }; \
	  if git -C "$$name" worktree list --porcelain 2>/dev/null | grep -q prunable; then \
	    echo "  $$name: BROKEN WORKTREE    (git -C $$name worktree repair|prune)"; found=1; \
	  fi; \
	  d=$$(git -C "$$name" status --porcelain | wc -l | tr -d ' '); \
	  [[ "$$d" != "0" ]] && { echo "  $$name: UNCOMMITTED        $$d file(s)"; found=1; }; \
	done < $(MANIFEST); \
	[[ "$$found" == "0" ]] && echo "  clean — nothing exists only on this machine"; true

# Makes the Part 5 versioning discipline visible rather than aspirational.
versions:
	@printf '%-22s %-12s %s\n' PACKAGE VERSION 'openalexPro FLOOR'; \
	while read -r name url branch kind; do \
	  [[ "$$name" == \#* || -z "$$name" ]] && continue; \
	  [[ "$$kind" == "r-package" ]] || continue; \
	  [[ -f "$$name/DESCRIPTION" ]] || continue; \
	  v=$$(awk -F': *' '/^Version:/{print $$2; exit}' "$$name/DESCRIPTION"); \
	  f=$$(grep -o 'openalexPro *(>=[^)]*)' "$$name/DESCRIPTION" | head -1); \
	  if [[ -z "$$f" ]]; then \
	    if grep -qE '^[[:space:]]+openalexPro,?[[:space:]]*$$' "$$name/DESCRIPTION"; then \
	      f='!! declared, NO FLOOR'; else f='-'; fi; \
	  fi; \
	  printf '%-22s %-12s %s\n' "$$name" "$$v" "$$f"; \
	done < $(MANIFEST)

## ------------------------------------------------------------------- syncing

clone:
	@while read -r name url branch kind; do \
	  [[ "$$name" == \#* || -z "$$name" ]] && continue; \
	  if [[ -d "$$name" ]]; then echo "present: $$name"; else \
	    echo "cloning: $$name"; git clone -b "$$branch" "$$url" "$$name"; fi; \
	done < $(MANIFEST)

fetch:
	@awk '!/^#/ && NF {print $$1}' $(MANIFEST) \
	  | xargs -P 8 -I{} git -C {} fetch --all --prune --quiet
	@echo "fetched all."

# Fast-forward only, and never touches a dirty repo. With local-only branches
# and unpushed work around, a blanket `git pull` would merge or half-fail.
pull:
	@while read -r name url branch kind; do \
	  [[ "$$name" == \#* || -z "$$name" ]] && continue; \
	  [[ -d "$$name/.git" ]] || continue; \
	  if [[ -n $$(git -C "$$name" status --porcelain) ]]; then \
	    echo "SKIP  (dirty)    $$name"; continue; fi; \
	  if git -C "$$name" pull --ff-only --quiet 2>/dev/null; then \
	    echo "ok               $$name"; \
	  else \
	    echo "SKIP  (not ff)   $$name"; fi; \
	done < $(MANIFEST)

## ------------------------------------------------------------------ R builds

install:
	@while read -r name url branch kind; do \
	  [[ "$$name" == \#* || -z "$$name" ]] && continue; \
	  [[ "$$kind" == "r-package" ]] || continue; \
	  echo "== install $$name"; \
	  R CMD INSTALL --no-multiarch --with-keep.source "$$name" || exit 1; \
	done < $(MANIFEST)

test:
	@while read -r name url branch kind; do \
	  [[ "$$name" == \#* || -z "$$name" ]] && continue; \
	  [[ "$$kind" == "r-package" ]] || continue; \
	  echo "== test $$name"; \
	  Rscript -e "devtools::load_all('$$name', quiet = TRUE); testthat::test_local('$$name')" || exit 1; \
	done < $(MANIFEST)

check:
	@while read -r name url branch kind; do \
	  [[ "$$name" == \#* || -z "$$name" ]] && continue; \
	  [[ "$$kind" == "r-package" ]] || continue; \
	  echo "== check $$name"; \
	  Rscript -e "devtools::check('$$name')" || exit 1; \
	done < $(MANIFEST)
