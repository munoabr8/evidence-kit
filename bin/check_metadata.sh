#!/usr/bin/env bash
set -euo pipefail

# This script is run in:

#bin/check_all_metadata_json.sh
# at line 25:    done < <(bin/check_metadata.sh --mode "$MODE" "$f" || true)

SCRIPT_NAME="$(basename "$0")"

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME --metadata FILE [--mode execution|legacy]

Required:
  --metadata FILE    Metadata file to validate

Optional:
  --mode MODE        Validation mode: execution or legacy
  -h, --help         Show this help message

Examples:
  $SCRIPT_NAME --metadata artifacts/run.meta
  $SCRIPT_NAME --mode execution --metadata artifacts/run.meta
  $SCRIPT_NAME --mode legacy --metadata artifacts/run.meta
EOF
}

die_json() {
  local type="$1"
  local message="$2"
  local exit_code="${3:-1}"
  echo "{\"type\":\"$type\",\"script\":\"$SCRIPT_NAME\",\"message\":\"$message\"}" >&2
  exit "$exit_code"
}




MODE="execution"
META=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --mode)
      [[ $# -ge 2 ]] || die_json "USAGE_ERROR" "--mode requires a value" 2
      MODE="$2"
      shift 2
      ;;
    --metadata)
      [[ $# -ge 2 ]] || die_json "USAGE_ERROR" "--metadata requires a file path" 2
      META="$2"
      shift 2
      ;;
    *)
      die_json "USAGE_ERROR" "Unknown argument: $1" 2
      ;;
  esac
done

[[ -n "$META" ]] || die_json "USAGE_ERROR" "--metadata is required" 2

if [[ "$MODE" != "execution" && "$MODE" != "legacy" ]]; then
  die_json "USAGE_ERROR" "--mode must be execution or legacy" 2
fi

if [[ ! -f "$META" ]]; then
  echo "{\"type\":\"METADATA_FILE_MISSING\",\"file\":\"$META\"}"
  exit 1
fi

fail=0

emit() {
  local type="$1"
  local extra="$2"
  echo "{\"type\":\"$type\",\"file\":\"$META\"$extra}"
}

require_field() {
  local field="$1"
  if ! grep -q "^${field}=" "$META"; then
    emit "METADATA_MISSING_FIELD" ",\"field\":\"$field\",\"mode\":\"$MODE\""
    fail=1
  fi
}

# --- legacy ---
require_field "timestamp"
require_field "cwd"
require_field "command"
require_field "git_branch"
require_field "git_commit"

# --- strict ---
if [[ "$MODE" == "execution" ]]; then
  require_field "artifact"
  require_field "exit_code"
  require_field "status"
fi

artifact="$(grep '^artifact=' "$META" | sed 's/^artifact=//' || true)"
exit_code="$(grep '^exit_code=' "$META" | sed 's/^exit_code=//' || true)"
status="$(grep '^status=' "$META" | sed 's/^status=//' || true)"

if [[ "$MODE" == "execution" ]]; then
  if [[ -n "$artifact" && ! -f "$artifact" ]]; then
    emit "METADATA_ARTIFACT_NOT_FOUND" ",\"artifact\":\"$artifact\""
    fail=1
  fi

  if [[ -n "$exit_code" && ! "$exit_code" =~ ^[0-9]+$ ]]; then
    emit "METADATA_BAD_EXIT_CODE" ",\"exit_code\":\"$exit_code\""
    fail=1
  fi

  if [[ -n "$status" && "$status" != "success" && "$status" != "fail" ]]; then
    emit "METADATA_BAD_STATUS" ",\"status\":\"$status\""
    fail=1
  fi
fi

if [[ "$fail" -eq 0 ]]; then
  echo "{\"type\":\"METADATA_OK\",\"file\":\"$META\",\"mode\":\"$MODE\"}"
fi

exit "$fail"




