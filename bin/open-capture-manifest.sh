#!/usr/bin/env bash
set -euo pipefail

PLAN="${1:-artifacts/capture_plan.txt}"

if [[ ! -f "$PLAN" ]]; then
  echo "[open] capture plan not found: $PLAN" >&2
  exit 1
fi

echo "[open] reading capture plan from $PLAN"

while IFS= read -r URL; do
  [[ -z "$URL" ]] && continue

  echo "[open] opening $URL"

  # macOS
  if command -v open >/dev/null 2>&1; then
    open "$URL"

  # Linux (Codespaces)
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL"

  # fallback: just print the URL
  else
    echo "$URL"
  fi

  # small delay between opens to avoid browser throttling
  sleep 0.3
done < "$PLAN"

echo "[open] all URLs processed"
