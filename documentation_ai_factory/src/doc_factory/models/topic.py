"""Intake phase data contracts.

Responsibility:
- TopicRequest: normalized user topic and scope.
- TaxonomyMapping: Architecture Space section and template routing.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class TopicRequest(BaseModel):
    """Normalized documentation topic from user input."""

    topic: str
    synonyms: list[str] = Field(default_factory=list)
    scope_in: list[str] = Field(default_factory=list)
    scope_out: list[str] = Field(default_factory=list)
    audience: Literal["architect", "engineer", "executive"] = "architect"
    depth: Literal["overview", "standard", "deep"] = "standard"
    preferred_clouds: list[str] = Field(default_factory=list)
    related_technologies: list[str] = Field(default_factory=list)


class TaxonomyMapping(BaseModel):
    """Maps a topic to Architecture Space taxonomy."""

    target_section_prefix: str
    suggested_path: str
    template_mix: dict[str, int] = Field(default_factory=dict)
    tags: list[str] = Field(default_factory=list)
    canonical_topic_slug: str
    needs_manual_mapping: bool = False
