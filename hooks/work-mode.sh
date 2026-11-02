#!/bin/bash
# UserPromptSubmit hook: David's two work modes, FULL (/full, Set 1) and QUICK (/quick, Set 2).
# Records the mode per session when he switches (the command, or his pasted Set 1 / Set 2 text), and
# reminds the model of the current mode on every message so it never drifts. New sessions start in FULL. statusline-mode.sh reads
# the same file to show [FULL] / [QUICK] / [MODE?] in the terminal.
input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // empty')
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty')
[ -z "$session" ] && exit 0
dir="$HOME/.claude/modes"; mkdir -p "$dir"
file="$dir/$session"

first_line=$(printf '%s' "$prompt" | head -1 | tr '[:upper:]' '[:lower:]')
case "$first_line" in
  /full*) echo FULL > "$file" ;;
  /quick*) echo QUICK > "$file" ;;
esac
# His own wording of each set also switches it, so pasting the old paragraph still works.
if printf '%s' "$prompt" | grep -qi "work on these, non-stop"; then echo FULL > "$file"; fi
if printf '%s' "$prompt" | grep -qi "apply quick fixes"; then echo QUICK > "$file"; fi

# Every new session starts in FULL; a session keeps whatever it was switched to (resumes included,
# since the mode is stored under the session id).
[ -s "$file" ] || echo FULL > "$file"
touch "$file"

# Mode files of sessions untouched for 30 days are cleared.
find "$dir" -type f -mtime +30 -delete 2>/dev/null

mode=$(cat "$file" 2>/dev/null)
case "$mode" in
  FULL) note="Work mode: FULL (/full skill). Ask all questions before starting, then run non-stop to the last item; done = driven in Chrome at ~390px and desktop as every affected role (apps: in the emulator); max 2 agents; commit locally, no push/deploy unless asked." ;;
  QUICK) note="Work mode: QUICK (/quick skill). Apply fixes and verify in code only (typecheck, lint, targeted tests); no browser, no push, no deploy unless asked; commit locally; say only code checks ran." ;;
esac
jq -n --arg c "$note" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $c}}'
