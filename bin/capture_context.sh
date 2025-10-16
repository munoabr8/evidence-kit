#!/usr/bin/env bash
# ./bin/capture_context.sh
# Capture comprehensive context information for evidence bundle
set -euo pipefail

: "${ART_DIR:?ART_DIR must be set}"

echo "[context] Capturing comprehensive context to $ART_DIR"

# 1. System Context
echo "[context] Gathering system information..."
{
  echo "=== System Information ==="
  echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  echo "--- OS Details ---"
  uname -a 2>/dev/null || echo "uname not available"
  echo ""
  if [ -f /etc/os-release ]; then
    echo "--- OS Release ---"
    cat /etc/os-release
    echo ""
  fi
  echo "--- CPU Info ---"
  lscpu 2>/dev/null | grep -E "^(Architecture|CPU\(s\)|Model name|Thread)" || echo "lscpu not available"
  echo ""
  echo "--- Memory ---"
  free -h 2>/dev/null || echo "free not available"
  echo ""
  echo "--- Disk Space ---"
  df -h . 2>/dev/null || echo "df not available"
  echo ""
  echo "--- Locale ---"
  locale 2>/dev/null | grep -E "^(LANG|LC_ALL)=" || echo "locale not available"
} > "$ART_DIR/system_context.txt"

# 2. Environment Context (sanitized)
echo "[context] Capturing safe environment variables..."
{
  echo "=== Environment Variables (Safe Subset) ==="
  env | grep -E '^(PATH|HOME|USER|SHELL|LANG|TZ|PWD|HOSTNAME)=' | sort
} > "$ART_DIR/env_context.txt"

# 3. Git Context
echo "[context] Capturing git repository context..."
if git rev-parse --git-dir > /dev/null 2>&1; then
  {
    cat <<EOF
{
  "commit_sha": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "commit_short": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')",
  "branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
  "author": "$(git log -1 --format='%an <%ae>' 2>/dev/null || echo 'unknown')",
  "author_date": "$(git log -1 --format='%ci' 2>/dev/null || echo 'unknown')",
  "commit_message": "$(git log -1 --format='%s' 2>/dev/null | sed 's/"/\\"/g' || echo 'unknown')",
  "is_dirty": $(git diff-index --quiet HEAD -- 2>/dev/null && echo false || echo true),
  "remotes": $(git remote -v 2>/dev/null | sed -E 's|(https?://[^@]+@)|\1[REDACTED]@|g' | jq -R -s -c 'split("\n") | map(select(length > 0))' || echo '[]')
}
EOF
  } > "$ART_DIR/git_context.json"
else
  echo '{"error": "not a git repository"}' > "$ART_DIR/git_context.json"
fi

# 4. GitHub Actions Context (if applicable)
if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  echo "[context] Capturing GitHub Actions context..."
  {
    cat <<EOF
{
  "workflow": "${GITHUB_WORKFLOW:-}",
  "run_id": "${GITHUB_RUN_ID:-}",
  "run_number": "${GITHUB_RUN_NUMBER:-}",
  "run_attempt": "${GITHUB_RUN_ATTEMPT:-}",
  "actor": "${GITHUB_ACTOR:-}",
  "event_name": "${GITHUB_EVENT_NAME:-}",
  "ref": "${GITHUB_REF:-}",
  "ref_name": "${GITHUB_REF_NAME:-}",
  "sha": "${GITHUB_SHA:-}",
  "repository": "${GITHUB_REPOSITORY:-}",
  "runner_os": "${RUNNER_OS:-}",
  "runner_arch": "${RUNNER_ARCH:-}",
  "runner_name": "${RUNNER_NAME:-}",
  "job": "${GITHUB_JOB:-}",
  "workspace": "${GITHUB_WORKSPACE:-}"
}
EOF
  } > "$ART_DIR/github_actions_context.json"
fi

# 5. Codespaces Context (if applicable)
if [ "${CODESPACES:-}" = "true" ] || [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
  echo "[context] Capturing GitHub Codespaces context..."
  {
    cat <<EOF
{
  "codespace_name": "${CODESPACE_NAME:-}",
  "port_forwarding_domain": "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}",
  "vscode_server_domain": "${GITHUB_CODESPACES_VSCODE_SERVER_DOMAIN:-}"
}
EOF
  } > "$ART_DIR/codespaces_context.json"
fi

# 6. Dependency Context
echo "[context] Capturing dependency information..."
{
  echo "=== Dependency Versions ==="
  echo ""
  echo "--- Python ---"
  if command -v python3 >/dev/null 2>&1; then
    python3 --version 2>&1
    echo ""
    echo "Python packages (sample):"
    pip list 2>/dev/null | head -20 || echo "pip not available"
  else
    echo "Python not available"
  fi
  echo ""
  echo "--- Node.js ---"
  if command -v node >/dev/null 2>&1; then
    node --version 2>&1
    echo ""
    if command -v npm >/dev/null 2>&1; then
      npm --version 2>&1
    fi
  else
    echo "Node.js not available"
  fi
  echo ""
  echo "--- Git ---"
  git --version 2>&1 || echo "Git not available"
  echo ""
  echo "--- Bash ---"
  bash --version 2>&1 | head -1 || echo "Bash version not available"
  echo ""
  echo "--- Make ---"
  make --version 2>&1 | head -1 || echo "Make not available"
} > "$ART_DIR/dependencies_context.txt"

# 7. Execution Metadata
echo "[context] Creating execution metadata template..."
{
  cat <<EOF
{
  "capture_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname 2>/dev/null || echo 'unknown')",
  "user": "${USER:-unknown}",
  "working_directory": "$(pwd)",
  "artifact_directory": "$ART_DIR"
}
EOF
} > "$ART_DIR/execution_metadata.json"

echo "[context] Context capture complete. Generated files:"
ls -lh "$ART_DIR"/*context*.* "$ART_DIR"/*metadata*.* 2>/dev/null || true
