import importlib
from pathlib import Path
from unittest.mock import patch

#python3 probe_context.py

import gen_index_ctx as ctx

# Isolate these checks from your shell's environment.
with patch.dict("os.environ", {}, clear=True):
    importlib.reload(ctx)

    # Defaults
    assert ctx.get_art_dir() == Path("artifacts").resolve()
    assert ctx.get_embed_limit() == 1048576
    print("Defaults passed")

    # Environment overrides defaults
    with patch.dict("os.environ", {
        "ART_DIR": "env-artifacts",
        "EMBED_LIMIT_BYTES": "2048",
    }):
        assert ctx.get_art_dir() == Path("env-artifacts").resolve()
        assert ctx.get_embed_limit() == 2048
        print("Environment fallbacks passed")

        # Explicit settings override environment
        ctx.set_context(Path("explicit-artifacts"), 512)
        assert ctx.get_art_dir() == Path("explicit-artifacts").resolve()
        assert ctx.get_embed_limit() == 512
        print("Explicit overrides passed")

print("Context checks passed")