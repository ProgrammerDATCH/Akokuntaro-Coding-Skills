---
name: gokabisa-habits
description: >-
  Akokuntaro Coding Skills — the team rules for any gokabisa (KABISA) work. Use whenever David works
  in a gokabisa repo or on a gokabisa Linear ticket (KAB-*): New-backend / Backend, console /
  Sana-CPMS-Frontend, FrontEnd-NextJs / Frontend, Driver-App, Shipping-Dashboard, KPI-Dashboard, or
  anything under the KABISA folders. Covers QA proof in Slack before In Review, screenshots in every
  PR, no merge to staging/develop before the Slack post, building a ticket exactly as written, and
  asking before adding anything he did not ask for. Pair it with coding-principles and the stack skill.
---

# gokabisa habits

Rules for every gokabisa repo and every KAB ticket. They come on top of coding-principles.

## QA proof before In Review (KAB-975)

Team rule since 16 Nov 2026, agreed by Lukas and Kevin.

- A ticket moves to **In Review** only with a Slack post proving QA was done: a short video, a
  screenshot, or a live demo on the next call.
- The post goes in the project's channel (#project-charge-app or #project-charge-cpms-sana) and
  links the ticket.
- No proof post, no review. A ticket without one goes back to In Progress.
- I prepare the proof (screenshots or a recording of the tested flow) and the post text. David
  posts it, unless he tells me to post it myself.

## Pull requests

- **Screenshots in every PR** that changes something people see: the flow as tested, before and
  after where it helps. David approves them first on the review page (screenshot-review skill);
  only confirmed shots go into the PR or the Slack proof. If I can't attach them myself, I hand
  him the approved files to drop in.
- **No merge into `staging` or `develop` before the Slack proof post exists.** Ask David whether
  it's posted; never assume it.
- Merge only on David's yes for that PR (the standing rule).

## Test open PRs together on `combined-preview` (local only)

When more than one PR is open on the same app, David tests them all at once on a local branch
called `combined-preview`: the base branch (`develop` / `staging`) with every open PR branch merged
in. It exists only on his machine and is never pushed.

- **Build or rebuild it** in each repo with
  `~/.claude/skills/gokabisa-habits/scripts/combined_preview.sh <base> <pr-branch> ...`. It fetches,
  resets `combined-preview` to `origin/<base>`, merges each PR branch, and points its push at a
  remote that doesn't exist. The real guard is the global git `pre-push` hook
  (`~/.config/git/hooks/pre-push`, copy in this repo's `hooks/git-pre-push-combined-preview.sh`):
  it refuses any push of `combined-preview`, even `git push origin combined-preview`. Never bypass
  it (`--no-verify`).
- **Every change goes on the original PR branch**, never on `combined-preview`: commit and push the
  fix on the PR branch, then rerun the script so the preview carries it. The script refuses to
  rebuild if a commit sits only on `combined-preview`, and stops on a merge conflict (resolve it on
  the PR branches).
- **Run and test on it**: `run kabisa` serves whatever branch each repo has checked out. Screenshots
  for a PR may come from the preview when they only show that PR's change.
- Rebuild after any PR branch gets new commits; drop the PR from the list once it's merged; delete
  the branch when nothing is open.

## Do the ticket exactly as written

- Build what the ticket or David says, nothing more. No extra features, fields, buttons, filters,
  checks or refactors because they seem useful.
- When something seems missing or worth adding, **ask first** with a one-line suggestion. Build it
  only after David approves.
- The same applies to writing: tickets, PR descriptions, comments, labels, links, code comments and
  commit messages say only what was asked or done. No added meaning, no guessed scope.
- Be logical, not bare: a ticket still gets the labels that plainly fit it (a broken button is a
  Bug, new behaviour is an Improvement or Feature) and its "Done when" line. What's cut is
  invented scope and notes, not the parts a good ticket always has.
- When David asks for a short reply on a ticket (for example "comment acknowledged"), write exactly
  that.
