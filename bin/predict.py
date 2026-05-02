#!/usr/bin/env python3
"""
predict.py — L2/L3 prediction-vs-outcome logger for evidence-kit.

Maps to the Layered Goal Graph:
  L2 (Action):  Log one prediction vs outcome
  L3 (Evidence): prediction record  →  predictions.json

Each record captures:
  - id           unique UUID
  - created_at   ISO-8601 timestamp
  - prediction   what you expect to happen
  - outcome      observed result (filled in by 'observe' subcommand)
  - status       'pending' | 'confirmed' | 'refuted'

CLI usage:
  python3 bin/predict.py log    "gen-index.py will exit 0 on an empty artifacts dir"
  python3 bin/predict.py observe <id> "it exited 0" --confirmed
  python3 bin/predict.py observe <id> "it crashed" --refuted
  python3 bin/predict.py show
"""
from __future__ import annotations

import json
import os
import time
import uuid
from pathlib import Path
from typing import Dict, List, Optional

PREDICTIONS_FILE = "predictions.json"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def _load(art_dir: Path) -> List[Dict]:
    path = Path(art_dir) / PREDICTIONS_FILE
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            pass
    return []


def _save(art_dir: Path, records: List[Dict]) -> None:
    path = Path(art_dir) / PREDICTIONS_FILE
    path.write_text(json.dumps(records, indent=2), encoding="utf-8")


# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------

def log_prediction(art_dir: Path, prediction: str) -> Dict:
    """
    Append a new prediction record with status='pending'.
    Returns the new record dict.
    """
    art_dir = Path(art_dir)
    records = _load(art_dir)
    record: Dict = {
        "id": str(uuid.uuid4()),
        "created_at": _now(),
        "prediction": prediction,
        "outcome": None,
        "resolved_at": None,
        "status": "pending",
    }
    records.append(record)
    _save(art_dir, records)
    return record


def record_outcome(
    art_dir: Path,
    record_id: str,
    outcome: str,
    confirmed: bool,
) -> Dict:
    """
    Update the prediction record identified by record_id with the observed
    outcome text and mark it 'confirmed' or 'refuted'.
    Raises KeyError if record_id is not found.
    """
    art_dir = Path(art_dir)
    records = _load(art_dir)
    for rec in records:
        if rec["id"] == record_id:
            rec["outcome"] = outcome
            rec["resolved_at"] = _now()
            rec["status"] = "confirmed" if confirmed else "refuted"
            _save(art_dir, records)
            return rec
    raise KeyError(f"prediction record not found: {record_id}")


def show_predictions(art_dir: Path) -> List[Dict]:
    """Return all prediction records (newest last)."""
    return _load(Path(art_dir))


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: Optional[List[str]] = None) -> None:
    import argparse
    import sys

    ap = argparse.ArgumentParser(
        description="Prediction-vs-outcome logger (L2/L3 of the Layered Goal Graph)"
    )
    ap.add_argument("--art-dir", default=os.environ.get("ART_DIR", "artifacts"))
    sub = ap.add_subparsers(dest="cmd")

    p_log = sub.add_parser("log", help="Record a new prediction (status=pending)")
    p_log.add_argument("prediction", help="What you expect to happen")

    p_obs = sub.add_parser("observe", help="Record observed outcome for a prediction")
    p_obs.add_argument("id", help="Prediction record UUID")
    p_obs.add_argument("outcome", help="Observed result text")
    group = p_obs.add_mutually_exclusive_group(required=True)
    group.add_argument("--confirmed", action="store_true")
    group.add_argument("--refuted", action="store_true")

    sub.add_parser("show", help="Print all prediction records as JSON")

    args = ap.parse_args(argv)
    art_dir = Path(args.art_dir)

    if args.cmd == "log":
        rec = log_prediction(art_dir, args.prediction)
        print(f"[predict] logged {rec['id']}")
        print(f"          prediction: {rec['prediction']}")
    elif args.cmd == "observe":
        try:
            rec = record_outcome(art_dir, args.id, args.outcome, confirmed=args.confirmed)
            print(f"[predict] {rec['id']} → {rec['status']}")
        except KeyError as exc:
            print(f"[predict] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)
    elif args.cmd == "show":
        records = show_predictions(art_dir)
        json.dump(records, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        ap.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
