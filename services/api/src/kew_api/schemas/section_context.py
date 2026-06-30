"""Shared section context and lineage across Plan and Agent chat modes."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Literal

from pydantic import BaseModel, Field

from kew_api.schemas.chat import AgentName, ChatMode


class SectionLineageEvent(BaseModel):
    id: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(UTC))
    chat_mode: ChatMode
    event_type: Literal["folder_plan", "advisory", "change_plan", "user_message"]
    agent: AgentName | None = None
    summary: str = Field(min_length=1)
    detail: str = ""


class SectionContext(BaseModel):
    scope_kind: Literal["file", "folder"]
    scope_path: str = ""
    updated_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    last_plan_summary: str | None = None
    last_plan_explanation: str | None = None
    last_target_structure: str | None = None
    lineage: list[SectionLineageEvent] = Field(default_factory=list)
