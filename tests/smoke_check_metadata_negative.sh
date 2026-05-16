#!/usr/bin/env bash
set -euo pipefail

META="artifacts/hello.cast.meta.txt"

rm -f artifacts/hello.cast "$META"

./bin/run_with_meta.sh \
  --out artifacts/hello.cast \
  -- asciinema rec -c "echo hello" artifacts/hello.cast

./bin/check_metadata.sh --metadata "$META"

# Missing status field
grep -v '^status=' "$META" > artifacts/missing_status.meta.txt

set +e
output="$(./bin/check_metadata.sh --metadata artifacts/missing_status.meta.txt)"
exit_code=$?
set -e

test "$exit_code" -eq 1
echo "$output" | grep -q '"type":"METADATA_MISSING_FIELD"'
echo "$output" | grep -q '"field":"status"'

# Bad status value
sed 's/^status=.*/status=maybe/' "$META" > artifacts/bad_status.meta.txt

set +e
output="$(./bin/check_metadata.sh --metadata artifacts/bad_status.meta.txt)"
exit_code=$?
set -e

test "$exit_code" -eq 1
echo "$output" | grep -q '"type":"METADATA_BAD_STATUS"'

# Bad exit code value
sed 's/^exit_code=.*/exit_code=banana/' "$META" > artifacts/bad_exit_code.meta.txt

set +e
output="$(./bin/check_metadata.sh --metadata artifacts/bad_exit_code.meta.txt)"
exit_code=$?
set -e

test "$exit_code" -eq 1
echo "$output" | grep -q '"type":"METADATA_BAD_EXIT_CODE"'

echo "PASS: metadata validator catches controlled failures"