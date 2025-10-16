# evidence-kit


## Running Make Targets

This repository uses `hunchly.mk` for its make targets. To run any target, use:

```bash
make -f hunchly.mk <target>
```

Replace `<target>` with the desired target (e.g., `capture`).

### Note for Embedded Usage

If you embed this repository as a submodule or within another project that has its own `Makefile`, do **not** add or rename a default `Makefile` here. Using a default `Makefile` may cause conflicts with the parent repository's build system.

For standalone use, you may create a `Makefile` that includes `hunchly.mk`, but this is not recommended for embedded scenarios.



Reusable Workflow Integration

The evidence-kit project provides a reusable GitHub Actions workflow that any other repository can call to run a workflow target and automatically generate Hunchly-compatible evidence.

Repository Roles
Repository	Role
evidence-kit	Defines the reusable workflow and core scripts (bin/run_and_capture.sh, bin/run-wf).
Your other project	Calls the reusable workflow to execute its own build/test/CI pipelines and capture evidence artifacts.