#!/usr/bin/env bash
set -euo pipefail
version=${1:?version}
js_out=${2:?js_out}
css_out=${3:?css_out}
vendor_manifest=${4:-artifacts/vendor-player.json}

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

mkdir -p $(dirname "$js_out")
mv "$TMP_JS" "$js_out"
mkdir -p $(dirname "$css_out")
mv "$TMP_CSS" "$css_out"

MAN_TMP=$(mktemp artifacts/.vendor-player-manifest.XXXXXX)
cat > "$MAN_TMP" <<JSON
{
  "version": "$version",
  "js": "$js_out",
  "css": "$css_out",
  "js_sha256": "$js_sha",
  "css_sha256": "$css_sha",
  "time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
mv "$MAN_TMP" "$vendor_manifest"
chmod 0644 "$vendor_manifest" || true

echo "[asciinema] vendor-player: wrote $vendor_manifest"
