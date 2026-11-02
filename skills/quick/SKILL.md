---
name: quick
description: >-
  David's QUICK work mode (Set 2) — invoked as /quick. Use for hot fixes when he is short of time:
  apply each fix and verify it in code only (typecheck, lint, targeted tests), commit locally, no
  browser testing, no push, no deploy — he tests himself. Stays on until he switches with /full.
---

# QUICK mode (Set 2)

David's words, which define the mode:

> Now let's apply quick fixes, not deploy or push or chrome debug on every task, just apply fix and
> verify in codes (I'll test my self - I have a less time) until I told u do change behavious

What that means in practice:

- Apply each fix and verify it **in code**: typecheck, lint, and the targeted tests for what changed.
- **No** Chrome or emulator testing, **no** push, **no** deploy — unless he asks in that message.
- Commit locally, small and by explicit path.
- Report in key points and say plainly that only code checks ran.
- The coding-principles and ui-review rules still apply to the code itself.

The mode stays on for the session until he types `/full`. The terminal status line shows `[QUICK]`.
