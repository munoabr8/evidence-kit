from pathlib import Path
import os

import  gen_index_ctx as ctx

print("=== Effective context probe ===")

art_dir = ctx.get_art_dir()
embed_limit = ctx.get_embed_limit()

print(f"ART_DIR environment:       {os.environ.get('ART_DIR')!r}")
print(f"Resolved artifact dir:     {art_dir}")
print(f"Resolved embed limit:      {embed_limit}")

art_dir.mkdir(parents=True, exist_ok=True)

probe_file = art_dir / "context-probe.txt"

probe_file.write_text(
    f"artifact_dir={art_dir}\n"
    f"embed_limit={embed_limit}\n"
)

print(f"Created probe artifact:    {probe_file}")

assert probe_file.exists()
assert probe_file.parent == art_dir

contents = probe_file.read_text()

assert f"embed_limit={embed_limit}" in contents

print("Effective behavior:        PASS")