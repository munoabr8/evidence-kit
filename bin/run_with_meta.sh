#!/usr/bin/env bash
set -euo pipefail

# This script is run in the make file:
# asciinema.mk
# 122: ./bin/run_with_meta.sh --out "$(CAST_OUT)" -- asciinema rec -c "$(ASCIINEMA_CMD)" "$(CAST_OUT)"

# Contract:
# Pre:
#   - --out FILE is provided
#   - command after -- is provided
#   - output directory is creatable
# Run:
#   - execute command exactly once
#   - capture raw exit code
# Post:
#   - write metadata sidecar under artifacts/metadata/
#   - include command, cwd, timestamp, git info, artifact path, raw exit code, status
#   - exit according to configured exit policy

# -----------------------------------------------------------------------------
# 1. Defaults / configuration
# -----------------------------------------------------------------------------

SCRIPT_NAME="$(basename "$0")"

OUT=""
EXIT_POLICY="wrapper"
CMD=()

# -----------------------------------------------------------------------------
# 2. Shared helpers
# -----------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME --out FILE [--exit-policy wrapper|preserve] -- COMMAND [ARGS...]

Required:
  --out FILE              Artifact path expected to be produced by COMMAND
  -- COMMAND              Command to execute and record metadata for

Optional:
  --exit-policy POLICY    wrapper  = normalize command failure to exit 1
                          preserve = exit with wrapped command's raw exit code
                          default: wrapper
  -h, --help              Show this help message

Exit codes:
  0 = command succeeded and metadata was written
  1 = command failed under wrapper exit policy
  2 = usage error
  3 = missing dependency
  5 = internal script error

Examples:
  $SCRIPT_NAME --out artifacts/run.cast -- echo hello

  $SCRIPT_NAME --out artifacts/test.cast -- \\
    asciinema rec -c "make test" artifacts/test.cast

  $SCRIPT_NAME --out artifacts/failing.cast --exit-policy preserve -- \\
    bash -c 'exit 7'

Metadata:
  For --out artifacts/run.cast, metadata is written to:
  artifacts/metadata/run.cast.meta.txt
EOF
}

die_json() {
  local type="$1"
  local message="$2"
  local exit_code="${3:-1}"

  echo "{\"type\":\"$type\",\"script\":\"$SCRIPT_NAME\",\"message\":\"$message\"}" >&2
  exit "$exit_code"
}

json_event() {
  local type="$1"
  local message="$2"

  echo "{\"type\":\"$type\",\"script\":\"$SCRIPT_NAME\",\"message\":\"$message\"}" >&2
}

require_command() {
  local cmd="$1"

  command -v "$cmd" >/dev/null 2>&1 || {
    die_json "MISSING_DEPENDENCY" "Required command not found: $cmd" 3
  }
}

absolute_path_for_output() {
  local path="$1"
  local dir
  local file

  dir="$(dirname "$path")"
  file="$(basename "$path")"

  mkdir -p "$dir"

  (
    cd "$dir"
    printf '%s/%s\n' "$(pwd -P)" "$file"
  )
}

# -----------------------------------------------------------------------------
# 3. Parse inputs
# -----------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;

    --out)
      [[ $# -ge 2 ]] || die_json "USAGE_ERROR" "--out requires a file path" 2
      [[ "$2" != "--" ]] || die_json "USAGE_ERROR" "--out requires a file path, got --" 2
      OUT="$2"
      shift 2
      ;;

    --exit-policy)
      [[ $# -ge 2 ]] || die_json "USAGE_ERROR" "--exit-policy requires a value" 2
      EXIT_POLICY="$2"
      shift 2
      ;;

    --)
      shift
      CMD=("$@")
      break
      ;;

    *)
      die_json "USAGE_ERROR" "Unknown argument: $1" 2
      ;;
  esac
done

# -----------------------------------------------------------------------------
# 4. Validate preconditions
# -----------------------------------------------------------------------------

[[ -n "$OUT" ]] || die_json "USAGE_ERROR" "--out is required" 2
[[ ${#CMD[@]} -gt 0 ]] || die_json "USAGE_ERROR" "Command is required after --" 2

if [[ "$EXIT_POLICY" != "wrapper" && "$EXIT_POLICY" != "preserve" ]]; then
  die_json "USAGE_ERROR" "--exit-policy must be wrapper or preserve" 2
fi

require_command date
require_command dirname
require_command basename
require_command pwd

# -----------------------------------------------------------------------------
# 5. Prepare execution context
# -----------------------------------------------------------------------------

mkdir -p "$(dirname "$OUT")"

artifact="$(absolute_path_for_output "$OUT")"

ART_DIR="${ART_DIR:-artifacts}"
META_DIR="${META_DIR:-$ART_DIR/metadata}"

mkdir -p "$META_DIR"

meta="$META_DIR/$(basename "$OUT").meta.txt"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cwd="$(pwd -P)"
git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo no-git)"
git_commit="$(git rev-parse HEAD 2>/dev/null || echo no-git)"

# -----------------------------------------------------------------------------
# 6. Execute observed command
# -----------------------------------------------------------------------------

json_event "RUN_STARTED" "Executing command with metadata capture"

set +e
"${CMD[@]}"
raw_exit_code=$?
set -e

# -----------------------------------------------------------------------------
# 7. Decide status and wrapper exit behavior
# -----------------------------------------------------------------------------

if [[ "$raw_exit_code" -eq 0 ]]; then
  status="success"
else
  status="fail"
fi

case "$EXIT_POLICY" in
  wrapper)
    if [[ "$raw_exit_code" -eq 0 ]]; then
      final_exit_code=0
    else
      final_exit_code=1
    fi
    ;;

  preserve)
    final_exit_code="$raw_exit_code"
    ;;
esac

# -----------------------------------------------------------------------------
# 8. Write metadata
# -----------------------------------------------------------------------------

{
  echo "timestamp=$timestamp"
  echo "cwd=$cwd"

  printf 'command='
  printf '%q ' "${CMD[@]}"
  printf '\n'

  echo "artifact=$artifact"
  echo "git_branch=$git_branch"
  echo "git_commit=$git_commit"
  echo "exit_policy=$EXIT_POLICY"
  echo "raw_exit_code=$raw_exit_code"
  echo "final_exit_code=$final_exit_code"

  # Kept for compatibility with check_metadata.sh.
  echo "exit_code=$raw_exit_code"

  echo "status=$status"
} > "$meta" || die_json "INTERNAL_ERROR" "Failed to write metadata file: $meta" 5

# -----------------------------------------------------------------------------
# 9. Verify postconditions
# -----------------------------------------------------------------------------

if [[ ! -f "$meta" ]]; then
  die_json "INTERNAL_ERROR" "Metadata file was not created: $meta" 5
fi

json_event "METADATA_WRITTEN" "Metadata written to $meta"

# -----------------------------------------------------------------------------
# 10. Final exit
# -----------------------------------------------------------------------------

exit "$final_exit_code"