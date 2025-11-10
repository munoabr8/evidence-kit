# gen_index_ctx.py  (or keep in the same module)
# module-scoped will need to eventually -> context class
from pathlib import Path

_ART_DIR: Path | None = None
_EMBED_LIMIT: int | None = None

def set_context(art_dir: Path, embed_limit: int) -> None:
    global _ART_DIR, _EMBED_LIMIT
    _ART_DIR = Path(art_dir).resolve()
    _EMBED_LIMIT = int(embed_limit)

def get_art_dir() -> Path:
    if _ART_DIR is not None:
        return _ART_DIR
    # lazy fallback: env → default
    import os
    return Path(os.getenv("ART_DIR", "artifacts")).resolve()

def get_embed_limit() -> int:
    if _EMBED_LIMIT is not None:
        return _EMBED_LIMIT
    import os
    return int(os.getenv("EMBED_LIMIT_BYTES", "1048576"))
 
