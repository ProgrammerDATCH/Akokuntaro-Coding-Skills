#!/bin/bash
# Cases for delete-guard.sh: block or allow. Run: bash hooks/delete-guard.test.sh
cd "$(dirname "$0")" || exit 1
CWD=/Users/someone/work/app
pass=0; fail=0
check() { # check <block|allow> <command>
  out=$(jq -n --arg c "$2" --arg d "$CWD" '{tool_input:{command:$c},cwd:$d}' | HOME=/Users/someone bash ./delete-guard.sh 2>&1)
  code=$?
  want=0; [ "$1" = block ] && want=2
  if [ $code -eq $want ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL ($1): $2"; [ -n "$out" ] && echo "      $out"; fi
}

# The command that started it, and its relatives
check block 'S=/tmp/x; mkdir -p $S; rm -f $S/*'
check block 'rm -rf $DIR'
check block 'rm -rf ${DIR}/build'
check block 'rm -rf "$(pwd)/x"'
check block 'rm -rf `pwd`'
check allow 'rm -f "${S:?}"/*'
check allow 'rm -rf "${OUT:?}"'

# Root, home, shallow paths
check block 'rm -rf /'
check block 'rm -f /*'
check block 'rm -rf ~'
check block 'rm -rf ~/*'
check block 'rm -rf /Users/someone'
check block 'rm -rf /tmp'
check block 'cd / && rm -rf *'

# Recursive deletes: routine places only
check allow 'rm -rf node_modules'
check allow 'rm -rf .next dist coverage'
check allow 'rm -rf /private/tmp/claude-502/abc/scratchpad/wt'
check allow 'rm -rf /tmp/build-123'
check allow 'rm -r /var/folders/xy/T/tmp.abc'
check block 'rm -rf src'
check block 'rm -rf ../other-repo'
check block 'rm -rf /Users/someone/work/app'
check block 'git status && rm -rf docs'

# Plain file deletes are fine
check allow 'rm notes.txt'
check allow 'rm -f /tmp/x.log'
check allow 'rm -f src/old.ts src/old.test.ts'

# find and xargs
check allow 'find node_modules/.cache -name "*.tmp" -delete'
check block 'find . -name "*.log" -delete'
check block 'find $D -delete'
check block 'find src -exec rm {} \;'
check block 'ls | xargs rm -rf'
check allow 'ls *.tmp | xargs rm -f'

# sudo
check block 'sudo rm -f /etc/hosts'
check block 'sudo npm i -g x'
check block 'cd /tmp && sudo ls'

# Words that only look like commands
check allow 'git commit -m "never rm -rf $S again"'
check allow 'echo "sudo rm -rf /"'
check allow $'cat > notes.md <<\'EOF\'\nrm -rf $S\nsudo ls\nEOF'
check allow 'grep -rn "rm -rf" scripts'
check allow 'npm run lint -- --rmdir'

echo "$pass passed, $fail failed"
[ $fail -eq 0 ]
