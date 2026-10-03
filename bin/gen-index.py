#!/usr/bin/env python3
from pathlib import Path
from gen_index_ctx import set_context, get_art_dir, get_embed_limit
from template import render_template
from html import escape

from contexts import IndexContext
import argparse
import base64
import mimetypes
import os
import shutil


mimetypes.init()


WRAPPABLE_SUFFIXES = {".cast", ".log", ".txt"}
RAW_SUFFIXES = {".js", ".css", ".json"}

ROLE_DIRS = {
    "captures": "cast",
    "metadata": "metadata",
    "fixtures": "fixtures",
    "logs": "logs",
    "plans": "plans",
    "assets": "assets",
}


def is_text_file(mime: str | None) -> bool:
    return bool(mime) and (
        mime.startswith("text/")
        or mime in ("application/json", "application/x-yaml", "application/yaml")
        or mime.endswith("+json")
    )


def should_link_raw(path: Path, mime: str | None) -> bool:
    return path.suffix in RAW_SUFFIXES


def is_wrappable(path: Path) -> bool:
    return path.suffix in WRAPPABLE_SUFFIXES


def iter_artifacts(art_dir: Path):
    """
    Yield artifact files from known role directories.

    Yields:
        tuple[str, Path, Path]
        role, absolute/relative source path, path relative to art_dir
    """

    for role, dirname in ROLE_DIRS.items():
        directory = art_dir / dirname

        if not directory.exists():
            continue

        for path in sorted(directory.rglob("*")):
            if not path.is_file():
                continue

            if path.suffix == ".html":
                continue

            rel_path = path.relative_to(art_dir)
            yield role, path, rel_path

    # Temporary migration fallback:
    # still include files directly under artifacts/
    # so older smoke tests do not silently disappear from the index.
    for path in sorted(art_dir.iterdir()):
        if not path.is_file():
            continue

        if path.name == "index.html":
            continue

        if path.suffix == ".html":
            continue

        rel_path = path.relative_to(art_dir)
        yield "root", path, rel_path


def copy_player_assets(art_dir: Path, repo_root: Path, wrapper_dir: Path):
    """
    Ensure local asciinema player assets exist, then return href paths
    relative to the wrapper directory.
    """

    assets_dir = art_dir / "assets"
    assets_dir.mkdir(parents=True, exist_ok=True)

    local_js = assets_dir / "asciinema-player.min.js"
    local_css = assets_dir / "asciinema-player.min.css"

    media_js = repo_root / "media-pack" / "player" / "asciinema-player.min.js"
    media_css = repo_root / "media-pack" / "player" / "asciinema-player.min.css"

    try:
        if not local_js.is_file() and media_js.is_file():
            shutil.copyfile(media_js, local_js)

        if not local_css.is_file() and media_css.is_file():
            shutil.copyfile(media_css, local_css)

    except Exception:
        pass

    if local_js.is_file():
        js = os.path.relpath(local_js, start=wrapper_dir)
    else:
        js = "https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.js"

    if local_css.is_file():
        css = os.path.relpath(local_css, start=wrapper_dir)
    else:
        css = "https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.css"

    return js, css


def make_wrapper(
    rel_path: Path,
    src_path: Path,
    mime: str | None,
    *,
    ctx: IndexContext,
):
    art_dir = ctx.art_dir
    embed_limit = ctx.embed_limit

    """
    Generate an HTML wrapper under artifacts/views/.

    The views directory mirrors the artifact role directory.

    Example:
        artifacts/cast/hello.cast
        -> artifacts/views/cast/hello.cast.html
    """

    #art_dir = get_art_dir()
    #embed_limit = get_embed_limit()

    views_dir = art_dir / "views" / rel_path.parent
    views_dir.mkdir(parents=True, exist_ok=True)

    safe_name = rel_path.name
    wrapper_path = views_dir / f"{safe_name}.html"

    mime_type = mime or "application/octet-stream"
    size = src_path.stat().st_size

    src_href = os.path.relpath(src_path, start=wrapper_path.parent)

    repo_root = Path(__file__).resolve().parent.parent

    with wrapper_path.open("w", encoding="utf-8") as dst:
        if safe_name.endswith(".cast"):
            js, css = copy_player_assets(
                    art_dir=art_dir,
                    repo_root=repo_root,
                    wrapper_dir=wrapper_path.parent,
                    )


            tpl_path = repo_root / "templates" / "cast_wrapper.html.tpl"

            glue_js = ""
            glue_tpl_path = repo_root / "templates" / "cast_glue.js.tpl"

            try:
                glue_js = glue_tpl_path.read_text(encoding="utf-8")
            except Exception:
                glue_js = ""

            if glue_js:
                glue_out = glue_js.replace("%%JS%%", js).replace("%%CAST_SRC%%", src_href)
                glue_path = art_dir / "assets" / "asciinema-glue.js"

                try:
                    glue_path.write_text(glue_out, encoding="utf-8")
                except Exception:
                    pass

            rendered = render_template(
                tpl_path,
                {
                    "TITLE": safe_name,
                    "TITLE_ESC": escape(safe_name),
                    "CSS": css,
                    "JS": js,
                    "GLUE_JS": glue_js.replace("%%JS%%", js).replace("%%CAST_SRC%%", src_href),
                    "CAST_SRC": src_href,
                },
            )

            dst.write(rendered)
            return wrapper_path.relative_to(art_dir).as_posix()

        dst.write("<!doctype html><meta charset='utf-8'><title>")
        dst.write(escape(safe_name))
        dst.write("</title><body style='margin:16px;font-family:system-ui,Segoe UI,Arial,sans-serif'>")
        dst.write(f"<h2>{escape(safe_name)}</h2>\n")

        if is_text_file(mime_type) and size <= embed_limit:
            with src_path.open("r", errors="replace") as src:
                dst.write("<pre>")
                dst.write(escape(src.read()))
                dst.write("</pre>")

        elif size <= embed_limit:
            with src_path.open("rb") as src:
                b64 = base64.b64encode(src.read()).decode("ascii")

            dst.write(
                f"<iframe src='data:{mime_type};base64,{b64}' "
                f"style='width:100%;height:80vh;border:1px solid #ccc'></iframe>"
            )

        else:
            dst.write(
                f"<p>File is large ({size} bytes). Open directly if needed: "
                f"<a href='{escape(src_href)}'>open {escape(safe_name)}</a></p>"
            )

        dst.write("</body>")

    return wrapper_path.relative_to(art_dir).as_posix()


def remove_obsolete_wrappers(art_dir: Path):
    """
    Remove HTML wrappers under artifacts/views/ that no longer have
    a corresponding base artifact.
    """

    views_dir = art_dir / "views"

    if not views_dir.exists():
        return

    for wrapper_path in views_dir.rglob("*.html"):
        base_rel = wrapper_path.relative_to(views_dir)
        base_name = base_rel.name[:-5]  # strip ".html"
        base_rel = base_rel.with_name(base_name)
        base_path = art_dir / base_rel

        if not base_path.exists():
            print(f"[cleanup] removing orphan wrapper: {wrapper_path.relative_to(art_dir)}")
            wrapper_path.unlink()
            continue

        if base_path.suffix in RAW_SUFFIXES:
            print(f"[cleanup] removing invalid raw-asset wrapper: {wrapper_path.relative_to(art_dir)}")
            wrapper_path.unlink()
            continue

        if base_path.suffix not in WRAPPABLE_SUFFIXES:
            print(f"[cleanup] removing unknown wrapper type: {wrapper_path.relative_to(art_dir)}")
            wrapper_path.unlink()
            continue


def build_index_link(art_dir: Path, rel_path: Path, src_path: Path, mime: str | None):
    size = src_path.stat().st_size
    label = "text" if is_text_file(mime) else (mime or "binary")
    name = rel_path.as_posix()

    if should_link_raw(src_path, mime):
        href = name
    elif is_wrappable(src_path):
        href = (Path("views") / rel_path.parent / f"{rel_path.name}.html").as_posix()
    else:
        href = name

    return f'<li><a href="{escape(href)}">{escape(name)}</a> ({escape(label)}, {size} bytes)</li>'


def build_directory_links(art_dir: Path):
    links = []

    for path in sorted(art_dir.iterdir()):
        if not path.is_dir():
            continue

        name = path.name

        if name == "views":
            links.append(f'<li><a href="{name}/">{name}/</a> (generated views)</li>')
        else:
            links.append(f'<li><a href="{name}/">{name}/</a> (dir)</li>')

    return links


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--art-dir", default=os.environ.get("ART_DIR", "artifacts"))
    parser.add_argument(
        "--embed-limit-bytes",
        type=int,
        default=int(os.environ.get("EMBED_LIMIT_BYTES", "1048576")),
    )

    args = parser.parse_args()

    art_dir = Path(args.art_dir)
    art_dir.mkdir(parents=True, exist_ok=True)

    for dirname in ROLE_DIRS.values():
        (art_dir / dirname).mkdir(parents=True, exist_ok=True)

    (art_dir / "views").mkdir(parents=True, exist_ok=True)

    set_context(art_dir=art_dir, embed_limit=args.embed_limit_bytes)

    ctx = IndexContext(
        art_dir=get_art_dir(),
        embed_limit=get_embed_limit(),
    )

    # Generate wrappers for previewable artifacts.
    for role, src_path, rel_path in iter_artifacts(art_dir):
        mime, _ = mimetypes.guess_type(str(src_path))

        if is_wrappable(src_path):
            make_wrapper(
                rel_path=rel_path,
                src_path=src_path,
                mime=mime,
                ctx=ctx,
            )
    remove_obsolete_wrappers(art_dir)

    links = []
    links.extend(build_directory_links(art_dir))

    for role, src_path, rel_path in iter_artifacts(art_dir):
        mime, _ = mimetypes.guess_type(str(src_path))
        links.append(build_index_link(art_dir, rel_path, src_path, mime))

    index_path = art_dir / "index.html"

    with index_path.open("w", encoding="utf-8") as idx:
        idx.write("<!doctype html><meta charset='utf-8'>")
        idx.write("<body><h1>Artifacts Index</h1><ul>")
        idx.write("".join(links))
        idx.write("</ul></body>")


if __name__ == "__main__":
    main()