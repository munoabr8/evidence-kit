#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
VENV="${JIRA_VENV:-/tmp/jira-check-venv}"
JIRA_PROBE="$ROOT/bin/probes/external/jira_context.py"

: "${JIRA_BASE_URL:?Set JIRA_BASE_URL}"
: "${JIRA_EMAIL:?Set JIRA_EMAIL}"
: "${JIRA_API_TOKEN:?Set JIRA_API_TOKEN}"

echo "Jira validation:"
echo "  repo_root:    $ROOT"
echo "  runtime:      $VENV/bin/python"
echo "  jira_probe:   $JIRA_PROBE"

test -x "$VENV/bin/python" || {
  echo "Jira runtime missing: $VENV/bin/python"
  exit 1
}

"$VENV/bin/python" -c \
  'import requests; print("Runtime check passed")'

PYTHONPATH="$ROOT/bin" \
  "$VENV/bin/python" \
  "$JIRA_PROBE" \
  "${1:-KAN-20}"