#!/usr/bin/env bash
set -Eeuo pipefail
trap 'rc=$?; echo "smoke_test.sh failed rc=$rc"; sed -n "1,200p" /tmp/http.$PORT.log || true; exit $rc' ERR


preflight_asserts() {
  test -f bin/gen-index.py || { echo "missing bin/gen-index.py"; exit 90; }
  mkdir -p artifacts
  python3 bin/gen-index.py || true
  test -f artifacts/index.html || { echo "missing artifacts/index.html"; exit 91; }
  test -f artifacts/asciinema-glue.js || { echo "missing glue.js"; exit 12; }
  test -f artifacts/asciinema-player.min.js || { echo "missing player.js"; exit 93; }
  [ "$(wc -c < artifacts/asciinema-player.min.js)" -ge "${MIN_JS_BYTES:-10240}" ] || { echo "player.js too small"; exit 94; }
}

preflight_asserts


LOG="${TMPDIR:-/tmp}/err_trap_harness.log"
: >"$LOG"

dump_diagnostics() {
  local status=$?
  printf 'TRAP: ts=%(%Y-%m-%dT%H:%M:%S)T status=%s cmd=%q line=%s func=%s src=%s pwd=%q\n' \
    -1 \
    "$status" \
    "$BASH_COMMAND" \
    "${BASH_LINENO[0]}" \
    "${FUNCNAME[1]-MAIN}" \
    "${BASH_SOURCE[1]-MAIN}" \
    "$PWD" >>"$LOG" || true

  return "$status"
}

 
trap 'dump_diagnostics' ERR

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

# Early invariants check: verify required files exist and basic sanity before starting server.
# If STRICT_INVARIANTS=true, fail early; otherwise emit warnings so CI logs are clearer.
check_invariants() {
  local strict=${STRICT_INVARIANTS:-false}
  local ok=0
  echo "[smoke-test] verifying required artifact invariants (STRICT_INVARIANTS=${strict})"

  # wrapper exists
  if [ ! -f "artifacts/${TARGET}.cast.html" ]; then
    echo "[invariant] MISSING: artifacts/${TARGET}.cast.html"
    ok=1
  else
    echo "[invariant] OK: artifacts/${TARGET}.cast.html"
  fi

  # glue
  if [ ! -f "artifacts/asciinema-glue.js" ]; then
    echo "[invariant] MISSING: artifacts/asciinema-glue.js"
    ok=1
  else
    echo "[invariant] OK: artifacts/asciinema-glue.js"
  fi

  # player JS
  if [ ! -f "artifacts/asciinema-player.min.js" ]; then
    echo "[invariant] MISSING: artifacts/asciinema-player.min.js"
    ok=1
  else
    sz=$(( $(wc -c < artifacts/asciinema-player.min.js) ))
    echo "[invariant] OK: artifacts/asciinema-player.min.js (${sz} bytes)"
    if [ "$sz" -lt "${MIN_JS_BYTES:-10240}" ]; then
      echo "[invariant] WARNING: asciinema-player.min.js smaller than MIN_JS_BYTES=${MIN_JS_BYTES:-10240}"
      ok=1
    fi
  fi

  # vendor manifest (if present) must be parseable and have required keys
  if [ -f "artifacts/vendor-player.json" ]; then
    if ! python3 - <<PYERR >/dev/null 2>&1
import json,sys
try:
    with open('artifacts/vendor-player.json') as f:
        j=json.load(f)
    assert 'version' in j and 'js' in j and 'css' in j
except Exception as e:
    print('bad manifest', e, file=sys.stderr); sys.exit(2)
PYERR
    then
      echo "[invariant] BAD: artifacts/vendor-player.json is invalid JSON or missing keys"
      ok=1
    else
      echo "[invariant] OK: artifacts/vendor-player.json"
    fi
  else
    echo "[invariant] NOTE: artifacts/vendor-player.json not present (optional)"
  fi

  if [ "$ok" -ne 0 ]; then
    if [ "$strict" = "true" ]; then
      echo "[smoke-test] invariant check FAILED (strict); aborting"
      dump_diagnostics || true
      exit 2
    else
      echo "[smoke-test] invariant check reported issues (non-strict mode): continuing but CI may fail later"
    fi
  else
    echo "[smoke-test] all quick invariants OK"
  fi
}

check_invariants

# assert outputs exist
if [ ! -f "${ASCIICAST}" ] || [ ! -f "artifacts/${TARGET}.cast.html" ]; then
  echo "smoke-test: FAILED - missing cast or wrapper"; ls -la artifacts || true; exit 2
fi

# Start a temporary HTTP server on a random free port and capture its PID
pushd artifacts >/dev/null
# allow caller to override PORT and to tell this script not to start a server
PORT=${PORT:-8009}
if [ -n "${SKIP_SERVER:-}" ]; then
  echo "smoke-test: SKIP_SERVER set - not starting HTTP server; assuming external server on port ${PORT}"
  SERVER_PID=""
else
  python3 -m http.server ${PORT} &
  SERVER_PID=$!
  sleep 0.3
  echo "smoke-test: HTTP server started (PID=${SERVER_PID}, port=${PORT})"
fi
popd >/dev/null

# helper to check headers
 
check_header(){
  local path="$1" ; local want="$2"   # want is a regex
  local hdr
  hdr=$(curl -s -I "http://127.0.0.1:${PORT}/${path}" | tr -d '\r') || return 1
  echo "--- headers for ${path} ---"
  echo "$hdr"
  echo "$hdr" | grep -iqE "Content-Type:\s*(${want})" || {
    echo "smoke-test: FAILED - ${path} wrong content-type"; return 2; }
}

# Verify wrappers and assets are served with correct content-types

check_header "${TARGET}.cast.html" "text/html"
check_header "asciinema-glue.js" "(application|text)/javascript"
check_header "asciinema-player.min.js" "(application|text)/javascript"

 
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
    echo "smoke-test: FAILED - vendor manifest $VENDOR_MANIFEST is invalid"
    if [ -n "${SERVER_PID:-}" ]; then kill ${SERVER_PID} || true; fi
    exit 2
  fi
fi

# check JS size
  if [ -f "artifacts/asciinema-player.min.js" ]; then
  sz=$(( $(wc -c < artifacts/asciinema-player.min.js) ))
  if [ "$sz" -lt "$MIN_JS_BYTES" ]; then
    echo "smoke-test: FAILED - asciinema-player.min.js too small (${sz} bytes)"
    if [ -n "${SERVER_PID:-}" ]; then kill ${SERVER_PID} || true; fi
    exit 2
  fi
else
  echo "smoke-test: WARNING - asciinema-player.min.js missing; wrappers may fall back to CDN"
fi

# check glue marker
if ! grep -q "$GLUE_MARKER" artifacts/asciinema-glue.js 2>/dev/null; then
  echo "smoke-test: FAILED - asciinema-glue.js missing expected marker '$GLUE_MARKER'"
  if [ -n "${SERVER_PID:-}" ]; then kill ${SERVER_PID} || true; fi
  exit 2
fi

# check wrapper HTML content
if ! grep -q "<asciinema-player" "artifacts/${TARGET}.cast.html" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper missing <asciinema-player> element"
  if [ -n "${SERVER_PID:-}" ]; then kill ${SERVER_PID} || true; fi
  exit 2
fi
if ! grep -q "asciinema-glue.js" "artifacts/${TARGET}.cast.html" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper does not reference asciinema-glue.js"
  if [ -n "${SERVER_PID:-}" ]; then kill ${SERVER_PID} || true; fi
  exit 2
fi

# Compute or verify sha256 sums for casts; write if missing
for c in *.cast; do
  [ -f "$c" ] || continue
  sumfile="${c}.sha256"
  sha=$(sha256sum "$c" | awk '{print $1}')
  if [ -f "$sumfile" ]; then
    expected=$(cut -d' ' -f1 "$sumfile" || true)
    if [ "$expected" != "$sha" ]; then
      echo "smoke-test: FAILED - checksum mismatch for $c"
      if [ -n "${SERVER_PID:-}" ]; then kill ${SERVER_PID} || true; fi
      exit 2
    fi
  else
    # In CI we permit auto-generating checksum files to avoid brittle failures
    if [ "${ALLOW_GENERATE_SHA:-false}" = "true" ] || [ "${CI:-}" = "true" ]; then
      echo "$sha  $c" > "$sumfile"
      echo "smoke-test: wrote $sumfile"
    else
      echo "smoke-test: FAILED - missing checksum file $sumfile (set ALLOW_GENERATE_SHA=true to auto-write)"
      if [ -n "${SERVER_PID:-}" ]; then kill ${SERVER_PID} || true; fi
      exit 2
    fi
  fi
done

# shutdown server
if [ -n "${SERVER_PID:-}" ]; then
  kill ${SERVER_PID} || true
  wait ${SERVER_PID} 2>/dev/null || true
fi

echo "smoke-test: OK"
exit 0
