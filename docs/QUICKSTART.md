# 5-Minute Quickstart

> **Goal:** get from a fresh clone to a working artifacts preview in under 5 minutes.  
> No prior knowledge of the full system required.

---

## Step 1 — Clone and enter the repo

```bash
git clone https://github.com/munoabr8/evidence-kit.git
cd evidence-kit
```

Python 3 and GNU Make are the only hard requirements.

---

## Step 2 — Create your artifacts directory

```bash
mkdir -p artifacts
```

Drop any files you want to preview into `artifacts/` (logs, `.cast` recordings, images, JSON, etc.).

---

## Step 3 — Generate previews

```bash
python3 bin/gen-index.py
```

This creates:
- `artifacts/index.html` — a browsable index of everything in `artifacts/`
- `artifacts/<file>.html` — a playable/readable wrapper for each supported file type

---

## Step 4 — Serve and open

```bash
python3 -m http.server 8009 --directory artifacts
# open http://localhost:8009
```

---

## What's next?

| I want to… | See |
|---|---|
| Record a terminal session | `asciinema rec artifacts/demo.cast` |
| Package artifacts for Hunchly | `python3 bin/package_for_hunchly.py` |
| Link evidence to a claim | `python3 bin/evidence_graph.py link demo.cast my-claim --text "..."` |
| Log a prediction | `python3 bin/predict.py log "gen-index.py exits 0"` |
| Run the full onboarding checklist | See [`FIRST_RUN_CHECKLIST.md`](FIRST_RUN_CHECKLIST.md) |
| Read the full scope contract | See [`SCOPE.md`](SCOPE.md) |
