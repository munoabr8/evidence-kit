# vendor/

This directory documents how vendor artifacts are managed. The project currently keeps vendored player files in `artifacts/` alongside an `artifacts/vendor-player.json` manifest that records versions and checksums.

Guidance:
- Prefer using `bin/vendor-player.sh` and commit the manifest. If you decide to commit binaries, follow the `SCOPE.md` contract and update `artifacts/vendor-player.json`.
- Consider Git LFS for large binaries; see `README.md` and `.gitattributes` for details.
