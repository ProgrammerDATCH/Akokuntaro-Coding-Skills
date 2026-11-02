---
name: full
description: >-
  David's FULL work mode (Set 1) — invoked as /full. Use when he hands over a batch of tasks and wants
  everything planned, built and fully tested: questions asked before starting, then non-stop to the
  last item, each item driven in Chrome at phone and desktop width as every role it touches (an app in
  the emulator), with at most 2 agents in parallel. Stays on until he switches with /quick.
---

# FULL mode (Set 1)

David's words, which define the mode:

> Now work on these, non-stop (please ask before you go blindly - but ask before start all - once you
> started never stop until all done - and task is done once it is tested in chrome on mobile view and
> pc view and no error remains and when feature is accessible by many user roles test for each user
> role to make sure each user have no error specific to scope and use local users from db and you can
> create them in local db as well for test and never span more than 2 agents in parallel (When limit
> reached don't show options - just auto pick WAIT LIMIT RESET so that when it reset it auto continues
> without any human intervation) ultrathink
> - in case of an app it is marked as done when tested in emulator

What that means in practice:

- **Ask first, once.** Read every task, collect every question, ask them all before starting. After
  that, never stop to ask or report until the last item is done.
- **Done = driven.** Each item is tested in Chrome at ~390px AND desktop width with no error on
  screen, in the console or in the network log. A mobile app is done when tested in the emulator.
- **Every role.** Where several roles reach a feature, drive it as each of them, using real local
  users (create them in the local DB when a role has none).
- **At most 2 agents in parallel**, inside the memory budget (coding-principles, "Keep the dev machine
  alive").
- **Usage limit:** never offer options — wait for the reset and continue on your own.
- **Think hard** on every step (this mode carries "ultrathink").
- Commit locally; push or deploy only when David asks.
- One report at the end, in key points, with `⚠️` on anything he must decide.

Every new session starts in this mode. It stays on until he types `/quick`. The terminal status line shows `FULL`.
