#!/usr/bin/env bash
set -euo pipefail


#scripts/check_structure_to_formal_transtion.sh
missing=0

SOURCE_FILE="${1:-docs/op_table_v8.tex}"
OUT_FILE="./artifacts/structured_to_formal_transition_row.txt"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "SOURCE NOT FOUND: $SOURCE_FILE" >&2
  exit 1
fi

mkdir -p artifacts

awk '
/\\StatusStructuredAnalysis/ { flag=1; buf=$0; next }
flag && /\\StatusFormalVerification/ {
  inrow=1
  print buf
  print $0
  flag=0
  next
}
flag { flag=0 }
inrow { print }
/\\hline/ && inrow { inrow=0; exit }
' "$SOURCE_FILE" > "$OUT_FILE"

if [[ ! -s "$OUT_FILE" ]]; then
  echo "EMPTY EXTRACTION: transition row not captured" >&2
  exit 1
fi

echo "[Check] Predicate contract tokens"

for token in \
  '\StatusStructuredAnalysis' \
  '\StatusFormalVerification' \
  '\MutatesEvidence' \
  '\AdvancesPhase' \
  '\AnchorAllowed' \
  '\StructuredAnalysisSet' \
  '\ManifestSnapshot' \
  '\TransitionTime' \
  '\VerificationResult' \
  '\Phase'
do
  if ! grep -Fq -- "$token" "$OUT_FILE"; then
    echo "MISSING PREDICATE CONTRACT TOKEN: $token" >&2
    missing=1
  fi
done

echo "[Check] Executor contract tokens"

for token in \
  'make verify-transition-state TICKET=k' \
  'make verify-artifact'
do
  if ! grep -Fq -- "$token" "$OUT_FILE"; then
    echo "MISSING EXECUTOR CONTRACT TOKEN: $token" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "FAIL: StructuredAnalysis -> FormalVerification guard contract violated" >&2
  exit 1
fi

echo "PASS: StructuredAnalysis -> FormalVerification guard contract preserved"
exit 0