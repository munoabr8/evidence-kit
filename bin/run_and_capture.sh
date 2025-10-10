#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
ART_DIR="${ART_DIR:-artifacts}"
WF="${1:-${WF:-tests}}"
PORT="${PORT:-8009}"

mkdir -p "$ART_DIR"

RAW_LOG="$ART_DIR/wf.raw.log"
LOG="$ART_DIR/wf.log"
HTML="$ART_DIR/wf.html"
CAPTURE_PLAN="$ART_DIR/capture_plan.txt"

echo "[capture] starting workflow '$WF' at $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- Execute the workflow and record output ---
env -i PATH="/usr/bin:/bin:/usr/local/bin" \
  bash -lc "./bin/run-wf $WF" 2>&1 | tee "$RAW_LOG"

# --- Redact secrets ---
sed -E \
  -e 's/(ghp_[A-Za-z0-9]{36})/[REDACTED]/g' \
  -e 's/(GITHUB_TOKEN=)[^ ]+/\1[REDACTED]/g' \
  "$RAW_LOG" > "$LOG"

# --- Convert CLI log to HTML for browser viewing ---
if command -v ansi2html >/dev/null 2>&1; then
  ansi2html < "$LOG" > "$HTML"
else
  {
    printf '<!doctype html><meta charset="utf-8"><title>workflow</title><pre>'
    sed -e 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g' "$LOG"
    printf '</pre>'
  } > "$HTML"
fi

# --- Write capture plan for convenience ---
{
  echo "http://localhost:${PORT}/wf.html"
} > "$CAPTURE_PLAN"

echo "[capture] done. HTML log: $HTML"
echo "[capture] open this in Chrome (forwarded port ${PORT}) for Hunchly capture."
