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

if [ -f bin/probe_context.py ]; then
  echo "  probe_context:      present"
else
  echo "  probe_context:      missing"
  exit 1
fi

if [ -f bin/probe_environment.py ]; then
  echo "  probe_environment:  present"
else
  echo "  probe_environment:  missing"
  exit 1
fi