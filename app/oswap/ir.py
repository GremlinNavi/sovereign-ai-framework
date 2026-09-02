"""Small, serializable intermediate representation for OSWAP plans."""
from __future__ import annotations

from dataclasses import asdict, dataclass


@dataclass(frozen=True)
class OSWAPPlan:
    operation: str
    allocation_mode: str
    expression: str
    resolved_value: int
    dry_run: bool = True

    def to_dict(self) -> dict:
        return asdict(self)
