#!/bin/bash
# Memory guard for a 16 GB dev Mac: it kernel-panicked (watchdog timeout) when agents ran jest with
# 7 workers (~20 GB), several next builds and browser sweeps at once. Parallel work is fine inside a
# budget (coding-principles "Keep the dev machine alive"); this enforces the hard edges of it.
# PreToolUse(Bash): exit 2 blocks the command and shows the reason to the agent.
#
# Only a tool in COMMAND position counts (start of a line or after ; && || |, or behind
# npx / yarn / pnpm / bunx / node_modules/.bin/), so a word in a commit message or heredoc never trips it.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -z "$cmd" ] && exit 0

MAX_HEAVY_JOBS=3      # tests, tsc, next build, headless browsers — across all sessions
MAX_JEST_WORKERS=4
MAX_BROWSERS=2
MIN_FREE_PCT=15       # memory_pressure "free percentage" below this = red
MAX_SWAP_MB=6144

block() { echo "Memory guard: $1" >&2; exit 2; }

runs() { # runs <tool-regex>: is that tool invoked as a command?
  printf '%s\n' "$cmd" | grep -Eq "(^[[:space:]]*|[;&|][[:space:]]*|(npx|yarn|bunx|pnpm( exec)?|npm exec)[[:space:]]+|node_modules/\.bin/)($1)([[:space:]]|\$)"
}
runs_build() { printf '%s\n' "$cmd" | grep -Eq '(^|[;&|][[:space:]]*|npx[[:space:]]+)next build'; }
starts_browser() { printf '%s\n' "$cmd" | grep -Eq '(^|[;&|][[:space:]]*)(node|npx)[[:space:]].*(sweep|playwright|puppeteer|chromium)'; }

# Heavy jobs running now, across every session (jest = its main process, not each worker).
running_jest()     { pgrep -f 'node_modules/\.bin/jest|jest/bin/jest' | wc -l | tr -d ' '; }
running_tsc()      { pgrep -f 'node_modules/\.bin/tsc|typescript/bin/tsc' | wc -l | tr -d ' '; }
running_builds()   { pgrep -f 'next build' | wc -l | tr -d ' '; }
running_browsers() { # a browser's main process carries --headless but no --type=
  pgrep -f -- '--headless' | while read -r p; do ps -o args= -p "$p" 2>/dev/null; done | grep -vc -- '--type=' | tr -d ' '
}

heavy=0
if runs 'jest|tsc|playwright' || runs_build || starts_browser; then heavy=1; fi

if [ $heavy -eq 1 ]; then
  swap_mb=$(sysctl -n vm.swapusage | sed -E 's/.*used = ([0-9.]+)M.*/\1/' | cut -d. -f1)
  free_pct=$(memory_pressure 2>/dev/null | tail -1 | grep -oE '[0-9]+' | tail -1)
  [ "${swap_mb:-0}" -gt $MAX_SWAP_MB ] && block "swap is ${swap_mb} MB used (red above $MAX_SWAP_MB). Free memory first (finished browsers, leftover test/build processes, servers the task doesn't need), then retry."
  [ -n "$free_pct" ] && [ "$free_pct" -lt $MIN_FREE_PCT ] && block "only ${free_pct}% memory free (red under ${MIN_FREE_PCT}%). Free memory first, then retry."
  jobs=$(( $(running_jest) + $(running_tsc) + $(running_builds) + $(running_browsers) ))
  [ "$jobs" -ge $MAX_HEAVY_JOBS ] && block "$jobs heavy jobs are already running (tests, tsc, builds, browsers; limit $MAX_HEAVY_JOBS across all sessions). Wait for one to finish."
fi

if runs 'jest'; then
  workers=$(printf '%s' "$cmd" | grep -oE -- '(--maxWorkers[= ]|(^| )-w ?)[0-9]+' | grep -oE '[0-9]+$' | sort -n | tail -1)
  if [ -n "$workers" ]; then
    [ "$workers" -gt $MAX_JEST_WORKERS ] && block "jest with $workers workers; the limit is $MAX_JEST_WORKERS (~300-500 MB each with isolatedModules)."
  elif ! printf '%s' "$cmd" | grep -Eq -- '(^| )-i( |$)|--runInBand|--maxWorkers=[0-9]+%'; then
    capped=0
    dirs=$(printf '%s\n' "$cwd"; printf '%s' "$cmd" | grep -oE 'cd +("[^"]+"|[^ ;&]+)' | sed -E 's/^cd +//; s/"//g')
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      case "$d" in /*) ;; *) d="$cwd/$d" ;; esac
      if grep -qs 'maxWorkers' "$d"/jest.config.* "$d"/package.json; then capped=1; fi
    done <<< "$dirs"
    [ $capped -eq 0 ] && block "jest without a worker cap starts one worker per core (~2.8 GB each with ts-jest type-checking). Add --maxWorkers=2 --workerIdleMemoryLimit=512MB (up to 4 when memory is green), or -i."
  fi
fi

if runs_build && [ "$(running_builds)" -ge 1 ]; then
  block "another 'next build' is already running (2-4 GB each). Wait for it to finish."
fi

if starts_browser && [ "$(running_browsers)" -ge $MAX_BROWSERS ]; then
  block "$MAX_BROWSERS headless browsers are already running. Close a finished one (or reuse it) first."
fi
exit 0
