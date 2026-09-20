
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

@dataclass(frozen=True)
class IndexContext:
    art_dir: Path
    embed_limit: int

@dataclass(frozen=True)
class WorkflowContext:
    ticket_id: str
    observed_state: str | None
    observed_at: datetime | None