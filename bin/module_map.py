#!/usr/bin/env python3
"""
module_map.py — L2/L3 component modularization tracker for evidence-kit.

Maps to the Layered Goal Graph:
  L1 (Objective):  Make it easier to change in the future
  L2 (Action):     Modularize components
  L3 (Evidence):   module map  →  module_map.json

Each module record captures:
  - name         short identifier (e.g. "gen-index")
  - path         relative path to the entry-point file or directory
  - description  one-sentence purpose
  - public_api   list of public callable/CLI names this module exposes
  - depends_on   list of other module names this module uses

CLI usage:
  python3 bin/module_map.py add gen-index bin/gen-index.py "Generates HTML previews"
  python3 bin/module_map.py update gen-index --description "..." --public-api gen_index,write_wrappers
  python3 bin/module_map.py show
  python3 bin/module_map.py show gen-index
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional

MODULE_MAP_FILE = "module_map.json"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _load(art_dir: Path) -> List[Dict]:
    path = Path(art_dir) / MODULE_MAP_FILE
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            pass
    return []


def _save(art_dir: Path, modules: List[Dict]) -> None:
    path = Path(art_dir) / MODULE_MAP_FILE
    path.write_text(json.dumps(modules, indent=2), encoding="utf-8")


def _find(modules: List[Dict], name: str) -> Optional[Dict]:
    return next((m for m in modules if m["name"] == name), None)


# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------

def add_module(
    art_dir: Path,
    name: str,
    path: str,
    description: str,
    public_api: Optional[List[str]] = None,
    depends_on: Optional[List[str]] = None,
) -> Dict:
    """
    Add a new module entry.  Raises ValueError if the name already exists.
    Returns the new record.
    """
    art_dir = Path(art_dir)
    modules = _load(art_dir)
    if _find(modules, name) is not None:
        raise ValueError(f"module already registered: {name}")
    record: Dict = {
        "name": name,
        "path": path,
        "description": description,
        "public_api": public_api or [],
        "depends_on": depends_on or [],
    }
    modules.append(record)
    _save(art_dir, modules)
    return record


def update_module(
    art_dir: Path,
    name: str,
    description: Optional[str] = None,
    public_api: Optional[List[str]] = None,
    depends_on: Optional[List[str]] = None,
) -> Dict:
    """
    Update fields of an existing module.  Raises KeyError if not found.
    Returns the updated record.
    """
    art_dir = Path(art_dir)
    modules = _load(art_dir)
    rec = _find(modules, name)
    if rec is None:
        raise KeyError(f"module not found: {name}")
    if description is not None:
        rec["description"] = description
    if public_api is not None:
        rec["public_api"] = public_api
    if depends_on is not None:
        rec["depends_on"] = depends_on
    _save(art_dir, modules)
    return rec


def get_module(art_dir: Path, name: str) -> Dict:
    """Return a single module record.  Raises KeyError if not found."""
    modules = _load(Path(art_dir))
    rec = _find(modules, name)
    if rec is None:
        raise KeyError(f"module not found: {name}")
    return rec


def list_modules(art_dir: Path) -> List[Dict]:
    """Return all module records."""
    return _load(Path(art_dir))


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: Optional[List[str]] = None) -> None:
    import argparse

    ap = argparse.ArgumentParser(
        description="Module map tracker (L2/L3 — Make it easier to change in the future)"
    )
    ap.add_argument("--art-dir", default=os.environ.get("ART_DIR", "artifacts"))
    sub = ap.add_subparsers(dest="cmd")

    p_add = sub.add_parser("add", help="Register a new module")
    p_add.add_argument("name", help="Short module identifier")
    p_add.add_argument("path", help="Relative path to entry-point file or directory")
    p_add.add_argument("description", help="One-sentence purpose")
    p_add.add_argument(
        "--public-api",
        default="",
        help="Comma-separated list of public callables/CLI names",
    )
    p_add.add_argument(
        "--depends-on",
        default="",
        help="Comma-separated list of module names this module uses",
    )

    p_upd = sub.add_parser("update", help="Update an existing module record")
    p_upd.add_argument("name", help="Module identifier to update")
    p_upd.add_argument("--description", default=None)
    p_upd.add_argument("--public-api", default=None)
    p_upd.add_argument("--depends-on", default=None)

    p_show = sub.add_parser("show", help="Print module map as JSON")
    p_show.add_argument("name", nargs="?", default=None, help="Module name (omit for all)")

    args = ap.parse_args(argv)
    art_dir = Path(args.art_dir)

    if args.cmd == "add":
        public_api = [s.strip() for s in args.public_api.split(",") if s.strip()]
        depends_on = [s.strip() for s in args.depends_on.split(",") if s.strip()]
        try:
            rec = add_module(art_dir, args.name, args.path, args.description,
                             public_api=public_api, depends_on=depends_on)
            print(f"[module_map] added '{rec['name']}' → {art_dir / MODULE_MAP_FILE}")
        except ValueError as exc:
            print(f"[module_map] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)

    elif args.cmd == "update":
        public_api = (
            [s.strip() for s in args.public_api.split(",") if s.strip()]
            if args.public_api is not None
            else None
        )
        depends_on = (
            [s.strip() for s in args.depends_on.split(",") if s.strip()]
            if args.depends_on is not None
            else None
        )
        try:
            rec = update_module(art_dir, args.name,
                                description=args.description,
                                public_api=public_api,
                                depends_on=depends_on)
            print(f"[module_map] updated '{rec['name']}'")
        except KeyError as exc:
            print(f"[module_map] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)

    elif args.cmd == "show":
        try:
            if args.name:
                data = get_module(art_dir, args.name)
            else:
                data = list_modules(art_dir)
            json.dump(data, sys.stdout, indent=2)
            sys.stdout.write("\n")
        except KeyError as exc:
            print(f"[module_map] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)

    else:
        ap.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
