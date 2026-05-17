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
