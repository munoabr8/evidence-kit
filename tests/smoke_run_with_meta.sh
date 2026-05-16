#!/usr/bin/env bash
set -euo pipefail

# run_with_meta.sh must execute the observed command once, 
# write metadata, validate metadata compatibility, 
# and preserve/normalize exit behavior according to policy.

rm -f artifacts/hello.cast artifacts/hello.cast.meta.txt
rm -f artifacts/fail.cast artifacts/fail.cast.meta.txt

./bin/run_with_meta.sh --help >/dev/null

if ./bin/run_with_meta.sh 2>/dev/null; then
  echo "FAIL: missing args should fail"
  exit 1
fi

./bin/run_with_meta.sh \
  --out artifacts/hello.cast \
  -- asciinema rec -c "echo hello" artifacts/hello.cast

test -f artifacts/hello.cast
test -f artifacts/hello.cast.meta.txt
./bin/check_metadata.sh --metadata artifacts/hello.cast.meta.txt

set +e
./bin/run_with_meta.sh \
  --out artifacts/fail.cast \
  --exit-policy preserve \
  -- bash -c 'exit 7'
exit_code=$?
set -e

test "$exit_code" -eq 7
grep -q '^raw_exit_code=7$' artifacts/fail.cast.meta.txt
grep -q '^final_exit_code=7$' artifacts/fail.cast.meta.txt
grep -q '^status=fail$' artifacts/fail.cast.meta.txt

echo "PASS: run_with_meta.sh smoke test passed"