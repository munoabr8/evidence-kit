#!/usr/bin/env python3
"""Analyze HTML files for common capture-system transformations that break JS playback.

Checks performed:
- whether <script> tags are present
- whether script srcs contain multiple concatenated URLs (look for multiple 'http' tokens)
- presence of data: URIs
- presence of <meta http-equiv="Content-Security-Policy"> tags
- references to .wasm

Usage: python3 bin/analyze_html_for_hunchly.py <file.html> [...]
"""
import sys
from pathlib import Path
import re

if len(sys.argv) < 2:
    print('usage: analyze_html_for_hunchly.py <html-file> [<html-file> ...]')
    sys.exit(2)

for p in sys.argv[1:]:
    path = Path(p)
    if not path.exists():
        print(p, 'MISSING')
        continue
    text = path.read_text(encoding='utf-8', errors='ignore')
    print('\n==', p, '==')
    # scripts
    scripts = re.findall(r'<script[^>]*>', text, flags=re.I)
    print('SCRIPT_TAGS:', len(scripts))
    # list srcs
    srcs = re.findall(r'<script[^>]*src=["\']([^"\']+)["\']', text, flags=re.I)
    print('SCRIPT_SRCS:', len(srcs))
    for s in srcs:
        n_http = s.count('http')
        print('  -', s, ('(concat?)' if n_http>1 else ''))
    # check for concatenated tokens in whole HTML
    tokens = re.findall(r'["\'">\s]([^"\'>\s]{20,})', text)
    concats = [t for t in tokens if t.count('http')>1 or ('asciinema-glue.js' in t and 'asciinema-player' in t)]
    print('POTENTIAL_CONCATENATED_TOKENS:', len(concats))
    for t in concats[:5]:
        print('  *', t[:240])
    # data URIs
    data_uris = re.findall(r'data:([^"\'\s>]+)', text)
    print('DATA_URIS:', len(data_uris))
    # CSP meta
    csp = re.search(r'<meta[^>]*http-equiv=["\']Content-Security-Policy["\']', text, flags=re.I)
    print('HAS_CSP_META:', bool(csp))
    # wasm references
    wasm = re.search(r'\.wasm', text, flags=re.I)
    print('HAS_WASM_REF:', bool(wasm))
    # show small summary lines
    print('LENGTH_BYTES:', len(text))

print('\nDone')
