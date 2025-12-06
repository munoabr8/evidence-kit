#!/usr/bin/env python3
from pathlib import Path
from gen_index_ctx import set_context, get_art_dir, get_embed_limit
from template import render_template
import os, mimetypes, base64, shutil
from html import escape

mimetypes.init()

def is_text_file(mime):
    return bool(mime) and (
        mime.startswith("text/") or
        mime in ("application/json","application/x-yaml","application/yaml") or
        mime.endswith("+json")
    )

def make_wrapper(name, src_path, mime):
    art_dir = get_art_dir()
    embed_limit = get_embed_limit()

    safe = Path(name).name
    wp = art_dir / f"{safe}.html"
    m = mime or "application/octet-stream"
    size = os.path.getsize(src_path)

    with wp.open("w", encoding="utf-8") as dst:
        if safe.endswith('.cast'):
            local_js  = art_dir / 'asciinema-player.min.js'
            local_css = art_dir / 'asciinema-player.min.css'

            repo_root = Path(__file__).resolve().parent.parent
            media_js  = repo_root / 'media-pack' / 'player' / 'asciinema-player.min.js'
            media_css = repo_root / 'media-pack' / 'player' / 'asciinema-player.min.css'

            try:
                if not local_js.is_file() and media_js.is_file():
                    shutil.copyfile(media_js, local_js)
                if not local_css.is_file() and media_css.is_file():
                    shutil.copyfile(media_css, local_css)
            except Exception:
                pass

            js  = './asciinema-player.min.js' if local_js.is_file() else \
                  'https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.js'
            css = './asciinema-player.min.css' if local_css.is_file() else \
                  'https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.css'

            tpl_path = repo_root / 'templates' / 'cast_wrapper.html.tpl'

            glue_js = ''
            glue_tpl_path = repo_root / 'templates' / 'cast_glue.js.tpl'
            try:
                glue_js = glue_tpl_path.read_text(encoding='utf-8')
            except Exception:
                glue_js = ''

            if glue_js:
                glue_out = glue_js.replace('%%JS%%', js)
                glue_path = art_dir / 'asciinema-glue.js'
                try:
                    glue_path.write_text(glue_out, encoding='utf-8')
                except Exception:
                    pass

            if not glue_js:
                glue_js = ''
            glue_js = glue_js.replace('%%JS%%', js).replace('%%CAST_SRC%%', f'./{safe}')

            rendered = render_template(tpl_path, {
                'TITLE': safe,
                'TITLE_ESC': escape(safe),
                'CSS': css,
                'JS': js,
                'GLUE_JS': glue_js,
                'CAST_SRC': f'./{safe}',
            })
            dst.write(rendered)
            return wp.name
        else:
            dst.write("<!doctype html><meta charset='utf-8'><title>")
            dst.write(escape(safe))
            dst.write("</title><body style='margin:16px;font-family:system-ui,Segoe UI,Arial,sans-serif'>")
            dst.write(f"<h2>{escape(safe)}</h2>\n")

            if is_text_file(m) and size <= embed_limit:
                with open(src_path, "r", errors="replace") as src:
                    dst.write("<pre>")
                    dst.write(escape(src.read()))
                    dst.write("</pre>")
            elif size <= embed_limit:
                with open(src_path, "rb") as src:
                    b64 = base64.b64encode(src.read()).decode("ascii")
                dst.write(
                    f"<iframe src='data:{m};base64,{b64}' "
                    f"style='width:100%;height:80vh;border:1px solid #ccc'></iframe>"
                )
            else:
                dst.write(
                    f"<p>File is large ({size} bytes). Open directly if needed: "
                    f"<a href='{safe}'>open {escape(safe)}</a></p>"
                )

            dst.write("</body>")
            return wp.name

def resolve_art_dir() -> Path:
    script_dir = Path(__file__).resolve().parent        # .../evidence-kit/bin
    project_root = script_dir.parent                    # .../evidence-kit

    env = os.getenv("ART_DIR")
    if env:
        p = Path(env)
        if not p.is_absolute():
            # interpret relative ART_DIR from project root, NOT CWD
            p = project_root / p
        return p.resolve()

    # default when ART_DIR is unset
    return (project_root / "artifacts").resolve()

def main():
    art_dir = resolve_art_dir()
    art_dir.mkdir(parents=True, exist_ok=True)
    set_context(art_dir, int(os.getenv("EMBED_LIMIT_BYTES","1048576")))

    index_path = art_dir / "index.html"

    if not str(index_path.resolve()).startswith(str(art_dir.resolve()) + os.sep):
        raise RuntimeError("index_path must be within ART_DIR")

    artifact_names = set()
    for name in os.listdir(art_dir):
        src_path = art_dir / name
        if src_path.is_file() and not str(name).endswith('.html'):
            artifact_names.add(Path(name).name)

    for name in os.listdir(art_dir):
        if str(name).endswith('.html') and name != 'index.html':
            base = str(name)[:-5]
            if base not in artifact_names:
                try:
                    (art_dir / name).unlink()
                    print(f"[index] removed obsolete wrapper: {name}")
                except Exception as e:
                    print(f"[index] failed to remove {name}: {e}")

    links = []
    for name in sorted(os.listdir(art_dir)):
        src_path = art_dir / name
        if src_path.is_dir():
            links.append(f'<li><a href="{name}/">{name}/</a> (dir)</li>')
            continue
        if not src_path.is_file() or str(name).endswith('.html'):
            continue

        mime, _ = mimetypes.guess_type(str(src_path))
        wrapper = make_wrapper(name, str(src_path), mime)
        size = src_path.stat().st_size
        label = "text" if is_text_file(mime) else (mime or "binary")
        links.append(f'<li><a href="{wrapper}">{name}</a> ({label}, {size} bytes)</li>')

    with index_path.open("w", encoding="utf-8") as idx:
        idx.write("<!doctype html><meta charset='utf-8'><body>"
                  "<h1>Artifacts Index</h1><ul>")
        idx.write("".join(links))
        idx.write("</ul></body>")
    print(f"[index] --wrote {index_path} with {len(links)} entries")

if __name__ == "__main__":
    main()