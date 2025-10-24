# Contributing

Guidance for contributors:

- Read `SCOPE.md` before adding new features or vendor binaries.
- Run `pre-commit install` to enable local pre-commit checks (`.pre-commit-config.yaml` is provided).
- Use small, focused PRs. Update `artifacts/vendor-player.json` when vendoring files.
- Run tests locally: `python3 -m pytest -q`.

If you intend to add vendor binaries, follow the PR checklist in `.github/PULL_REQUEST_TEMPLATE.md`.
