# Evidence Kit Examples

This directory contains examples demonstrating various context injection strategies.

## Available Examples

### 1. Enhanced Capture Example

**File**: `enhanced-capture-example.sh`

Demonstrates a complete evidence capture workflow with comprehensive context injection including:
- System information
- Git repository context
- Environment details
- Custom application-specific metadata
- Workflow execution logs

**Usage**:
```bash
./examples/enhanced-capture-example.sh
```

**Output**: Creates an `artifacts-example/` directory with all captured evidence and an HTML index.

**View Results**:
```bash
cd artifacts-example
python3 -m http.server 8009
# Open http://localhost:8009/index.html in your browser
```

## Creating Your Own Examples

To create custom evidence capture workflows:

1. **Set up environment variables**:
   ```bash
   ROOT="$(cd "$(dirname "$0")/.." && pwd)"
   ART_DIR="${ROOT}/artifacts-custom"
   export ROOT ART_DIR
   mkdir -p "$ART_DIR"
   ```

2. **Capture standard context**:
   ```bash
   ./bin/capture_context.sh
   ```

3. **Add custom context** (optional):
   ```bash
   cat > "$ART_DIR/custom_context.json" <<EOF
   {
     "project": "my-project",
     "environment": "production",
     "tags": ["release", "v1.0"]
   }
   EOF
   ```

4. **Execute your workflow** and capture output:
   ```bash
   your-command 2>&1 | tee "$ART_DIR/workflow.log"
   ```

5. **Generate the index**:
   ```bash
   python3 bin/gen-index.py
   ```

## Context Files Generated

Each example typically generates these context files:

- `system_context.txt` - OS, CPU, memory, disk information
- `env_context.txt` - Safe environment variables
- `git_context.json` - Git repository metadata
- `execution_metadata.json` - Workflow execution timing and details
- `dependencies_context.txt` - Software versions and packages
- `github_actions_context.json` - CI/CD metadata (when applicable)
- `checksums.sha256` - Integrity verification checksums

## Tips

- **Customize context capture**: Edit `bin/capture_context.sh` to add your own checks
- **Filter sensitive data**: Always review captured context before sharing
- **Add domain-specific context**: Create additional context files specific to your use case
- **Integrate with CI/CD**: Use these patterns in your GitHub Actions workflows

## Reference

See `CONTEXT_INJECTION_STRATEGIES.md` in the repository root for a comprehensive guide to all available context injection strategies.
