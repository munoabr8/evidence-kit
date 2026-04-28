import os
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = os.path.dirname(os.path.dirname(__file__))
GEN = os.path.join(ROOT, 'bin', 'gen-index.py')


def run_gen(tmpdir, extra_env=None):
    env = os.environ.copy()
    env['ART_DIR'] = str(tmpdir)
    if extra_env:
        env.update(extra_env)
    subprocess.check_call([sys.executable, GEN], env=env, cwd=ROOT)


# ---------------------------------------------------------------------------
# Baseline / happy-path
# ---------------------------------------------------------------------------

def test_gen_index_happy_path(tmp_path):
    """Small text artifact gets a wrapper and appears in index."""
    art = tmp_path
    (art / 'small.txt').write_text('hello world')
    run_gen(art)
    assert (art / 'index.html').exists()
    assert (art / 'small.txt.html').exists()


def test_gen_index_large_binary(tmp_path):
    """Binary files are not wrapped (not in WRAP_SUFFIXES) but do appear in index.html."""
    art = tmp_path
    big = art / 'big.bin'
    big.write_bytes(b'\x00' * (2 * 1024 * 1024))
    run_gen(art)
    idx = art / 'index.html'
    assert idx.exists()
    # .bin is not a wrappable type — no wrapper should be created
    assert not (art / 'big.bin.html').exists()
    # The file should still be listed in the index (direct link)
    assert 'big.bin' in idx.read_text(encoding='utf-8')


# ---------------------------------------------------------------------------
# Edge-case / stress tests
# ---------------------------------------------------------------------------

def test_empty_artifacts_dir(tmp_path):
    """Generator handles an empty directory without crashing."""
    run_gen(tmp_path)
    assert (tmp_path / 'index.html').exists()


def test_many_files(tmp_path):
    """Generator handles 50+ files and lists all of them in the index."""
    for i in range(50):
        (tmp_path / f'note_{i:03d}.txt').write_text(f'file {i}')
    run_gen(tmp_path)
    idx_text = (tmp_path / 'index.html').read_text(encoding='utf-8')
    for i in range(50):
        assert f'note_{i:03d}.txt' in idx_text
    # Each .txt file should have a wrapper
    for i in range(50):
        assert (tmp_path / f'note_{i:03d}.txt.html').exists()


def test_unicode_filename(tmp_path):
    """Generator does not crash on unicode filenames."""
    (tmp_path / 'café_résumé.txt').write_text('unicode content')
    run_gen(tmp_path)
    assert (tmp_path / 'index.html').exists()
    assert (tmp_path / 'café_résumé.txt.html').exists()


def test_orphan_wrapper_cleanup(tmp_path):
    """Wrappers whose source file has been deleted are removed on next run."""
    # First run: create a .txt file → wrapper is generated
    (tmp_path / 'gone.txt').write_text('temporary')
    run_gen(tmp_path)
    assert (tmp_path / 'gone.txt.html').exists()

    # Delete the source and re-run
    (tmp_path / 'gone.txt').unlink()
    run_gen(tmp_path)
    assert not (tmp_path / 'gone.txt.html').exists()


def test_raw_assets_not_wrapped(tmp_path):
    """JS/CSS/JSON files are linked directly in the index, never wrapped."""
    (tmp_path / 'player.js').write_text('// js')
    (tmp_path / 'style.css').write_text('/* css */')
    (tmp_path / 'data.json').write_text('{}')
    run_gen(tmp_path)
    # No wrapper files for raw assets
    assert not (tmp_path / 'player.js.html').exists()
    assert not (tmp_path / 'style.css.html').exists()
    assert not (tmp_path / 'data.json.html').exists()
    # The index links them directly
    idx = (tmp_path / 'index.html').read_text(encoding='utf-8')
    assert 'href="player.js"' in idx
    assert 'href="style.css"' in idx
    assert 'href="data.json"' in idx


def test_embed_limit_small_text_embedded(tmp_path):
    """Text files under the embed limit are embedded verbatim in their wrapper."""
    content = 'embedded content here'
    (tmp_path / 'small.txt').write_text(content)
    run_gen(tmp_path, extra_env={'EMBED_LIMIT_BYTES': '1048576'})
    wrapper = (tmp_path / 'small.txt.html').read_text(encoding='utf-8')
    assert content in wrapper


def test_embed_limit_large_text_linked(tmp_path):
    """Text files over the embed limit get a download link, not embedded content."""
    big_content = 'x' * 200
    (tmp_path / 'big.txt').write_text(big_content)
    # Set limit to 100 bytes so the 200-byte file is "large"
    run_gen(tmp_path, extra_env={'EMBED_LIMIT_BYTES': '100'})
    wrapper = (tmp_path / 'big.txt.html').read_text(encoding='utf-8')
    assert big_content not in wrapper
    assert 'big.txt' in wrapper  # should contain a link to the file


def test_cast_file_gets_wrapper(tmp_path):
    """A .cast file produces a cast wrapper HTML (CDN fallback when no local player)."""
    cast_data = '{"version":2,"width":80,"height":24}\n[0.1,"o","hello\\r\\n"]\n'
    (tmp_path / 'demo.cast').write_text(cast_data)
    run_gen(tmp_path)
    wrapper = tmp_path / 'demo.cast.html'
    assert wrapper.exists()
    content = wrapper.read_text(encoding='utf-8')
    # Should reference the cast source file
    assert 'demo.cast' in content
    # Should reference either local or CDN player JS
    assert 'asciinema-player' in content


def test_log_file_gets_wrapper(tmp_path):
    """A .log file produces a plain HTML wrapper containing the file content."""
    import base64
    raw = b'step 1\nstep 2\n'
    (tmp_path / 'run.log').write_bytes(raw)
    run_gen(tmp_path)
    wrapper = tmp_path / 'run.log.html'
    assert wrapper.exists()
    content = wrapper.read_text(encoding='utf-8')
    # Content may be embedded as plain text (<pre>) or base64 iframe depending on MIME detection
    b64 = base64.b64encode(raw).decode('ascii')
    assert (raw.decode('utf-8') in content) or (b64 in content), (
        "Expected log content to appear as plain text or base64 in wrapper"
    )


def test_zero_byte_file(tmp_path):
    """Generator handles zero-byte files without crashing."""
    (tmp_path / 'empty.txt').write_bytes(b'')
    run_gen(tmp_path)
    assert (tmp_path / 'index.html').exists()
    assert (tmp_path / 'empty.txt.html').exists()


def test_index_not_re_wrapped(tmp_path):
    """index.html itself is never listed or wrapped in a second run."""
    (tmp_path / 'note.txt').write_text('hi')
    run_gen(tmp_path)
    # Run again — index.html now exists as input; it should not create index.html.html
    run_gen(tmp_path)
    assert not (tmp_path / 'index.html.html').exists()
    idx = (tmp_path / 'index.html').read_text(encoding='utf-8')
    # index.html itself should not appear as a listed artifact
    assert 'href="index.html"' not in idx


# ---------------------------------------------------------------------------
# template.py unit tests
# ---------------------------------------------------------------------------

sys.path.insert(0, os.path.join(ROOT, 'bin'))
from template import render_template  # noqa: E402


def test_template_basic_substitution(tmp_path):
    tpl = tmp_path / 'test.tpl'
    tpl.write_text('Hello %%NAME%%, you are %%AGE%% years old.')
    result = render_template(str(tpl), {'NAME': 'Alice', 'AGE': 30})
    assert result == 'Hello Alice, you are 30 years old.'


def test_template_unknown_placeholder_preserved(tmp_path):
    tpl = tmp_path / 'test.tpl'
    tpl.write_text('Value: %%UNKNOWN%%')
    result = render_template(str(tpl), {})
    assert result == 'Value: %%UNKNOWN%%'


def test_template_extra_key_ignored(tmp_path):
    tpl = tmp_path / 'test.tpl'
    tpl.write_text('Hi %%NAME%%')
    result = render_template(str(tpl), {'NAME': 'Bob', 'EXTRA': 'ignored'})
    assert result == 'Hi Bob'


def test_template_braces_in_js_not_mangled(tmp_path):
    """JS-style braces must not be touched by the template engine."""
    js_snippet = 'if (x) { return {a: 1}; }'
    tpl = tmp_path / 'test.tpl'
    tpl.write_text(f'%%TITLE%% {js_snippet}')
    result = render_template(str(tpl), {'TITLE': 'Test'})
    assert js_snippet in result


# ---------------------------------------------------------------------------
# gen_index_ctx.py unit tests
# ---------------------------------------------------------------------------

import importlib


def _fresh_ctx():
    """Return a freshly-imported gen_index_ctx so state doesn't leak between tests."""
    import gen_index_ctx as m
    m._ART_DIR = None
    m._EMBED_LIMIT = None
    return m


def test_ctx_set_and_get(tmp_path):
    ctx = _fresh_ctx()
    ctx.set_context(tmp_path, 512)
    assert ctx.get_art_dir() == tmp_path.resolve()
    assert ctx.get_embed_limit() == 512


def test_ctx_env_fallback(tmp_path, monkeypatch):
    ctx = _fresh_ctx()
    monkeypatch.setenv('ART_DIR', str(tmp_path))
    monkeypatch.setenv('EMBED_LIMIT_BYTES', '2048')
    assert ctx.get_art_dir() == tmp_path.resolve()
    assert ctx.get_embed_limit() == 2048


def test_ctx_set_overrides_env(tmp_path, monkeypatch):
    ctx = _fresh_ctx()
    other = tmp_path / 'other'
    other.mkdir()
    monkeypatch.setenv('ART_DIR', str(tmp_path))
    ctx.set_context(other, 99)
    assert ctx.get_art_dir() == other.resolve()
    assert ctx.get_embed_limit() == 99
