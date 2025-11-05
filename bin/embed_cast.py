#!/usr/bin/env python3
"""Create a self-contained HTML wrapper for an asciinema .cast file.

Usage: python3 bin/embed_cast.py <input.cast> <output.html>

The output will inline asciinema-player JS and CSS (prefers local files under
artifacts/, falls back to CDN), and embed the cast as a data: URL so the HTML
is portable and can be captured by tools like Hunchly.
"""
import sys
import os
import base64
import urllib.request

ROOT = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
ART = os.path.join(ROOT, 'artifacts')

CDN_BASE = 'https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist'
JS_CDN = f'{CDN_BASE}/asciinema-player.min.js'
CSS_CDN = f'{CDN_BASE}/asciinema-player.min.css'


def read_local_or_fetch(path, url):
    if os.path.isfile(path):
        with open(path, 'r', encoding='utf-8', errors='replace') as fh:
            return fh.read()
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            return r.read().decode('utf-8')
    except Exception:
        return ''


def make_data_url(path):
    with open(path, 'rb') as fh:
        data = fh.read()
    b64 = base64.b64encode(data).decode('ascii')
    # asciinema casts are generally text, but treat as octet-stream for safety
    return f'data:application/octet-stream;base64,{b64}'


HTML_TMPL = """<!doctype html>
<meta charset='utf-8'>
<title>{title}</title>
<style>
{css}
</style>
<body style='margin:16px;font-family:system-ui,Segoe UI,Arial,sans-serif'>
<h2>{title}</h2>
<script>
{js}
</script>
<asciinema-player src="{cast_data}" preload style='width:100%;height:80vh'></asciinema-player>
</body>
"""


def main():
    if len(sys.argv) < 3:
        print('Usage: embed_cast.py <input.cast> <output.html>')
        sys.exit(2)
    inp = sys.argv[1]
    out = sys.argv[2]
    if not os.path.isfile(inp):
        print('Input not found:', inp)
        sys.exit(3)

    js_path = os.path.join(ART, 'asciinema-player.min.js')
    css_path = os.path.join(ART, 'asciinema-player.min.css')

    js = read_local_or_fetch(js_path, JS_CDN)
    css = read_local_or_fetch(css_path, CSS_CDN)

    if not js:
        print('Warning: could not find or fetch asciinema-player JS; output may not play.')
    if not css:
        print('Warning: could not find or fetch asciinema-player CSS; output may not style correctly.')

    cast_data = make_data_url(inp)

    title = os.path.basename(inp)
    html = HTML_TMPL.format(title=title, css=css, js=js, cast_data=cast_data)

    with open(out, 'w', encoding='utf-8') as fh:
        fh.write(html)

    print('Wrote self-contained wrapper:', out)


if __name__ == '__main__':
    main()
