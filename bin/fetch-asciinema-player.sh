#!/bin/sh
# bin/fetch-asciinema-player.sh
# Usage: fetch-asciinema-player.sh <version> <js-out> <css-out>
set -eu
version=${1:-}
js_out=${2:-}
css_out=${3:-}
if [ -z "$version" ] || [ -z "$js_out" ] || [ -z "$css_out" ]; then
  echo "Usage: $0 <version> <js-out> <css-out>" >&2
  exit 2
fi
mkdir -p "$(dirname "$js_out")"
echo "[asciinema] fetch-asciinema-player: v$version -> $js_out $css_out"
if [ -f "$js_out" ] && [ -f "$css_out" ]; then
  echo "[asciinema] player already present: $js_out $css_out"
  exit 0
fi
JS_BUNDLE_URL="https://cdn.jsdelivr.net/npm/asciinema-player@${version}/dist/bundle/asciinema-player.min.js"
CSS_BUNDLE_URL="https://cdn.jsdelivr.net/npm/asciinema-player@${version}/dist/bundle/asciinema-player.css"
echo "[asciinema] trying jsDelivr bundle: $JS_BUNDLE_URL"
if curl -fsS "$JS_BUNDLE_URL" -o "$js_out"; then
  echo "[asciinema] downloaded JS bundle from jsDelivr"
  curl -fsS "$CSS_BUNDLE_URL" -o "$css_out" || true
  if [ ! -s "$css_out" ]; then
    CSS_FALLBACK_URL="https://cdn.jsdelivr.net/npm/asciinema-player@${version}/dist/asciinema-player.min.css"
    curl -fsS "$CSS_FALLBACK_URL" -o "$css_out" || true
  fi
else
  echo "[asciinema] jsDelivr bundle not available; trying npm tarball"
  TAR_URL="https://registry.npmjs.org/asciinema-player/-/asciinema-player-${version}.tgz"
  echo "[asciinema] downloading $TAR_URL"
  TMP_TGZ=$(mktemp /tmp/asciinema-player.XXXXXX.tgz)
  if ! curl -fsSL "$TAR_URL" -o "$TMP_TGZ"; then
    echo "[asciinema] failed to download tarball $TAR_URL" >&2
    rm -f "$TMP_TGZ" || true
    exit 1
  fi
  TMP_DIR=$(mktemp -d /tmp/asciinema-player.XXXXXX)
  if ! tar -xzf "$TMP_TGZ" -C "$TMP_DIR"; then
    echo "[asciinema] failed to extract tarball" >&2
    rm -f "$TMP_TGZ"; rm -rf "$TMP_DIR" || true
    exit 1
  fi
  if [ -f "$TMP_DIR/package/dist/bundle/asciinema-player.min.js" ]; then
    cp "$TMP_DIR/package/dist/bundle/asciinema-player.min.js" "$js_out"
    cp "$TMP_DIR/package/dist/bundle/asciinema-player.css" "$css_out" 2>/dev/null || true
  elif [ -f "$TMP_DIR/package/dist/bundle/asciinema-player.js" ]; then
    cp "$TMP_DIR/package/dist/bundle/asciinema-player.js" "$js_out"
    cp "$TMP_DIR/package/dist/bundle/asciinema-player.css" "$css_out" 2>/dev/null || true
  else
    FOUND_JS=$(find "$TMP_DIR/package" -type f -name 'asciinema-player*.js' | head -n1 || true)
    FOUND_CSS=$(find "$TMP_DIR/package" -type f -name 'asciinema-player*.css' | head -n1 || true)
    if [ -n "$FOUND_JS" ]; then cp "$FOUND_JS" "$js_out"; fi
    if [ -n "$FOUND_CSS" ]; then cp "$FOUND_CSS" "$css_out"; fi
  fi
  rm -f "$TMP_TGZ"; rm -rf "$TMP_DIR"
fi
# sanity checks
if [ ! -s "$js_out" ]; then
  echo "[asciinema] failed to obtain player JS" >&2
  rm -f "$js_out" "$css_out" || true
  exit 1
fi
if [ $(wc -c < "$js_out") -lt 1000 ]; then
  echo "[asciinema] downloaded JS suspiciously small" >&2
  rm -f "$js_out" "$css_out" || true
  exit 1
fi
if [ ! -s "$css_out" ]; then
  echo "[asciinema] warning: CSS not obtained; player may still work" >&2
else
  if [ $(wc -c < "$css_out") -lt 200 ]; then
    echo "[asciinema] downloaded CSS suspiciously small" >&2
    rm -f "$js_out" "$css_out" || true
    exit 1
  fi
fi
echo "[asciinema] wrote $js_out and $css_out"
