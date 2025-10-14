#!/usr/bin/env python3
#./bin/gen-index.py
import os
import mimetypes
from html import escape

ART_DIR = os.environ.get("ART_DIR", "artifacts")
INDEX_PATH = os.path.join(ART_DIR, "index.html")

def is_text_file(mime):
    if not mime:
        return False
    return (
        mime.startswith("text/") or
        mime == "application/json" or
        mime.endswith("+json") or
        mime in ["application/x-yaml", "application/yaml"]
    )

def main():
    if not os.path.isdir(ART_DIR):
        print(f"[index] artifacts dir not found: {ART_DIR}")
        return

    files = sorted(os.listdir(ART_DIR))
    links = []

    for f in files:
        full_path = os.path.join(ART_DIR, f)
        if not os.path.isfile(full_path):
            continue

        mime, _ = mimetypes.guess_type(full_path)
        size = os.path.getsize(full_path)

        # If already HTML, just link to it
        if mime == "text/html":
            links.append(f'<li><a href="{f}" target="_blank">{f}</a> (HTML, {size} bytes)</li>')
            continue

        # If text-like, wrap it into an HTML file
        if is_text_file(mime):
            wrapper_name = f"{f}.html"
            wrapper_path = os.path.join(ART_DIR, wrapper_name)

            with open(full_path, "r", errors="replace") as src, open(wrapper_path, "w") as dst:
                content = escape(src.read())
                dst.write(f"<!doctype html><html><body><pre>{content}</pre></body></html>")

            links.append(f'<li><a href="{wrapper_name}" target="_blank">{f}</a> (text, {size} bytes)</li>')
        
        else:
            # Just link directly (browser may download or render)
            links.append(f'<li><a href="{f}" target="_blank">{f}</a> ({mime or 'unknown'}, {size} bytes)</li>')

    # Write the index.html
    with open(INDEX_PATH, "w") as idx:
        idx.write("<!doctype html><html><body>\n")
        idx.write("<h1>Artifacts Index</h1>\n<ul>\n")
        for link in links:
            idx.write(link + "\n")
        idx.write("</ul>\n</body></html>\n")

    print(f"[index] wrote {INDEX_PATH} with {len(links)} entries")

if __name__ == "__main__":
    main()
