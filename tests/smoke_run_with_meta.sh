#!/usr/bin/env bash
set -euo pipefail

HELLO_CAST="artifacts/cast/hello.cast"
HELLO_META="artifacts/metadata/hello.cast.meta.txt"

FAIL_CAST="artifacts/cast/fail.cast"
FAIL_META="artifacts/metadata/fail.cast.meta.txt"

rm -f "$HELLO_CAST" "$HELLO_META"
rm -f "$FAIL_CAST" "$FAIL_META"

./bin/run_with_meta.sh --help >/dev/null

if ./bin/run_with_meta.sh 2>/dev/null; then
  echo "FAIL: missing args should fail"
  exit 1
fi

./bin/run_with_meta.sh \
  --out "$HELLO_CAST" \
  -- asciinema rec -c "echo hello" "$HELLO_CAST"

test -f "$HELLO_CAST"
test -f "$HELLO_META"

./bin/check_metadata.sh --metadata "$HELLO_META"

set +e
./bin/run_with_meta.sh \
  --out "$FAIL_CAST" \
  --exit-policy preserve \
  -- bash -c 'exit 7'
exit_code=$?
set -e

test "$exit_code" -eq 7
test -f "$FAIL_META"

grep -q '^raw_exit_code=7$' "$FAIL_META"
grep -q '^final_exit_code=7$' "$FAIL_META"
grep -q '^status=fail$' "$FAIL_META"

echo "PASS: run_with_meta.sh smoke test passed"