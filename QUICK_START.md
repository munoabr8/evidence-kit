# Quick Start Guide

This guide will help you get started with evidence-kit and understand how to capture comprehensive evidence with rich context.

## Prerequisites

- Git repository (for git context)
- Bash shell
- Python 3 (for index generation)
- Optional: GitHub Actions (for CI/CD context)

## Basic Usage

### 1. Capture Evidence from a Workflow

```bash
# Set up your environment
export ROOT="$(pwd)"
export ART_DIR="$ROOT/artifacts"

# Run the capture workflow
make -f hunchly.mk capture
```

This will:
- Capture comprehensive context (system, git, environment, etc.)
- Execute the workflow (default: `tests`)
- Generate logs with secret redaction
- Create HTML versions for browser viewing
- Generate checksums for integrity verification

### 2. Generate and View the Index

```bash
# Generate the HTML index with context summary
make -f hunchly.mk artifacts-index

# Serve the artifacts locally
make -f hunchly.mk serve
# Then open http://localhost:8009/index.html
```

### 3. Try the Example

```bash
# Run the complete example
./examples/enhanced-capture-example.sh

# View the results
cd artifacts-example
python3 -m http.server 8009
# Open http://localhost:8009/index.html
```

## Understanding the Artifacts

After running a capture, you'll find these files in your artifacts directory:

### Core Workflow Artifacts
- `wf.log` - Redacted workflow output
- `wf.raw.log` - Original workflow output (before redaction)
- `wf.html` - HTML version for browser viewing
- `capture_plan.txt` - URLs for Hunchly capture

### Context Files
- `system_context.txt` - OS, CPU, memory, disk info
- `env_context.txt` - Safe environment variables
- `git_context.json` - Commit, branch, author details
- `execution_metadata.json` - Timing, duration, exit codes
- `dependencies_context.txt` - Tool and package versions

### CI/CD Context (when applicable)
- `github_actions_context.json` - GitHub Actions metadata
- `codespaces_context.json` - Codespaces environment info

### Integrity
- `checksums.sha256` - SHA-256 checksums of all artifacts
- `index.html` - Browsable index with context summary

## Customizing Context Capture

### Add Custom Context

You can add your own context files to the artifacts directory:

```bash
export ROOT="$(pwd)"
export ART_DIR="$ROOT/artifacts"

# Capture standard context
./bin/capture_context.sh

# Add your custom context
cat > "$ART_DIR/my_context.json" <<EOF
{
  "project": "my-project",
  "version": "1.0.0",
  "environment": "production",
  "custom_field": "custom_value"
}
EOF

# Generate the index
python3 bin/gen-index.py
```

### Run Different Workflows

```bash
# Run the 'build' workflow instead of 'tests'
export WF=build
make -f hunchly.mk capture

# Or specify it directly
./bin/run_and_capture.sh build
```

### Customize Port

```bash
# Use a different port for serving
export HTTP_PORT=8080
make -f hunchly.mk serve
```

## Integration with GitHub Actions

Use the reusable workflow in your repository:

```yaml
name: Evidence Capture

on: [push, pull_request]

jobs:
  capture-evidence:
    uses: your-org/evidence-kit/.github/workflows/reusable-action.yml@main
    with:
      workflow: tests
      port: 8009
```

**Note**: Replace `your-org/evidence-kit` with the actual path to your evidence-kit repository (e.g., if you forked it, use `your-username/evidence-kit`).

## Viewing Evidence in Hunchly

1. Start the local server:
   ```bash
   make -f hunchly.mk serve
   ```

2. Forward the port (if in Codespaces or remote environment)

3. Open Chrome with Hunchly extension active

4. Navigate to the URLs in `capture_plan.txt`:
   - `http://localhost:8009/wf.html` - Workflow log
   - `http://localhost:8009/index.html` - Full artifact index

5. Hunchly will automatically capture the evidence with context

## Advanced Usage

### Complete Workflow

```bash
# Run everything: capture, index, and serve
make -f hunchly.mk all
```

### Check Available Targets

```bash
make -f hunchly.mk help
```

### Live Terminal Session

```bash
# Start a live terminal for interactive capture
make -f hunchly.mk live

# Stop the live terminal
make -f hunchly.mk live-stop
```

## Troubleshooting

### Missing Dependencies

If you get errors about missing tools:

```bash
# Install ttyd (for live terminal)
sudo apt-get update && sudo apt-get install -y ttyd

# Install ansi2html (for HTML conversion)
pip install --user ansi2html

# Or run setup
make -f hunchly.mk setup
```

### Permission Issues

If artifacts are not readable:

```bash
# Fix permissions
chmod -R u+rw artifacts/
```

### Port Already in Use

```bash
# Check what's using the port
make -f hunchly.mk ports

# Kill processes on conflicting ports
make -f hunchly.mk kill-ports
```

## Best Practices

1. **Review redaction**: Always check that sensitive data is properly redacted in logs
2. **Verify checksums**: Use `checksums.sha256` to verify artifact integrity
3. **Add custom context**: Include project-specific metadata for better traceability
4. **Regular captures**: Run evidence capture on all important workflows (build, test, deploy)
5. **Archive evidence**: Store evidence bundles for compliance and audit purposes

## Next Steps

- Read [CONTEXT_INJECTION_STRATEGIES.md](CONTEXT_INJECTION_STRATEGIES.md) for comprehensive strategies
- Explore [examples/](examples/) for more advanced use cases
- Customize `bin/capture_context.sh` for your specific needs
- Integrate evidence capture into your CI/CD pipeline

## Getting Help

- Check the [README.md](README.md) for overview and features
- Review the [examples/](examples/) directory
- Examine the scripts in [bin/](bin/) for implementation details
