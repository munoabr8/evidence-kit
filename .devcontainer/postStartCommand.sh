#!/usr/bin/env bash
# .devcontainer/postStartCommand.sh
# Runs after devcontainer starts - with full observability

set -euo pipefail

LOGFILE="/tmp/devcontainer-startup.log"

echo "=== Devcontainer postStartCommand ===" | tee "$LOGFILE"
echo "Started: $(date -Iseconds)" | tee -a "$LOGFILE"
echo | tee -a "$LOGFILE"

# Run observability probe
if [ -x /workspaces/evidence-kit/bin/probes/devcontainer_startup_probe ]; then
    echo "Running startup probe..." | tee -a "$LOGFILE"
    if /workspaces/evidence-kit/bin/probes/devcontainer_startup_probe 2>&1 | tee -a "$LOGFILE"; then
        echo "✓ Probe passed" | tee -a "$LOGFILE"
    else
        echo "✗ Probe failed (continuing with setup)" | tee -a "$LOGFILE"
    fi
    echo | tee -a "$LOGFILE"
fi

# Run setup with proper error handling
echo "Running hunchly.mk setup..." | tee -a "$LOGFILE"
if make -f /workspaces/evidence-kit/hunchly.mk setup 2>&1 | tee -a "$LOGFILE"; then
    echo "✓ Setup completed successfully" | tee -a "$LOGFILE"
    exit 0
else
    EXIT_CODE=$?
    echo "✗ Setup failed with exit code: $EXIT_CODE" | tee -a "$LOGFILE"
    echo "Log saved to: $LOGFILE" | tee -a "$LOGFILE"
    exit $EXIT_CODE
fi
