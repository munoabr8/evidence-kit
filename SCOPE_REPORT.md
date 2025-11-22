# SCOPE_REPORT — last 90 days (summary)

Generated: 2025-10-22

This document summarizes repository activity from the last 90 days and classifies recent additions as core, adjacent, or out-of-scope with recommendations for containment and follow-ups.

## High-level summary

- Commits reviewed: 13 (2025-10-09 through 2025-10-22)
- Notable recent activities:
  - Added a short project contract `SCOPE.md` and linked it from `README.md` (2025-10-22).
  - Vendored asciinema player assets and added centralized glue and helper scripts (2025-10-20).
  - Introduced an environment probe and several capture helper scripts (mid October).
  - Iterative Makefile and generator improvements (`bin/gen-index.py`, `asciinema.mk`, `hunchly.mk`).

## Commit snapshot (selected)

- 42074c0 (2025-10-22) docs: add SCOPE.md and link from README
  - Files: `README.md`, `SCOPE.md`

- 2bd8132 (2025-10-20) vendor: commit asciinema player and centralized glue; allow in .gitignore
  - Files added/changed: `.gitignore`, `artifacts/asciinema-glue.js`, `artifacts/asciinema-player.min.css`, `artifacts/asciinema-player.min.js`, `asciinema.mk`, `bin/fetch-asciinema-player.sh`, `bin/gen-index.py`, `hunchly.mk`
  - This commit introduced the vendored player assets (minified JS/CSS) and the vendor manifest pattern (`artifacts/vendor-player.json`). The minified CSS/JS are large single-line files (minified) and increase repository weight.

- Multiple commits (2025-10-09 .. 2025-10-16) added core capture tooling and the environment probe
  - Files: `bin/run_and_capture.sh`, `bin/run-wf`, `bin/capture_setup.sh`, `bin/env_probe`, `templates/*`, `artifacts/*` (small HTML/log artifacts), `bin/gen-index.py` evolution.

## Files and artifacts of interest

- Core (clear fit with repository responsibilities):
  - `bin/run_and_capture.sh`, `bin/run-wf`, `bin/capture_setup.sh` — capture helpers used by Make targets and capture flow.
  - `bin/gen-index.py`, `templates/` — index and wrapper generator; central to producing playback wrappers.
  - `asciinema.mk`, `hunchly.mk`, `Makefile` tweaks — Make targets that glue capture/playback flows.
  - Small artifacts used by capture/testing: `artifacts/capture_plan.txt`, `artifacts/wf.html`, small logs.

- Adjacent (useful but candidate for a strict manifest/policy):
  - `artifacts/asciinema-player.min.js` and `artifacts/asciinema-player.min.css` — vendored player bundles. These are necessary for a local-first playback experience, but they are large and therefore appropriately controlled by a vendor manifest and potentially Git LFS.
  - `bin/fetch-asciinema-player.sh`, `bin/vendor-player.sh`, `artifacts/vendor-player.json` — vendor tooling and manifest. These are helpful and low-risk when coupled with manifest/checksum enforcement.
  - `bin/env_probe` (and probe helper scripts) — provides environment detection used by Make targets. Useful, but the refactor attempts introduced extra files; consider extracting to a small separate module if you want to keep this repo minimal.

- Out-of-scope / risky (require explicit approval or relocation):
  - Committing large binary or minified vendor assets into history without a policy (e.g., many big files, pack expansion). If you expect many such assets, prefer Git LFS or an external artifact store.
  - Adding heavy CI or long-running services in this repo. Keep the repo focused on minimal capture/playback helpers; CI can call external build hosts or separate infra repos.

## Quantitative notes

- The vendor commit added minified player assets (JS/CSS) and produced a vendor manifest `artifacts/vendor-player.json` with SHA256 checksums.
- Many of the helper scripts and incremental generator changes are small text files and are low-cost to maintain.

## Recommendations

1. Keep the short project contract (`SCOPE.md`) — it helps reviewers and contributors immediately understand what belongs here.

2. Adopt and enforce the vendor manifest policy (already partially present as `artifacts/vendor-player.json`):
   - Continue storing the manifest in `artifacts/` and require checksum verification in CI (we added `bin/scope_check.py` and a GitHub Action to run it).
   - If you expect to keep many or larger vendor assets, adopt Git LFS and add a `.gitattributes` file for the relevant patterns (e.g., `artifacts/*.js`, `artifacts/*.css`, `artifacts/*.tar.gz`). I can add `.gitattributes` and migration steps on request.

3. Contain the probe/refactor work:
   - If `bin/env_probe` is intended to be used across projects, consider extracting it to a small separate repository (or `munoabr8/env-probe`) and keep a thin shim in this repo that calls it. This reduces churn here and keeps the evidence-kit focused.

4. Use CI to enforce scope boundaries:
   - We added a `scope-check` Make target and a GitHub Action that runs it on PRs; ensure it remains enabled and consider failing PRs that add files over a size threshold without manifest entries.

5. Document follow-ups as issues:
   - Decide and record a vendoring policy (keep in-repo, LFS, or external host).
   - Decide whether to extract `bin/env_probe` (and, if yes, create a migration plan).

## Suggested next steps (actionable)

- If you want me to proceed, I can:
  - Add `.gitattributes` and optionally convert the current vendor files to Git LFS (requires force-push/migration instructions).
  - Create issues/PR templates that require a scope justification when adding vendor binaries.
  - Extract `bin/env_probe` into a separate repository and leave a shim here.

---

Generated from the git history (last 90 days) and file diffs. If you want a more detailed machine-readable audit (per-file sizes, total repo growth, or a CSV of changed files), I can generate that next.
# Scope report (last 90 days)

Generated: 2025-10-22T21:31:41Z

## Summary
- Commits (last 90 days):
    15	munoabr8
- Lines added: 3582
- Lines removed: 315

## Files added (last 90 days)


## Notable large/new files
- artifacts/asciinema-player.min.js (vendor runtime)
- artifacts/asciinema-player.min.css
- artifacts/asciinema-glue.js

## Observations
- The project has expanded from an artifacts-index generator to include:
  - vendoring of a third-party runtime (asciinema-player)
  - environment probing (environment:
  codespaces:        true
  docker:            true
  github_actions:    false)
  - capture orchestration scripts (, [wf] starting workflow 'tests' at 2025-10-22T21:31:41Z
[wf] running tests

no tests ran in 0.01s
[wf] finished workflow 'tests' at 2025-10-22T21:31:42Z)
  - Makefile targets and smoke-test/serve helpers
- Total code churn (~3.5k lines added) indicates substantive feature addition rather than small tweaks.

## Suggested next actions
1. Add a short  describing the intended contract for evidence-kit (core responsibilities): generator + wrappers + minimal capture helper.
2. Move large vendor files to Git LFS or omit them from source and keep the vendor script as the canonical source of truth.
3. Add a single-line test or CI smoke-step that validates  generates and, if vendored, that  exists.
4. If desired, split the repo: move vendoring and probe helpers to a separate repository (or subfolder with its own lifecycle).

