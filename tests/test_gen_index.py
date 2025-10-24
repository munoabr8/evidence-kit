import os
import shutil
import tempfile
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(__file__))
GEN = os.path.join(ROOT, 'bin', 'gen-index.py')


def run_gen(tmpdir):
    env = os.environ.copy()
    env['ART_DIR'] = tmpdir
    subprocess.check_call([sys.executable, GEN], env=env, cwd=ROOT)


def test_gen_index_happy_path(tmp_path):
    # create a small text artifact and run generator
    art = tmp_path
    (art / 'small.txt').write_text('hello world')
    run_gen(str(art))
    idx = art / 'index.html'
    assert idx.exists()
    wrapper = art / 'small.txt.html'
    assert wrapper.exists()


def test_gen_index_large_binary(tmp_path):
    # create a binary file > EMBED_LIMIT (use 2MB) and assert wrapper is created
    art = tmp_path
    big = art / 'big.bin'
    with open(big, 'wb') as fh:
        fh.write(b'\0' * (2 * 1024 * 1024))
    run_gen(str(art))
    idx = art / 'index.html'
    assert idx.exists()
    wrapper = art / 'big.bin.html'
    assert wrapper.exists()
