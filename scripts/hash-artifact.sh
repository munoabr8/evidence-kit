#!/usr/bin/env bash
# scripts/hash-artifact.sh
# Computes canonical SHA-256 for an evidence artifact.
#
# Canonical rule:
# Replace the artifact_hash line with a fixed placeholder before hashing.
#
# Usage:
#   ./scripts/hash-artifact.sh artifacts/main_refactor.tex

set -euo pipefail

artifact="${1:-}"

PLACEHOLDER="sha256:0000000000000000000000000000000000000000000000000000000000000000"

fail() {
    echo "{\"status\":\"failed\",\"code\":\"$1\",\"message\":\"$2\"}" >&2
    exit 1
}

[[ -n "$artifact" ]] || fail "MISSING_ARGUMENT" "artifact path is required"
[[ -f "$artifact" ]] || fail "ARTIFACT_NOT_FOUND" "artifact not found: $artifact"
[[ -s "$artifact" ]] || fail "EMPTY_ARTIFACT" "artifact is empty: $artifact"

# Canonicalize only the self-referential hash field.
# Everything else remains inside the hash scope.
if command -v sha256sum >/dev/null 2>&1; then
    sed -E "s|^([[:space:]]*artifact_hash:[[:space:]]*).*$|\1${PLACEHOLDER}|" "$artifact" \
        | sha256sum \
        | awk '{print $1}'
elif command -v shasum >/dev/null 2>&1; then
    sed -E "s|^([[:space:]]*artifact_hash:[[:space:]]*).*$|\1${PLACEHOLDER}|" "$artifact" \
        | shasum -a 256 \
        | awk '{print $1}'
else
    fail "HASH_TOOL_NOT_FOUND" "sha256sum or shasum is required"
fi