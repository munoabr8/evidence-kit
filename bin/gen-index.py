#!/usr/bin/env python3
import os, mimetypes, base64, sys
from html import escape
# Ensure we can import the sibling `template.py` when running this script directly.
sys.path.insert(0, os.path.dirname(__file__))
from template import render_template
# Ensure we can import the sibling `template.py` when running this script directly.
sys.path.insert(0, os.path.dirname(__file__))
from template import render_template

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
        # Special-case asciinema casts (.cast) — render a standalone wrapper
        # from the template (the template contains the full document). For
        # non-cast artifacts we continue to write a simple document wrapper
        # and embed the artifact content.
        # Special-case asciinema casts (.cast) — render a standalone wrapper
        # from the template (the template contains the full document). For
        # non-cast artifacts we continue to write a simple document wrapper
        # and embed the artifact content.
        if name.endswith('.cast'):
            # Prefer local vendored player files in artifacts/ when present.
            # If the files exist under the old `media-pack/player/` layout (migration
            # state), copy them into the artifacts dir so the local server (which
            # serves from artifacts/) can serve them at ./asciinema-player.min.js
            local_js = os.path.join(ART_DIR, 'asciinema-player.min.js')
            local_css = os.path.join(ART_DIR, 'asciinema-player.min.css')
            repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
            media_js = os.path.join(repo_root, 'media-pack', 'player', 'asciinema-player.min.js')
            media_css = os.path.join(repo_root, 'media-pack', 'player', 'asciinema-player.min.css')

            # If local artifact copies are missing but media-pack has them, copy them
            # into ART_DIR so wrappers can reference them as ./asciinema-player.min.js
            try:
                if not os.path.isfile(local_js) and os.path.isfile(media_js):
                    shutil.copyfile(media_js, local_js)
                if not os.path.isfile(local_css) and os.path.isfile(media_css):
                    shutil.copyfile(media_css, local_css)
            except Exception:
                # Best-effort; do not fail the index generation for copy errors.
                pass

            if os.path.isfile(local_js):
                js = './asciinema-player.min.js'
            else:
                js = 'https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.js'
            if os.path.isfile(local_css):
                css = './asciinema-player.min.css'
            else:
                css = 'https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.css'

            # Render the cast wrapper from a template for readability.
            tpl_path = os.path.join(os.path.dirname(__file__), '..', 'templates', 'cast_wrapper.html.tpl')
            glue_js = ''
            # Load glue JS from a separate template and write it to artifacts so
            # wrappers can reference a centralized `asciinema-glue.js` (cacheable).
            glue_tpl_path = os.path.join(os.path.dirname(__file__), '..', 'templates', 'cast_glue.js.tpl')
            try:
                with open(glue_tpl_path, 'r', encoding='utf-8') as gf:
                    glue_js = gf.read()
            except Exception:
                glue_js = ''

            # If we have glue_js content, render it (substitute %%JS%%) and
            # write a centralized artifacts/asciinema-glue.js file.
            if glue_js:
                glue_out = glue_js.replace('%%JS%%', js)
                glue_path = os.path.join(ART_DIR, 'asciinema-glue.js')
                try:
                    with open(glue_path, 'w', encoding='utf-8') as go:
                        go.write(glue_out)
                except Exception:
                    pass
            # For backward compatibility keep the inline glue logic local-only when
            # using a vendored JS file. The template will contain a placeholder
            # where the glue JS will be inserted.
            # If the vendored local JS exists, we will attempt the glue logic; if
            # glue_js is empty the template will still render but without the
            # programmatic fallback.
            if not glue_js:
                glue_js = ''

            # Substitute any placeholders inside the glue_js before rendering
            # the template so tokens like %%JS%% are resolved. We still keep the
            # local `glue_js` var for compatibility but wrappers will reference
            # the centralized `asciinema-glue.js` we wrote above.
            glue_js = glue_js.replace('%%JS%%', js).replace('%%CAST_SRC%%', f'./{name}')

            rendered = render_template(tpl_path, {
                'TITLE': name,
                'TITLE_ESC': escape(name),
                'CSS': css,
                'JS': js,
                'GLUE_JS': glue_js,
                'CAST_SRC': f'./{name}',
            })
            dst.write(rendered)
            # The template contains a full document including the closing </body>,
            # so return early to avoid appending another closing tag below.
            return wrapper
        else:
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
            # Render the cast wrapper from a template for readability.
            tpl_path = os.path.join(os.path.dirname(__file__), '..', 'templates', 'cast_wrapper.html.tpl')
            glue_js = ''
            # Load glue JS from a separate template and write it to artifacts so
            # wrappers can reference a centralized `asciinema-glue.js` (cacheable).
            glue_tpl_path = os.path.join(os.path.dirname(__file__), '..', 'templates', 'cast_glue.js.tpl')
            try:
                with open(glue_tpl_path, 'r', encoding='utf-8') as gf:
                    glue_js = gf.read()
            except Exception:
                glue_js = ''

            # If we have glue_js content, render it (substitute %%JS%%) and
            # write a centralized artifacts/asciinema-glue.js file.
            if glue_js:
                glue_out = glue_js.replace('%%JS%%', js)
                glue_path = os.path.join(ART_DIR, 'asciinema-glue.js')
                try:
                    with open(glue_path, 'w', encoding='utf-8') as go:
                        go.write(glue_out)
                except Exception:
                    pass
            # For backward compatibility keep the inline glue logic local-only when
            # using a vendored JS file. The template will contain a placeholder
            # where the glue JS will be inserted.
            # If the vendored local JS exists, we will attempt the glue logic; if
            # glue_js is empty the template will still render but without the
            # programmatic fallback.
            if not glue_js:
                glue_js = ''

            # Substitute any placeholders inside the glue_js before rendering
            # the template so tokens like %%JS%% are resolved. We still keep the
            # local `glue_js` var for compatibility but wrappers will reference
            # the centralized `asciinema-glue.js` we wrote above.
            glue_js = glue_js.replace('%%JS%%', js).replace('%%CAST_SRC%%', f'./{name}')

            rendered = render_template(tpl_path, {
                'TITLE': name,
                'TITLE_ESC': escape(name),
                'CSS': css,
                'JS': js,
                'GLUE_JS': glue_js,
                'CAST_SRC': f'./{name}',
            })
            dst.write(rendered)
            # The template contains a full document including the closing </body>,
            # so return early to avoid appending another closing tag below.
            return wrapper
        else:
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
