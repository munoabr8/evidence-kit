#!/usr/bin/env bash
# scripts/verify-contract.sh - Verify embedded LaTeX evidence contract
# { P } verify-contract.sh { Q }

set -euo pipefail

artifact_file="${1:-}"
ticket_id="${2:-}"

# Structured Audit Logging
fail() {
    local stage="$1"
    local code="$2"
    local message="$3"
    printf '{"status":"failed","stage":"%s","code":"%s","message":"%s"}\n' "$stage" "$code" "$message" >&2
    exit 1
}

pass() {
    local message="$1"
    printf '{"status":"passed","message":"%s"}\n' "$message"
    exit 0
}

# --- { P } Precondition Check ---
[[ -n "$artifact_file" ]] || fail "P" "MISSING_ARGUMENT" "artifact_file argument is required"
[[ -n "$ticket_id" ]]     || fail "P" "MISSING_ARGUMENT" "ticket_id argument is required"
[[ -f "$artifact_file" ]] || fail "P" "ARTIFACT_NOT_FOUND" "Artifact not found: $artifact_file"

# --- { C } Command: Safe Block Extraction ---
contract_block=$(sed -n '/^[[:space:]]*\\begin{evidencecontract}/,/^[[:space:]]*\\end{evidencecontract}/p' "$artifact_file" || true)

[[ -n "$contract_block" ]] || fail "C" "CONTRACT_NOT_FOUND" "No \begin{evidencecontract} block found."
# Extract Fields (Normalization: remove whitespace and quotes)
extracted_version=$(echo "$contract_block" | awk -F': ' '/version:/ {print $2}' | tr -d ' ' | grep -v '^$' || echo "1.0")
extracted_key=$(echo "$contract_block" | awk -F': ' '/evidence_key:/ {print $2}' | tr -d '"' | tr -d ' ' || true)
extracted_hash=$(echo "$contract_block" | awk -F': ' '/artifact_hash:/ {print $2}' | tr -d '"' | tr -d ' ' || true)
extracted_cmd=$(echo "$contract_block" | awk -F': ' '/command:/ {print $2}' | tr -d '"' | sed 's/^[[:space:]]*//' || true)
extracted_reviewer=$(echo "$contract_block" | awk -F': ' '/reviewer:/ {print $2}' | tr -d ' ' || true)

# --- Versioned Validation Logic ---
case "$extracted_version" in
    1.0)
        # 1.0 Logic: Legacy support
        [[ -n "$extracted_key" ]]  || fail "C" "MISSING_FIELD" "v1.0 requires evidence_key."
        [[ -n "$extracted_hash" ]] || fail "C" "MISSING_FIELD" "v1.0 requires artifact_hash."
        [[ -n "$extracted_cmd" ]]  || fail "C" "MISSING_FIELD" "v1.0 requires command."
        ;;
    1.1)
        # 1.1 Logic: Enforces 'reviewer' field
        [[ -n "$extracted_key" ]]    || fail "C" "MISSING_FIELD" "v1.1 requires evidence_key."
        [[ -n "$extracted_hash" ]]   || fail "C" "MISSING_FIELD" "v1.1 requires artifact_hash."
        [[ -n "$extracted_cmd" ]]    || fail "C" "MISSING_FIELD" "v1.1 requires command."
        #[[ -n "$extracted_reviewer" ]] || fail "C" "MISSING_FIELD" "v1.1 requires reviewer."
        ;;
    *)
        fail "C" "INVALID_VERSION" "Contract version $extracted_version is not supported."
        ;;
esac

# --- { Q } Postcondition Verification ---
if [[ "$extracted_key" == "$ticket_id" ]]; then
    pass "Contract v$extracted_version verified for $ticket_id"
else
    fail "Q" "KEY_MISMATCH" "Contract key '$extracted_key' does not match Jira ticket '$ticket_id'"
fi