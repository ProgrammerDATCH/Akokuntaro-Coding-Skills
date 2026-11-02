#!/bin/bash
# Status line: David's work mode badge, then the status line he had before (saved by the installer
# in statusline-inner.txt). The mode is set per session by work-mode.sh.
input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
mode=$(cat "$HOME/.claude/modes/$session" 2>/dev/null)
case "$mode" in
  FULL) badge=$'\033[1;30;42m FULL \033[0m' ;;
  QUICK) badge=$'\033[1;30;43m QUICK \033[0m' ;;
  *) badge=$'\033[2m[MODE?]\033[0m' ;;
esac
inner_file="$HOME/.claude/hooks/statusline-inner.txt"
if [ -s "$inner_file" ]; then
  rest=$(printf '%s' "$input" | bash -c "$(cat "$inner_file")" 2>/dev/null | head -1)
  printf '%s %s\n' "$badge" "$rest"
else
  printf '%s\n' "$badge"
fi
