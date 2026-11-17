---
name: combined-preview
description: >-
  Akokuntaro Coding Skills — test several open PRs together on one local-only branch. Use whenever
  more than one PR (or feature branch) is open on the same repo and David wants to run or test them
  all at once locally, or says "stack the branches", "combined preview", "test all changes in one".
  Covers building and rebuilding the `combined-preview` branch from the base plus every open PR
  branch, the rule that every change goes on the original PR branch, and the git pre-push hook that
  keeps the preview from ever being pushed. Works in any repo.
---

# combined-preview: open PRs together, locally

`combined-preview` is a branch that exists only on David's machine: the base branch (`develop`,
`staging`, `main`…) with every open PR branch merged in. He runs the apps on it to see all pending
changes together. It is never pushed and never gets its own commits.

## Build or rebuild it

In each repo:

```bash
~/.claude/skills/combined-preview/scripts/combined_preview.sh <base> <pr-branch> [<pr-branch> ...]
# e.g. combined_preview.sh develop datch/kab-912-... datch/kab-982-...
```

It fetches, resets `combined-preview` to `origin/<base>`, and merges each `origin/<pr-branch>` in
the order given. It refuses to run with uncommitted tracked changes. The running dev servers pick up
the new code (Next and nodemon reload; restart anything that doesn't).

## Every change goes on the PR branch

- Fix, review change or new commit: check out the **PR branch**, commit, push it, then rerun the
  script so the preview carries it. Never commit on `combined-preview`.
- The script refuses to rebuild if `combined-preview` holds a commit that's on none of the PR
  branches, and names it so it can be moved (cherry-pick it onto its PR branch, then rebuild).
- A merge conflict stops the script. Resolve it on the PR branches (usually by merging the base
  into the later PR), never on the preview.

## It never leaves the machine

- The script points the branch's push at a remote that doesn't exist.
- The real guard is the global git `pre-push` hook (`~/.config/git/hooks/pre-push`, where
  `core.hooksPath` points; copy in `scripts/git-pre-push-hook.sh`). It refuses any push of
  `combined-preview`, including `git push origin combined-preview` and `HEAD:combined-preview`.
- Never bypass it with `--no-verify`. If the hook is missing on a machine, install it before
  building the preview: copy `scripts/git-pre-push-hook.sh` to the hooks folder as `pre-push` and
  make it executable.

## Keep it current

- Rebuild after any PR branch gets new commits.
- When a PR merges, drop it from the list and rebuild from the updated base.
- When nothing is open, switch back to the base and delete the branch (`git branch -D combined-preview`).
- Screenshots for a PR may be taken on the preview when they only show that PR's change.
