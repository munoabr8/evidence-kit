#!/usr/bin/env bash
set -euo pipefail

TARGET=smoke
ASCIICAST=artifacts/${TARGET}.cast
mkdir -p artifacts

if command -v asciinema >/dev/null; then
  # Use asciinema to record a quick non-interactive session
  asciinema rec --overwrite -q -c "printf 'smoke\n'; sleep 0.1; printf 'done\n'" "${ASCIICAST}" || { echo "asciinema rec failed"; exit 1; }
else
  # Create a minimal asciicast v2 file as a fallback for CI-less environments
  now=$(date +%s)
  printf '{"version":2,"width":80,"height":24,"timestamp":%s}\n' "${now}" > "${ASCIICAST}"
  printf '[0.0, "o", "smoke\\n"]\n' >> "${ASCIICAST}"
fi

# regenerate wrappers
python3 bin/gen-index.py

# assert outputs exist
if [ ! -f "${ASCIICAST}" ] || [ ! -f "artifacts/${TARGET}.cast.html" ]; then
  echo "smoke-test: FAILED - missing cast or wrapper"; ls -la artifacts || true; exit 2
fi

# Start a temporary HTTP server on a random free port and capture its PID
pushd artifacts >/dev/null
PORT=8009
python3 -m http.server ${PORT} &
SERVER_PID=$!
popd >/dev/null
sleep 0.3

echo "smoke-test: HTTP server started (PID=${SERVER_PID}, port=${PORT})"

# helper to check headers
check_header(){
  local path="$1" expected_ct="$2"
  local hdr
  hdr=$(curl -s -I "http://127.0.0.1:${PORT}/${path}" | tr -d '\r' ) || return 1
  echo "--- headers for ${path} ---"
  echo "$hdr"
  if ! echo "$hdr" | grep -i "Content-type: ${expected_ct}" >/dev/null; then
    echo "smoke-test: FAILED - ${path} not served as ${expected_ct}"; return 2
  fi
  return 0
}

# Verify wrappers and assets are served with correct content-types
check_header "${TARGET}.cast.html" "text/html" || { kill ${SERVER_PID} || true; exit 2; }
check_header "asciinema-glue.js" "text/javascript" || { kill ${SERVER_PID} || true; exit 2; }
check_header "asciinema-player.min.js" "text/javascript" || { kill ${SERVER_PID} || true; exit 2; }

# Invariants to validate (strict checks)
# 1) vendor manifest exists and has version/js/css/js_sha256/css_sha256 fields (if present)
# 2) asciinema-player.min.js is >= MIN_JS_BYTES
# 3) asciinema-glue.js contains a marker string indicating generated glue
# 4) wrapper HTML contains an <asciinema-player> tag and references asciinema-glue.js
# 5) checksum files must exist and match unless ALLOW_GENERATE_SHA=true

MIN_JS_BYTES=${MIN_JS_BYTES:-10240} # default 10KB
GLUE_MARKER=${GLUE_MARKER:-"Centralized glue"}
VENDOR_MANIFEST=artifacts/vendor-player.json

if [ -f "$VENDOR_MANIFEST" ]; then
  # quick JSON sanity check for required keys
  if ! python3 - <<PYERR >/dev/null 2>&1
import json,sys
try:
    with open('$VENDOR_MANIFEST') as f:
        j=json.load(f)
    assert 'version' in j and 'js' in j and 'css' in j and 'js_sha256' in j and 'css_sha256' in j
except Exception as e:
    print('bad manifest', e, file=sys.stderr); sys.exit(2)
PYERR
  then
    echo "smoke-test: FAILED - vendor manifest $VENDOR_MANIFEST is invalid"; kill ${SERVER_PID} || true; exit 2
  fi
fi

# check JS size
if [ -f "artifacts/asciinema-player.min.js" ]; then
  sz=$(( $(wc -c < artifacts/asciinema-player.min.js) ))
  if [ "$sz" -lt "$MIN_JS_BYTES" ]; then
    echo "smoke-test: FAILED - asciinema-player.min.js too small (${sz} bytes)"; kill ${SERVER_PID} || true; exit 2
  fi
else
  echo "smoke-test: WARNING - asciinema-player.min.js missing; wrappers may fall back to CDN"
fi

# check glue marker
if ! grep -q "$GLUE_MARKER" artifacts/asciinema-glue.js 2>/dev/null; then
  echo "smoke-test: FAILED - asciinema-glue.js missing expected marker '$GLUE_MARKER'"; kill ${SERVER_PID} || true; exit 2
fi

# check wrapper HTML content
if ! grep -q "<asciinema-player" "artifacts/${TARGET}.cast.html" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper missing <asciinema-player> element"; kill ${SERVER_PID} || true; exit 2
fi
if ! grep -q "asciinema-glue.js" "artifacts/${TARGET}.cast.html" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper does not reference asciinema-glue.js"; kill ${SERVER_PID} || true; exit 2
fi

# Compute or verify sha256 sums for casts; write if missing
for c in *.cast; do
  [ -f "$c" ] || continue
  sumfile="${c}.sha256"
  sha=$(sha256sum "$c" | awk '{print $1}')
  if [ -f "$sumfile" ]; then
    expected=$(cut -d' ' -f1 "$sumfile" || true)
    if [ "$expected" != "$sha" ]; then
      echo "smoke-test: FAILED - checksum mismatch for $c"; kill ${SERVER_PID} || true; exit 2
    fi
  else
    if [ "${ALLOW_GENERATE_SHA:-false}" = "true" ]; then
      echo "$sha  $c" > "$sumfile"
      echo "smoke-test: wrote $sumfile"
    else
      echo "smoke-test: FAILED - missing checksum file $sumfile (set ALLOW_GENERATE_SHA=true to auto-write)"; kill ${SERVER_PID} || true; exit 2
    fi
  fi
done

# shutdown server
kill ${SERVER_PID} || true
wait ${SERVER_PID} 2>/dev/null || true

echo "smoke-test: OK"
exit 0
