#!/bin/bash
# anchor.sh - Executes the Evidence Anchoring Contract
# Formalized: { P } anchor.sh { Q }

TICKET_ID=$1

# 1. Validate Precondition (P)
if [ -z "$TICKET_ID" ]; then
    echo "Usage: ./scripts/anchor.sh [JIRA-TICKET-ID]"
    exit 1
fi

if [ ! -d ".git" ] || [ ! -f "evidence-manifest.txt" ]; then
    echo "[P] Precondition FAILED: Must be in root of a Git repo with evidence-manifest.txt"
    exit 1
fi

echo "[P] Precondition Met: Contract initiated for $TICKET_ID."

# 2. Command (C)
echo "[C] Executing staging and commit..."

# Recursive staging: ∀ f ∈ manifest : git add f
xargs git add -f < evidence-manifest.txt

# Atomic commit: git commit -> hash
# We capture the hash directly from git rev-parse for reliability
git commit -m "Evidence snapshot for $TICKET_ID: $(date)" > /dev/null
COMMIT_HASH=$(git rev-parse --short HEAD)

# 3. Postcondition (Q)
# Verify Invariant: ∀ f ∈ manifest : f ∈ git_tree(hash)
ALL_MET=true
while read -r file; do
    if ! git ls-tree -r HEAD --name-only | grep -q "$file"; then
        echo "[FAIL] Invariant Violation: $file not found in HEAD."
        ALL_MET=false
    fi
done < evidence-manifest.txt

if [ "$ALL_MET" = true ]; then
    EVIDENCE_ID="${TICKET_ID}@${COMMIT_HASH}"
    echo "[Q] Postcondition Met: Invariant verified."
    echo "--- EVIDENCE ID: $EVIDENCE_ID ---"
    exit 0
else
    echo "[Q] Postcondition FAILED: Manifest file not tracked in commit."
    exit 1
fi