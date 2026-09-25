---
name: coding-principles
description: >-
  Akokuntaro Coding Skills — David's universal coding standards: clean, reusable,
  strongly-typed code.
  Apply on ANY coding task in his repos (TypeScript, JavaScript, React,
  Node/Express, Python): how to name things, when to extract/abstract for reuse,
  how strict TypeScript should be, commenting density, error handling, the
  do/don't list that keeps code consistent, and how to REPORT BACK to him: short
  key points, never prose, with anything needing his decision flagged.
  Load this for every coding session;
  pair it with the stack-specific skill (nextjs-dashboard, express-prisma-api,
  react-vite-app, python-app) when one applies.
---

# Coding principles — Akokuntaro Coding Skills (David's defaults)

These are the cross-cutting rules. Follow them on every task. When a stack-specific
skill is also loaded, the stack skill wins on stack details; this skill wins on
philosophy (reuse, naming, typing, comments).

## North star

Clean, **reusable**, strongly-typed code. Prefer small composable primitives over
copy-paste. Code should read well without needing comments to explain *what* it does.

## Reuse & abstraction — bias toward DRY (aggressive)

David prefers reusable code. **Design for reuse from the start**, not after the third copy.

- Before writing logic, check `lib/`, `utils/`, `src/utils/`, shared `hooks/`,
  `components/shared/`, and existing services for something to reuse or extend.
- Factor cross-cutting behaviour into typed primitives — like the ones already in
  these repos: `cn()`, `globalFetch()` / `assertApiOk()`, `sendResponse()`,
  `catchAsync()`, `ApiError`, `optionalOrEmpty()`, `commonSchemas`,
  `transformPrismaData`. New helpers should feel like they belong next to these.
- A function/component doing two jobs → split it. Repeated JSX → extract a component.
  Repeated query/mutation → a `useXxx` hook. Repeated request shaping → a service fn.
- Centralise constants, config, and types — never hard-code a value that appears twice
  (URLs, table/field IDs, status strings, colours). Put them in `constants.ts` / config.
- **Don't** over-engineer for imaginary futures. Reuse means "factor what genuinely
  recurs or is clearly cross-cutting," not "add config knobs nobody asked for."
- **A referenced design means THE component.** "Like the teacher dashboard's envelope" =
  grep for that component and import it, never a lookalike built in the same spirit. One
  canonical implementation per pattern.
- **Rebuilds prune.** Porting or rewriting a page is the moment to DELETE controls that
  duplicate another control's job (a filter panel beside a drill bar, a second date picker).
  Carrying legacy redundancy forward just schedules the follow-up task where David removes it.

## TypeScript rigor — strict but pragmatic

- `strict: true`. Explicit return types and param types on **exported** functions and
  public APIs. Let inference handle obvious locals.
- `noUnusedLocals` / `noUnusedParameters` stay **off**; prefix intentionally-unused
  params with `_` (e.g. `(_req, res)`).
- Avoid `any` in application code. `any` is acceptable **only at I/O boundaries**
  (raw Airtable/Prisma/3rd-party payloads) — shape it into a typed model immediately
  after (see `transformPrismaData`, `extractField`).
- Define and **export** `type`/`interface` for domain models, request/response shapes,
  and component props. Co-locate types with their feature or in a `types/` dir.
- Prefer `type` for unions/shapes; `interface` is fine for extendable object contracts.
  Use discriminated unions over loose optional grab-bags.

## Comments — minimal

Self-documenting code first. Good names and types carry the meaning.

- Comment **only** genuinely non-obvious things: a tricky algorithm, a workaround, a
  business rule, or *why* a surprising choice was made — never narrate what the code
  plainly does.
- No JSDoc by default. Add it only on a widely-shared primitive/util that others import,
  or when explicitly asked. Keep it short.
- Delete commented-out code; don't ship `// TODO` graveyards or `old.txt`-style dumps.

## Naming & conventions

- Name in **plain, common English** — specific and unambiguous (`pendingInvoices`, not
  `data2`, `tmp`, or `procInvLst`). Avoid abbreviations, jargon, and cleverness; a name
  should read like the thing it holds. The same plain-English rule governs any text users
  see (see the UI skills' copy rules).
- Files: components `PascalCase.tsx`; everything else (utils, services, hooks, routes,
  controllers) `camelCase.ts`. Hooks start with `use` (`useShippingRequests`).
- Express controllers: handler functions end in `Handler` (`createUserHandler`),
  services are plain verbs (`createUser`, `updateUser`).
- Variables/functions `camelCase`; types/components/classes `PascalCase`;
  true constants `SCREAMING_SNAKE_CASE` (`ERROR_CODES`, `API_BASE_URL`).
- Booleans read as predicates: `isActive`, `hasAccess`, `isMissing`, `isFuture`.
- Use path aliases instead of deep relative imports: `@/services/...`, `@/lib/...`.
- Import order: external packages → aliased internal (`@/...`) → relative → styles.

## Error handling

- Never swallow errors silently. Surface a real message to the caller/UI.
- Throw typed/operational errors with a code + message (backend: `ApiError` +
  `ERROR_CODES`); convert unknown errors into a friendly message at the boundary.
- Validate input at the edge (Joi on Express, Zod on React forms) before it reaches
  business logic. Don't trust client data.
- One standard response envelope per surface and stick to it (see `sendResponse`,
  `ApiResponse`, `assertApiOk`).

## Tooling defaults

- Package manager: **npm** (lockfile committed).
- Server state: **TanStack Query**. Client/global state: **React Context + hooks** —
  reach for Context only when truly cross-cutting (auth, theme); prefer URL state,
  server state, and local state otherwise. No Redux/Zustand unless asked.
- Tests: write them alongside features (vitest/jest for TS, pytest for Python). Cover
  core business logic and utilities well; UI smoke-test the critical paths.
- Secrets via env vars only — never hard-code keys/tokens. Provide `example.env`.

## Scope & verification — finish the job, then prove it

The two ways work comes back rejected are **narrowing the ask** and **calling it done without
driving it**. Both are avoidable.

### Definition of done — the standing agreement

David's working agreement. It holds unless he overrides it for a given task.

- **Ask clarifying questions BEFORE starting.** Once started, work the batch through non-stop —
  don't stop halfway to check in; finish all of it.
- **Done means driven in Chrome at BOTH widths** — ~390px and desktop — with no error left on
  the screen or in the console.
- **Where several roles reach the feature, done means driven AS EACH ROLE**, so nobody lands on
  a scope-specific error.
- **Use real users from the local database**, and create a user there when a role has none.
  Fabricated state proves nothing about the scoping rules.
- **A mobile app is done in the emulator** — same bar, same roles.
- **Never run more than 2 agents in parallel.**
- **Commit locally; never push or deploy unless David asks.**

**Two documented overrides.** On a quick fix / small task, and when David explicitly says be
fast or don't debug, typecheck + lint is the bar — then say in the report that this is all
that was run.

### Read the ask for INTENT, not just the literal targets

A request that names two URLs is naming examples, not a whitelist. Before building, ask *who
performs this action and where* — then cover every one of those places.

- "Add the envelope on `head-teacher/class-attendance`" means **every register screen** where
  somebody takes attendance. A teacher takes one on their own page; if the feature can be assigned
  *to* a teacher, the teacher's page needs it too.
- Enumerate the surfaces before coding: which roles reach this, which routes render it, which pages
  duplicate the same component. If a surface is deliberately out of scope, say so in the reply —
  never leave it silently undone.
- When two readings differ materially and you can't resolve it from the code, ask. Otherwise pick
  the WIDER reading and state the assumption.
- **A named instance means the category.** "Remove this description on phone" means every
  descriptive line on that page, not the one sentence quoted. Before finishing, sweep for
  siblings of whatever was named — other text of the same kind, other tiers/roles, the sibling
  app when the codebase has a fork — and state the scope covered.
- **Sibling apps converge.** When two apps share a design (a fork), apply the change to both by
  default. If David orders a deliberate divergence, implement it but flag it as a likely
  convergence candidate — ordered divergences have historically been revoked within a day.

### Test every role the change can affect

Role-scoped apps break per-role, not globally. A change to a shared endpoint or a scoping rule is
not tested until it has been exercised **as each role that reaches it**.

- List the affected roles first (the permission grant, the sidebar `roles`, the backend's own
  allowlist — they disagree more often than not), then run the surface as each one.
- Script it when the list is long: log in per role, hit the endpoint, assert the shape. A dozen curl
  calls in a loop find in one minute what clicking finds in an hour.
- The role you changed the behaviour FOR is the one most likely to be broken — test it first, not
  last.

### Drive the feature, don't just load it

"The page renders" is not verification. Renders, then **interacts**:

- Click through every state the change introduced: open the popup, drill the map, submit the form,
  switch the tab, page to page 2, toggle the filter, and go back.
- Verify the numbers, not just the absence of an error. A drill that returns 0 where its parent said
  1,079 is a passing request and a broken feature.
- Check both the empty case and a case with real data — an empty dataset hides most bugs.
- Read the **network log**, not only the screenshot or the console. A 403 on a page that looks
  fine is a feature silently missing, and it is invisible in a screenshot: the board renders its
  totals and swallows the drill. Scan every request the page made and account for each non-200,
  including the ones that were already there before your change.
- Watch the **cold** load, cache cleared. A defect that lasts thirty seconds is the entire first
  impression and is gone by the time you look again.

**"I tested it" means the network log was read.** Saying work is verified when only the happy
path was eyeballed is worse than saying it is untested, because it moves the finding to the
person who asked for it — and they WILL find it.

### Numbers must reconcile

David audits arithmetic. Any figure you touch must re-add: parts sum to the total
(present + absent + unmarked = registered), percentages derive from the numbers beside them,
and paired visuals are OPTICALLY equal (ink size), not box-equal.

- If existing logic silently merges or hides a category (unmarked folded into present), surface
  it in the same turn as a flagged question — even when it is documented and you didn't write it.
  Preserving it just defers the correction to him.
- Say in the report that the totals reconcile; he will check.

### Done means discoverable

A capability is not finished when its page works at a deep link — it is finished when the
target role can NAVIGATE to it.

- Wire the sidebar / menu entry for every role that gains the feature, then verify by logging in
  as that role and reaching it through the UI, not by typing the URL.
- Sidebar visibility has its own gates (role filters, module narrowing, pinned sets) that pass
  API-level testing untouched — the entry point is part of the feature.
- **Reach every screen the way the user does, every time — including reloads.** Retyping the URL
  between checks is still testing the deep link; it silently re-verifies the page and never the
  door. Click the menu item, the card, the tab, the "back" control. A blocking modal over the
  dashboard, an entry scrolled out of the sidebar, or a menu that needs expanding are all part of
  what the user has to get through, and only clicking finds them.

### Drive the browser as a person, not as a script

Automating the page from the console proves the FUNCTION works, never the INTERFACE. These are
the ways a passing script hides a broken screen:

- **Click with the pointer, not `element.click()`.** A DOM click ignores what is on top of the
  element, so an overlay, a modal or a mis-sized hit target still "passes".
- **Check the coordinate frame before trusting a click.** A screenshot frame is often not 1:1 with
  CSS pixels (retina, zoom, a scaled capture). Convert — `frame = css * (frameWidth /
  window.innerWidth)` — or clicks land on the neighbouring row and the wrong result gets
  diagnosed as something else entirely.
- **Type with the keyboard, not by assigning `input.value`.** Only real keystrokes reveal lost
  focus, remounts, input masks and handlers that swallow keys.
- **A 404 on a route whose file exists, while its siblings serve, is a stale dev server.**
  Restart it before reading any code; a long-running watcher drops routes added after it started.

### When they find a bug you said you had tested

Do not patch only the screenshot they sent. A reported defect is a sample of a class:

1. Reproduce it, and find the CAUSE rather than the symptom. Three "permission denied" pages had
   three different causes; fixing the visible one would have left two.
2. Ask what else shares that cause, and sweep for it — every role in the family, every sibling
   map, every page calling that endpoint.
3. Re-drive the surfaces you had previously claimed were verified, not just the new one.
4. Say plainly what the cause was. "Fixed" without a cause invites the same report next week.

### Report in key points, and flag anything that needs him

**David does not want to read prose.** A long report is a worse report: the one line that mattered
gets buried and he has to hunt for it. Write the reply as short key points, not paragraphs.

- **Lead with what changed or broke, in one line.** Then the points. No preamble, no recap of the
  request, no narration of the journey.
- **One line per point.** If a point needs a "why", it gets a clause, not a paragraph. Cut every
  sentence that does not change what he knows or does.
- **Prefix anything he must act on or decide with `⚠️`** — a recommendation, a choice only he can
  make, a manual step, a risk, something deliberately left undone. He scans for the marker rather
  than reading for it, so an unflagged ask is an ask he will miss.
- Nothing else gets the marker. Marking ordinary results trains him to ignore it.
- Detail belongs in the commit message and the code comments, where it is searchable, not in the
  reply.

Still say what was verified and what was not — "verified" must mean DRIVEN, and if it only
compiled, say that instead. Just say it in a line, not a section.

Example shape:

    Partner boards fixed — three separate causes, all shipped.

    - Stale role allowlist beside the RBAC grant; deleted, scope still clamps per role.
    - Partners lacked `attendance.view`, so the drill 403'd. New migration, VIEW only.
    - Card linked to the head teacher's page, not theirs.

    Driven as all 8 roles at both widths; numbers reconcile.

    ⚠️ UAT has the roles but no partner accounts — an admin must create them before anyone can
       sign in as one.

### Corrections that keep recurring

Every line below is a real correction from a recent session. Each one costs a round trip.

- **Click the entry AS the role — a working URL proves nothing.** A sidebar item shipped pointing
  at a path the router never rewrote and 404'd for every head teacher, because it was "verified"
  by opening the page directly.
- **A 403 naming a permission the database grants is a CACHE bug, not an RBAC one.** Check the
  cache before writing a migration — a new grant would have fixed nobody.
- **Any cache / lock / channel key shared by two apps carries the app name.** Two apps sharing
  user ids wrote the same Redis key and served each other's permissions.
- **Never force-move a branch.** Rebase or merge; verify nothing would be lost before any branch
  move, and after pushing verify production contains every develop commit.
- **A report's geo LEVEL comes from the reader's ROLE**, never from whichever geo fields their
  account happens to have filled in — officer records carry geo deeper than the role governs.
- **Numbers must reconcile** — parts sum to the total, and say so in the report, because he checks.
- **Sweep the category, not the named instance.** A named example means every sibling of that kind.
- **Reuse THE component**, never a lookalike built in the same spirit.
- **Never create backup copies of files** — no `.bak`, `.orig`, `.backup`, not even temporarily.
  Git is the undo.
- **Never add Claude/Anthropic attribution** to commits or PRs.
- **Descriptive prose is desktop furniture** — `hidden sm:block` it on phones, all of it, not just
  the sentence that was quoted.
- **Never declare a component inside another component's body.** A nested `Row`/`SearchRow` is a
  new type on every render, so React unmounts and rebuilds its subtree each keystroke — a search
  box loses focus mid-word and the keys land on whatever gets focus instead. Hoist it to module
  scope and pass props.
- **Type into the field, don't set its value.** Driving a form by assigning `input.value` in the
  console cannot reveal a focus or remount bug; only real keystrokes do.
- **Navigate by clicking, never by retyping the URL** — a reload by address bar re-tests the page
  and never the entry point, which is the half that breaks.
- **Convert CSS coordinates into the screenshot's frame before clicking**, or the click lands on
  the next item and the wrong thing gets blamed.
- **Suspect the dev server before the code** when a route 404s but its file is present and its
  siblings load.

## A location is CHOSEN, never typed

Any administrative place — country, province, district, sector, cell, village — is picked from the
official list, as a cascading selector where each level is filtered by the one above it. Never a
free-text box, and never only the deepest level.

**Why:** a typed "Nyanza" arrives as `nyanza`, `NYANZA`, `Nyanza ` and `Nyanaza`, and none of them
match the schools. Every scope query, every geo join and every report grouping compares these
strings, so one typo puts a partner in a district that does not exist and their board reads zero
forever — with nothing on screen to say why.

- Reuse the app's existing selector rather than building another. These repos already have one
  (`components/LocationSelect.tsx`, backed by `rwanda-geo-structure`) with per-level lock flags.
- **Lock the levels the viewer is already pinned to; show them, do not hide them.** Somebody
  creating a record inside their own district should see "Province: South · District: Nyanza"
  fixed, so they can tell what area they are working in — and cannot leave it.
- Take the fixed levels from the SERVER's view of the caller, never from the form. A rung read
  back out of the request is the guard undone.
- The same rule governs phone numbers and national IDs: use the shared input that normalises them
  (`RwandaPhoneInput`, `NationalIdField`), never a bare text box.

## Do / Don't

**Do**
- Reuse and extend existing helpers before writing new ones.
- Keep functions small and single-purpose; return early to avoid nesting.
- Type the boundaries; thread types through.
- Co-locate by feature where the stack supports it.
- Name things — and write any user-facing text — in plain, specific, common English.

**Don't**
- Narrow a request to the literal URLs/files it named while leaving the same feature broken next door.
- Treat a named example as the whole ask — sweep the category (all similar text, tiers, sibling app).
- Build a lookalike of a referenced component instead of importing the component itself.
- Port a page forward with its duplicated legacy controls intact.
- Ship a feature whose target role has no navigation entry to reach it.
- Report work as done or verified when it was only compiled, or only exercised as one role.
- Copy-paste a block a second time instead of extracting it.
- Sprinkle `any`, `// @ts-ignore`, or `eslint-disable` to silence the compiler.
- Hard-code values that recur (IDs, URLs, colours, status strings).
- Add narrating comments, dead code, or speculative abstraction.
- Introduce a new library when an existing dependency already does the job.
