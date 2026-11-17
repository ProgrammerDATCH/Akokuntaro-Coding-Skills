#!/usr/bin/env bash
# Build (or rebuild) the local-only `combined-preview` branch: the base branch with every open PR
# branch merged in, so all pending changes run together locally.
#
#   combined_preview.sh <base> <pr-branch> [<pr-branch> ...]
#   e.g. combined_preview.sh develop datch/kab-912-... datch/kab-982-...
#
# Run inside the repo. It never pushes, and it blocks pushing the branch. Changes are always made on
# the PR branches; this branch is rebuilt from them. It refuses to rebuild when combined-preview holds
# a commit that is on none of the PR branches (move that commit to its PR branch first), and stops on
# a merge conflict so nothing is guessed.
set -euo pipefail

BRANCH="combined-preview"
[ $# -ge 2 ] || { echo "usage: $0 <base> <pr-branch> [<pr-branch> ...]" >&2; exit 2; }
BASE="$1"; shift

git rev-parse --git-dir >/dev/null
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Uncommitted changes to tracked files; commit them on their PR branch first." >&2
  exit 1
fi

git fetch -q origin
for b in "$BASE" "$@"; do
  git rev-parse -q --verify "origin/$b" >/dev/null || { echo "origin/$b not found" >&2; exit 1; }
done

# A commit made on combined-preview itself would be lost by the rebuild: stop and say which.
if git rev-parse -q --verify "$BRANCH" >/dev/null; then
  stray=""
  for c in $(git rev-list --no-merges "origin/$BASE..$BRANCH"); do
    found=""
    for b in "$@"; do
      if git merge-base --is-ancestor "$c" "origin/$b"; then found=1; break; fi
    done
    [ -n "$found" ] || stray="$stray $c"
  done
  if [ -n "$stray" ]; then
    echo "These commits are only on $BRANCH; move them to their PR branch first:" >&2
    for c in $stray; do git log -1 --format='  %h %s' "$c" >&2; done
    exit 1
  fi
fi

git checkout -q -B "$BRANCH" "origin/$BASE"
git branch -q --unset-upstream "$BRANCH" 2>/dev/null || true
# Local only: any push of this branch goes to a remote that doesn't exist, so it fails.
git config "branch.$BRANCH.pushRemote" no-push-local-only

for b in "$@"; do
  if ! git merge -q --no-edit "origin/$b"; then
    git merge --abort
    echo "Conflict merging $b into $BRANCH; left at the merges before it. Resolve on the PR branches." >&2
    exit 1
  fi
done

echo "$BRANCH = origin/$BASE + $* ($(git rev-parse --short HEAD)); local only."
