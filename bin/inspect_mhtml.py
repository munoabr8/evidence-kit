#!/usr/bin/env python3
"""Inspect an MHTML file: list embedded parts and extract the text/html part.

Usage: python3 bin/inspect_mhtml.py path/to/exported.mhtml
"""
import sys
from email import message_from_file
from pathlib import Path

if len(sys.argv) < 2:
    print('usage: inspect_mhtml.py exported.mhtml')
    sys.exit(2)

path = Path(sys.argv[1])
if not path.exists():
    print('MISSING', path)
    sys.exit(3)

f = path.open('r', encoding='utf-8', errors='ignore')
msg = message_from_file(f)

out_html = Path('artifacts/exported_extracted.html')
found_html = 0
parts = []
for i, part in enumerate(msg.walk()):
    ctype = part.get_content_type()
    cloc = part.get('Content-Location') or part.get('Content-Id') or ''
    payload = part.get_payload(decode=True)
    size = len(payload) if payload is not None else 0
    parts.append((i, ctype, cloc, size))
    if ctype == 'text/html' and not found_html:
        try:
            text = payload.decode(part.get_content_charset('utf-8') or 'utf-8', errors='replace')
        except Exception:
            text = payload.decode('utf-8', errors='replace') if payload else ''
        out_html.write_text(text, encoding='utf-8')
        found_html = 1

print('MHTML PARTS SUMMARY:')
for idx, ctype, cloc, size in parts:
    print(f'  part#{idx}: type={ctype} loc="{cloc}" size={size}')

if found_html:
    print('\nExtracted HTML written to:', out_html)
else:
    print('\nNo text/html part found in MHTML')

print('\nDone')
