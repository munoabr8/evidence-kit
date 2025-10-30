#!/usr/bin/env bash
# Shared helpers for probes
set -euo pipefail

_die() { echo "env_probe: $*" >&2; exit "${2:-3}"; }

_abs() {
  if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1; then
    readlink -f -- "${1}"
  else
    (cd "${1}" 2>/dev/null && pwd -P) || return 1
  fi
}

decide_root() {
  if [ -n "${ROOT:-}" ]; then
    [ -d "$ROOT" ] || _die "ROOT override is not a directory: $ROOT"
    case "$ROOT" in /*) : ;; *) _die "ROOT override must be absolute: $ROOT";; esac
    : "${ART_DIR:="$ROOT/artifacts"}"
    return 0
  fi
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || _die "not inside a git work tree" 3
  if git rev-parse --is-bare-repository >/dev/null 2>&1; then
    _die "bare git repository unsupported" 3
  fi
  local super top
  super="$(git rev-parse --show-superproject-working-tree 2>/dev/null || true)"
  if [ -n "$super" ]; then top="$super"; else top="$(git rev-parse --show-toplevel 2>/dev/null)" || _die "cannot resolve repo toplevel" 3; fi
  top="$(_abs "$top")" || _die "cannot resolve absolute path for: $top"
  ROOT="$top"
  : "${ART_DIR:="$ROOT/artifacts"}"
  export ROOT ART_DIR
}

guard_root() {
  case "$ROOT" in /*) : ;; *) _die "ROOT is not absolute after decision: $ROOT";; esac
  [ -n "$ROOT" ] && [ -d "$ROOT" ] || _die "ROOT missing or not a dir: $ROOT"
  case "$ART_DIR" in /*) : ;; *) _die "ART_DIR must be absolute: $ART_DIR";; esac
}

_detect_git_flags() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    in_git=true
    git_root="$(git rev-parse --show-toplevel)"
    superproject_root="$(git rev-parse --show-superproject-working-tree 2>/dev/null || true)"
    is_submodule=false
    [ -n "$superproject_root" ] && is_submodule=true
  else
    in_git=false
    is_submodule=false
    git_root=""
    superproject_root=""
  fi
}
