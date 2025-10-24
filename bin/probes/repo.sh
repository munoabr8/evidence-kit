#!/usr/bin/env bash
set -euo pipefail
script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
. "$script_dir/../probe_common.sh"

probe_repo() {
  _detect_git_flags
  decide_root
  guard_root
  if [ "$in_git" != true ]; then
    echo "repo: not a git repository" >&2; return 4
  fi
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "<no-head>")
  head=$(git rev-parse --verify HEAD 2>/dev/null || echo "")
  is_dirty=false
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then is_dirty=true; fi
  untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  if [ "${1:-}" = --json ]; then
    python3 - <<PY
import json
print(json.dumps({
  'branch': '${branch}',
  'head': '${head}',
  'is_dirty': ${is_dirty},
  'untracked_count': ${untracked_count}
}, indent=2))
PY
  else
    echo "repo:"
    echo "  branch: $branch"
    echo "  head:   $head"
    echo "  dirty:  $is_dirty"
    echo "  untracked_count: $untracked_count"
  fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  probe_repo "$1"
fi
