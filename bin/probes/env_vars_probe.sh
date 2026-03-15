#!/usr/bin/env bash
# env_vars_probe.sh
# Outputs all environment variables in sorted order.

set -Eeuo pipefail

# If a JSON output is requested, convert the environment to a JSON object.
if [[ "${1:-}" == "--json" ]]; then
  # Escape double quotes in values, then produce JSON.
  echo "{"
  first=1
  while IFS='=' read -r key value; do
    # Escape backslashes and double quotes
    value_escaped=$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')
    if [[ $first -eq 1 ]]; then
      printf '  "%s": "%s"' "$key" "$value_escaped"
      first=0
    else
      printf ',\n  "%s": "%s"' "$key" "$value_escaped"
    fi
  done < <(env)
  echo -e "\n}"
else
  # Default: list variables in KEY=VALUE format, sorted alphabetically.
  env | sort
fi
