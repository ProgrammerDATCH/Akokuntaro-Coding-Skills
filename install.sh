#!/usr/bin/env bash
#
# Install Akokuntaro Coding Skills (David's coding-style conventions) into every detected AI agent.
#
#   curl -fsSL https://raw.githubusercontent.com/ProgrammerDATCH/Akokuntaro-Coding-Skills/develop/install.sh | bash
#
# It fetches (or updates) the skills source, finds every agent that uses the
# SKILL.md format, and symlinks each skill into it (copying if symlinks aren't
# allowed). Re-runnable and idempotent.
#
# Env overrides:
#   SKILLS_BRANCH    branch to pull         (default: develop)
#   SKILLS_SRC_DIR   where to keep source   (default: ~/.local/share/coding-style-skills)
#   SKILLS_TARGETS   ':'-separated skills dirs to install into (skips auto-detect)
#   CLAUDE_CONFIG_DIR  honored when detecting Claude Code (may be ':'-separated)

set -euo pipefail

REPO_SLUG="ProgrammerDATCH/Akokuntaro-Coding-Skills"
BRANCH="${SKILLS_BRANCH:-develop}"
SRC_DIR="${SKILLS_SRC_DIR:-$HOME/.local/share/coding-style-skills}"
SKILLS="coding-principles ui-review rwanda-identifiers nextjs-dashboard express-prisma-api react-vite-app python-app full quick"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  +\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Locate the skills source: use the surrounding checkout if present,
#    otherwise clone (or download a tarball when git is unavailable).
resolve_source() {
  # Only treat as a local checkout when the script is a real file on disk
  # (i.e. `bash install.sh`). When piped via `curl | bash`, BASH_SOURCE is
  # "bash", not a file, so we always fetch — never mistake the current dir.
  script="${BASH_SOURCE[0]:-}"
  self_dir=""
  if [ -n "$script" ] && [ -f "$script" ]; then
    self_dir="$(cd "$(dirname "$script")" 2>/dev/null && pwd || true)"
  fi
  if [ -n "$self_dir" ] && [ -d "$self_dir/skills" ]; then
    SRC_DIR="$self_dir"
    info "Using local checkout at $SRC_DIR"
  elif command -v git >/dev/null 2>&1; then
    if [ -d "$SRC_DIR/.git" ]; then
      info "Updating skills source in $SRC_DIR"
      git -C "$SRC_DIR" pull --ff-only --quiet || warn "could not update; using existing copy"
    else
      info "Cloning skills into $SRC_DIR"
      rm -rf "$SRC_DIR"
      git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO_SLUG.git" "$SRC_DIR" --quiet
    fi
  else
    command -v curl >/dev/null 2>&1 || die "need git or curl to download the skills"
    info "Downloading skills tarball into $SRC_DIR"
    rm -rf "$SRC_DIR"; mkdir -p "$SRC_DIR"
    curl -fsSL "https://github.com/$REPO_SLUG/archive/refs/heads/$BRANCH.tar.gz" \
      | tar -xz -C "$SRC_DIR" --strip-components=1
  fi
  [ -d "$SRC_DIR/skills" ] || die "skills/ not found in $SRC_DIR"
}

# 2. Find every agent that consumes SKILL.md skills. Prints "Name|/skills/dir"
#    per line. Extend the known list below as more agents are supported.
discover_agents() {
  if [ -n "${SKILLS_TARGETS:-}" ]; then
    printf '%s\n' "$SKILLS_TARGETS" | tr ':' '\n' | while IFS= read -r d; do
      [ -n "$d" ] && printf 'Custom|%s\n' "$d"
    done
    return
  fi
  # Claude Code — respects CLAUDE_CONFIG_DIR (which may itself be ':'-separated).
  printf '%s\n' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" | tr ':' '\n' | while IFS= read -r home; do
    [ -n "$home" ] && printf 'Claude Code|%s/skills\n' "$home"
  done
}

# 3. Symlink every skill into one agent's skills dir (copy if symlinks fail).
install_into() {
  name="$1"; dir="$2"
  mkdir -p "$dir"
  for s in $SKILLS; do
    target="$SRC_DIR/skills/$s"; link="$dir/$s"
    [ -d "$target" ] || die "missing skill: $target"
    if ln -sfn "$target" "$link" 2>/dev/null; then :; else
      rm -rf "$link"; cp -R "$target" "$link"
    fi
  done
  ok "$name -> $dir"
}

# Claude Code only: the memory guard (see coding-principles "Keep the dev machine alive") as a
# PreToolUse hook on Bash. The script is symlinked so a pull updates it; settings.json gains the hook
# once and is otherwise left exactly as it was. Needs jq; skipped with a warning without it.
install_memory_guard() {
  claude_dir="${CLAUDE_CONFIG_DIR%%:*}"; claude_dir="${claude_dir:-$HOME/.claude}"
  [ -d "$claude_dir" ] || return 0
  mkdir -p "$claude_dir/hooks"
  ln -sfn "$SRC_DIR/hooks/memory-guard.sh" "$claude_dir/hooks/memory-guard.sh" 2>/dev/null \
    || cp "$SRC_DIR/hooks/memory-guard.sh" "$claude_dir/hooks/memory-guard.sh"
  command -v jq >/dev/null 2>&1 || { warn "jq not found — add the memory-guard hook to settings.json by hand"; return 0; }
  settings="$claude_dir/settings.json"
  [ -f "$settings" ] || echo '{}' > "$settings"
  if jq -e '[.hooks.PreToolUse[]?.hooks[]?.command] | any(test("memory-guard.sh"))' "$settings" >/dev/null 2>&1; then
    ok "memory guard hook already registered"
    return 0
  fi
  tmp="$(mktemp)"
  jq --arg cmd "bash \"$claude_dir/hooks/memory-guard.sh\"" \
    '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{"matcher":"Bash","hooks":[{"type":"command","command":$cmd,"timeout":10,"statusMessage":"Checking memory"}]}])' \
    "$settings" > "$tmp" && mv "$tmp" "$settings"
  ok "memory guard hook -> $settings"
}

# Claude Code only: the delete guard (see coding-principles "Deleting files") as a PreToolUse hook
# on Bash. It refuses rm on an unguarded variable, anything near / or home, a recursive delete outside
# temp and build folders, and sudo. Both files are symlinked, so a pull updates them; settings.json
# gains the hook once. Needs jq and python3; skipped with a warning without them.
install_delete_guard() {
  claude_dir="${CLAUDE_CONFIG_DIR%%:*}"; claude_dir="${claude_dir:-$HOME/.claude}"
  [ -d "$claude_dir" ] || return 0
  mkdir -p "$claude_dir/hooks"
  for script in delete-guard.sh delete-guard.py; do
    ln -sfn "$SRC_DIR/hooks/$script" "$claude_dir/hooks/$script" 2>/dev/null \
      || cp "$SRC_DIR/hooks/$script" "$claude_dir/hooks/$script"
  done
  command -v python3 >/dev/null 2>&1 || warn "python3 not found — the delete guard will skip its checks"
  command -v jq >/dev/null 2>&1 || { warn "jq not found — add the delete-guard hook to settings.json by hand"; return 0; }
  settings="$claude_dir/settings.json"
  [ -f "$settings" ] || echo '{}' > "$settings"
  if jq -e '[.hooks.PreToolUse[]?.hooks[]?.command] | any(test("delete-guard.sh"))' "$settings" >/dev/null 2>&1; then
    ok "delete guard hook already registered"
    return 0
  fi
  tmp="$(mktemp)"
  jq --arg cmd "bash \"$claude_dir/hooks/delete-guard.sh\"" \
    '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{"matcher":"Bash","hooks":[{"type":"command","command":$cmd,"timeout":10,"statusMessage":"Checking deletes"}]}])' \
    "$settings" > "$tmp" && mv "$tmp" "$settings"
  ok "delete guard hook -> $settings"
}

# Claude Code only: David's work modes, FULL (/full) and QUICK (/quick). work-mode.sh records the
# mode per session and reminds the model of it on every message; statusline-mode.sh shows it in front
# of whatever status line was already set up (saved to statusline-inner.txt). Idempotent; needs jq.
install_work_mode() {
  claude_dir="${CLAUDE_CONFIG_DIR%%:*}"; claude_dir="${claude_dir:-$HOME/.claude}"
  [ -d "$claude_dir" ] || return 0
  mkdir -p "$claude_dir/hooks"
  for script in work-mode.sh statusline-mode.sh; do
    ln -sfn "$SRC_DIR/hooks/$script" "$claude_dir/hooks/$script" 2>/dev/null \
      || cp "$SRC_DIR/hooks/$script" "$claude_dir/hooks/$script"
  done
  command -v jq >/dev/null 2>&1 || { warn "jq not found — add the work-mode hook and status line by hand"; return 0; }
  settings="$claude_dir/settings.json"
  [ -f "$settings" ] || echo '{}' > "$settings"
  tmp="$(mktemp)"
  if ! jq -e '[.hooks.UserPromptSubmit[]?.hooks[]?.command] | any(test("work-mode.sh"))' "$settings" >/dev/null 2>&1; then
    jq --arg cmd "bash \"$claude_dir/hooks/work-mode.sh\"" \
      '.hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) + [{"hooks":[{"type":"command","command":$cmd,"timeout":5}]}])' \
      "$settings" > "$tmp" && mv "$tmp" "$settings"
    ok "work mode hook -> $settings"
  fi
  current="$(jq -r '.statusLine.command // empty' "$settings")"
  case "$current" in
    *statusline-mode.sh*) ok "work mode status line already set" ;;
    *)
      printf '%s' "$current" > "$claude_dir/hooks/statusline-inner.txt"
      jq --arg cmd "bash \"$claude_dir/hooks/statusline-mode.sh\"" \
        '.statusLine = ((.statusLine // {}) + {"type":"command","command":$cmd})' "$settings" > "$tmp" && mv "$tmp" "$settings"
      ok "work mode status line -> $settings (previous one kept after the badge)" ;;
  esac
}

main() {
  info "Installing coding-style skills"
  resolve_source

  agents="$(discover_agents)"
  if [ -z "$agents" ]; then
    warn "no agents detected — defaulting to Claude Code (~/.claude)"
    agents="Claude Code|$HOME/.claude/skills"
  fi

  printf '%s\n' "$agents" | while IFS= read -r entry; do
    [ -n "$entry" ] && install_into "${entry%%|*}" "${entry#*|}"
  done
  install_memory_guard
  install_delete_guard
  install_work_mode
  info "Done — installed: ${SKILLS// /, }"
  info "Start a new agent session to pick up the skills."
}

main "$@"
