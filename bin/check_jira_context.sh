#!/usr/bin/env bash
set -euo pipefail

#check_jira_context.sh

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Check required configuration without printing credentials.
: "${JIRA_BASE_URL:?Set JIRA_BASE_URL}"
: "${JIRA_EMAIL:?Set JIRA_EMAIL}"
: "${JIRA_API_TOKEN:?Set JIRA_API_TOKEN}"

# Establish the runtime prerequisites.
python3 -m venv .venv
.venv/bin/python -m pip install requests

# Confirm the dependency is importable.
.venv/bin/python -c 'import requests; print("Runtime check passed")'

# Exercise the actual behavior.
PYTHONPATH=bin .venv/bin/python \
  bin/probe_jira_context.py "${1:-KAN-20}"