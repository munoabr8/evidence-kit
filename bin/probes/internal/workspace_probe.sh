#!/usr/bin/env bash
set -euo pipefail

echo "workspace:"
echo "  pwd:                $(pwd)"
echo "  git_root:           $(git rev-parse --show-toplevel 2>/dev/null || echo unavailable)"
echo "  branch:             $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unavailable)"
echo "  commit:             $(git rev-parse HEAD 2>/dev/null || echo unavailable)"

if git diff --quiet && git diff --cached --quiet; then
  clean=true
else
  clean=false
fi

echo "  clean:              $clean"

check_file() {
  local label="$1"
  local path="$2"

  if [ -f "$path" ]; then
    echo "  $label: present"
  else
    echo "  $label: missing ($path)"
    exit 1
  fi
}

check_file "probe_context" \
  "bin/probes/internal/probe_context.py"

check_file "probe_environment" \
  "bin/probes/internal/probe_environment.py"

check_file "probe_effective" \
  "bin/probes/internal/probe_effective_context.py"

echo "workspace probe: PASS"