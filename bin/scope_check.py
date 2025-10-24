#!/usr/bin/env python3
"""Simple scope-check utility:

- Runs the index generator to ensure it completes (gen-index.py).
- Ensures any large files in `artifacts/` (> 64 KB) are listed in `artifacts/vendor-player.json`
  and that their SHA256 matches the manifest.

Exit code 0 on success, non-zero on failure.
"""
import os
import sys
import json
import hashlib
import subprocess

ROOT = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
ART = os.path.join(ROOT, 'artifacts')
MANIFEST = os.path.join(ART, 'vendor-player.json')
GEN = os.path.join(ROOT, 'bin', 'gen-index.py')

# Default threshold for "large" files: 1 MB. Can be overridden with SCOPE_CHECK_MIN_BYTES.
SIZE_THRESHOLD = int(os.environ.get('SCOPE_CHECK_MIN_BYTES', 1 * 1024 * 1024))

def sha256_of(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

def run_index():
    # Run gen-index.py and ensure it exits 0
    try:
        subprocess.check_call([sys.executable, GEN], cwd=ROOT)
    except subprocess.CalledProcessError as e:
        print(f"[scope-check] gen-index.py failed: {e}")
        return False
    return True

def load_manifest():
    if not os.path.isfile(MANIFEST):
        return None
    try:
        with open(MANIFEST, 'r', encoding='utf-8') as fh:
            return json.load(fh)
    except Exception as e:
        print(f"[scope-check] failed to parse manifest {MANIFEST}: {e}")
        return None

def check_vendor_manifest(manifest):
    # manifest is simple mapping used by existing vendor-player.json pattern
    required = {}
    if not manifest:
        print(f"[scope-check] no manifest found at {MANIFEST}")
        manifest = {}
    # Build expected mapping from manifest keys we care about
    # Support either flat keys (js, css) or a nested object in the future.
    for k in ('js', 'css'):
        if k in manifest:
            # store paths relative to repo root for consistent comparison
            p = os.path.normpath(os.path.join(ROOT, manifest[k]))
            required[os.path.normpath(p)] = manifest.get(f"{k}_sha256")

    failures = 0
    # Inspect artifacts for large files
    for name in os.listdir(ART):
        path = os.path.join(ART, name)
        if not os.path.isfile(path):
            continue
        # skip generated HTML wrappers (created by gen-index.py)
        if name.endswith('.html'):
            continue
        size = os.path.getsize(path)
        if size < SIZE_THRESHOLD:
            continue
        rel = os.path.normpath(os.path.abspath(path))
        if rel not in required:
            print(f"[scope-check] large file without manifest entry: {path} ({size} bytes). Add a manifest entry or approve the change.")
            failures += 1
            continue
        expected = required.get(rel)
        if not expected:
            print(f"[scope-check] manifest entry for {rel} missing checksum")
            failures += 1
            continue
        actual = sha256_of(path)
        if actual != expected:
            print(f"[scope-check] checksum mismatch for {rel}: expected {expected}, got {actual}")
            failures += 1

    if failures:
        print(f"[scope-check] {failures} failure(s) detected")
        return False
    print("[scope-check] OK")
    return True

def main():
    if not run_index():
        sys.exit(2)
    manifest = load_manifest()
    ok = check_vendor_manifest(manifest)
    sys.exit(0 if ok else 3)

if __name__ == '__main__':
    main()
