# Interface Spec

> **L3 Evidence artifact** for the L1 objective: *Make it easier to change in the future.*  
> Documents the stable public contracts between components.  
> Self-check rule #4: "If changing one part forces changes everywhere, the design is too rigid."

---

## Contract: `bin/gen-index.py`

**Purpose:** Enumerate `artifacts/`, generate `artifacts/index.html` and per-artifact HTML wrappers.

**Stable inputs:**
- `ART_DIR` environment variable (default: `artifacts/`)
- Files present under `ART_DIR/` (any extension)

**Stable outputs:**
- `ART_DIR/index.html` — browsable artifact index
- `ART_DIR/<name>.html` — wrapper per non-HTML artifact
- `ART_DIR/<name>.cast.html` — playable wrapper for `.cast` files
- `ART_DIR/asciinema-glue.js` — shared player glue (written once)

**Breaking-change boundary:** callers may rely on the existence and relative path of `index.html` and `*.cast.html` files. Internal helper functions are not part of the public contract.

---

## Contract: `bin/evidence_graph.py`

**Purpose:** Link artifacts to claims, detect contradictions, emit falsification reports.

**Stable CLI surface:**
```
evidence_graph.py metadata   [--art-dir DIR]
evidence_graph.py validate   [--art-dir DIR]
evidence_graph.py link       <artifact> <claim-id> [--text TEXT] [--art-dir DIR]
evidence_graph.py contradict <claim-a>  <claim-b>  [--reason REASON] [--art-dir DIR]
evidence_graph.py falsify    [--art-dir DIR]
```

**Stable outputs (JSON schema):**

`metadata.json` — array of artifact objects:
```json
[{"name": "...", "size": 0, "mime": "...", "sha256": "...", "mtime": 0.0, "claims": []}]
```

`claims.json` — object with `claims` array and `contradictions` array.

`validation_log.json` — object with `status` (`"PASSED"` | `"FAILED"`), `checks` array, and `contradictions` array.

**Breaking-change boundary:** the JSON field names above and the `falsify` exit code (0 = no wrong assumptions, 1 = wrong assumptions found) are stable. Internal function signatures are not.

---

## Contract: `bin/predict.py`

**Purpose:** Log predictions and record outcomes; emit `predictions.json`.

**Stable CLI surface:**
```
predict.py log     <prediction-text>              [--art-dir DIR]
predict.py observe <uuid> <outcome-text> --confirmed|--refuted  [--art-dir DIR]
predict.py show                                   [--art-dir DIR]
```

**Stable outputs:**

`predictions.json` — array of prediction objects:
```json
[{"id": "...", "created_at": "...", "prediction": "...",
  "outcome": null, "resolved_at": null, "status": "pending"}]
```
`status` is one of `"pending"`, `"confirmed"`, `"refuted"`.

**Breaking-change boundary:** the JSON field names above, the UUID format of `id`, and the three `status` values are stable.

---

## Contract: `bin/module_map.py`

**Purpose:** Register components and their public APIs; emit `module_map.json`.

**Stable CLI surface:**
```
module_map.py add    <name> <path> <description> [--public-api A,B] [--depends-on X,Y] [--art-dir DIR]
module_map.py update <name> [--description ...] [--public-api ...] [--depends-on ...] [--art-dir DIR]
module_map.py show   [name]                                                             [--art-dir DIR]
```

**Stable outputs:**

`module_map.json` — array of module objects:
```json
[{"name": "...", "path": "...", "description": "...", "public_api": [], "depends_on": []}]
```

**Breaking-change boundary:** the JSON field names above are stable. The `name` field is the primary key; renaming a module is a breaking change for any downstream consumer that references it.

---

## Contract: `bin/template.py`

**Purpose:** Minimal template loader used by `gen-index.py`.

**Stable inputs:** template files under `templates/`.

**Stable behavior:** `render(template_path, context)` → rendered string. No side effects.

**Breaking-change boundary:** the `render` function signature is stable. Template file names are internal.

---

## Stability policy

| Status | Meaning |
|---|---|
| **Stable** | Won't change without a deprecation notice and major version bump |
| **Internal** | May change in any commit; do not depend on it |

All JSON field names and CLI flag names in this document are **Stable**.  
All Python function signatures not listed here are **Internal**.

---

## Updating this spec

When adding a new component or changing a stable contract:
1. Update this file in the same PR as the code change.
2. Add the new module to `module_map.json` via `bin/module_map.py add`.
3. Run `python3 bin/evidence_graph.py validate` to confirm the artifact inventory is consistent.
