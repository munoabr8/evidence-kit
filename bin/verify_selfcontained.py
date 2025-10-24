#!/usr/bin/env python3
"""Verify embedded cast in self-contained asciinema wrapper.

Prints whether a data:application/octet-stream;base64 source exists, decodes it,
parses JSON, and prints basic metadata.
"""
import re
import base64
import json
import sys
from pathlib import Path

p = Path('artifacts/smoke.cast.selfcontained.html')
if not p.exists():
    print('FILE_MISSING', p)
    sys.exit(2)

html = p.read_text(encoding='utf-8', errors='ignore')
# Find asciinema-player src with base64 payload
m = re.search(r'<asciinema-player[^>]*src="data:application/octet-stream;base64,([^" >]+)"', html)
if not m:
    print('EMBED_NOT_FOUND')
    sys.exit(3)

b64 = m.group(1)
try:
    raw = base64.b64decode(b64)
except Exception as e:
    print('BASE64_DECODE_ERROR', e)
    sys.exit(4)

print('DECODED_BYTES', len(raw))
# Asciinema v2 often stores a JSON header on the first line, followed by newline-delimited
# event arrays. We'll attempt to parse that form: first line -> header JSON, remaining
# lines -> events (each line is a JSON array). If payload is pure JSON, fall back to that.
text = None
try:
    text = raw.decode('utf-8')
except Exception:
    print('RAW_NOT_UTF8')
    sys.exit(6)

# Split into lines and try parsing the first line as header
lines = [ln for ln in text.splitlines() if ln.strip() != '']
if not lines:
    print('NO_LINES')
    sys.exit(7)

try:
    header = json.loads(lines[0])
    print('HEADER_KEYS', list(header.keys()))
    for k in ('version', 'width', 'height', 'duration', 'env'):
        if k in header:
            print(f'{k.upper()}:', header[k])
    # parse remaining lines as events
    events = []
    for ln in lines[1:]:
        try:
            ev = json.loads(ln)
            events.append(ev)
        except Exception:
            # ignore malformed event lines but report
            print('EVENT_LINE_PARSE_FAIL', ln[:120])
    print('EVENT_COUNT', len(events))
    if events:
        print('FIRST_EVENT', events[0])
    print('OK')
    sys.exit(0)
except Exception:
    # Not the header+lines format. Try parse raw as JSON document.
    try:
        j = json.loads(text)
        print('JSON_TOP_KEYS', list(j.keys()))
        for k in ('version', 'width', 'height', 'duration', 'env'):
            if k in j:
                print(f'{k.upper()}:', j[k])
        # attempt to find events
        events = j.get('stdout') or j.get('events') or j.get('events', None)
        if isinstance(events, list):
            print('EVENT_COUNT', len(events))
            if events:
                print('FIRST_EVENT', events[0])
        else:
            print('EVENTS_FIELD_TYPE', type(events))
        print('OK')
        sys.exit(0)
    except Exception as e:
        print('JSON_PARSE_ERROR', e)
        preview = text[:400]
        print('PREVIEW', preview)
        sys.exit(5)
