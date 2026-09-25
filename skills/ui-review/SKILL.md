---
name: ui-review
description: >-
  Akokuntaro Coding Skills — David's UI finishing pass. Apply on ANY frontend/UI
  task (Next.js, Vite/React, Streamlit — any stack) BEFORE calling the work done:
  the phone-compact rules (same design as PC with secondary elements shrunk to
  captions or removed, banners halved, prose hidden on phones, trailing icons
  right-aligned, only tables scroll), and the finishing checklist that catches
  what he otherwise sends back — oversized mobile elements, duplicated controls,
  unreachable features. Pair it with coding-principles and the stack skill.
---

# UI review — the finishing pass (David's defaults)

Every one of these rules exists because a "done" UI task came back. Run this pass on any
frontend work before reporting it finished — it is a review lens, not a build guide, so it
applies whatever the stack.

## Phones: same design, radically more compact

Mobile is never a different layout — it is the PC design with everything secondary shrunk
much further than feels natural. The right instinct is "shrink to a caption or remove",
not "shrink 20%".

- **Secondary elements become captions.** A card that supports a primary action (a class
  card above a button, a meta strip under a title) drops to ~8–9px lines, loses any datum
  that is duplicated nearby, and reads clearly subordinate to the action it decorates.
- **Descriptive prose disappears on phones.** Explanatory sentences under page titles are
  desktop furniture: `hidden sm:block` them ALL — every paragraph of the kind, not just the
  one the ticket quoted. A phone opens straight onto the controls.
- **Banners halve.** A hero that stacks identity + meta cards + actions becomes one identity
  row plus one wrapping chips row. Target roughly half its desktop height; when the greeting
  and buttons fight for a row, the greeting takes its own full row (`order-first w-full`).
- **Trailing icon actions hug the right edge.** When a wrapped row leaves an icon button
  (envelope, bell) dangling on the left, give it `ml-auto` so every wrap keeps it right.
- **Only the wide thing scrolls.** A table gets its own `overflow-x-auto` wrapper with a
  `min-width` so its columns stay readable; the card/sheet around it stays page-wide. If a
  header or signature line scrolls away with the table, the wrapper is on the wrong element.
  The page body itself never scrolls horizontally.
- **Component-owned sizing beats ad-hoc pixels.** Anything rendered inside a sized system
  (an isometric platter, a chart card, a grid cell) must join that system's own container-query
  units and slots — a hand-picked `max-w-[250px]` wrapper is wrong at both ends of the range.

## One control per job

If two controls answer the same question, keep the compact one and delete the other — a
drill/search bar makes an eight-select filter panel redundant; a summary tile row that
filters makes a chip row redundant. Rebuilding or porting a page is the moment to prune,
not to faithfully carry the duplication forward.

## A gate must have a way out

A modal that opens by itself and cannot be closed is not a prompt, it is a wall. If a screen
shows a blocking dialog on arrival — "finish setting these up", "you have N incomplete" — it
must still let the person leave it:

- Escape and a visible close control both work, and the dialog remembers it was dismissed for
  the session rather than reopening on every render.
- Whatever it blocks, the primary navigation stays reachable, so a person who came to do
  something else can still get there.
- It states what happens if they ignore it. A gate with no stated consequence reads as a bug.

Test it as the role that actually triggers the condition — the account with nothing outstanding
never sees the gate, so a pass as that user proves nothing.

## Paired visuals are optically equal

Two logos, two markers, two columns that read as a pair must match in INK, not in box:
an asset that carries internal padding or caption text draws smaller at equal box size.
Measure the visible mark and size for that (or use per-asset ink metrics when available).

## A loading state must never read as an answer

Placeholders are read as results. Every one of these shipped and came back:

- **A climbing number must not come to rest.** Clamped to a ceiling it stops after a few
  seconds on a round, motionless figure — which looks exactly like a settled answer, and is
  usually LARGER than the real one it stands in for. Sweep and restart instead, keep it off
  round numbers, and dim it (`animate-pulse`, muted colour) for as long as it is a placeholder.
- **"Loading" and "no value" are different states.** Styling on `isLoading` alone renders a
  fabricated figure at full strength the moment a query settles empty. A query that FAILED
  shows a dash, never a placeholder.
- **A fallback place name is a claim about scope.** "Rwanda" standing in until the server
  answers tells a district reader for the whole load that they are reading the country. Fall
  back to the viewer's own posting, never to the widest one.
- **"never" is a fact, not an absence.** `timeAgo(null)` beside five figures reads as five
  stale figures. Say "counting…" while the first fetch is running, "could not load" on error,
  and a time only once there is one.

Drive the cold load, not the warm one — clear the cache first. A bug that lasts thirty seconds
is invisible on a second visit and is the whole experience on a first.

## The pass itself

Before reporting UI work done, drive it at BOTH widths — a real desktop viewport and a
~390px phone view — and hunt specifically for:

1. Any secondary element larger than its primary action on the phone.
2. Any descriptive prose still visible on the phone.
3. A wrapped row with a stray icon on the wrong side.
4. Horizontal overflow: `scrollWidth > clientWidth` on the document = a bug; on a table
   wrapper = correct.
5. Two controls doing one job.
6. The feature reachable through NAVIGATION as the target role — click the sidebar/menu entry
   and land on the page. A working deep link is not enough, and neither is retyping the URL to
   reload between checks: that re-tests the page and never the door.
7. Numbers on screen that must re-add to a total nearby actually re-adding.
8. Any self-opening dialog closable by Escape and by a control, with the navigation still
   reachable behind it.
9. The COLD load, watched from first paint: no placeholder resting on a round number, no
   fallback that widens the scope, no "never" where "counting…" belongs.

Report which widths and roles were driven, and what was deliberately left out.
