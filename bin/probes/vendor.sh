#!/usr/bin/env bash
set -euo pipefail
script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
. "$script_dir/../probe_common.sh"

probe_vendor() {
  decide_root
  guard_root
  local manifest="$ART_DIR/vendor-player.json"
  if [ ! -f "$manifest" ]; then
    echo "vendor: missing manifest: $manifest" >&2; return 5
  fi

  if [ "${1:-}" = --json ]; then
    python3 - <<PY
import json,os,hashlib,sys
manifest='$manifest'
try:
  obj=json.loads(open(manifest).read())
except Exception as e:
  print(json.dumps({'error':str(e)})); sys.exit(6)
def sha256_of(path):
  h=hashlib.sha256()
  with open(path,'rb') as f:
    for chunk in iter(lambda: f.read(8192), b''):
      h.update(chunk)
  return h.hexdigest()
report={'manifest':obj,'checks':{}}
for key in ('js','css'):
  if key in obj:
    path=obj[key]
    ok=False
    sha=None
    if os.path.exists(path):
      sha=sha256_of(path)
      expected=obj.get(key+'_sha256')
      ok=(expected is None) or (sha==expected)
    report['checks'][key]={'path':path,'exists':os.path.exists(path),'sha256':sha,'matches':ok,'expected':obj.get(key+'_sha256')}
print(json.dumps(report,indent=2))
PY
    return 0
  fi

  python3 - <<PY
import json,os,hashlib,sys
manifest='$manifest'
obj=json.loads(open(manifest).read())
def sha256_of(path):
  h=hashlib.sha256()
  with open(path,'rb') as f:
    for chunk in iter(lambda: f.read(8192), b''):
      h.update(chunk)
  return h.hexdigest()
print('vendor: manifest=%s' % manifest)
for key in ('js','css'):
  if key in obj:
    path=obj[key]
    exists=os.path.exists(path)
    print('  %s: %s (exists=%s)' % (key, path, exists))
    if exists:
      sha=sha256_of(path)
      expected=obj.get(key+'_sha256')
      print('    sha256: %s' % sha)
      if expected:
        print('    expected: %s' % expected)
        print('    match: %s' % ('OK' if sha==expected else 'MISMATCH'))
    else:
      print('    expected: (none in manifest)')
PY

  if [ "${ALLOW_GENERATE_SHA:-}" = "true" ]; then
    for key in js css; do
      val=$(python3 -c "import json;print(json.load(open('$manifest')).get('$key') or '')")
      if [ -n "$val" ] && [ -f "$val" ]; then
        shafile="$val.sha256"
        if [ ! -f "$shafile" ]; then
          sha256sum "$val" | awk '{print $1}' > "$shafile" && echo "vendor: wrote $shafile"
        fi
      fi
    done
  fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  probe_vendor "$1"
fi
