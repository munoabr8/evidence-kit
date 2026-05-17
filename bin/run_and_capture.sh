#!/usr/bin/env bash
# ./bin/run_and_capture.sh
set -euo pipefail

# Who calls this script:
# hunchly.mk -> capture make target

: "${ROOT:?missing ROOT}"
: "${ART_DIR:?missing ART_DIR}"

case "$ROOT" in
  /*) ;;
  *) echo "ROOT must be absolute" >&2; exit 2 ;;
esac

case "$ART_DIR" in
  /*) ;;
  *) echo "ART_DIR must be absolute" >&2; exit 2 ;;
esac

WF="${1:-${WF:-smoke}}"
PORT="${PORT:-8020}"

# Canonical artifact role directories
ASSETS_DIR="$ART_DIR/assets"
CAST_DIR="$ART_DIR/cast"
FIXTURES_DIR="$ART_DIR/fixtures"
LOGS_DIR="$ART_DIR/logs"
METADATA_DIR="$ART_DIR/metadata"
PLANS_DIR="$ART_DIR/plans"
VIEWS_DIR="$ART_DIR/views"

mkdir -p \
  "$ASSETS_DIR" \
  "$CAST_DIR" \
  "$FIXTURES_DIR" \
  "$LOGS_DIR" \
  "$METADATA_DIR" \
  "$PLANS_DIR" \
  "$VIEWS_DIR"

RAW_LOG="$LOGS_DIR/wf.raw.log"
LOG="$LOGS_DIR/wf.log"
HTML="$VIEWS_DIR/wf.html"
CAPTURE_PLAN="$PLANS_DIR/capture_plan.txt"

timestamp_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

echo "[capture] starting workflow '$WF' at $(timestamp_utc)"

# --- Execute the workflow and record output ---
env -i \
  HOME="${HOME:-/Users/abrahammunoz}" \
  PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/sbin" \
  LANG="${LANG:-en_US.UTF-8}" \
  XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:-/Users/abrahammunoz}/.config}" \
  ASCIINEMA_CONFIG_HOME="${ASCIINEMA_CONFIG_HOME:-${XDG_CONFIG_HOME:-${HOME:-/Users/abrahammunoz}/.config}/asciinema}" \
  ROOT="$ROOT" \
  ART_DIR="$ART_DIR" \
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
  echo "http://localhost:${PORT}/views/wf.html"
} > "$CAPTURE_PLAN"

echo "[capture] done. Raw log: $RAW_LOG"
echo "[capture] done. Redacted log: $LOG"
echo "[capture] done. HTML log: $HTML"
echo "[capture] done. Capture plan: $CAPTURE_PLAN"
echo "[capture] open this in Chrome for Hunchly capture: http://localhost:${PORT}/views/wf.html"