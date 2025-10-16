#!/usr/bin/env bash
#./bin/run_and_capture.sh
set -euo pipefail

# --- Config ---

: "${ROOT:?missing ROOT}"
: "${ART_DIR:?missing ART_DIR}"

case "$ROOT" in /*) ;; *) echo "ROOT must be absolute" >&2; exit 2;; esac
case "$ART_DIR" in /*) ;; *) echo "ART_DIR must be absolute" >&2; exit 2;; esac


WF="${1:-${WF:-tests}}"
PORT="${PORT:-8020}"

mkdir -p "$ART_DIR"

RAW_LOG="$ART_DIR/wf.raw.log"
LOG="$ART_DIR/wf.log"
HTML="$ART_DIR/wf.html"
CAPTURE_PLAN="$ART_DIR/capture_plan.txt"

echo "[capture] starting workflow '$WF' at $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- Capture contextual information ---
if [ -x "./bin/capture_context.sh" ]; then
  echo "[capture] gathering context..."
  ./bin/capture_context.sh
else
  echo "[capture] WARNING: capture_context.sh not found or not executable"
fi

# --- Execute the workflow and record output ---
START_TIME=$(date +%s)
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

# --- Update execution metadata with timing ---
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [ -f "$ART_DIR/execution_metadata.json" ]; then
  # Update existing metadata with workflow execution details
  TMP_META=$(mktemp)
  jq --arg wf "$WF" \
     --arg dur "$DURATION" \
     --arg end "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '. + {workflow: $wf, duration_seconds: ($dur | tonumber), end_time: $end}' \
     "$ART_DIR/execution_metadata.json" > "$TMP_META" 2>/dev/null || cp "$ART_DIR/execution_metadata.json" "$TMP_META"
  mv "$TMP_META" "$ART_DIR/execution_metadata.json"
fi

# --- Generate checksums for integrity verification ---
echo "[capture] generating artifact checksums..."
(cd "$ART_DIR" && sha256sum *.log *.html *.txt *.json 2>/dev/null > checksums.sha256 || true)

# --- Write capture plan for convenience ---
{
  echo "http://localhost:${PORT}/wf.html"
  echo "http://localhost:${PORT}/index.html"
} > "$CAPTURE_PLAN"

echo "[capture] done. HTML log: $HTML"
echo "[capture] Duration: ${DURATION}s"
echo "[capture] open this in Chrome (forwarded port ${PORT}) for Hunchly capture."
