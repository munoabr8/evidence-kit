#!/usr/bin/env bash
# scripts/verify-state.sh - Formal Verification Gate
# Usage: ./scripts/verify-state.sh --check-invariants
#
# Contract:
#   Verify that every non-comment, non-empty entry in evidence-manifest.txt
#   as committed in HEAD resolves to a file blob in HEAD.
#
# Formal invariant:
#   ∀ f ∈ evidence-manifest.txt@HEAD : f ∈ git_tree(HEAD) ∧ type(f) = blob

set -u
set -o pipefail

readonly REQUIRED_FLAG="--check-invariants"
readonly MANIFEST_FILE="evidence-manifest.txt"

usage() {
    echo "Usage: ./scripts/verify-state.sh ${REQUIRED_FLAG}"
}

fail() {
    echo "[FAIL] $1"
    exit 1
}

is_comment_or_blank() {
    local line="$1"

    [[ "$line" =~ ^[[:space:]]*# ]] && return 0
    [[ "$line" =~ ^[[:space:]]*$ ]] && return 0

    return 1
}

is_invalid_manifest_path() {
    local path="$1"

    case "$path" in
        /*|../*|*/../*|.git/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

require_expected_flag() {
    if [[ "${1:-}" != "$REQUIRED_FLAG" ]]; then
        usage
        exit 1
    fi
}

require_git_repo() {
    local repo_root

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        fail "Precondition Violation: Must be executed inside a Git repository."
    }

    cd "$repo_root" || {
        fail "Precondition Violation: Could not move to repository root: $repo_root"
    }
}

require_head_exists() {
    git rev-parse --verify HEAD >/dev/null 2>&1 || {
        fail "Precondition Violation: Repository has no commits; HEAD does not exist."
    }
}

require_manifest_exists_in_head() {
    git cat-file -e "HEAD:${MANIFEST_FILE}" 2>/dev/null || {
        fail "Invariant Violation: ${MANIFEST_FILE} is not tracked in HEAD."
    }
}

verify_manifest_entry() {
    local manifest_entry="$1"
    local object_type

    manifest_entry="${manifest_entry%$'\r'}"

    if is_comment_or_blank "$manifest_entry"; then
        return 0
    fi

    if is_invalid_manifest_path "$manifest_entry"; then
        echo "[FAIL] Invalid manifest path: $manifest_entry"
        return 1
    fi

    object_type="$(git cat-file -t "HEAD:${manifest_entry}" 2>/dev/null || true)"

    case "$object_type" in
        blob)
            echo "[OK] Tracked File: $manifest_entry"
            return 0
            ;;
        tree)
            echo "[FAIL] Invariant Violation: '$manifest_entry' resolves to a directory tree, but a file blob is expected."
            return 1
            ;;
        "")
            echo "[FAIL] Invariant Violation: '$manifest_entry' does not resolve to any object in HEAD."
            return 1
            ;;
        *)
            echo "[FAIL] Invariant Violation: '$manifest_entry' resolves to Git object type '$object_type', but a file blob is expected."
            return 1
            ;;
    esac
}

verify_manifest_entries_against_head() {
    local manifest_entry
    local all_met=true

    while IFS= read -r manifest_entry || [[ -n "$manifest_entry" ]]; do
        if ! verify_manifest_entry "$manifest_entry"; then
            all_met=false
        fi
    done < <(git show "HEAD:${MANIFEST_FILE}")

    [[ "$all_met" == true ]]
}

main() {
    require_expected_flag "${1:-}"

    echo "[Gatekeeper] Verifying committed HEAD against manifest..."

    require_git_repo
    require_head_exists
    require_manifest_exists_in_head

    echo "--------------------------------------------------"

    if verify_manifest_entries_against_head; then
        local current_hash
        current_hash="$(git rev-parse --short HEAD)"

        echo "--------------------------------------------------"
        echo "[PASS] Invariants Hold: Manifest integrity verified at HEAD (${current_hash})."
        exit 0
    else
        echo "--------------------------------------------------"
        echo "[FAIL] Verification Gate Closed: Resolve discrepancies before progressing."
        exit 1
    fi
}

main "$@"