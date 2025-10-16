# Context Injection Strategies

This document outlines strategies for injecting more contextual information into evidence captures to enhance traceability, reproducibility, and forensic analysis.

## Overview

The evidence-kit currently captures workflow execution logs and basic environment detection. To provide richer evidence, we can inject additional contextual information across multiple dimensions.

## 1. Environment Context

### 1.1 System Information
**Strategy**: Capture detailed system information at the start of evidence collection.

**Implementation approaches**:
- OS version and kernel details (`uname -a`, `/etc/os-release`)
- CPU architecture and specifications
- Memory and disk space available
- Network configuration (sanitized)
- Locale and timezone settings

**Benefits**:
- Helps reproduce issues in similar environments
- Identifies environment-specific failures
- Documents system constraints

**Example integration**:
```bash
# In run_and_capture.sh, add system snapshot
echo "=== System Context ===" >> "$ART_DIR/system_context.txt"
uname -a >> "$ART_DIR/system_context.txt"
cat /etc/os-release >> "$ART_DIR/system_context.txt"
free -h >> "$ART_DIR/system_context.txt"
df -h >> "$ART_DIR/system_context.txt"
```

### 1.2 Environment Variables
**Strategy**: Capture sanitized environment variables relevant to the workflow.

**Implementation approaches**:
- Whitelist approach: Only capture known-safe variables (PATH, HOME, USER, etc.)
- Blacklist approach: Capture all except secrets (tokens, passwords, keys)
- Pattern-based redaction (similar to existing token redaction)

**Benefits**:
- Documents configuration that affects workflow behavior
- Helps identify missing or incorrect environment setup
- Maintains audit trail of execution context

**Example integration**:
```bash
# Capture safe environment variables
env | grep -E '^(PATH|HOME|USER|SHELL|LANG|TZ)=' > "$ART_DIR/env_context.txt"
```

## 2. Git/Repository Context

### 2.1 Commit Information
**Strategy**: Capture comprehensive git metadata about the current state.

**Implementation approaches**:
- Current commit SHA (full and short)
- Branch name
- Commit message and author
- Commit timestamp
- Tags associated with current commit
- Dirty state indicator (uncommitted changes)

**Benefits**:
- Enables exact reproduction of workflow execution
- Links evidence to specific code version
- Tracks whether execution was on clean or modified code

**Example integration**:
```bash
# In run_and_capture.sh
cat > "$ART_DIR/git_context.json" <<EOF
{
  "commit_sha": "$(git rev-parse HEAD)",
  "commit_short": "$(git rev-parse --short HEAD)",
  "branch": "$(git rev-parse --abbrev-ref HEAD)",
  "author": "$(git log -1 --format='%an <%ae>')",
  "date": "$(git log -1 --format='%ci')",
  "message": "$(git log -1 --format='%s')",
  "is_dirty": $(git diff-index --quiet HEAD -- && echo false || echo true)
}
EOF
```

### 2.2 Repository Configuration
**Strategy**: Document repository-specific settings and metadata.

**Implementation approaches**:
- Remote URLs (sanitized)
- Submodule status
- Repository size and file count
- `.gitignore` patterns
- Git config (non-sensitive parts)

**Benefits**:
- Provides complete picture of repository structure
- Documents external dependencies (submodules)
- Helps diagnose configuration-related issues

## 3. Workflow Execution Context

### 3.1 Execution Metadata
**Strategy**: Capture detailed metadata about the workflow execution itself.

**Implementation approaches**:
- Start and end timestamps (UTC and local)
- Execution duration (total and per-step)
- Exit codes for each command
- Resource usage (CPU, memory, I/O)
- Parallel execution tracking (if applicable)

**Benefits**:
- Performance analysis and optimization
- Identifies long-running or resource-intensive operations
- Provides timing context for debugging

**Example integration**:
```bash
# Enhanced run_and_capture.sh
START_TIME=$(date +%s)
START_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ... execute workflow ...

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

cat > "$ART_DIR/execution_metadata.json" <<EOF
{
  "workflow": "$WF",
  "start_time": "$START_ISO",
  "duration_seconds": $DURATION,
  "exit_code": $?,
  "hostname": "$(hostname)"
}
EOF
```

### 3.2 Command Tracing
**Strategy**: Capture detailed trace of executed commands.

**Implementation approaches**:
- Enable bash tracing (`set -x`) with timestamps
- Capture command history
- Log function call stack for complex workflows
- Record command arguments and working directories

**Benefits**:
- Complete audit trail of operations
- Easier debugging of complex workflows
- Verifiable compliance with procedures

**Example integration**:
```bash
# Enable timestamped tracing
export PS4='+ [$(date +%Y-%m-%dT%H:%M:%S)] '
set -x
```

## 4. Dependency Context

### 4.1 Package Versions
**Strategy**: Document all software dependencies and their versions.

**Implementation approaches**:
- Python packages (`pip freeze`, `pip list`)
- Node.js packages (`npm list`, `package-lock.json`)
- System packages (`dpkg -l`, `rpm -qa`)
- Custom tools and binaries (`--version` output)

**Benefits**:
- Ensures reproducibility across different environments
- Identifies version conflicts
- Documents testing environment precisely

**Example integration**:
```bash
# Capture dependency context
{
  echo "=== Python Packages ==="
  pip list 2>/dev/null || echo "pip not available"
  echo ""
  echo "=== System Packages (sample) ==="
  dpkg -l | head -20 2>/dev/null || echo "dpkg not available"
} > "$ART_DIR/dependencies_context.txt"
```

### 4.2 External Service Dependencies
**Strategy**: Document external services and their availability.

**Implementation approaches**:
- API endpoint health checks
- Database connectivity tests
- Network service availability
- Version/status of external dependencies

**Benefits**:
- Identifies external factors affecting execution
- Documents service state at execution time
- Helps diagnose integration issues

## 5. CI/CD Platform Context

### 5.1 GitHub Actions Specific
**Strategy**: Capture GitHub Actions-specific context when running in CI.

**Implementation approaches**:
- Workflow name and run ID
- Actor (who triggered the run)
- Event type (push, pull_request, etc.)
- Run attempt number
- Job name and matrix parameters
- Runner OS and version

**Benefits**:
- Links evidence to specific CI/CD run
- Provides complete workflow provenance
- Enables drill-down from GitHub UI to detailed evidence

**Example integration**:
```bash
# In run_and_capture.sh, detect GitHub Actions
if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  cat > "$ART_DIR/github_actions_context.json" <<EOF
{
  "workflow": "${GITHUB_WORKFLOW:-}",
  "run_id": "${GITHUB_RUN_ID:-}",
  "run_number": "${GITHUB_RUN_NUMBER:-}",
  "actor": "${GITHUB_ACTOR:-}",
  "event_name": "${GITHUB_EVENT_NAME:-}",
  "ref": "${GITHUB_REF:-}",
  "repository": "${GITHUB_REPOSITORY:-}",
  "runner_os": "${RUNNER_OS:-}",
  "runner_name": "${RUNNER_NAME:-}"
}
EOF
fi
```

### 5.2 Other CI Platforms
**Strategy**: Support context capture for various CI platforms.

**Implementation approaches**:
- Jenkins: BUILD_NUMBER, JOB_NAME, etc.
- GitLab CI: CI_PIPELINE_ID, CI_COMMIT_SHA, etc.
- CircleCI: CIRCLE_BUILD_NUM, CIRCLE_PROJECT_REPONAME, etc.
- Platform detection and conditional capture

**Benefits**:
- Platform-agnostic evidence collection
- Consistent context across different CI systems
- Easier migration between platforms

## 6. Test Results Context

### 6.1 Test Execution Details
**Strategy**: Capture structured test results and coverage data.

**Implementation approaches**:
- Parse JUnit XML or similar formats
- Capture test coverage reports
- Screenshot or video of UI tests
- Performance test metrics
- Flaky test indicators

**Benefits**:
- Structured test result analysis
- Historical test performance tracking
- Visual evidence for UI tests

### 6.2 Failure Diagnostics
**Strategy**: Automatically capture diagnostic information on failures.

**Implementation approaches**:
- Stack traces with source context
- Core dumps or crash reports
- Log tails from relevant services
- State dumps (database, cache, etc.)
- Screenshots of error states

**Benefits**:
- Faster root cause analysis
- Reduced need for reproduction steps
- Complete failure context

## 7. Security and Compliance Context

### 7.1 Audit Trail
**Strategy**: Maintain tamper-evident audit trail.

**Implementation approaches**:
- Cryptographic hashes of all artifacts
- Digital signatures
- Checksums file
- Timestamp authority integration
- Chain of custody metadata

**Benefits**:
- Verifiable evidence integrity
- Compliance with regulatory requirements
- Non-repudiation

**Example integration**:
```bash
# Generate checksums for all artifacts
(cd "$ART_DIR" && sha256sum * > checksums.sha256)
```

### 7.2 Redaction Logging
**Strategy**: Document what was redacted and why.

**Implementation approaches**:
- Log of redacted patterns
- Count of redactions per type
- Redaction audit trail
- Compliance with data protection regulations

**Benefits**:
- Transparency in redaction process
- Compliance verification
- Helps identify over/under-redaction

## 8. User and Session Context

### 8.1 Interactive Session Context
**Strategy**: When running interactively (e.g., in Codespaces), capture session info.

**Implementation approaches**:
- User identity (sanitized)
- Terminal session ID
- SSH connection details (if applicable)
- Browser/client information (for web-based terminals)
- Session start time

**Benefits**:
- Links evidence to specific user session
- Helps track multi-user environments
- Provides accountability

### 8.2 Input Context
**Strategy**: Capture user inputs and interactions (with consent).

**Implementation approaches**:
- Command history
- Script arguments
- Interactive prompts and responses
- Configuration file contents (sanitized)

**Benefits**:
- Complete reproduction of interactive sessions
- Understanding of user intent
- Training and documentation purposes

## 9. Metadata Enrichment

### 9.1 Semantic Tags
**Strategy**: Add semantic meaning to evidence through tagging.

**Implementation approaches**:
- Workflow purpose tags (test, build, deploy, etc.)
- Severity/priority indicators
- Business context labels
- Custom metadata fields

**Benefits**:
- Easier evidence retrieval and filtering
- Better organization of artifacts
- Context for non-technical stakeholders

### 9.2 Cross-Reference Links
**Strategy**: Link evidence to related artifacts and systems.

**Implementation approaches**:
- Links to issue/ticket systems (Jira, GitHub Issues)
- Links to documentation
- Links to related evidence bundles
- Links to monitoring dashboards

**Benefits**:
- Holistic view of evidence context
- Easier navigation of complex investigations
- Integration with existing tools

## 10. Visualization and Presentation Context

### 10.1 Evidence Index Enhancement
**Strategy**: Enhance the HTML index with richer metadata.

**Implementation approaches**:
- Thumbnail previews for images
- Syntax highlighting for code
- Collapsible sections for large artifacts
- Search/filter functionality
- Timeline view of execution

**Benefits**:
- Better user experience when reviewing evidence
- Faster identification of relevant artifacts
- More professional presentation

### 10.2 Summary Reports
**Strategy**: Generate executive summaries of evidence.

**Implementation approaches**:
- Markdown summary with key findings
- Charts and graphs (execution time, resource usage)
- Test result summaries
- Risk indicators or alerts

**Benefits**:
- Quick overview without diving into details
- Easier communication with stakeholders
- Actionable insights

## Implementation Priorities

### High Priority (Core Context)
1. Git commit information (Section 2.1)
2. Execution metadata (Section 3.1)
3. GitHub Actions context (Section 5.1)
4. System information (Section 1.1)

### Medium Priority (Enhanced Context)
5. Environment variables (Section 1.2)
6. Dependency versions (Section 4.1)
7. Test results context (Section 6.1)
8. Audit trail (Section 7.1)

### Low Priority (Advanced Features)
9. External service health (Section 4.2)
10. Visualization enhancements (Section 10.1)
11. Cross-reference links (Section 9.2)
12. Summary reports (Section 10.2)

## Example: Comprehensive Context Bundle

Here's what a fully contextualized evidence bundle might contain:

```
artifacts/
├── checksums.sha256              # Artifact integrity
├── execution_metadata.json       # Timing, duration, exit codes
├── git_context.json              # Commit, branch, author
├── github_actions_context.json   # CI/CD platform details
├── system_context.txt            # OS, CPU, memory
├── env_context.txt               # Environment variables
├── dependencies_context.txt      # Package versions
├── wf.log                        # Main workflow log (redacted)
├── wf.html                       # HTML version for browser
├── wf.raw.log                    # Raw log (before redaction)
├── capture_plan.txt              # URLs for capture
└── index.html                    # Enhanced index with all context
```

## Conclusion

By implementing these context injection strategies, the evidence-kit will provide:
- **Reproducibility**: Complete information to recreate execution environment
- **Traceability**: Clear links between evidence and source code/commits
- **Debuggability**: Rich diagnostic information for troubleshooting
- **Compliance**: Audit trails and tamper-evident artifacts
- **Usability**: Well-organized, searchable, and presentable evidence

The strategies are designed to be incrementally adoptable, allowing projects to start with basic context and gradually add more sophisticated context capture as needed.
