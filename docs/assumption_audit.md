assumption_audit.md

# Assumption Audit

## A0. Evidence scripts need explicit contracts

Status: active assumption

Assumption:
Scripts that mutate, validate, or generate evidence should expose a lightweight Hoare-style contract.

Reason:
A Pre → Run → Post structure makes hidden assumptions easier to detect, test, and refactor.

Expected benefit:
- clearer required inputs
- clearer outputs
- easier smoke-test design
- faster detection of layout drift
- fewer implicit script contracts

Risk:
This could become documentation overhead if applied to every small helper script.

Scope limit:
Apply only to scripts or Make targets that create, delete, validate, or transform evidence.

Test:
When a script breaks, can the failure be classified as a violated precondition, run behavior, or postcondition?

Falsification condition:
If contract comments do not reduce debugging time or improve test clarity after several script changes, stop requiring them.






## A1. Metadata lives directly under artifacts/

Status: falsified and fixed

Old assumption:
Runtime metadata files are stored as flat sidecars under `artifacts/*.meta.txt`.

Evidence:
`bin/check_all_metadata_json.sh` previously scanned `artifacts/*.meta.txt`.

Current decision:
Runtime provenance metadata belongs under `artifacts/metadata/`.

Invariant:
Scripts that scan runtime metadata must scan `artifacts/metadata/*.meta.txt`.

Test:
`make -f asciinema.mk smoke`

Resolution:
Updated `bin/check_all_metadata_json.sh` to scan `artifacts/metadata/*.meta.txt`.





## A3. Every run_with_meta.sh invocation produces its declared artifact

Status: falsified and fixed

Old assumption:
If `run_with_meta.sh --out FILE -- COMMAND` runs, then `FILE` exists afterward.

Evidence:
`fail.cast.meta.txt` referenced `artifacts/cast/fail.cast`, but the failing command `bash -c 'exit 7'` did not create that artifact.

Current decision:
A failed command may produce valid metadata without producing the declared artifact.

Invariant:
Artifact existence is required only when `status=success`.

Test:
`./bin/check_all_metadata_json.sh`

Resolution:
Updated metadata validation so missing artifacts are violations only for successful runs.
