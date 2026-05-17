#!/usr/bin/env bash
set -euo pipefail

# Does the generated HTML wrapper point to the right playback assets
# and use the supported AsciinemaPlayer.create() API?

TARGET="${TARGET:-smoke}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"

WRAPPER="${1:-${ARTIFACTS_DIR}/views/cast/${TARGET}.cast.html}"

EXPECTED_CSS="../../assets/asciinema-player.min.css"
EXPECTED_JS="../../assets/asciinema-player.min.js"
EXPECTED_CAST="../../cast/${TARGET}.cast"

echo "[smoke-playback] checking $WRAPPER"

test -f "$WRAPPER" || {
  echo "FAIL: missing $WRAPPER"
  echo "Available wrappers:"
  find "$ARTIFACTS_DIR" -maxdepth 4 -type f -name "*.html" | sort || true
  exit 60
}

grep -q "href=['\"]${EXPECTED_CSS}['\"]" "$WRAPPER" \
  && echo "OK: wrapper references assets CSS: ${EXPECTED_CSS}" \
  || { echo "FAIL: wrapper does not reference assets CSS: ${EXPECTED_CSS}"; exit 61; }

grep -q "src=['\"]${EXPECTED_JS}['\"]" "$WRAPPER" \
  && echo "OK: wrapper references assets JS: ${EXPECTED_JS}" \
  || { echo "FAIL: wrapper does not reference assets JS: ${EXPECTED_JS}"; exit 62; }

grep -q "${EXPECTED_CAST}" "$WRAPPER" \
  && echo "OK: wrapper references cast: ${EXPECTED_CAST}" \
  || { echo "FAIL: wrapper does not reference cast: ${EXPECTED_CAST}"; exit 64; }

grep -q "AsciinemaPlayer.create" "$WRAPPER" \
  && echo "OK: wrapper uses AsciinemaPlayer.create()" \
  || { echo "FAIL: wrapper missing AsciinemaPlayer.create()"; exit 65; }

! grep -q "<asciinema-player" "$WRAPPER" \
  && echo "OK: wrapper does not use unsupported <asciinema-player> custom element" \
  || { echo "FAIL: wrapper still uses unsupported <asciinema-player> custom element"; exit 66; }

! grep -q "%%" "$WRAPPER" \
  && echo "OK: no unresolved template tokens" \
  || { echo "FAIL: unresolved template token found"; exit 67; }

echo "[smoke-playback] OK"