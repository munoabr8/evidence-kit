#!/usr/bin/env bash
set -euo pipefail

# Who calls the script:
#   - Developer, smoke test, or workflow script that wants a repository-wide
#     metadata validation report.
#
# Who does this script call:
#   - check_metadata.sh
#   - python3
#
# How the script executes:
#   - discovers artifacts/metadata/*.meta.txt
#   - runs check_metadata.sh once per metadata file
#   - filters out METADATA_OK records
#   - aggregates remaining records into a JSON violations array
#   - asks Python to add a summary object
#
# Contract:
# Pre:
#   - check_metadata.sh exists next to this script
#   - check_metadata.sh is executable
#   - python3 is available
#   - artifacts/metadata may or may not contain *.meta.txt files
#
# Run:
#   - execute check_metadata.sh once per discovered metadata file
#   - capture violation records
#   - ignore METADATA_OK records
#   - preserve checker failure output without aborting the aggregate run
#
# Post:
#   - emit valid JSON to stdout
#   - emitted JSON contains:
#       - violations
#       - summary
#   - remove temporary file
#   - exit 0 if aggregation/report generation succeeds

# CLI usage:
#   ./check_all_metadata.sh [mode]
#
# Arguments:
#   mode
#     Optional. Metadata validation mode passed to check_metadata.sh.
#     Default: execution
#
# Examples:
#   ./check_all_metadata.sh
#   ./check_all_metadata.sh execution
#   ./check_all_metadata.sh planning
#
# Output:
#   Writes JSON report to stdout.
#
# Exit behavior:
#   0 = report generated successfully
#   1 = precondition failure or invalid report generation

# -----------------------------------------------------------------------------
# 1. Defaults / configuration
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_METADATA="$SCRIPT_DIR/check_metadata.sh"

MODE="${1:-execution}"
METADATA_GLOB="artifacts/metadata/*.meta.txt"

TMP_FILE=""


# -----------------------------------------------------------------------------
# 2. Shared helpers
# -----------------------------------------------------------------------------

usage() {
  cat <<'EOF'
Usage:
  check_all_metadata.sh [mode]

Arguments:
  mode    Optional validation mode passed to check_metadata.sh.
          Default: execution

Examples:
  check_all_metadata.sh
  check_all_metadata.sh execution
  check_all_metadata.sh planning

Output:
  Writes JSON report to stdout.

Exit behavior:
  0 = report generated successfully
  1 = precondition failure or invalid report generation
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${TMP_FILE:-}" && -f "$TMP_FILE" ]]; then
    rm -f "$TMP_FILE"
  fi
}

trap cleanup EXIT


# -----------------------------------------------------------------------------
# 3. Parse inputs
# -----------------------------------------------------------------------------

parse_inputs() {
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
  esac

  MODE="${1:-execution}"

  if [[ "$#" -gt 1 ]]; then
    usage >&2
    die "Too many arguments"
  fi
}


# -----------------------------------------------------------------------------
# 4. Validate preconditions
# -----------------------------------------------------------------------------

validate_preconditions() {
  [[ -f "$CHECK_METADATA" ]] || die "Missing checker: $CHECK_METADATA"
  [[ -x "$CHECK_METADATA" ]] || die "Checker is not executable: $CHECK_METADATA"
  command -v python3 >/dev/null 2>&1 || die "python3 not found"
}


# -----------------------------------------------------------------------------
# 5. Prepare execution context
# -----------------------------------------------------------------------------

prepare_execution_context() {
  TMP_FILE="$(mktemp)"
}


# -----------------------------------------------------------------------------
# 6. Execute observed command
# -----------------------------------------------------------------------------

collect_violations() {
  {
    echo '{"violations":['

    first=1

    shopt -s nullglob
    for f in $METADATA_GLOB; do
      while IFS= read -r line; do
        [[ "$line" == *'"METADATA_OK"'* ]] && continue

        if [[ "$first" -eq 0 ]]; then
          echo ','
        fi

        printf '%s' "$line"
        first=0
        
      done < <("$CHECK_METADATA" --mode "$MODE" --metadata "$f" || true)
    done

    echo ']}'
  } > "$TMP_FILE"
}


# -----------------------------------------------------------------------------
# 7. Decide status and wrapper exit behavior
# -----------------------------------------------------------------------------

decide_exit_policy() {
  # Current policy:
  #   - This script reports violations.
  #   - Finding violations is not itself a wrapper failure.
  #   - Invalid JSON, missing tools, or failed report generation are failures.
  return 0
}


# -----------------------------------------------------------------------------
# 8. Emit final JSON report
# -----------------------------------------------------------------------------

emit_summary() {
  python3 - "$TMP_FILE" <<'PY'
import json
import sys
from collections import Counter, defaultdict

path = sys.argv[1]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

violations = data.get("violations", [])

by_type = Counter(v.get("type", "UNKNOWN") for v in violations)
by_file = defaultdict(list)

for v in violations:
    file = v.get("file", "UNKNOWN")
    by_file[file].append(v)

data["summary"] = {
    "total_violations": len(violations),
    "files_with_violations": len(by_file),
    "by_type": dict(by_type),
    "by_file": {
        file: {
            "count": len(items),
            "types": sorted(set(i.get("type", "UNKNOWN") for i in items)),
            "fields": sorted(set(i.get("field") for i in items if i.get("field"))),
        }
        for file, items in sorted(by_file.items())
    },
}

print(json.dumps(data, indent=2))
PY
}


# -----------------------------------------------------------------------------
# 9. Verify postconditions
# -----------------------------------------------------------------------------

verify_postconditions() {
  [[ -f "$TMP_FILE" ]] || die "Temporary report file missing before cleanup"

  python3 - "$TMP_FILE" >/dev/null <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

if "violations" not in data:
    raise SystemExit("missing violations key")

if not isinstance(data["violations"], list):
    raise SystemExit("violations is not a list")
PY
}


# -----------------------------------------------------------------------------
# 10. Final exit
# -----------------------------------------------------------------------------

main() {
  parse_inputs "$@"
  validate_preconditions
  prepare_execution_context
  collect_violations
  verify_postconditions
  emit_summary
  decide_exit_policy
}

main "$@"