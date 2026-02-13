## Devcontainer Diagnostics

### Quick Check
```bash
# Run the startup probe anytime:
/workspaces/evidence-kit/bin/probes/devcontainer_startup_probe

# Check startup logs:
cat /tmp/devcontainer-startup.log
```

### Files Created

1. **[bin/probes/devcontainer_startup_probe](../bin/probes/devcontainer_startup_probe)** - Comprehensive startup diagnostic
2. **[.devcontainer/postStartCommand.sh](../.devcontainer/postStartCommand.sh)** - Observable startup script with logging
3. **[.devcontainer/Dockerfile.alpine](../.devcontainer/Dockerfile.alpine)** - Fixed Dockerfile for Alpine Linux

### Root Cause Analysis

**Problem**: OS mismatch between Dockerfile spec (Ubuntu) and runtime (Alpine)

**Evidence**:
- Dockerfile uses `apt-get` (Debian/Ubuntu)
- Runtime environment is Alpine Linux v3.23 with `apk` package manager
- Tools (ttyd, asciinema) never installed because wrong package manager
- `|| true` in postStartCommand masked the failure

**Impact**:
- Setup silently fails
- Missing required tools
- "Recovery mode" when functionality broken

### Solutions Applied

1. **New Alpine Dockerfile**: [Dockerfile.alpine](../.devcontainer/Dockerfile.alpine) uses `apk` and pre-installs all tools
2. **Observable Startup**: [postStartCommand.sh](../.devcontainer/postStartCommand.sh) logs everything to `/tmp/devcontainer-startup.log`
3. **Cross-Platform Setup**: [hunchly.mk](../hunchly.mk) now detects and uses correct package manager
4. **Updated Config**: [devcontainer.json](../.devcontainer/devcontainer.json) points to Alpine Dockerfile and observable startup

### Next Steps

**To apply fixes**:
```bash
# 1. Rebuild container with new Dockerfile
# VS Code Command: "Dev Containers: Rebuild Container"

# 2. Or manually test the probe now:
/workspaces/evidence-kit/bin/probes/devcontainer_startup_probe

# 3. Test setup with new logic:
make -f hunchly.mk setup
```

### Monitoring Going Forward

The probe checks:
- ✓ OS and package manager detection
- ✓ User context and permissions
- ✓ Workspace mount and writability
- ✓ Git configuration
- ✓ Required and optional tools
- ✓ Python environment
- ✓ Network connectivity
- ✓ Artifacts directory
- ✓ Makefile validity
- ✓ Environment variables

All startup output is logged to `/tmp/devcontainer-startup.log` for post-mortem analysis.
