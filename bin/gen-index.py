#!/usr/bin/env python3
import os, mimetypes, base64
from html import escape

ART_DIR = os.environ.get("ART_DIR", "artifacts")
INDEX_PATH = os.path.join(ART_DIR, "index.html")
EMBED_LIMIT = int(os.environ.get("EMBED_LIMIT_BYTES", "1048576"))  # 1 MB

def is_text_file(mime):
    return bool(mime) and (
        mime.startswith("text/") or
        mime in ("application/json","application/x-yaml","application/yaml") or
        mime.endswith("+json")
    )

def make_wrapper(name, path, mime):
    wrapper = f"{name}.html"
    wp = os.path.join(ART_DIR, wrapper)
    m = mime or "application/octet-stream"
    size = os.path.getsize(path)

    with open(wp, "w") as dst:
        dst.write("<!doctype html><meta charset='utf-8'><title>")
        dst.write(escape(name))
        dst.write("</title><body style='margin:16px;font-family:system-ui,Segoe UI,Arial,sans-serif'>")
        dst.write(f"<h2>{escape(name)}</h2>\n")

        if is_text_file(m) and size <= EMBED_LIMIT:
            with open(path, "r", errors="replace") as src:
                dst.write("<pre>")
                dst.write(escape(src.read()))
                dst.write("</pre>")
        elif size <= EMBED_LIMIT:
            with open(path, "rb") as src:
                b64 = base64.b64encode(src.read()).decode("ascii")
            # iframe tends to avoid download prompts better than <object> in some setups
            dst.write(f"<iframe src='data:{m};base64,{b64}' "
                      f"style='width:100%;height:80vh;border:1px solid #ccc'></iframe>")
        else:
            # too large to embed: still avoid forced download by preview hint
            dst.write(f"<p>File is large ({size} bytes). Open directly if needed: "
                      f"<a href='{name}'>open {escape(name)}</a></p>")

        dst.write("</body>")
    return wrapper
    
def main():
    if not os.path.isdir(ART_DIR):
        print(f"[index] artifacts dir not found: {ART_DIR}")
        return

    # Step 1: Collect current artifact names (excluding directories and .html files)
    artifact_names = set()
    for name in os.listdir(ART_DIR):
        path = os.path.join(ART_DIR, name)
        if os.path.isfile(path) and not name.endswith('.html'):
            artifact_names.add(name)

    # Step 2: Remove obsolete .html wrapper files (excluding index.html)
    for name in os.listdir(ART_DIR):
        if name.endswith('.html') and name != 'index.html':
            # Only keep wrappers for current artifacts
            base = name[:-5]  # remove .html
            if base not in artifact_names:
                try:
                    os.remove(os.path.join(ART_DIR, name))
                    print(f"[index] removed obsolete wrapper: {name}")
                except Exception as e:
                    print(f"[index] failed to remove {name}: {e}")

    links = []
    for name in sorted(os.listdir(ART_DIR)):
        path = os.path.join(ART_DIR, name)
        if os.path.isdir(path):  # show dirs
            links.append(f'<li><a href="{name}/">{name}/</a> (dir)</li>')
            continue
        if not os.path.isfile(path) or name.endswith('.html'):
            continue

        mime, _ = mimetypes.guess_type(path)
        wrapper = make_wrapper(name, path, mime)
        size = os.path.getsize(path)
        label = "text" if is_text_file(mime) else (mime or "binary")
        links.append(f'<li><a href="{wrapper}">{name}</a> ({label}, {size} bytes)</li>')

    with open(INDEX_PATH, "w") as idx:
        idx.write("<!doctype html><meta charset='utf-8'><body>"
                  "<h1>Artifacts Index</h1><ul>")
        idx.write("".join(links))
        idx.write("</ul></body>")
    print(f"[index] wrote {INDEX_PATH} with {len(links)} entries")

if __name__ == "__main__":
    main()
