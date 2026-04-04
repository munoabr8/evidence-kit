#!/usr/bin/env bash
set -Eeuo pipefail

PORT=8009

echo "[¬S] verifying artifacts exist"
test -f artifacts/index.html
test -f artifacts/asciinema-glue.js

echo "[¬S] verifying file types"
file artifacts/asciinema-glue.js | grep -q "text"

echo "[¬S] verifying server behavior"
curl -sI "http://localhost:${PORT}/asciinema-player.min.js" | grep -q "Content-Type"

echo "[¬S] verification passed"
