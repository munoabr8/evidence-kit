#!/usr/bin/env python3
"""Produce a static HTML wrapper for an asciinema .cast file.

This creates a lightweight HTML file that contains:
- a human-readable transcript of events inside a <noscript> block
- a "last frame" snapshot rendered as preformatted text

This is intended as a fallback for environments that strip or block scripts
(for example, some capture/storage systems). It does not provide interactive
playback but ensures the recorded output is preserved and viewable.
"""
from pathlib import Path
import json
import sys

def parse_cast(path: Path):
    text = path.read_text(encoding='utf-8', errors='ignore')
    lines = [ln for ln in text.splitlines() if ln.strip() != '']
    if not lines:
        return None, []
    header = json.loads(lines[0])
    events = []
    for ln in lines[1:]:
        try:
            ev = json.loads(ln)
            events.append(ev)
        except Exception:
            # ignore malformed
            continue
    return header, events

def render_transcript(events):
    # events are typically [time, type, data]
    out = []
    for ev in events:
        if not isinstance(ev, list) or len(ev) < 3:
            continue
        t, typ, data = ev[0], ev[1], ev[2]
        if typ == 'o' or typ == 'stdout':
            out.append(f'[{t:.6f}] {data}')
        else:
            out.append(f'[{t:.6f}] ({typ}) {data}')
    return '\n'.join(out)

def last_frame_text(events):
    # naive reconstruction: apply output sequentially and keep the final text
    # This is a minimal approach: treat each 'o' as literal output, join lines
    buf = ''
    for ev in events:
        if not isinstance(ev, list) or len(ev) < 3:
            continue
        typ = ev[1]
        data = ev[2]
        if typ == 'o' or typ == 'stdout':
            buf += data
    # Take last screenful (last 100 lines) to keep output reasonable
    lines = buf.splitlines()
    if len(lines) > 200:
        lines = lines[-200:]
    return '\n'.join(lines)

def main():
    if len(sys.argv) < 2:
        print('usage: embed_cast_static.py <path.cast>')
        sys.exit(2)
    castp = Path(sys.argv[1])
    if not castp.exists():
        print('missing', castp)
        sys.exit(3)
    header, events = parse_cast(castp)
    outp = castp.with_suffix(castp.suffix + '.static.html')
    title = castp.name
    transcript = render_transcript(events)
    last = last_frame_text(events)
    html = f"""<!doctype html>
<meta charset='utf-8'>
<title>{title} (static)</title>
<style>body{{font-family:system-ui,Segoe UI,Arial,sans-serif;margin:16px}}pre{{background:#111;color:#eee;padding:12px;border-radius:6px;overflow:auto}}</style>
<h2>{title} (static fallback)</h2>
<p>This is a static fallback generated from the .cast file. It will display a transcript and the last captured terminal frame if JavaScript is unavailable or stripped.</p>
<noscript>
<h3>Transcript</h3>
<pre>{transcript}</pre>
</noscript>
<h3>Last frame snapshot</h3>
<pre>{last}</pre>
<hr>
<p>Original metadata: {json.dumps(header)}</p>
"""
    outp.write_text(html, encoding='utf-8')
    print('Wrote static wrapper:', outp)

if __name__ == '__main__':
    main()
