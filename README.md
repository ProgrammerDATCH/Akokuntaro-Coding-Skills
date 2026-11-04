# Akokuntaro Coding Skills

**Akokuntaro Coding Skills** — personal [Claude Code Skills](https://docs.claude.com/en/docs/claude-code/skills)
that teach Claude David's coding conventions — preferred stacks, patterns, naming, and the
do/don't rules — so every session follows the same style.

## Skills

| Skill | When Claude uses it |
| --- | --- |
| **coding-principles** | Every coding task — reuse/DRY bias, naming, TypeScript rigor, minimal comments, error handling, do/don't. The base layer. |
| **ui-review** | Every frontend/UI task, before calling it done — the phone-compact rules (secondary elements shrink to captions, prose hidden on phones, only tables scroll), one-control-per-job pruning, optical equality, and the finishing checklist. |
| **rwanda-identifiers** | Any field holding a Rwandan phone number or National ID — the accepted spellings, the single normalised stored form, the 16-digit NID rule with its birth-year window, and the optional-field trap. |
| **full** / **quick** | David's two work modes, typed as `/full` and `/quick`. FULL: questions first, then non-stop, every item driven in Chrome at both widths as every role (apps in the emulator). QUICK: fixes verified in code only, no browser, push or deploy. |
| **nextjs-dashboard** | New frontends / full-stack dashboards — Next.js 15 App Router, React 19, Tailwind v4, shadcn/ui, TanStack Query, next-auth. *Default frontend.* |
| **express-prisma-api** | Standalone backend APIs — Express + TypeScript + Prisma/MySQL, layered controllers/services, `ApiError`/`ERROR_CODES`, Joi, JWT. *Default backend.* |
| **react-vite-app** | SPA frontends talking to a separate API — Vite + React 18, react-router, `globalFetch`/`assertApiOk`, react-hook-form + zod, sonner. |
| **python-app** | Python data/analytics apps — Streamlit, pandas/plotly, layered `app/` (ui/engine/db/connectors), theme module, pytest. |

`coding-principles` is the foundation; the stack skills layer on top and win on stack
specifics. Claude auto-loads the relevant skill from each `description`.

## Defaults at a glance

- **New frontend** → Next.js 15 (App Router) · **New backend** → Express + TS + Prisma
- **Styling** → Tailwind v4 + shadcn/ui · **Server state** → TanStack Query · **Client state** → React Context
- **Package manager** → npm · **Auth** → next-auth (Next) / JWT+passport (Express)
- **Reuse** → aggressive DRY · **Comments** → minimal · **TS** → strict, pragmatic on unused · **Tests** → write alongside features

## Install

One line. Finds every agent. Installs for each.

```bash
# macOS / Linux / WSL / Git Bash
curl -fsSL https://raw.githubusercontent.com/ProgrammerDATCH/Akokuntaro-Coding-Skills/develop/install.sh | bash
```

```powershell
# Windows (PowerShell 5.1+)
irm https://raw.githubusercontent.com/ProgrammerDATCH/Akokuntaro-Coding-Skills/develop/install.ps1 | iex
```

The installer fetches (or updates) the skills source, detects every agent that uses the
`SKILL.md` format — currently Claude Code (`~/.claude/skills`, honoring
`CLAUDE_CONFIG_DIR`) — and **symlinks** each skill into it (copying where symlinks aren't
allowed). It's re-runnable and idempotent; run it again to update.

On Claude Code it also installs the **memory guard** (`hooks/memory-guard.sh`) as a `PreToolUse`
hook on Bash. Parallel work is allowed inside a memory budget; it refuses a heavy job (tests, `tsc`,
`next build`, a headless browser) when memory is in the red (under 15% free or swap over 6 GB) or 3
are already running, jest above 4 workers or with no cap, a second `next build`, and a 3rd headless
browser — the rules in coding-principles "Keep the dev machine alive". It adds the
hook to `~/.claude/settings.json` once (needs `jq`) and leaves the rest of the file alone. Bash
installer only.

It also installs the **delete guard** (`hooks/delete-guard.sh` + `delete-guard.py`) as a second
`PreToolUse` hook on Bash. It refuses:
- `rm` on an unguarded variable (`rm -f $S/*`; `"${S:?}"` is fine);
- anything at `/`, home or less than three folders deep;
- `rm -r` or `find -delete` outside temp folders and build output (`node_modules`, `dist`, `.next`...);
- `xargs rm -r`;
- `sudo`.

Words in a commit message, `echo` or heredoc don't trip it. The rules are in coding-principles,
"Deleting files", and the cases in `hooks/delete-guard.test.sh`. Needs `jq` and `python3`; Bash
installer only.

It also installs David's two **work modes** as skills — `/full` (plan, then full browser testing per
role) and `/quick` (code checks only) — plus a hook that remembers the mode per session and a status
line badge (`FULL` or `QUICK`; every new session starts in FULL) in front of whatever status line was already set.

**Env overrides**

| Var | Default | Purpose |
| --- | --- | --- |
| `SKILLS_BRANCH` | `develop` | Branch to pull |
| `SKILLS_SRC_DIR` | `~/.local/share/coding-style-skills` (`%LOCALAPPDATA%\coding-style-skills` on Windows) | Where the source lives |
| `SKILLS_TARGETS` | _(auto-detect)_ | `:`-separated (`;` on Windows) skills dirs to install into |

> The one-liners point at `develop` because that's this repo's branch. If you later make
> `main` the default branch, switch the URLs to `/main/`.

### Manual install (no script)

```bash
mkdir -p ~/.claude/skills
for s in coding-principles ui-review rwanda-identifiers nextjs-dashboard express-prisma-api react-vite-app python-app; do
  ln -sfn "$(pwd)/skills/$s" ~/.claude/skills/$s
done
```

Verify with `/skills` (or list them) inside Claude Code; each should appear by name.

## Editing

Each skill is `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`) plus a
markdown body. The `description` controls when Claude auto-loads the skill — keep it
specific about triggers. After editing, changes apply on the next session (no rebuild).

## Layout

```
install.sh             one-line installer (macOS / Linux / WSL / Git Bash)
install.ps1            one-line installer (Windows PowerShell)
hooks/
  work-mode.sh         UserPromptSubmit hook: records FULL / QUICK per session, reminds the model
  statusline-mode.sh   status line badge FULL / QUICK in front of the previous status line
  memory-guard.sh      Claude Code PreToolUse hook: keeps parallel work inside a 16 GB machine's budget
  delete-guard.sh      Claude Code PreToolUse hook: refuses deletes that could reach further than meant
  delete-guard.py      its rules (shlex-parsed, so quoted text never counts)
  delete-guard.test.sh the cases it must block and allow: bash hooks/delete-guard.test.sh
skills/
  coding-principles/SKILL.md
  ui-review/SKILL.md
  full/SKILL.md
  quick/SKILL.md
  rwanda-identifiers/SKILL.md
  nextjs-dashboard/SKILL.md
  express-prisma-api/SKILL.md
  react-vite-app/SKILL.md
  python-app/SKILL.md
```
