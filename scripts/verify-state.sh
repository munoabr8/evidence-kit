#!/bin/bash
# scripts/verify-state.sh - The Formal Verification Gate
# Usage: ./verify-state.sh --check-invariants

if [ "$1" != "--check-invariants" ]; then
    echo "Usage: ./verify-state.sh --check-invariants"
    exit 1
fi

echo "[Gatekeeper] Verifying system state against manifest..."

# Invariant Check: ∀ f ∈ manifest : f ∈ git_tree(HEAD)
# This confirms the Current HEAD matches the requirements of the manifest.
MANIFEST="evidence-manifest.txt"

if [ ! -f "$MANIFEST" ]; then
    echo "[FAIL] Invariant Violation: $MANIFEST not found."
    exit 1
fi

ALL_MET=true
while read -r file; do
    # Check if the file exists in the current git tree
    if ! git ls-tree -r HEAD --name-only | grep -q "$file"; then
        echo "[FAIL] Invariant Violation: $file is not tracked in the current HEAD."
        ALL_MET=false
    fi
done < "$MANIFEST"

if [ "$ALL_MET" = true ]; then
    echo "[PASS] Invariants Hold: Manifest integrity verified."
    exit 0
else
    echo "[FAIL] Verification Gate Closed. Resolve discrepancies before review."
    exit 1
fi