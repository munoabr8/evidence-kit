#!/usr/bin/env bash
set -euo pipefail

missing=0

SOURCE_FILE="${1:-../downloads/op_table_v8.tex}"
OUT_FILE="./artifacts/structured_to_formal_transition_row.txt"

awk '
/\\StatusStructuredAnalysis/ { flag=1; buf=$0; next }
flag && /\\StatusFormalVerification/ { inrow=1; print buf; print $0; flag=0; next }
flag { flag=0 }
inrow { print }
/\\hline/ && inrow { inrow=0; exit }
' "$SOURCE_FILE" > "$OUT_FILE"

test -s "$OUT_FILE" \
|| { echo "EMPTY EXTRACTION: transition row not captured"; exit 1; }


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
  grep -Fq "$token" "$OUT_FILE" \
  || { echo "MISSING PREDICATE CONTRACT TOKEN: $token"; predicate_missing=1; }
done

echo "[Check] Executor contract tokens"

for token in \
'make verify-transition-state TICKET=k' \
'make verify-artifact'
do
  grep -Fq "$token" "$OUT_FILE" \
  || { echo "MISSING EXECUTOR CONTRACT TOKEN: $token"; executor_missing=1; }
done

if [ "$missing" -eq 0 ]; then
  echo "PASS: StructuredAnalysis -> FormalVerification guard contract preserved"
else
  echo "FAIL: StructuredAnalysis -> FormalVerification guard contract violated"
  exit 1
fi