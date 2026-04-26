#!/usr/bin/env bash
set -euo pipefail

ART_DIR="${1:-}"

if [[ -z "$ART_DIR" ]]; then
  echo "usage: $0 <artifacts_dir>"
  exit 1
fi

if [[ ! -d "$ART_DIR" ]]; then
  echo "error: directory not found: $ART_DIR"
  exit 1
fi

echo "[backfill] scanning $ART_DIR"

count_created=0
count_skipped=0

for cast in "$ART_DIR"/*.cast; do
  [[ -e "$cast" ]] || continue

  base="$(basename "$cast" .cast)"
  sidecar="$ART_DIR/$base.meta.txt"

  if [[ -f "$sidecar" ]]; then
    echo "[backfill] exists: $sidecar"
    ((count_skipped += 1))
    continue
  fi

  echo "[backfill] creating: $sidecar"

  cat > "$sidecar" <<EOF
timestamp=BACKFILLED
cwd=UNKNOWN
command=UNKNOWN
git_branch=UNKNOWN
git_commit=UNKNOWN
source=BACKFILLED
EOF

  ((count_created += 1))
done

echo "[backfill] created: $count_created"
echo "[backfill] skipped: $count_skipped"