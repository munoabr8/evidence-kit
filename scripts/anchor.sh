#!/usr/bin/env bash
# scripts/anchor.sh - Executes the Evidence Anchoring Contract
# Formalized: { P } anchor.sh { Q }

set -euo pipefail

readonly MANIFEST_FILE="evidence-manifest.txt"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    shift
fi

ticket_id="${1:-}"

fail() {
    echo "$1" >&2
    exit 1
}

if [[ -z "$ticket_id" ]]; then
    echo "Usage: ./scripts/anchor.sh [--dry-run] JIRA-TICKET-ID" >&2
    exit 1
fi

if [[ ! "$ticket_id" =~ ^[A-Z]+-[0-9]+$ ]]; then
    fail "[P] Precondition FAILED: Ticket ID format is invalid."
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" ||
    fail "[P] Precondition FAILED: Must be inside a Git repository."

cd "$repo_root" ||
    fail "[P] Precondition FAILED: Could not move to repository root."

[[ -f "$MANIFEST_FILE" ]] ||
    fail "[P] Precondition FAILED: $MANIFEST_FILE not found at repo root."

echo "[P] Checking manifest completeness..."
shopt -s nullglob
for f in artifacts/*.tex; do
    grep -qxF -- "$f" "$MANIFEST_FILE" ||
        fail "[P] Precondition FAILED: Untracked artifact detected -> $f"
done
shopt -u nullglob

mapfile -t M < <(
    awk '
        !/^[[:space:]]*#/ &&
        !/^[[:space:]]*$/ {
            sub(/\r$/, "")
            print
        }
    ' "$MANIFEST_FILE"
)
readonly M

for file in "${M[@]}"; do
    if [[ "$file" == /* || "$file" == ../* || "$file" == */../* || "$file" == .git/* ]]; then
        fail "[P] Precondition FAILED: Unsafe path detected -> $file"
    fi

    [[ -f "$file" ]] ||
        fail "[P] Precondition FAILED: Evidence file missing -> $file"

    [[ -s "$file" ]] ||
        fail "[P] Precondition FAILED: Empty file blob violation -> $file"
done

echo "[P] Verifying tracking authority environment..."
command -v jira >/dev/null 2>&1 ||
    fail "[P] Precondition FAILED: 'jira' CLI tool is not installed or in PATH."

command -v jq >/dev/null 2>&1 ||
    fail "[P] Precondition FAILED: 'jq' tool is not installed or in PATH."

echo "[P] Fetching remote state from tracking authority for $ticket_id..."
if ! RAW_RESPONSE="$(jira issue view "$ticket_id" --raw 2>&1)"; then
    echo "[P] Precondition FAILED: 'jira' CLI execution encountered an error." >&2
    echo "    Details: $RAW_RESPONSE" >&2
    exit 1
fi

anchor_allowed_status() {
    local status="$1"

    case "$status" in
        "STRUCTURED ANALYSIS" | \
        "FORMAL VERIFICATION" | \
        "ARTIFACT REVIEW" | \
        "DONE: READY-FOR-SEAL" | \
        "DONE: VERIFIED")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

CURRENT_STATUS="$(
    jq -r '.fields.status.name // empty' <<<"$RAW_RESPONSE" |
        xargs |
        tr '[:lower:]' '[:upper:]'
)"

[[ -n "$CURRENT_STATUS" ]] ||
    fail "[P] Precondition FAILED: Unable to resolve Jira status."

if ! anchor_allowed_status "$CURRENT_STATUS"; then
    echo "[P] Precondition FAILED: State asymmetry detected." >&2
    echo "    Ticket $ticket_id is currently '$CURRENT_STATUS'." >&2
    echo "    Contract requires an authorized workflow state." >&2
    exit 1
fi

verify_manifest_against_head() {
    local all_met=true
    local file

    git cat-file -e "HEAD:$MANIFEST_FILE" 2>/dev/null || {
        echo "[FAIL] Invariant Violation: $MANIFEST_FILE is not tracked in HEAD."
        all_met=false
    }

    for file in "${M[@]}"; do
        if ! git cat-file -e "HEAD:$file" 2>/dev/null; then
            echo "[FAIL] Invariant Violation: $file is not tracked in HEAD."
            all_met=false
        fi
    done

    [[ "$all_met" == true ]]
}

echo "[P] Precondition Met: Contract initiated and synchronized for $ticket_id."

echo "[P] Validating semantic contracts in manifest artifacts..."
for file in "${M[@]}"; do
    if [[ "$file" == *.tex ]]; then
        ./scripts/verify-contract.sh "$file" "$ticket_id" || {
            fail "[P] Precondition FAILED: Semantic verification failed for $file."
        }
    fi
done
echo "[P] Semantic validation passed."

if [[ "$DRY_RUN" == true ]]; then
    echo "[!] DRY RUN ENABLED: Validations passed. Skipping staging and commit."
    echo "--- EVIDENCE ID WOULD BE: ${ticket_id}@$(git rev-parse --short HEAD) ---"
    exit 0
fi

# Prevent unrelated staged changes from being included in the evidence commit.
if ! git diff --cached --quiet; then
    fail "[P] Precondition FAILED: Git index already contains staged changes."
fi

echo "[C] Staging manifest and evidence files..."

git add -- "$MANIFEST_FILE" ||
    fail "[C] Failed to stage $MANIFEST_FILE."

for file in "${M[@]}"; do
    git add -f -- "$file" ||
        fail "[C] Failed to stage verified file: $file"
done

if git diff --cached --quiet; then
    echo "[C] No new changes staged. Checking if current HEAD satisfies contract..."

    if verify_manifest_against_head; then
        commit_hash="$(git rev-parse --short HEAD)"
        echo "[Q] Postcondition Met: Pre-existing state valid."
        echo "--- EVIDENCE ID: ${ticket_id}@${commit_hash} ---"
        exit 0
    fi

    fail "[Q] Postcondition FAILED: No changes staged, and HEAD is missing manifest files."
fi

commit_message="Evidence snapshot for $ticket_id: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

git commit -m "$commit_message" ||
    fail "[C] Commit FAILED."

commit_hash="$(git rev-parse --short HEAD)"

echo "[Q] Verifying manifest against committed HEAD..."
if verify_manifest_against_head; then
    evidence_id="${ticket_id}@${commit_hash}"
    echo "[Q] Postcondition Met: Invariant verified."
    echo "--- EVIDENCE ID: $evidence_id ---"
    exit 0
fi

fail "[Q] Postcondition FAILED: Manifest files not completely tracked in commit."
