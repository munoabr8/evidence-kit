#!/usr/bin/env python3
"""Package asciinema cast artifacts for Hunchly ingestion.

For each <name>.cast, this script will produce:
 - <name>.selfcontained.html (via bin/embed_cast.py)
 - <name>.static.html (via bin/embed_cast_static.py)
 - <name>.hunchly.zip containing the three files

Usage: python3 bin/package_for_hunchly.py [artifacts/*.cast]
If no args provided, processes all .cast files under artifacts/.
"""
import sys
import subprocess
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artifacts'
BIN = ROOT / 'bin'

def run(cmd):
    print('RUN:', ' '.join(cmd))
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if r.returncode != 0:
        print('ERR:', r.stderr)
    return r

def package_cast(castp: Path):
    name = castp.stem
    selfcontained = ART / f'{name}.selfcontained.html'
    static = ART / f'{name}.static.html'
    zipf = ART / f'{name}.hunchly.zip'

    # 1) create self-contained
    run([sys.executable, str(BIN / 'embed_cast.py'), str(castp), str(selfcontained)])
    # 2) create static fallback
    run([sys.executable, str(BIN / 'embed_cast_static.py'), str(castp)])

    # 3) create zip
    with zipfile.ZipFile(zipf, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        z.write(castp, arcname=castp.name)
        if selfcontained.exists(): z.write(selfcontained, arcname=selfcontained.name)
        if static.exists(): z.write(static, arcname=static.name)

    print('Wrote package:', zipf)
    return zipf

def main():
    args = sys.argv[1:]
    if not args:
        casts = list(ART.glob('*.cast'))
    else:
        casts = [Path(a) for a in args]
    if not casts:
        print('No casts found')
        sys.exit(1)
    for c in casts:
        if not c.exists():
            print('Missing', c)
            continue
        package_cast(c)

if __name__ == '__main__':
    main()
