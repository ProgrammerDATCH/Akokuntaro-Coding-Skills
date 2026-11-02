#!/bin/bash
# Memory guard for a 16 GB dev Mac: it kernel-panicked (watchdog timeout) when agents ran jest with
# 7 workers (~20 GB), several next builds and browser sweeps at once.
# PreToolUse(Bash): exit 2 blocks the command and shows the reason to the agent.
#
# Only a tool in COMMAND position counts (start of a line or after ; && || |, or behind
# npx / yarn / pnpm / bunx / .bin/), so a word in a commit message or heredoc never trips it.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -z "$cmd" ] && exit 0

runs() { # runs <tool-regex>: is that tool invoked as a command?
  printf '%s\n' "$cmd" | grep -Eq "(^[[:space:]]*|[;&|][[:space:]]*|(npx|yarn|bunx|pnpm( exec)?|npm exec)[[:space:]]+|node_modules/\.bin/)($1)([[:space:]]|\$)"
}

if runs 'jest|tsc|playwright' || printf '%s\n' "$cmd" | grep -Eq '(^|[;&|][[:space:]]*|npx[[:space:]]+)next build'; then
  swap_mb=$(sysctl -n vm.swapusage | sed -E 's/.*used = ([0-9.]+)M.*/\1/' | cut -d. -f1)
  if [ "${swap_mb:-0}" -gt 6144 ]; then
    echo "Memory guard: swap is ${swap_mb} MB used (limit 6144). This Mac panics when swap runs out. Free memory first (stop a dev server, a finished browser, a leftover test or build process), then retry." >&2
    exit 2
  fi
fi

if runs 'jest' && ! printf '%s' "$cmd" | grep -Eq -- '--maxWorkers|(^| )-w ?[0-9]|(^| )-i( |$)|--runInBand'; then
  capped=0
  dirs=$(printf '%s\n' "$cwd"; printf '%s' "$cmd" | grep -oE 'cd +("[^"]+"|[^ ;&]+)' | sed -E 's/^cd +//; s/"//g')
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    case "$d" in /*) ;; *) d="$cwd/$d" ;; esac
    if grep -qs 'maxWorkers' "$d"/jest.config.* "$d"/package.json; then capped=1; fi
  done <<< "$dirs"
  if [ $capped -eq 0 ]; then
    echo "Memory guard: jest without a worker cap uses ~2.8 GB per worker (7 workers = ~20 GB). Add --maxWorkers=2 --workerIdleMemoryLimit=512MB (or -i)." >&2
    exit 2
  fi
fi

if printf '%s\n' "$cmd" | grep -Eq '(^|[;&|][[:space:]]*|npx[[:space:]]+)next build' && pgrep -f 'next build' >/dev/null; then
  echo "Memory guard: another 'next build' is already running. Wait for it to finish; never run two builds at once on this Mac." >&2
  exit 2
fi
exit 0
