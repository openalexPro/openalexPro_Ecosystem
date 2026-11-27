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
    sha=$(git ls-remote "$(url "$repo")" "refs/heads/$b" "refs/tags/$b" 2>/dev/null | head -1 | cut -f1 || true)
    if [ -z "$sha" ] && [[ "$b" =~ ^[0-9a-f]{7,40}$ ]]; then sha=$b; fi
    if [ -z "$sha" ]; then echo "$repo: no ref $b, skipped" >&2; continue; fi
    key="$repo@$b"
    old=$(jq -r --arg k "$key" '.[$k] | if . == null then "" else "\(.commit) \(.standard) \(.checker)" end' "$STATE" 2>/dev/null || true)
    if [ "$FORCE" != "true" ] && [ "$old" = "$sha $STANDARD $CHECKER" ]; then
      echo "$key unchanged" >&2
      continue
    fi
    echo "$key -> check ($sha)" >&2
    items+=("$(jq -cn --arg repo "$repo" --arg branch "$b" --arg commit "$sha" --argjson private "$private" \
      --arg standard "$STANDARD" --arg checker "$CHECKER" \
      '{repo: $repo, branch: $branch, commit: $commit, private: $private, standard: $standard, checker: $checker,
        id: ($repo + "@" + $branch | gsub("[^A-Za-z0-9._-]"; "-"))}')")
  done
done <<< "$targets"

if [ ${#items[@]} -eq 0 ]; then echo '{"include":[]}'; else printf '%s\n' "${items[@]}" | jq -cs '{include: .}'; fi
