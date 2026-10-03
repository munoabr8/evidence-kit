import os
from pathlib import Path

import gen_index_ctx as ctx

# probe_environment.py

print("External environment:")
print(f"  ART_DIR={os.environ.get('ART_DIR')!r}")
print(f"  EMBED_LIMIT_BYTES={os.environ.get('EMBED_LIMIT_BYTES')!r}")

print("Resolved context:")
print(f"  ART_DIR={ctx.get_art_dir()!r}")
print(f"  EMBED_LIMIT_BYTES={ctx.get_embed_limit()!r}")

expected_art_dir = os.environ.get("ART_DIR")

if expected_art_dir is not None:
    assert ctx.get_art_dir() == Path(expected_art_dir).resolve()

print("Environment propagation passed")
 