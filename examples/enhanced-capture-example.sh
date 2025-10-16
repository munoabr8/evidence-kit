#!/usr/bin/env bash
# Example: Enhanced evidence capture with custom context
# This example demonstrates how to use the context injection strategies

set -euo pipefail

# Setup
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ART_DIR="${ROOT}/artifacts-example"
export ROOT ART_DIR

mkdir -p "$ART_DIR"

echo "=== Enhanced Evidence Capture Example ==="
echo "Root: $ROOT"
echo "Artifacts: $ART_DIR"
echo ""

# Step 1: Capture comprehensive context
echo "[1/4] Capturing context..."
if [ -x "${ROOT}/bin/capture_context.sh" ]; then
  "${ROOT}/bin/capture_context.sh"
else
  echo "ERROR: capture_context.sh not found"
  exit 1
fi

# Step 2: Add custom application-specific context
echo "[2/4] Adding custom application context..."
cat > "$ART_DIR/application_context.json" <<EOF
{
  "application": "evidence-kit-example",
  "version": "1.0.0",
  "environment": "development",
  "custom_tags": ["example", "demo", "context-injection"],
  "configuration": {
    "feature_flags": {
      "enhanced_logging": true,
      "context_capture": true
    }
  }
}
EOF

# Step 3: Run a sample workflow
echo "[3/4] Running sample workflow..."
{
  echo "=== Sample Workflow Execution ==="
  echo "Start time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  
  echo "Step 1: System check"
  echo "  - OS: $(uname -s)"
  echo "  - User: ${USER}"
  echo "  - PWD: $(pwd)"
  echo ""
  
  echo "Step 2: Repository validation"
  if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "  ✓ Git repository detected"
    echo "  - Branch: $(git rev-parse --abbrev-ref HEAD)"
    echo "  - Commit: $(git rev-parse --short HEAD)"
  else
    echo "  ✗ Not a git repository"
  fi
  echo ""
  
  echo "Step 3: Simulated test execution"
  echo "  Running tests..."
  sleep 1
  echo "  ✓ All tests passed (simulated)"
  echo ""
  
  echo "End time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "=== Workflow Complete ==="
} | tee "$ART_DIR/example_workflow.log"

# Step 4: Generate enhanced index
echo "[4/4] Generating index..."
python3 "${ROOT}/bin/gen-index.py"

echo ""
echo "=== Example Complete ==="
echo ""
echo "Artifacts have been generated in: $ART_DIR"
echo ""
echo "Generated files:"
ls -lh "$ART_DIR"
echo ""
echo "To view the evidence bundle, run:"
echo "  cd $ART_DIR && python3 -m http.server 8009"
echo "  Then open: http://localhost:8009/index.html"
