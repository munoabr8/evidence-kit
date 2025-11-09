# ci/

This folder documents CI-related helpers and workflows. The repository's GitHub Actions live under `.github/workflows/` and `ci/` can contain helper scripts, example job fragments, or local scripts used to run CI checks.

Suggested contents:
- `scope-check-fragment.yml` — reusable workflow fragment (if desired).
- `local-run.sh` — helper script to run checks locally.