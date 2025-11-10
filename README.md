# evidence-kit

evidence-kit is a small, local-first toolkit for capturing, packaging, and previewing terminal-based workflow evidence. It makes it easy to record terminal sessions (asciinema), collect supporting artifacts (logs, files, checksums), and generate HTML previews that can be served for review or archiving.

Scope: the minimal project contract is in `SCOPE.md` (captures + generate wrappers + minimal make/CLI helpers).

Goals
- Capture reproducible terminal runs and supporting files as an evidence bundle.
- Provide local-first playback of terminal recordings with an HTML wrapper (no mandatory uploads).
- Keep tooling minimal and dependency-light (Make + small Python scripts + shell helpers).

Quick start
1. Regenerate previews (run from the repo root):
```bash
python3 bin/gen-index.py
```

2. Serve artifacts locally:
```bash
make -f hunchly.mk serve
# open http://localhost:8009
```

Recording terminal sessions
- Manual (one-off):
```bash
# Record a single make target run interactively
asciinema rec -c "make -f hunchly.mk <target>" artifacts/<target>.cast
python3 bin/gen-index.py
```

- Using the provided Make helper (recommended):
```bash
make -f hunchly.mk asciinema-record TARGET=<target>
```
This will record the specified target, write `artifacts/<target>.cast` (uses --overwrite), and regenerate HTML wrappers.

Playback and previews
- The generator `bin/gen-index.py` creates `artifacts/index.html` and per-artifact HTML wrappers (for `.cast` files it produces `*.cast.html` with an embedded asciinema player).
- The code prefers vendored copies of `asciinema-player.min.js`/`.css` in `artifacts/` and will fall back to a CDN when needed.

Artifacts index & capturing web pages
-----------------------------------
This project makes it easy to capture web pages (or any files) into `artifacts/` and have them appear automatically in a browsable, playback-ready index.

Quick contract:
- Input: files saved under `artifacts/` (HTML, `.cast`, images, JSON, etc.) or URLs captured by the capture helpers.
- Output: `artifacts/index.html` plus per-artifact HTML preview wrappers, and (for `.cast`) playable `*.cast.html` wrappers.
- Error modes: missing vendored player assets (fall back to CDN), or missing `.cast` files (must be recorded or generated).

How to capture web pages and make them visible
1. Use the built-in capture workflow (recommended):

```bash
# ensure artifacts dir exists and probe is healthy
mkdir -p artifacts
make -f hunchly.mk .env.probe

# run the capture helper which will populate artifacts/ (see bin/run_and_capture.sh)
make -f hunchly.mk capture
```

The `capture` target delegates to `bin/run_and_capture.sh` so you can customize what gets captured (URLs, screenshots, saved HTML). See `bin/capture_setup.sh` for setup hints.

2. Or capture manually:

```bash
# save or copy files into artifacts/ (for example using wget)
wget -P artifacts/ -k -E -p https://example.com/page.html

# regenerate previews
python3 bin/gen-index.py
```

3. Make player assets available (local-first playback):

```bash
# vendor a local copy of the asciinema player (recommended for offline stability)
./bin/vendor-player.sh 3.11.1 artifacts/asciinema-player.min.js artifacts/asciinema-player.min.css artifacts/vendor-player.json

# regenerate wrappers (will prefer local vendored files)
python3 bin/gen-index.py

# serve and inspect
make -f hunchly.mk serve
# open http://localhost:8009
```

Notes
- `bin/gen-index.py` will create small wrapper HTML files for each artifact and a single `artifacts/index.html` for browsing. For `.cast` files it builds a fully playable HTML wrapper and writes `artifacts/asciinema-glue.js` used by the wrappers.
- If you delete `artifacts/` you can re-run the vendoring and `gen-index.py` steps above to restore the playback assets and wrappers. Recorded `.cast` files are not recoverable unless re-recorded or generated synthetically.
- If you want automated, repeatable captures for many pages, customize `bin/run_and_capture.sh` (it is what `make capture` calls).

Standalone vs embedded (submodule) behavior
-------------------------------------------
When using evidence-kit stand-alone (the repository root is the evidence-kit repo), `artifacts/` is expected to live in the repository root and the default generator and Make targets will use that directory.

When evidence-kit is embedded as a Git submodule inside a larger repository, the tooling will prefer the superproject's working tree when available. That prevents duplicate `artifacts/` directories (one in the parent and one in the submodule) when using the provided Make capture flow.

How it decides:
- The probe uses `git rev-parse --show-superproject-working-tree` to detect a superproject. If present, the probe sets the root to the superproject and `ART_DIR` defaults to `$ROOT/artifacts` (the superproject's `artifacts/`).
- If no superproject is detected, `ART_DIR` falls back to `$ROOT/artifacts` where `$ROOT` is the repo toplevel.

Commands to inspect and control behavior:

```bash
# show what the probe resolves to (where artifacts will be created by make capture)
./bin/env_probe --print-root
./bin/env_probe --print-art-dir

# force captures to the submodule-local artifacts directory
ART_DIR="$(pwd)/artifacts" make -f hunchly.mk capture

# force captures to the superproject (centralized artifacts)
ROOT="/path/to/superproject" ART_DIR="/path/to/superproject/artifacts" make -f hunchly.mk capture
```

Recommendation
- For CI or centralized evidence collection, use the probe/Make flow (`make capture`) run from the submodule: it will automatically centralize artifacts in the superproject.
- For per-submodule isolation (when you do not want captured files merged into the parent repo), set `ART_DIR` explicitly when invoking capture or run `python3 bin/gen-index.py` in the submodule directory so artifacts stay local.



Security and trust model
- The generator and wrapper include a pragmatic fallback that will attempt to evaluate the vendored player bundle to recover a factory API when the UMD/IIFE doesn't register the `asciinema-player` custom element. That involves `eval()` of local vendor code. This is allowed for local-first, trusted engineering workflows but should be treated as risky when processing untrusted inputs.
- If you plan to share the generated artifacts widely or run in an untrusted environment, consider:
  - Removing the eval fallback and relying only on vendor files that register the custom element.
  - Pre-wrapping the vendored `asciinema-player` bundle at vendor-time to ensure it always calls `customElements.define` (we can add a vendoring helper for this).

Implementation notes
- `hunchly.mk` contains common targets: `capture`, `artifacts-index`, `serve`, and `asciinema-record`.
- `bin/gen-index.py` enumerates `artifacts/`, generates the index and per-artifact wrappers, and special-cases `.cast` files.
- `templates/` contains the HTML/JS templates used to render `.cast` wrappers and the programmatic glue.
- `bin/template.py` is a tiny template loader used to keep the generator small and free of heavy template dependencies.

Troubleshooting
- Blank player page: verify `artifacts/asciinema-player.min.js` and `.css` are present and served with `Content-type: text/javascript` and `text/css` respectively. See `artifacts/` and run `python3 -m http.server 8009` to test locally.
- CDN script blocked: some environments (or intermediary proxies) may return incorrect headers for CDN assets. For reliability vendor `asciinema-player.min.js` into `artifacts/` and let the generator prefer local assets.
- Recording failure: ensure `asciinema` is installed. On Debian/Ubuntu: `sudo apt install asciinema` or `pipx install asciinema` if you prefer isolated installs.

Next improvements (ideas)
- Centralize the glue into `artifacts/asciinema-glue.js` so wrappers are small and cache-friendly.
- Provide a vendoring helper that wraps/patches the player bundle to always register the custom element and avoid eval.
- Add a small smoke-test script (Make target) that records a synthetic session, regenerates wrappers, serves artifacts, and asserts HTTP headers/checksums.

Contributing
- Make changes via branches and open a pull request. Keep vendored assets pinned and update them in a separate change so reviewers can focus on behavioral changes.

Git LFS note
-------------
This repository may track large vendored artifacts under `artifacts/` (e.g. minified player bundles). If you plan to run playback locally or work with vendor binaries, install Git LFS on your machine and run:

```bash
git lfs install
git lfs pull
```

The repository includes a `.gitattributes` file that marks common artifact patterns as LFS-tracked. We do not migrate history by default; adding `.gitattributes` only affects future commits.

License
- (add license info as appropriate)
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
