# evidence-kit



Reusable Workflow Integration

The evidence-kit project provides a reusable GitHub Actions workflow that any other repository can call to run a workflow target and automatically generate Hunchly-compatible evidence.

Repository Roles
Repository	Role
evidence-kit	Defines the reusable workflow and core scripts (bin/run_and_capture.sh, bin/run-wf).
Your other project	Calls the reusable workflow to execute its own build/test/CI pipelines and capture evidence artifacts.