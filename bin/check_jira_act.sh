#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

export JIRA_BASE_URL JIRA_EMAIL JIRA_API_TOKEN

act workflow_dispatch -j check \
  -W .github/workflows/jira-context-check.yml \
  --container-architecture linux/amd64 \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest \
  -s JIRA_BASE_URL \
  -s JIRA_EMAIL \
  -s JIRA_API_TOKEN

