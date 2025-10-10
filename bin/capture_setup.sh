#!/usr/bin/env bash
set -euo pipefail

# Ensure required tools exist
if ! command -v ttyd >/dev/null 2>&1; then
  echo "[setup] Installing ttyd..."
  sudo apt-get update -y && sudo apt-get install -y ttyd
else
  echo "[setup] ttyd already installed"
fi

if ! command -v ansi2html >/dev/null 2>&1; then
  echo "[setup] Installing ansi2html..."
  pip install --user ansi2html
else
  echo "[setup] ansi2html already installed"
fi

# Create artifacts directory
mkdir -p artifacts

# Optional low-privilege user
if ! id wfuser >/dev/null 2>&1; then
  echo "[setup] Creating low-privilege user wfuser..."
  sudo useradd -m -s /bin/bash wfuser
else
  echo "[setup] wfuser already exists"
fi

# Start a ttyd web terminal in background
PORT="${PORT:-8020}"
BASIC_AUTH="${BASIC_AUTH:-wf:pass}"

echo "[setup] Starting ttyd on port ${PORT} (Private Codespaces port)"
sudo -u wfuser ttyd -p "${PORT}" -c "${BASIC_AUTH}" bash >/tmp/ttyd.log 2>&1 &
echo $! > artifacts/ttyd.pid

echo "[setup] ttyd started (PID: $(cat artifacts/ttyd.pid))"
echo "[setup] Open forwarded port ${PORT} in Chrome for Hunchly capture"
