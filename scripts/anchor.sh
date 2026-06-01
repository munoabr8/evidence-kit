#!/usr/bin/env bash
# scripts/anchor.sh - Executes the Evidence Anchoring Contract
# Formalized: { P } anchor.sh { Q }

set -u
set -o pipefail

manifest_file="evidence-manifest.txt"
ticket_id="${1:-}"
EXPECTED_STATUS="In Review"

# 1. Validate Precondition (P)
if [[ -z "$ticket_id" ]]; then
    echo "Usage: ./scripts/anchor.sh [JIRA-TICKET-ID]"
    exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "[P] Precondition FAILED: Must be inside a Git repository."
    exit 1
}
cd "$repo_root" || exit 1

if [[ ! -f "$manifest_file" ]]; then
    echo "[P] Precondition FAILED: $manifest_file not found at repo root."
    exit 1
fi

# Assert tracking authority alignment
echo "[P] Verifying tracking authority state for $ticket_id..."
if ! command -v jira &> /dev/null; then
    echo "[P] Precondition FAILED: 'jira' CLI tool is not installed or in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "[P] Precondition FAILED: 'jq' tool is not installed or in PATH."
    exit 1
fi

# Capture raw response to handle network/auth failures vs. payload structure
RAW_RESPONSE=$(jira issue view "$ticket_id" --raw 2>&1)
if [[ $? -ne 0 ]]; then
    echo "[P] Precondition FAILED: 'jira' CLI execution encountered an error."
    echo "    Details: $RAW_RESPONSE"
    exit 1
fi

if [[ $? -ne 0 ]]; then
    echo "[P] Precondition FAILED: 'jira' CLI execution encountered an error."
    echo "    Details: $RAW_RESPONSE"
    exit 1
fi

CURRENT_STATUS=$(echo "$RAW_RESPONSE" | jq -r '.fields.status.name' 2>/dev/null)

if [[ -z "$CURRENT_STATUS" || "$CURRENT_STATUS" == "null" ]]; then
    echo "[P] Precondition FAILED: Unable to resolve status field from Jira payload."
    echo "    Raw Payload: $RAW_RESPONSE"
    exit 1
fi

if [[ "$CURRENT_STATUS" != "$EXPECTED_STATUS" ]]; then
    echo "[P] Precondition FAILED: State asymmetry detected."
    echo "    Ticket $ticket_id is currently '$CURRENT_STATUS', but contract requires '$EXPECTED_STATUS'."
    exit 1
fi

# Helper function to verify invariant state
verify_manifest_against_head() {
    local all_met=true
    local file
    while IFS= read -r file || [[ -n "$file" ]]; do
        file="${file%$'\r'}" # Trim CRLF
        [[ "$file" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$file" ]] && continue
        
        if ! git cat-file -e "HEAD:$file" 2>/dev/null; then
            echo "[FAIL] Invariant Violation: $file is not tracked in HEAD."
            all_met=false
        fi
    done < "$manifest_file"
    
    [[ "$all_met" == true ]] && return 0 || return 1
}

echo "[P] Precondition Met: Contract initiated and synchronized for $ticket_id."

# 2. Command (C)
echo "[C] Staging manifest and evidence files..."

git add -- "$manifest_file" || {
    echo "[C] Failed to stage $manifest_file."
    exit 1
}

while IFS= read -r file || [[ -n "$file" ]]; do
    file="${file%$'\r'}"
    [[ "$file" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$file" ]] && continue

    if [[ ! -e "$file" ]]; then
        echo "[C] Manifest file missing from working tree: $file"
        exit 1
    fi

    if ! git add -f -- "$file"; then
        echo "[C] Failed to stage manifest file: $file"
        exit 1
    fi
done < "$manifest_file"

# Handle the No-Op / Idempotency check safely
if git diff --cached --quiet; then
    echo "[C] No new changes staged. Checking if current HEAD satisfies contract..."
    if verify_manifest_against_head; then
        commit_hash="$(git rev-parse --short HEAD)"
        echo "[Q] Postcondition Met (Pre-existing state valid)."
        echo "--- EVIDENCE ID: ${ticket_id}@${commit_hash} ---"
        exit 0
    else
        echo "[Q] Postcondition FAILED: No changes staged, and HEAD is missing manifest files."
        exit 1
    fi
fi

# Proceed with commit if changes exist
commit_message="Evidence snapshot for $ticket_id: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
if ! git commit -m "$commit_message"; then
    echo "[C] Commit FAILED."
    exit 1
fi

commit_hash="$(git rev-parse --short HEAD)"

# 3. Postcondition (Q)
echo "[Q] Verifying manifest against committed HEAD..."
if verify_manifest_against_head; then
    evidence_id="${ticket_id}@${commit_hash}"
    echo "[Q] Postcondition Met: Invariant verified."
    echo "--- EVIDENCE ID: $evidence_id ---"
    exit 0
else
    echo "[Q] Postcondition FAILED: Manifest files not completely tracked in commit."
    exit 1
fi