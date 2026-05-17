#!/usr/bin/env bash
set -euo pipefail

ART_DIR="${ART_DIR:-artifacts}"
CAST_DIR="$ART_DIR/cast"
VIEW_DIR="$ART_DIR/views/cast"

CAST_FILE="$CAST_DIR/visible_test.cast"
WRAPPER_FILE="$VIEW_DIR/visible_test.cast.html"

mkdir -p "$CAST_DIR" "$VIEW_DIR"

# Create a small valid-ish asciinema cast fixture if missing.
# If you already generate visible_test.cast elsewhere, this block can be removed.
if [[ ! -f "$CAST_FILE" ]]; then
  cat > "$CAST_FILE" <<'EOF'
{"version": 2, "width": 80, "height": 24, "timestamp": 0, "env": {"SHELL": "/bin/bash", "TERM": "xterm-256color"}}
[0.1, "o", "START\r\n"]
[0.2, "o", "END\r\n"]
EOF
fi

python3 ./bin/gen-index.py --art-dir "$ART_DIR"

if [[ ! -f "$WRAPPER_FILE" ]]; then
  echo "FAIL: expected wrapper not generated: $WRAPPER_FILE" >&2
  exit 1
fi

grep -q "AsciinemaPlayer.create" "$WRAPPER_FILE" || {
  echo "FAIL: wrapper does not use AsciinemaPlayer.create()" >&2
  exit 1
}

grep -q "../../cast/visible_test.cast" "$WRAPPER_FILE" || {
  echo "FAIL: wrapper does not reference cast with correct relative path" >&2
  exit 1
}

grep -q "../../assets/asciinema-player.min.js" "$WRAPPER_FILE" || {
  echo "FAIL: wrapper does not reference JS asset with correct relative path" >&2
  exit 1
}

grep -q "../../assets/asciinema-player.min.css" "$WRAPPER_FILE" || {
  echo "FAIL: wrapper does not reference CSS asset with correct relative path" >&2
  exit 1
}

if grep -q "<asciinema-player" "$WRAPPER_FILE"; then
  echo "FAIL: wrapper still uses unsupported <asciinema-player> custom element" >&2
  exit 1
fi

echo "PASS: cast wrapper uses AsciinemaPlayer.create() with correct relative paths"