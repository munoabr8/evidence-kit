#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def collect_artifacts(art_dir: Path):
    casts = sorted(p.name for p in art_dir.glob("*.cast"))
    wrappers = sorted(p.name for p in art_dir.glob("*.cast.html"))

    assets = sorted(
        p.name
        for p in art_dir.iterdir()
        if p.is_file()
        and not p.name.endswith(".cast")
        and not p.name.endswith(".cast.html")
    )

    relations = []

    for cast in casts:
        wrapper_name = f"{cast}.html"
        if wrapper_name in wrappers:
            relations.append({
                "cast": cast,
                "wrapper": wrapper_name
            })

    return {
        "casts": casts,
        "wrappers": wrappers,
        "assets": assets,
        "relations": relations,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifacts", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    art_dir = Path(args.artifacts).resolve()
    out_path = Path(args.out).resolve()

    if not art_dir.exists():
        raise SystemExit(f"Artifacts directory not found: {art_dir}")

    data = {
        "generated_at": now_utc(),
        "artifacts_dir": str(art_dir),
    }

    data.update(collect_artifacts(art_dir))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(data, indent=2), encoding="utf-8")

    print(json.dumps({
        "status": "ok",
        "snapshot": str(out_path)
    }, indent=2))


if __name__ == "__main__":
    main()