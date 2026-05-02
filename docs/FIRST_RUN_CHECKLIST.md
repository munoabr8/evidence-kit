# First-Run Checklist

Work through this checklist top-to-bottom on a fresh clone.  
Each item is self-contained — you do **not** need to understand the whole system first.

---

## Environment

- [ ] Python 3 is installed (`python3 --version`)
- [ ] GNU Make is installed (`make --version`)
- [ ] Git is installed (`git --version`)

---

## Basic smoke-check

- [ ] Clone the repo and `cd` into it
- [ ] Run `python3 bin/gen-index.py` — exits 0 (even with an empty `artifacts/` dir)
- [ ] `artifacts/index.html` now exists

---

## Local preview

- [ ] Run `python3 -m http.server 8009 --directory artifacts`
- [ ] Open `http://localhost:8009` in a browser — the index page loads

---

## Record a terminal session (optional)

- [ ] `asciinema` is installed (`asciinema --version`)
- [ ] Run `asciinema rec artifacts/hello.cast -c "echo hello"` — file is created
- [ ] Run `python3 bin/gen-index.py` — `artifacts/hello.cast.html` is created
- [ ] Open `http://localhost:8009/hello.cast.html` — playback works

---

## Evidence graph (optional)

- [ ] Run `python3 bin/evidence_graph.py metadata --art-dir artifacts` — `artifacts/metadata.json` created
- [ ] Run `python3 bin/evidence_graph.py validate --art-dir artifacts` — exits with `PASSED`
- [ ] Link an artifact to a claim:
  ```bash
  python3 bin/evidence_graph.py link hello.cast claim-001 \
      --text "terminal records hello" --art-dir artifacts
  ```
- [ ] Run `python3 bin/evidence_graph.py falsify --art-dir artifacts` — `claim-001` shows `supported`

---

## Prediction logging (optional)

- [ ] Log a prediction:
  ```bash
  python3 bin/predict.py log "gen-index.py exits 0 on empty dir" --art-dir artifacts
  ```
  Note the UUID printed.
- [ ] Record the outcome (replace `<id>` with the UUID from above):
  ```bash
  python3 bin/predict.py observe <id> "it exited 0 as expected" --confirmed \
      --art-dir artifacts
  ```
- [ ] Run `python3 bin/predict.py show --art-dir artifacts` — record shows `confirmed`

---

## Module map (optional)

- [ ] Register a component:
  ```bash
  python3 bin/module_map.py add gen-index bin/gen-index.py \
      "Generates HTML previews for artifacts" \
      --public-api gen_index --art-dir artifacts
  ```
- [ ] Run `python3 bin/module_map.py show --art-dir artifacts` — record appears as JSON
- [ ] Check `artifacts/module_map.json` exists and is valid JSON

---

## Checklist self-check

Self-check rules from the Layered Goal Graph:

1. If an action has no path upward, it is probably noise.
2. If a high-level goal has no path downward, it is probably fantasy.
3. If onboarding requires understanding the whole system first, the onboarding design is wrong.
4. If changing one part forces changes everywhere, the design is too rigid.

Each item above is independently runnable. If you find a step that blocks on a later step, that is a gap — please open an issue.
