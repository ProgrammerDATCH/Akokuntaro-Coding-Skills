#!/bin/bash
# Delete guard: refuses a deletion that could reach far more than intended. The case that
# started it: `rm -f $S/*`, where an empty $S becomes `rm -f /*`.
# coding-principles, "Deleting files".
# PreToolUse(Bash): exit 2 blocks the command and shows the reason to the agent.
#
# Refuses:
#   - sudo, anywhere it runs as a command;
#   - rm, or find -delete / -exec rm, on a target with an unguarded variable ($S, ${S},
#     $(...)). "${S:?}" is allowed: the shell stops instead of running rm on an empty S;
#   - any rm of /, ~, $HOME, or a path less than three folders deep (/Users/david);
#   - rm -r, or find -delete, outside the places where deleting is routine:
#       * the session scratchpad and other temp folders: /tmp/..., /private/tmp/...,
#         /var/folders/...;
#       * build output and caches inside a project: node_modules, dist, build, .next, out,
#         coverage, .turbo, .cache, .expo, __pycache__, .pytest_cache, .parcel-cache;
#   - xargs rm -r, whose targets can't be known.
# Only a tool in COMMAND position counts, so the words in a commit message, an echo or a heredoc
# never trip it. The rules live in delete-guard.py; the cases in delete-guard.test.sh.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -z "$cmd" ] && exit 0
case "$cmd" in *rm*|*sudo*|*-delete*) ;; *) exit 0 ;; esac

py=$(command -v python3 || echo /usr/bin/python3)
[ -x "$py" ] || { echo "Delete guard: python3 not found; deletion checks skipped" >&2; exit 0; }

reason=$("$py" "$(dirname "$0")/delete-guard.py" "$cmd" "$cwd" "$HOME")
[ -n "$reason" ] && { echo "Delete guard: $reason" >&2; exit 2; }
exit 0
