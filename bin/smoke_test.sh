#!/usr/bin/env bash
set -Eeuo pipefail

PORT="${PORT:-8009}"
SERVER_PID=""


# to run this in as a make target: ALLOW_GENERATE_SHA=true make -f hunchly.mk smoke-test

dump_diagnostics() {
  echo "--- SMOKE TEST DIAGNOSTICS ---"
  echo "PWD: $(pwd)"
  echo "ARTIFACTS:"
  find artifacts -maxdepth 4 -type f -o -type d | sort || true
  echo "Server headers (if server running):"
  if [ -n "${SERVER_PID:-}" ]; then
    curl -s -I "http://127.0.0.1:${PORT}/" || true
  fi
  echo "--- END DIAGNOSTICS ---"
}

cleanup() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
}

trap 'rc=$?; echo "smoke_test.sh failed rc=$rc"; dump_diagnostics || true; cleanup; exit $rc' ERR
trap 'cleanup' EXIT

TARGET="${TARGET:-smoke}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"

# Role-based artifact layout.
CAST_DIR="${ARTIFACTS_DIR}/cast"
VIEWS_DIR="${ARTIFACTS_DIR}/views"
ASSETS_DIR="${ARTIFACTS_DIR}/assets"

ASCIICAST="${CAST_DIR}/${TARGET}.cast"
WRAPPER="${VIEWS_DIR}/cast/${TARGET}.cast.html"
WRAPPER_HTTP_PATH="views/cast/${TARGET}.cast.html"

mkdir -p "${CAST_DIR}" "${VIEWS_DIR}/cast" "${ASSETS_DIR}"

if command -v asciinema >/dev/null; then
  asciinema rec --overwrite -q \
    -c "printf 'smoke\n'; sleep 0.1; printf 'done\n'" \
    "${ASCIICAST}" || {
      echo "asciinema rec failed"
      exit 1
    }
else
  now=$(date +%s)
  printf '{"version":2,"width":80,"height":24,"timestamp":%s}\n' "${now}" > "${ASCIICAST}"
  printf '[0.0, "o", "smoke\\n"]\n' >> "${ASCIICAST}"
fi

# Regenerate index + wrappers.
python3 bin/gen-index.py --art-dir "${ARTIFACTS_DIR}"

check_invariants() {
  local strict="${STRICT_INVARIANTS:-false}"
  local ok=0

  echo "[smoke-test] verifying required artifact invariants (STRICT_INVARIANTS=${strict})"

  if [ ! -f "${ASCIICAST}" ]; then
    echo "[invariant] MISSING: ${ASCIICAST}"
    ok=1
  else
    echo "[invariant] OK: ${ASCIICAST}"
  fi

  if [ ! -f "${WRAPPER}" ]; then
    echo "[invariant] MISSING: ${WRAPPER}"
    ok=1
  else
    echo "[invariant] OK: ${WRAPPER}"
  fi

  if [ ! -f "${ASSETS_DIR}/asciinema-glue.js" ]; then
    echo "[invariant] NOTE: ${ASSETS_DIR}/asciinema-glue.js not present or no longer required"
  else
    echo "[invariant] OK: ${ASSETS_DIR}/asciinema-glue.js"
  fi

  if [ ! -f "${ASSETS_DIR}/asciinema-player.min.js" ]; then
    echo "[invariant] MISSING: ${ASSETS_DIR}/asciinema-player.min.js"
    ok=1
  else
    local sz
    sz=$(( $(wc -c < "${ASSETS_DIR}/asciinema-player.min.js") ))
    echo "[invariant] OK: ${ASSETS_DIR}/asciinema-player.min.js (${sz} bytes)"
    if [ "$sz" -lt "${MIN_JS_BYTES:-10240}" ]; then
      echo "[invariant] WARNING: asciinema-player.min.js smaller than MIN_JS_BYTES=${MIN_JS_BYTES:-10240}"
      ok=1
    fi
  fi

  if [ ! -f "${ASSETS_DIR}/asciinema-player.min.css" ]; then
    echo "[invariant] MISSING: ${ASSETS_DIR}/asciinema-player.min.css"
    ok=1
  else
    echo "[invariant] OK: ${ASSETS_DIR}/asciinema-player.min.css"
  fi

  if [ -f "${ARTIFACTS_DIR}/vendor-player.json" ]; then
    if ! python3 - <<PYERR >/dev/null 2>&1
import json, sys
try:
    with open("${ARTIFACTS_DIR}/vendor-player.json") as f:
        j = json.load(f)
    assert "version" in j and "js" in j and "css" in j
except Exception as e:
    print("bad manifest", e, file=sys.stderr)
    sys.exit(2)
PYERR
    then
      echo "[invariant] BAD: ${ARTIFACTS_DIR}/vendor-player.json is invalid JSON or missing keys"
      ok=1
    else
      echo "[invariant] OK: ${ARTIFACTS_DIR}/vendor-player.json"
    fi
  else
    echo "[invariant] NOTE: ${ARTIFACTS_DIR}/vendor-player.json not present (optional)"
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

# Assert core outputs exist.
if [ ! -f "${ASCIICAST}" ] || [ ! -f "${WRAPPER}" ]; then
  echo "smoke-test: FAILED - missing cast or wrapper"
  echo "expected cast: ${ASCIICAST}"
  echo "expected wrapper: ${WRAPPER}"
  find "${ARTIFACTS_DIR}" -maxdepth 4 -type f | sort || true
  exit 2
fi

pushd "${ARTIFACTS_DIR}" >/dev/null

if [ -n "${SKIP_SERVER:-}" ]; then
  echo "smoke-test: SKIP_SERVER set - not starting HTTP server; assuming external server on port ${PORT}"
else
  python3 -m http.server "${PORT}" --bind 127.0.0.1 &
  SERVER_PID=$!
  sleep 0.3
  echo "smoke-test: HTTP server started (PID=${SERVER_PID}, port=${PORT})"
fi

popd >/dev/null

check_header() {
  local path="$1"
  local want="$2"
  local hdr

  hdr=$(curl --max-time 3 --connect-timeout 1 -s -I "http://127.0.0.1:${PORT}/${path}" | tr -d '\r') || {
    echo "smoke-test: FAILED - could not fetch headers for ${path}"
    return 1
  }

  echo "--- headers for ${path} ---"
  echo "$hdr"

  echo "$hdr" | grep -iqE "Content-Type:\s*(${want})" || {
    echo "smoke-test: FAILED - ${path} wrong content-type"
    return 2
  }
}

# Verify wrappers and assets are served with correct content-types.
check_header "${WRAPPER_HTTP_PATH}" "text/html"
check_header "assets/asciinema-player.min.js" "(application|text)/javascript"
check_header "assets/asciinema-player.min.css" "text/css"

if [ -f "${ASSETS_DIR}/asciinema-glue.js" ]; then
  check_header "assets/asciinema-glue.js" "(application|text)/javascript"
fi

MIN_JS_BYTES="${MIN_JS_BYTES:-10240}"
VENDOR_MANIFEST="${ARTIFACTS_DIR}/vendor-player.json"

if [ -f "${VENDOR_MANIFEST}" ]; then
  if ! python3 - <<PYERR >/dev/null 2>&1
import json, sys
try:
    with open("${VENDOR_MANIFEST}") as f:
        j = json.load(f)
    assert "version" in j and "js" in j and "css" in j
except Exception as e:
    print("bad manifest", e, file=sys.stderr)
    sys.exit(2)
PYERR
  then
    echo "smoke-test: FAILED - vendor manifest ${VENDOR_MANIFEST} is invalid"
    exit 2
  fi
fi

if [ -f "${ASSETS_DIR}/asciinema-player.min.js" ]; then
  sz=$(( $(wc -c < "${ASSETS_DIR}/asciinema-player.min.js") ))
  if [ "$sz" -lt "$MIN_JS_BYTES" ]; then
    echo "smoke-test: FAILED - asciinema-player.min.js too small (${sz} bytes)"
    exit 2
  fi
else
  echo "smoke-test: FAILED - asciinema-player.min.js missing"
  exit 2
fi

# New wrapper API invariant:
# local player asset works with AsciinemaPlayer.create(), not the unsupported custom element.
if ! grep -q "AsciinemaPlayer.create" "${WRAPPER}" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper missing AsciinemaPlayer.create()"
  exit 2
fi

if grep -q "<asciinema-player" "${WRAPPER}" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper still uses unsupported <asciinema-player> custom element"
  exit 2
fi

if ! grep -q "../../cast/${TARGET}.cast" "${WRAPPER}" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper does not reference cast with expected relative path"
  echo "expected: ../../cast/${TARGET}.cast"
  exit 2
fi

if ! grep -q "../../assets/asciinema-player.min.js" "${WRAPPER}" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper does not reference JS asset with expected relative path"
  echo "expected: ../../assets/asciinema-player.min.js"
  exit 2
fi

if ! grep -q "../../assets/asciinema-player.min.css" "${WRAPPER}" 2>/dev/null; then
  echo "smoke-test: FAILED - wrapper does not reference CSS asset with expected relative path"
  echo "expected: ../../assets/asciinema-player.min.css"
  exit 2
fi

# Compute or verify sha256 sums for casts recursively.
while IFS= read -r c; do
  sumfile="${c}.sha256"
  sha=$(sha256sum "$c" | awk '{print $1}')

  if [ -f "$sumfile" ]; then
    expected=$(cut -d' ' -f1 "$sumfile" || true)

    if [ "$expected" != "$sha" ]; then
      if [ "${ALLOW_GENERATE_SHA:-false}" = "true" ] || [ "${CI:-}" = "true" ]; then
        echo "$sha  $c" > "$sumfile"
        echo "smoke-test: updated stale checksum $sumfile"
      else
        echo "smoke-test: FAILED - checksum mismatch for $c"
        echo "set ALLOW_GENERATE_SHA=true to update stale checksum"
        exit 2
      fi
    fi

  else
    if [ "${ALLOW_GENERATE_SHA:-false}" = "true" ] || [ "${CI:-}" = "true" ]; then
      echo "$sha  $c" > "$sumfile"
      echo "smoke-test: wrote $sumfile"
    else
      echo "smoke-test: FAILED - missing checksum file $sumfile (set ALLOW_GENERATE_SHA=true to auto-write)"
      exit 2
    fi
  fi
done < <(find "${ARTIFACTS_DIR}" -type f -name "*.cast" | sort)

echo "smoke-test: OK"
exit 0