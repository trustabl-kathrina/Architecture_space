"""Shared envelope and base types for all artifacts.

Responsibility:
- ArtifactEnvelope wrapper with schema_version, run_id, producer_agent.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any, Literal

from pydantic import BaseModel, Field


class ArtifactEnvelope(BaseModel):
    """Wrapper for versioned artifacts persisted to the run store."""

    schema_version: Literal["1.0"] = "1.0"
    run_id: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    producer_agent: str
    payload: dict[str, Any]
