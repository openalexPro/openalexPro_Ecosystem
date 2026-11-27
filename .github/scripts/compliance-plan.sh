#!/usr/bin/env bash
# Decide which repository/branch pairs need a compliance check.
#
# Env: REPO (all | owner/name), REF (comma list of branches, or a tag/commit for a
# one-off), FORCE (true/false), TOKEN (read token for private repos; optional).
# Reads repos.tsv, compliance/external.tsv and compliance/state.json from the
# current directory (the ecosystem repo). Prints a JSON matrix {"include": [...]}.
set -euo pipefail

REPO=${REPO:-all}
REF=${REF:-main,dev}
FORCE=${FORCE:-false}
STATE=compliance/state.json

STANDARD=$(git hash-object STANDARD.md)
CHECKER=$(git rev-parse -q --verify HEAD:pkg/openalexStandard || echo uncommitted)

# Heads of the ecosystem dependencies the check installs (compliance.yml): a change in
# them re-checks the packages too. dev checks use the dev branches, everything else main.
branch_head() { git ls-remote "https://github.com/$1.git" "refs/heads/$2" 2>/dev/null | cut -c1-12; }
DEPS_dev="$(branch_head openalexPro/openalexPro dev)-$(branch_head openalexPro/openalexAPI dev)"
DEPS_main="$(branch_head openalexPro/openalexPro main)-$(branch_head openalexPro/openalexAPI main)"

url() { if [ -n "${TOKEN:-}" ]; then echo "https://x-access-token:${TOKEN}@github.com/$1.git"; else echo "https://github.com/$1.git"; fi; }

# watched repositories: "owner/name<TAB>branches"
watched() {
  awk -F'\t' '!/^#/ && $4 == "r-package" { sub(/^git@github.com:/, "", $2); sub(/\.git$/, "", $2); print $2 "\tmain,dev" }' repos.tsv
  [ -f compliance/external.tsv ] && awk -F'\t' '!/^#/ && NF >= 1 && $1 != "repo" { print $1 "\t" ($2 == "" ? "main,dev" : $2) }' compliance/external.tsv
  true
}

if [ "$REPO" = "all" ]; then
  targets=$(watched)
else
  targets=$(printf '%s\t%s\n' "$REPO" "$REF")
fi

items=()
while IFS=$'\t' read -r repo branches; do
  [ -z "$repo" ] && continue
  private=$(GH_TOKEN="${TOKEN:-${GH_TOKEN:-}}" gh api "repos/$repo" --jq .private 2>/dev/null || echo unknown)
  if [ "$private" = "unknown" ]; then
    echo "::warning::cannot read $repo (missing, or private without a token); skipped" >&2
    continue
  fi
  IFS=',' read -ra refs <<< "$branches"
  for b in "${refs[@]}"; do
    b=$(echo "$b" | xargs)
    if ! refs=$(git ls-remote "$(url "$repo")" "refs/heads/$b" "refs/tags/$b^{}" "refs/tags/$b" 2>/dev/null); then
      echo "::warning::cannot read $repo with git (token without Contents: read?); skipped" >&2
      continue
    fi
    # annotated tags: the peeled line (^{}) names the commit
    sha=$( (echo "$refs" | grep '\^{}$' || echo "$refs") | head -1 | cut -f1)
    if [ -z "$sha" ] && [[ "$b" =~ ^[0-9a-f]{7,40}$ ]]; then
      sha=$(GH_TOKEN="${TOKEN:-${GH_TOKEN:-}}" gh api "repos/$repo/commits/$b" --jq .sha 2>/dev/null || true)
    fi
    if [ -z "$sha" ]; then echo "$repo: no ref $b, skipped" >&2; continue; fi
    if [ "$b" = "dev" ]; then deps=$DEPS_dev; else deps=$DEPS_main; fi
    # a one-off check (a repo or ref outside the daily list) is published under adhoc/, without state
    adhoc=false
    if [ "$REPO" != "all" ] && { [ "$b" != "main" ] && [ "$b" != "dev" ] || ! watched | cut -f1 | grep -qx "$repo"; }; then adhoc=true; fi
    key="$repo@$b"
    old=$(jq -r --arg k "$key" '.[$k] | if . == null then "" else "\(.commit) \(.standard) \(.checker) \(.deps) \(.verdict)" end' "$STATE" 2>/dev/null || true)
    # unchanged, and not an error (errors are retried on every run)
    if [ "$FORCE" != "true" ] && [ "${old% *}" = "$sha $STANDARD $CHECKER $deps" ] && [ "${old##* }" != "error" ]; then
      echo "$key unchanged" >&2
      continue
    fi
    echo "$key -> check ($sha)" >&2
    items+=("$(jq -cn --arg repo "$repo" --arg branch "$b" --arg commit "$sha" --argjson private "$private" \
      --arg standard "$STANDARD" --arg checker "$CHECKER" --arg deps "$deps" --argjson adhoc "$adhoc" \
      '{repo: $repo, branch: $branch, commit: $commit, private: $private, standard: $standard, checker: $checker, deps: $deps, adhoc: $adhoc,
        id: ($repo + "@" + $branch | gsub("[^A-Za-z0-9._-]"; "-"))}')")
  done
done <<< "$targets"

if [ ${#items[@]} -eq 0 ]; then echo '{"include":[]}'; else printf '%s\n' "${items[@]}" | jq -cs '{include: .}'; fi
