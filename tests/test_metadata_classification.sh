#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

 
TMP="$(mktemp -d)"

trap 'rm -rf "$TMP"' EXIT

CONSTRAINT_LOOP_ROOT="$(cd "../../constraint-loop" && pwd)"

 
 
 
mkdir -p "$TMP/artifacts/metadata"

cat > "$TMP/artifacts/metadata/sample.meta.txt" <<EOF
timestamp=2026-01-01T00:00:00Z
cwd=/tmp
command=echo test
git_branch=main
git_commit=abc123
EOF


OUT_JSON="$TMP/violations.json"
CLASSIFIED="$TMP/classified.json"

(
  cd "$TMP"
  "$REPO_ROOT/bin/check_all_metadata_txt.sh" execution > "$OUT_JSON"
)

python3 "$CONSTRAINT_LOOP_ROOT/bin/classify_failure.py" < "$OUT_JSON" > "$CLASSIFIED"


grep -q '"code": "METADATA_MISSING_FIELD"' "$CLASSIFIED"

count=$(grep -c '"code": "METADATA_MISSING_FIELD"' "$CLASSIFIED")
if [[ "$count" -lt 1 ]]; then
  echo "FAIL: expected at least 1 METADATA_MISSING_FIELD"
  exit 1
fi

grep -q '"entity": "MetadataSidecar"' "$CLASSIFIED"
grep -q '"known": true' "$CLASSIFIED"

echo "PASS: metadata classification"