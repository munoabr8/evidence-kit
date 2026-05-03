# Goal Graph — evidence-kit

This document is the machine-readable, human-readable capture of the Layered Goal Graph
that governs evidence-kit's design. Every component and artifact in this repository
should trace back to at least one node here.

Self-check rules:
1. If an action has no path upward to a North Star value, it is probably noise.
2. If a North Star value has no path downward to concrete actions, it is probably fantasy.
3. If onboarding requires understanding the whole system first, the onboarding design is wrong.
4. If changing one part forces changes everywhere, the design is too rigid.

---

## L0 — Values (North Star)

| ID  | Value |
|-----|-------|
| V1  | Minimize cognitive load on developers |
| V2  | Minimize friction of Evidence Kit usage |
| V3  | Minimize number of wrong assumptions |
| V4  | Make risky operations visible, explicit, and verifiable |

---

## L1 — Strategic Objectives

| ID  | Objective | Supports (L0) |
|-----|-----------|---------------|
| S1  | Simplify developer experience | V1 |
| S2  | Streamline Evidence Kit usage | V2 |
| S3  | Simplify onboarding for new users | V1, V2 |
| S4  | Build a falsification engine | V3 |
| S5  | Instrument risky operations | V4 |
| S6  | Make it easier to change in the future | V1, V2, V3, V4 |

---

## L2 — Operational Objectives

### S1 — Simplify developer experience
- Reduce context switching
- Intuitive interfaces and defaults
- Clear feedback and errors

### S2 — Streamline Evidence Kit usage
- One-command setup
- Integrated workflows
- Reusable templates
- Low-friction commands

### S3 — Simplify onboarding for new users
- Fast first value
- Progressive learning
- Clear guidance and examples
- Reduce upfront concepts

### S4 — Build a falsification engine
- Surface contradictions
- Link artifacts to claims
- Run validation tests
- Classify failures
- Drive repairs

### S5 — Instrument risky operations
- Require verifiable risk feedback
- Log pre/post state
- Make operations reversible/recoverable
- Expose failures clearly

### S6 — Make it easier to change in the future
- Modularize components
- Define stable interfaces
- Decouple concerns
- Version and migrate

---

## L3 — Actions / Tactics

### S1
- Sensible defaults
- Inline guidance
- Better error messages
- Keyboard shortcuts

### S2
- Setup script
- Template repo
- Command aliases
- Workflow automation

### S3
- 5-minute quickstart
- First-run checklist
- Example project
- In-context help

### S4
- Contradiction detector
- Claim → evidence map
- Test runner
- Failure taxonomy
- Repair playbooks

### S5
- Risk declaration
- Pre/post snapshots
- Audit log
- Reversible ops
- Failure alerts

### S6
- Modular architecture
- Clear boundaries
- Stable APIs
- Config-driven
- Migration guides

---

## L4 — Evidence / Artifacts

| L1 Objective | Artifact(s) | Produced by |
|---|---|---|
| S1 — Simplify developer experience | Telemetry, Error logs, UX feedback, Time-on-task | (instrumentation, future) |
| S2 — Streamline Evidence Kit usage | Setup logs, Command logs, Usage analytics, Template usage | `bin/run_and_capture.sh`, `hunchly.mk` |
| S3 — Simplify onboarding | Onboarding guide, Checklist completion, Time to first success, Confusion notes | `docs/QUICKSTART.md`, `docs/FIRST_RUN_CHECKLIST.md` |
| S4 — Build a falsification engine | Contradiction report, Claim-evidence graph, Test results, Failure reports, Repair history | `bin/evidence_graph.py` → `claims.json`, `validation_log.json`, `metadata.json` |
| S5 — Instrument risky operations | Risk registry, Operation logs, Pre/post state diff, Audit trail, Incident reports | `bin/risk_ops.py` → `risk_registry.json`, `audit_trail.json`, `pre_post_snapshots.json` |
| S6 — Make it easier to change | Module map, Interface docs, Changelog, Migration tests, Deprecation log | `bin/module_map.py` → `module_map.json`, `docs/INTERFACE_SPEC.md` |

---

## Quality Checks (Q)

| L1 Objective | Quality Check |
|---|---|
| S1 | Is cognitive load measurably reduced? (legibility, speed, error rate) |
| S2 | Is usage friction measurably reduced? (setup time, steps, drop-off) |
| S3 | Can a new user achieve first success quickly and confidently? |
| S4 | Are wrong assumptions being surfaced and corrected? |
| S5 | Are risky operations visible, explicit, and verifiable? |
| S6 | Can components be changed without cascading breakage? |

---

## Strategy Map (L0 ↔ L1)

```
V1 (Cognitive load)    ←→  S1, S3, S6
V2 (Friction)          ←→  S2, S3, S6
V3 (Wrong assumptions) ←→  S4, S6
V4 (Risky operations)  ←→  S5, S6
```

Each North Star value is supported by multiple strategic objectives (purple lines in the
visual goal graph).

---

## Execution Map (L1 → L2 → L3 → L4)

| Layer | S1 — Simplify developer experience | S2 — Streamline Evidence Kit usage | S3 — Simplify onboarding for new users | S4 — Build a falsification engine | S5 — Instrument risky operations | S6 — Make it easier to change |
|---|---|---|---|---|---|---|
| **L2 Operational Objectives** | Reduce context switching; intuitive interfaces; clear feedback | One-command setup; integrated workflows; reusable templates | Fast first value; progressive learning; clear guidance; reduce upfront | Surface contradictions; link artifacts to claims; run tests; classify failures | Require verifiable feedback; log pre/post; reversible; expose failures | Modularize; stable interfaces; decouple; version and migrate |
| **L3 Actions / Tactics** | Sensible defaults; inline guidance; better errors; shortcuts | Setup script; templates; aliases; workflow automation | Quickstart; checklist; example project; in-context help | Contradiction detector; claim → evidence map; test runner | Risk declaration; pre/post snapshots; audit log; failure alerts | Modular architecture; clear boundaries; stable APIs; config-driven |
| **L4 Evidence / Artifacts** | Telemetry; error logs; UX feedback; time-on-task | Setup logs; command logs; usage analytics; templates used | Onboarding guide; checklist completion; time to first success; confusion notes | Contradiction report; claim-evidence graph; test results; failure reports; repair history | Risk registry; operation logs; pre/post state diff; audit trail; incident reports | Module map; interface docs; changelog; migration tests; deprecation log |
| **Quality Check** | Is cognitive load measurably reduced? (legibility, speed, error rate) | Is usage friction measurably reduced? (setup time, steps, drop-off) | Can a new user achieve first success quickly and confidently? | Are wrong assumptions being surfaced and corrected? | Are risky operations observable, explicit, and verifiable? | Can components be changed without cascading breakage? |

---

## Implementation status

| L1 Objective | Status | Key files |
|---|---|---|
| S1 — Simplify developer experience | Partial | `bin/gen-index.py`, `hunchly.mk`, `docs/QUICKSTART.md` |
| S2 — Streamline Evidence Kit usage | Partial | `hunchly.mk`, `asciinema.mk`, `bin/run_and_capture.sh` |
| S3 — Simplify onboarding | Implemented | `docs/QUICKSTART.md`, `docs/FIRST_RUN_CHECKLIST.md` |
| S4 — Build a falsification engine | Implemented | `bin/evidence_graph.py`, `bin/predict.py` |
| S5 — Instrument risky operations | Implemented | `bin/risk_ops.py` |
| S6 — Make it easier to change | Implemented | `bin/module_map.py`, `docs/INTERFACE_SPEC.md` |

---

## Why This Matters

| Benefit | Detail |
|---|---|
| Fewer wrong assumptions | Continuous falsification surfaces and corrects bad beliefs before they compound. |
| Faster onboarding, higher adoption | Lower the cost of first success → less support burden, more contributors. |
| Lower cognitive load, more flow | Intuitive defaults and clear feedback keep developers in a productive state. |
| Less friction → used and trusted | An Evidence Kit that is easy to invoke actually gets used, making evidence real. |
| Visible, verifiable risk operations | Explicit risk declarations and audit trails build confidence in the system. |
| Easier changes, lower long-term cost | Stable interfaces and modular architecture reduce the cost of every future change. |

---

## North Star Outcome

> **Evidence you can trust. Decisions you can defend. Systems that get better over time.**

This model is iterative: **Measure → Learn → Improve → Repeat.**
Every link should have evidence. Every goal should be testable.

---

*This document is updated whenever a new component is added or a strategic objective changes.
Reference it in PR descriptions when adding features that serve a goal-graph node.*
