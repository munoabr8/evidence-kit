# evidence-kit


## Overview

The evidence-kit provides tools for capturing comprehensive execution evidence with rich contextual information. It automatically gathers system details, git metadata, environment configuration, and more to create complete, reproducible evidence bundles.

## Features

- **Comprehensive Context Capture**: Automatically collects system, git, environment, and CI/CD context
- **Workflow Execution Logging**: Records complete command output with timestamps
- **Secret Redaction**: Automatically redacts tokens and sensitive information
- **HTML Evidence Bundles**: Generates browsable HTML artifacts for easy review
- **Integrity Verification**: Creates checksums for tamper-evident evidence
- **Hunchly Compatible**: Designed for seamless integration with Hunchly capture workflows

## Running Make Targets

This repository uses `hunchly.mk` for its make targets. To run any target, use:

```bash
make -f hunchly.mk <target>
```

Replace `<target>` with the desired target (e.g., `capture`).

### Note for Embedded Usage

If you embed this repository as a submodule or within another project that has its own `Makefile`, do **not** add or rename a default `Makefile` here. Using a default `Makefile` may cause conflicts with the parent repository's build system.

For standalone use, you may create a `Makefile` that includes `hunchly.mk`, but this is not recommended for embedded scenarios.



## Quick Start

### Basic Evidence Capture

```bash
# Set up environment
export ROOT="$(pwd)"
export ART_DIR="$ROOT/artifacts"

# Run a workflow and capture evidence
make -f hunchly.mk capture
```

### Enhanced Evidence Capture with Context

```bash
# Try the example to see all context injection features
./examples/enhanced-capture-example.sh

# View the generated evidence bundle
cd artifacts-example
python3 -m http.server 8009
# Open http://localhost:8009/index.html
```

## Context Injection Strategies

The evidence-kit captures rich contextual information to make evidence more useful:

- **System Context**: OS, CPU, memory, disk space
- **Git Context**: Commit SHA, branch, author, dirty state
- **Environment Context**: Safe environment variables
- **CI/CD Context**: GitHub Actions metadata, runner information
- **Execution Context**: Timestamps, duration, exit codes
- **Dependencies**: Package versions, tool versions
- **Integrity**: SHA-256 checksums of all artifacts

For detailed strategies and implementation guidance, see [CONTEXT_INJECTION_STRATEGIES.md](CONTEXT_INJECTION_STRATEGIES.md).

## Examples

See the [examples/](examples/) directory for demonstrations of various context injection strategies:

- `enhanced-capture-example.sh`: Complete example with full context capture

## Reusable Workflow Integration

The evidence-kit project provides a reusable GitHub Actions workflow that any other repository can call to run a workflow target and automatically generate Hunchly-compatible evidence.

Repository Roles
Repository	Role
evidence-kit	Defines the reusable workflow and core scripts (bin/run_and_capture.sh, bin/run-wf).
Your other project	Calls the reusable workflow to execute its own build/test/CI pipelines and capture evidence artifacts.