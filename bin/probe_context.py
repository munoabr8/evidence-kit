import importlib
import os
from pathlib import Path
from unittest.mock import patch

# python3 probe_context.py

import gen_index_ctx as ctx


def check(name, actual, expected):
    print(f"\nCHECK: {name}")
    print(f"  expected: {expected!r}")
    print(f"  actual:   {actual!r}")

    assert actual == expected, (
        f"{name} failed: expected {expected!r}, got {actual!r}"
    )

    print("  result:   PASS")


print("=== gen_index_ctx context probe ===")

# Isolate these checks from your shell's environment.
with patch.dict("os.environ", {}, clear=True):
    print("\n[1] Reloading module with empty environment")
    importlib.reload(ctx)

    print(f"  ART_DIR env:           {os.environ.get('ART_DIR')!r}")
    print(f"  EMBED_LIMIT_BYTES env: {os.environ.get('EMBED_LIMIT_BYTES')!r}")

    # Defaults
    check(
        "default artifact directory",
        ctx.get_art_dir(),
        Path("artifacts").resolve(),
    )

    check(
        "default embed limit",
        ctx.get_embed_limit(),
        1048576,
    )

    # Environment overrides defaults
    print("\n[2] Applying environment overrides")

    with patch.dict(
        "os.environ",
        {
            "ART_DIR": "env-artifacts",
            "EMBED_LIMIT_BYTES": "2048",
        },
    ):
        print(f"  ART_DIR env:           {os.environ['ART_DIR']!r}")
        print(f"  EMBED_LIMIT_BYTES env: {os.environ['EMBED_LIMIT_BYTES']!r}")

        check(
            "environment artifact directory",
            ctx.get_art_dir(),
            Path("env-artifacts").resolve(),
        )

        check(
            "environment embed limit",
            ctx.get_embed_limit(),
            2048,
        )

        # Explicit settings override environment
        print("\n[3] Applying explicit context")
        print("  set_context(Path('explicit-artifacts'), 512)")

        ctx.set_context(Path("explicit-artifacts"), 512)

        check(
            "explicit artifact directory",
            ctx.get_art_dir(),
            Path("explicit-artifacts").resolve(),
        )

        check(
            "explicit embed limit",
            ctx.get_embed_limit(),
            512,
        )

print("\n=== Context checks passed ===")