#!/usr/bin/env bash
set -euo pipefail
version=${1:?version}
js_out=${2:?js_out}
css_out=${3:?css_out}
vendor_manifest=${4:-artifacts/vendor-player.json}
# Optional fifth argument or env VENDOR_COMMENT can provide a human-readable
# comment stored in the manifest under the `_comment` key. JSON doesn't have
# native comments so we keep a `_comment` field for notes.
VENDOR_COMMENT=${5:-${VENDOR_COMMENT:-}}

TMPDIR=$(mktemp -d artifacts/.asciinema-player-tmp.XXXXXX)
TMP_JS="$TMPDIR/asciinema-player.min.js"
TMP_CSS="$TMPDIR/asciinema-player.min.css"
cleanup(){ rc=$?; rm -rf "$TMPDIR" || true; exit $rc; }
trap cleanup EXIT

TRIES=3; SLEEP=2; OK=0
for i in $(seq 1 $TRIES); do
  if bin/fetch-asciinema-player.sh "$version" "$TMP_JS" "$TMP_CSS"; then OK=1; break; else echo "[asciinema] vendor-player: attempt $i failed" >&2; sleep $SLEEP; fi
done
if [ "$OK" -ne 1 ]; then echo "[asciinema] vendor-player: download failed after $TRIES attempts" >&2; exit 1; fi

# compute shas
js_sha=$(sha256sum "$TMP_JS" | awk '{print $1}')
css_sha=$(sha256sum "$TMP_CSS" | awk '{print $1}')

# Primary write: atomically move into the requested output locations (typically artifacts/)
mkdir -p "$(dirname "$js_out")"
JS_TMP_OUT=$(mktemp "$(dirname "$js_out")/.asciinema-player-js.XXXXXX")
mv "$TMP_JS" "$JS_TMP_OUT"
mv "$JS_TMP_OUT" "$js_out"
mkdir -p "$(dirname "$css_out")"
CSS_TMP_OUT=$(mktemp "$(dirname "$css_out")/.asciinema-player-css.XXXXXX")
mv "$TMP_CSS" "$CSS_TMP_OUT"
mv "$CSS_TMP_OUT" "$css_out"

# Mirror write: also write copies into media-pack/player/ (for canonical storage)
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
MEDIA_DIR="$REPO_ROOT/media-pack/player"
mkdir -p "$MEDIA_DIR"
MEDIA_JS_OUT="$MEDIA_DIR/$(basename "$js_out")"
MEDIA_CSS_OUT="$MEDIA_DIR/$(basename "$css_out")"

# Copy artifacts outputs into media-pack/player atomically
if [ -f "$js_out" ]; then
  MEDIA_JS_TMP=$(mktemp "$MEDIA_DIR/.asciinema-player-js.XXXXXX")
  cp -f "$js_out" "$MEDIA_JS_TMP"
  mv "$MEDIA_JS_TMP" "$MEDIA_JS_OUT"
  echo "[asciinema] mirrored $js_out -> $MEDIA_JS_OUT"
fi
if [ -f "$css_out" ]; then
  MEDIA_CSS_TMP=$(mktemp "$MEDIA_DIR/.asciinema-player-css.XXXXXX")
  cp -f "$css_out" "$MEDIA_CSS_TMP"
  mv "$MEDIA_CSS_TMP" "$MEDIA_CSS_OUT"
  echo "[asciinema] mirrored $css_out -> $MEDIA_CSS_OUT"
fi

# Write manifest into the requested manifest path (typically artifacts/), and
# also mirror into media-pack/player/vendor-player.json for convenience.
MAN_TMP=$(mktemp artifacts/.vendor-player-manifest.XXXXXX)

# Prepare optional comment, escape quotes and collapse newlines to spaces
comment_safe=''
if [ -n "$VENDOR_COMMENT" ]; then
  comment_safe=$(printf '%s' "$VENDOR_COMMENT" | sed 's/"/\\"/g' | tr '\n' ' ')
fi

# Write manifest with one attribute per line for readability
printf '{\n' > "$MAN_TMP"
if [ -n "$comment_safe" ]; then
  printf '  "_comment": "%s",\n' "$comment_safe" >> "$MAN_TMP"
fi
printf '  "version": "%s",\n' "$version" >> "$MAN_TMP"
printf '  "js": "%s",\n' "$js_out" >> "$MAN_TMP"
printf '  "css": "%s",\n' "$css_out" >> "$MAN_TMP"
printf '  "js_sha256": "%s",\n' "$js_sha" >> "$MAN_TMP"
printf '  "css_sha256": "%s",\n' "$css_sha" >> "$MAN_TMP"
printf '  "time": "%s"\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$MAN_TMP"
printf '}\n' >> "$MAN_TMP"

mv "$MAN_TMP" "$vendor_manifest"
chmod 0644 "$vendor_manifest" || true
if [ -n "$MEDIA_DIR" ]; then
  MEDIA_MANIFEST="$MEDIA_DIR/$(basename "$vendor_manifest")"
  MEDIA_MAN_TMP=$(mktemp "$MEDIA_DIR/.vendor-player-manifest.XXXXXX")
  # Rewrite js/css paths in the mirrored manifest to point at media-pack/player/<basename>
  MEDIA_JS_REL="media-pack/player/$(basename "$js_out")"
  MEDIA_CSS_REL="media-pack/player/$(basename "$css_out")"
  awk -v js="$MEDIA_JS_REL" -v css="$MEDIA_CSS_REL" '
    /^[[:space:]]*"js":/ { print "  \"js\": \"" js "\","; next }
    /^[[:space:]]*"css":/ { print "  \"css\": \"" css "\","; next }
    { print }
  ' "$vendor_manifest" > "$MEDIA_MAN_TMP"
  mv "$MEDIA_MAN_TMP" "$MEDIA_MANIFEST"
  chmod 0644 "$MEDIA_MANIFEST" || true
  echo "[asciinema] mirrored manifest (paths -> media-pack/player) -> $MEDIA_MANIFEST"
fi

echo "[asciinema] vendor-player: wrote $vendor_manifest"
