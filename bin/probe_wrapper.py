import runpy
from pathlib import Path
from tempfile import TemporaryDirectory

from contexts import IndexContext

module = runpy.run_path(str(Path(__file__).with_name("gen-index.py")))
make_wrapper = module["make_wrapper"]

with TemporaryDirectory() as tmp:
    art_dir = Path(tmp)
    rel_path = Path("logs/example.txt")
    src_path = art_dir / rel_path
    src_path.parent.mkdir(parents=True)
    src_path.write_bytes(b"hello")
    expected_wrapper = art_dir / "views/logs/example.txt.html"

    # At the limit: embed the text.
    result = make_wrapper(
        rel_path, src_path, "text/plain",
        ctx=IndexContext(art_dir=art_dir, embed_limit=5),
    )

    assert art_dir / result == expected_wrapper
    html = expected_wrapper.read_text(encoding="utf-8")
    assert "<pre>hello</pre>" in html
    assert "File is large" not in html
    print("PASS: supplied directory and embedding at the limit")

    # Below the file size: provide a link instead.
    make_wrapper(
        rel_path, src_path, "text/plain",
        ctx=IndexContext(art_dir=art_dir, embed_limit=4),
    )

    html = expected_wrapper.read_text(encoding="utf-8")
    assert "File is large" in html
    assert "<pre>" not in html
    assert "../../logs/example.txt" in html
    print("PASS: supplied embed limit and relative link")

 

with TemporaryDirectory() as tmp:
    art_dir = Path(tmp)
    rel_path = Path("cast/example.cast")
    src_path = art_dir / rel_path
    src_path.parent.mkdir(parents=True)

    # Minimal asciinema v2 recording.
    src_path.write_text(
        '{"version":2,"width":80,"height":24}\n'
        '[0.0,"o","hello\\r\\n"]\n',
        encoding="utf-8",
    )

    result = make_wrapper(
        rel_path, src_path, "application/x-asciicast",
        ctx=IndexContext(art_dir=art_dir, embed_limit=1),
    )

    expected_wrapper = art_dir / "views/cast/example.cast.html"
    assert art_dir / result == expected_wrapper

    html = expected_wrapper.read_text(encoding="utf-8")
    assert "example.cast" in html
    assert "../../cast/example.cast" in html
    assert "asciinema-player" in html
    assert "File is large" not in html

    print("PASS: cast wrapper location, recording link, and player reference")
    print("Wrapper checks passed")
