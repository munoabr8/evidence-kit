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

Capture workflow execution with comprehensive context:

```bash
make -f hunchly.mk capture
```

### View Evidence Bundle

Generate an HTML index and serve the artifacts:

```bash
make -f hunchly.mk artifacts-index
make -f hunchly.mk serve
# Open http://localhost:8009/index.html
```

### Try the Complete Example

See all context injection features in action:

```bash
./examples/enhanced-capture-example.sh
```

For detailed instructions and advanced usage, see [QUICK_START.md](QUICK_START.md).

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

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - Step-by-step guide to get started quickly
- **[CONTEXT_INJECTION_STRATEGIES.md](CONTEXT_INJECTION_STRATEGIES.md)** - Comprehensive guide to context injection strategies
- **[examples/](examples/)** - Working examples demonstrating various features
- **[bin/](bin/)** - Core scripts with inline documentation

## Project Structure

```
evidence-kit/
├── bin/                      # Core scripts
│   ├── capture_context.sh    # Captures comprehensive context
│   ├── run_and_capture.sh    # Main evidence capture workflow
│   ├── run-wf                # Workflow executor
│   ├── gen-index.py          # HTML index generator
│   └── env_probe             # Environment detection utility
├── examples/                 # Usage examples
│   ├── enhanced-capture-example.sh
│   └── README.md
├── templates/                # GitHub Actions templates
│   └── reusable-action.yml
├── hunchly.mk               # Make targets
├── README.md                # This file
├── QUICK_START.md           # Quick start guide
└── CONTEXT_INJECTION_STRATEGIES.md  # Strategy documentation
```