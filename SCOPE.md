Project scope (evidence-kit)
================================

This document records the intended, minimal contract for the evidence-kit repository. It is
meant to make scope decisions explicit and to limit unplanned feature growth.

Core responsibilities (in-scope):

- Provide a small, local-first toolkit to capture evidence for Hunchly workflows. This includes
  helpers and Make targets that invoke capture flows and collect resulting artifacts into a
  repository-local `artifacts/` directory (or the superproject's `artifacts/` when embedded as a
  submodule).
- Generate a browsable, cache-friendly artifacts index and per-artifact HTML preview wrappers
  (including playable wrappers for asciinema `.cast` files) via `bin/gen-index.py`.
- Provide minimal, documented CLI/Make helpers to record terminal sessions with `asciinema`
  (for example `make -f hunchly.mk asciinema-record ...`) and to regenerate the preview
  artifacts.

Allowed adjacent responsibilities (accepted but limited):

- Small smoke-tests and local-serving helpers that validate the generated artifacts and MIME
  headers (for example `bin/smoke_test.sh`). These are intended to assist with development and
  CI, not to add new long-lived operational services.
- A lightweight vendoring helper script `bin/vendor-player.sh` that can fetch the asciinema
  player bundle and write a manifest (e.g., `artifacts/vendor-player.json`). The canonical
  artifact is the manifest and the vendor script; committing large binaries is discouraged.

Out-of-scope (require explicit approval or extraction):

- Long-term hosting/serving infrastructure, background daemons, or production-grade HTTP
  servers bundled into this repository. A simple `python3 -m http.server` wrapper for
  development is acceptable; anything heavier should live elsewhere.
- Large binary vendor artifacts checked in without LFS or a documented lifecycle (who updates
  them and how). Prefer Git LFS or rely on the vendor script + manifest to fetch at build time.
- Cross-cutting tooling that has its own release cadence (e.g., a separate probe suite,
  complex monitoring, or a standalone asset packager). These should be extracted to another
  repository if they will be actively maintained.

PR requirements / reviewer checklist
- Any PR that adds features beyond the Core responsibilities MUST include:
  - A one-line justification for scope (why it belongs here rather than a separate repo).
  - A short maintenance note: who will own updates and how frequently vendor assets will be
    refreshed.
  - Tests (or a smoke check) demonstrating the new feature works and a README note if new
    developer or runtime dependencies are required.

Policy on vendored assets
- Prefer not to commit large third-party bundles directly into Git. Options:
  - Keep assets out of the repository and fetch them with `bin/vendor-player.sh`; commit
    `artifacts/vendor-player.json` (manifest + checksums) to pin versions.
  - If you must commit binaries, add them to Git LFS and document the LFS requirement in
    `README.md`.

If you want to change this contract, update `SCOPE.md` and reference the reason in the PR.
