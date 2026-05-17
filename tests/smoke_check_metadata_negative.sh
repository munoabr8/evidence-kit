#!/usr/bin/env bash
set -euo pipefail

CAST="artifacts/cast/hello.cast"
META="artifacts/metadata/hello.cast.meta.txt"

FIXTURE_META_DIR="artifacts/fixtures/metadata"
MISSING_STATUS="$FIXTURE_META_DIR/missing_status.meta.txt"
BAD_STATUS="$FIXTURE_META_DIR/bad_status.meta.txt"
BAD_EXIT_CODE="$FIXTURE_META_DIR/bad_exit_code.meta.txt"

mkdir -p "$(dirname "$CAST")" "$(dirname "$META")" "$FIXTURE_META_DIR"

rm -f "$CAST" "$META" "$MISSING_STATUS" "$BAD_STATUS" "$BAD_EXIT_CODE"

./bin/run_with_meta.sh \
  --out "$CAST" \
  -- asciinema rec -c "echo hello" "$CAST"

./bin/check_metadata.sh --metadata "$META"

# Missing status field
grep -v '^status=' "$META" > "$MISSING_STATUS"

set +e
output="$(./bin/check_metadata.sh --metadata "$MISSING_STATUS")"
exit_code=$?
set -e

test "$exit_code" -eq 1
echo "$output" | grep -q '"type":"METADATA_MISSING_FIELD"'
echo "$output" | grep -q '"field":"status"'

# Bad status value
sed 's/^status=.*/status=maybe/' "$META" > "$BAD_STATUS"

set +e
output="$(./bin/check_metadata.sh --metadata "$BAD_STATUS")"
exit_code=$?
set -e

test "$exit_code" -eq 1
echo "$output" | grep -q '"type":"METADATA_BAD_STATUS"'

# Bad exit code value
sed 's/^exit_code=.*/exit_code=banana/' "$META" > "$BAD_EXIT_CODE"

set +e
output="$(./bin/check_metadata.sh --metadata "$BAD_EXIT_CODE")"
exit_code=$?
set -e

test "$exit_code" -eq 1
echo "$output" | grep -q '"type":"METADATA_BAD_EXIT_CODE"'

echo "PASS: metadata validator catches controlled failures"