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
  after where it helps. If I can't attach them myself, I hand them to David to drop in.
- **No merge into `staging` or `develop` before the Slack proof post exists.** Ask David whether
  it's posted; never assume it.
- Merge only on David's yes for that PR (the standing rule).

## Do the ticket exactly as written

- Build what the ticket or David says, nothing more. No extra features, fields, buttons, filters,
  checks or refactors because they seem useful.
- When something seems missing or worth adding, **ask first** with a one-line suggestion. Build it
  only after David approves.
- The same applies to writing: tickets, PR descriptions, comments, labels, links, code comments and
  commit messages say only what was asked or done. No added meaning, no guessed scope, no extra
  labels or "related" links nobody asked for.
- When David asks for a short reply on a ticket (for example "comment acknowledged"), write exactly
  that.
