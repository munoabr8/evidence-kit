#!/usr/bin/env bash
set -euo pipefail

OUT=""
CMD=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      OUT="${2:-}"
      shift 2
      ;;
    --)
      shift
      CMD=("$@")
      break
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 --out <artifact-path> -- <command> [args...]" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$OUT" ]]; then
  echo "Missing required --out argument" >&2
  exit 2
fi

if [[ ${#CMD[@]} -eq 0 ]]; then
  echo "Missing command to execute" >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT")"

base="${OUT%.*}"
meta="${base}.meta.txt"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cwd="$(pwd -P)"
artifact="$(realpath "$OUT" 2>/dev/null || echo "$OUT")"
git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo no-git)"
git_commit="$(git rev-parse HEAD 2>/dev/null || echo no-git)"

set +e
"${CMD[@]}"
exit_code=$?
set -e

{
  echo "timestamp=$timestamp"
  echo "cwd=$cwd"
  printf 'command='
  printf '%q ' "${CMD[@]}"
  printf '\n'
  echo "artifact=$artifact"
  echo "git_branch=$git_branch"
  echo "git_commit=$git_commit"
  echo "exit_code=$exit_code"
  if [[ "$exit_code" -eq 0 ]]; then
    echo "status=success"
  else
    echo "status=fail"
  fi
} > "$meta"

exit "$exit_code"