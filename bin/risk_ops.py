#!/usr/bin/env python3
"""
risk_ops.py — L2/L3/L4 risky-operation instrumentation for evidence-kit.

Maps to the Layered Goal Graph:
  L0 (North Star):  Make risky operations visible, explicit, and verifiable
  L1 (Objective):   Instrument risky operations
  L2 (Actions):
    - Require verifiable risk feedback   →  declare(), surface_failure()
    - Log pre/post state                 →  snapshot()
    - Make operations reversible         →  record_reversible()
    - Expose failures clearly            →  surface_failure(), show()
  L3 (Evidence):
    - Risk declaration                   →  risk_registry.json
    - Pre/post snapshots                 →  pre_post_snapshots.json
    - Audit log                          →  audit_trail.json
    - Reversible ops registry            →  risk_registry.json (rollback_cmd field)
    - Failure alerts                     →  audit_trail.json (severity field)
  L4 (Artifacts):
    - risk_registry.json  — declared operations and their risk levels
    - audit_trail.json    — append-only log of events
    - pre_post_snapshots.json — state captured before and after each operation

  Quality check: Are risky operations visible, explicit, and verifiable?

CLI usage (run from repo root):
  python3 bin/risk_ops.py declare  <op_name> <risk_level> <description> [--rollback CMD]
  python3 bin/risk_ops.py snapshot <op_name> <phase> <key=value ...>
  python3 bin/risk_ops.py log      <op_name> <event> [--details TEXT] [--severity LEVEL]
  python3 bin/risk_ops.py diff     <op_name>
  python3 bin/risk_ops.py show     [--registry|--trail|--snapshots]
"""
from __future__ import annotations

import json
import os
import time
from pathlib import Path
from typing import Dict, List, Optional

RISK_REGISTRY_FILE = "risk_registry.json"
AUDIT_TRAIL_FILE = "audit_trail.json"
PRE_POST_SNAPSHOTS_FILE = "pre_post_snapshots.json"

VALID_RISK_LEVELS = ("low", "medium", "high", "critical")
VALID_PHASES = ("pre", "post")
VALID_SEVERITIES = ("info", "warning", "error", "critical")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def _load_json(path: Path, default):
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            pass
    return default


def _write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


# ---------------------------------------------------------------------------
# Risk registry  (L3: risk declaration)
# ---------------------------------------------------------------------------

def _load_registry(art_dir: Path) -> List[Dict]:
    return _load_json(Path(art_dir) / RISK_REGISTRY_FILE, [])


def _save_registry(art_dir: Path, registry: List[Dict]) -> None:
    _write_json(Path(art_dir) / RISK_REGISTRY_FILE, registry)


def declare_risk(
    art_dir: Path,
    op_name: str,
    risk_level: str,
    description: str,
    rollback_cmd: str = "",
) -> Dict:
    """
    Declare a risky operation and register it in risk_registry.json.

    op_name     — short identifier for the operation (e.g. "deploy-prod")
    risk_level  — one of: low, medium, high, critical
    description — human-readable explanation of why the operation is risky
    rollback_cmd — optional shell command to reverse the operation

    Raises ValueError for unknown risk_level or duplicate op_name.
    Returns the new registry entry.
    """
    if risk_level not in VALID_RISK_LEVELS:
        raise ValueError(
            f"risk_level must be one of {VALID_RISK_LEVELS}, got: {risk_level!r}"
        )
    art_dir = Path(art_dir)
    registry = _load_registry(art_dir)
    if any(r["op_name"] == op_name for r in registry):
        raise ValueError(f"operation already declared: {op_name}")
    entry: Dict = {
        "op_name": op_name,
        "risk_level": risk_level,
        "description": description,
        "rollback_cmd": rollback_cmd,
        "declared_at": _now(),
    }
    registry.append(entry)
    _save_registry(art_dir, registry)
    return entry


# ---------------------------------------------------------------------------
# Pre/post snapshots  (L3: log pre/post state)
# ---------------------------------------------------------------------------

def _load_snapshots(art_dir: Path) -> List[Dict]:
    return _load_json(Path(art_dir) / PRE_POST_SNAPSHOTS_FILE, [])


def _save_snapshots(art_dir: Path, snapshots: List[Dict]) -> None:
    _write_json(Path(art_dir) / PRE_POST_SNAPSHOTS_FILE, snapshots)


def snapshot(
    art_dir: Path,
    op_name: str,
    phase: str,
    state: Dict,
) -> Dict:
    """
    Record a state snapshot for op_name at the given phase ('pre' or 'post').

    state — arbitrary dict describing the system state at this point
    Returns the snapshot entry.
    """
    if phase not in VALID_PHASES:
        raise ValueError(f"phase must be one of {VALID_PHASES}, got: {phase!r}")
    art_dir = Path(art_dir)
    snapshots = _load_snapshots(art_dir)
    entry: Dict = {
        "op_name": op_name,
        "phase": phase,
        "captured_at": _now(),
        "state": state,
    }
    snapshots.append(entry)
    _save_snapshots(art_dir, snapshots)
    return entry


def diff_snapshots(art_dir: Path, op_name: str) -> Dict:
    """
    Return the most recent pre/post snapshot pair for op_name and their diff.

    The diff lists keys whose values changed, were added, or were removed
    between the pre and post snapshots.
    Returns a dict with keys: op_name, pre, post, diff.
    Raises KeyError if pre or post snapshot is missing for op_name.
    """
    art_dir = Path(art_dir)
    snapshots = _load_snapshots(art_dir)
    pre_entries = [s for s in snapshots if s["op_name"] == op_name and s["phase"] == "pre"]
    post_entries = [s for s in snapshots if s["op_name"] == op_name and s["phase"] == "post"]

    if not pre_entries:
        raise KeyError(f"no pre-snapshot found for operation: {op_name}")
    if not post_entries:
        raise KeyError(f"no post-snapshot found for operation: {op_name}")

    pre = pre_entries[-1]
    post = post_entries[-1]
    pre_state = pre["state"]
    post_state = post["state"]

    all_keys = set(pre_state) | set(post_state)
    changed = {}
    for k in sorted(all_keys):
        if k not in pre_state:
            changed[k] = {"before": None, "after": post_state[k], "change": "added"}
        elif k not in post_state:
            changed[k] = {"before": pre_state[k], "after": None, "change": "removed"}
        elif pre_state[k] != post_state[k]:
            changed[k] = {"before": pre_state[k], "after": post_state[k], "change": "modified"}

    return {
        "op_name": op_name,
        "pre_captured_at": pre["captured_at"],
        "post_captured_at": post["captured_at"],
        "diff": changed,
    }


# ---------------------------------------------------------------------------
# Audit trail  (L3: audit log + failure alerts)
# ---------------------------------------------------------------------------

def _load_trail(art_dir: Path) -> List[Dict]:
    return _load_json(Path(art_dir) / AUDIT_TRAIL_FILE, [])


def _save_trail(art_dir: Path, trail: List[Dict]) -> None:
    _write_json(Path(art_dir) / AUDIT_TRAIL_FILE, trail)


def log_event(
    art_dir: Path,
    op_name: str,
    event: str,
    details: str = "",
    severity: str = "info",
) -> Dict:
    """
    Append an event to the audit trail for op_name.

    event    — short label (e.g. "started", "completed", "failed")
    details  — optional free-text detail
    severity — one of: info, warning, error, critical

    Returns the new trail entry.
    """
    if severity not in VALID_SEVERITIES:
        raise ValueError(
            f"severity must be one of {VALID_SEVERITIES}, got: {severity!r}"
        )
    art_dir = Path(art_dir)
    trail = _load_trail(art_dir)
    entry: Dict = {
        "op_name": op_name,
        "event": event,
        "details": details,
        "severity": severity,
        "logged_at": _now(),
    }
    trail.append(entry)
    _save_trail(art_dir, trail)
    return entry


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: Optional[List[str]] = None) -> None:
    import argparse
    import sys

    ap = argparse.ArgumentParser(
        description=(
            "Risky-operation instrumentation CLI\n"
            "(L1: Instrument risky operations — Layered Goal Graph)"
        )
    )
    ap.add_argument("--art-dir", default=os.environ.get("ART_DIR", "artifacts"))
    sub = ap.add_subparsers(dest="cmd")

    # declare
    p_dec = sub.add_parser("declare", help="Declare a risky operation (L3: risk declaration)")
    p_dec.add_argument("op_name", help="Short operation identifier")
    p_dec.add_argument(
        "risk_level",
        choices=list(VALID_RISK_LEVELS),
        help="Risk level: low | medium | high | critical",
    )
    p_dec.add_argument("description", help="Why this operation is risky")
    p_dec.add_argument(
        "--rollback",
        default="",
        metavar="CMD",
        help="Shell command to reverse the operation (makes it reversible)",
    )

    # snapshot
    p_snap = sub.add_parser(
        "snapshot", help="Capture a pre or post state snapshot (L3: pre/post snapshots)"
    )
    p_snap.add_argument("op_name")
    p_snap.add_argument("phase", choices=list(VALID_PHASES), help="pre | post")
    p_snap.add_argument(
        "state",
        nargs="*",
        metavar="KEY=VALUE",
        help="State key=value pairs (e.g. version=1.2.3 status=running)",
    )

    # log
    p_log = sub.add_parser("log", help="Append an event to the audit trail (L3: audit log)")
    p_log.add_argument("op_name")
    p_log.add_argument("event", help="Short event label (e.g. started, failed)")
    p_log.add_argument("--details", default="", help="Optional free-text detail")
    p_log.add_argument(
        "--severity",
        default="info",
        choices=list(VALID_SEVERITIES),
        help="info | warning | error | critical",
    )

    # diff
    p_diff = sub.add_parser(
        "diff", help="Show pre/post state diff for an operation (L4: pre/post state diff)"
    )
    p_diff.add_argument("op_name")

    # show
    p_show = sub.add_parser(
        "show", help="Print risk artifacts as JSON (L4: risk registry, audit trail, snapshots)"
    )
    group = p_show.add_mutually_exclusive_group()
    group.add_argument(
        "--registry", action="store_true", help="Show risk_registry.json"
    )
    group.add_argument(
        "--trail", action="store_true", help="Show audit_trail.json"
    )
    group.add_argument(
        "--snapshots", action="store_true", help="Show pre_post_snapshots.json"
    )

    args = ap.parse_args(argv)
    art_dir = Path(args.art_dir)

    if args.cmd == "declare":
        try:
            entry = declare_risk(
                art_dir, args.op_name, args.risk_level, args.description,
                rollback_cmd=args.rollback,
            )
            print(f"[risk_ops] declared '{entry['op_name']}' ({entry['risk_level']}) "
                  f"→ {art_dir / RISK_REGISTRY_FILE}")
        except ValueError as exc:
            print(f"[risk_ops] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)

    elif args.cmd == "snapshot":
        state: Dict = {}
        for item in args.state:
            if "=" not in item:
                print(f"[risk_ops] ERROR: state items must be KEY=VALUE, got: {item!r}",
                      file=sys.stderr)
                sys.exit(1)
            k, _, v = item.partition("=")
            state[k] = v
        try:
            entry = snapshot(art_dir, args.op_name, args.phase, state)
            print(f"[risk_ops] snapshot '{args.op_name}' ({args.phase}) "
                  f"→ {art_dir / PRE_POST_SNAPSHOTS_FILE}")
        except ValueError as exc:
            print(f"[risk_ops] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)

    elif args.cmd == "log":
        try:
            entry = log_event(
                art_dir, args.op_name, args.event,
                details=args.details, severity=args.severity,
            )
            print(f"[risk_ops] logged '{entry['event']}' for '{entry['op_name']}' "
                  f"(severity={entry['severity']}) → {art_dir / AUDIT_TRAIL_FILE}")
        except ValueError as exc:
            print(f"[risk_ops] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)

    elif args.cmd == "diff":
        try:
            result = diff_snapshots(art_dir, args.op_name)
            json.dump(result, sys.stdout, indent=2)
            sys.stdout.write("\n")
        except KeyError as exc:
            print(f"[risk_ops] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)

    elif args.cmd == "show":
        if args.registry:
            data = _load_registry(art_dir)
        elif args.trail:
            data = _load_trail(art_dir)
        elif args.snapshots:
            data = _load_snapshots(art_dir)
        else:
            data = {
                "risk_registry": _load_registry(art_dir),
                "audit_trail": _load_trail(art_dir),
                "pre_post_snapshots": _load_snapshots(art_dir),
            }
        json.dump(data, sys.stdout, indent=2)
        sys.stdout.write("\n")

    else:
        ap.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
