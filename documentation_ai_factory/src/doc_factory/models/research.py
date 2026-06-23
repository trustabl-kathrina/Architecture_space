"""Research phase data contracts.

Responsibility:
- ResearchQueryPlan, SourceCorpus, ResearchSummary, and related types.
"""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class ResearchQuery(BaseModel):
    """Single Tavily search query."""

    query_id: str
    text: str
    intent: Literal["concept", "architecture", "benchmark", "comparison", "poc", "vendor"]
    priority: int = 1


class ResearchQueryPlan(BaseModel):
    """Planned set of research queries for a topic."""

    queries: list[ResearchQuery] = Field(default_factory=list)
    max_results_per_query: int = 5
    recency_months: int = 24


class SourceRecord(BaseModel):
    """One retrieved web source."""

    source_id: str
    url: str
    title: str
    snippet: str
    domain: str
    retrieved_at: datetime
    query_id: str
    published_at: datetime | None = None


class SourceCorpus(BaseModel):
    """Raw aggregated sources from Tavily."""

    sources: list[SourceRecord] = Field(default_factory=list)
    dedupe_stats: dict[str, int] = Field(default_factory=dict)


class RankedSource(BaseModel):
    """Source with relevance scoring."""

    source: SourceRecord
    relevance_score: float
    authority_score: float


class RankedSourceCorpus(BaseModel):
    """Deduplicated and ranked sources."""

    ranked_sources: list[RankedSource] = Field(default_factory=list)


class ResearchTheme(BaseModel):
    """Thematic cluster from research synthesis."""

    theme_id: str
    title: str
    summary: str
    source_ids: list[str] = Field(default_factory=list)
    confidence: Literal["high", "medium", "low"] = "medium"


class ResearchSummary(BaseModel):
    """Synthesized research output for planning."""

    themes: list[ResearchTheme] = Field(default_factory=list)
    key_facts: list[str] = Field(default_factory=list)
    open_questions: list[str] = Field(default_factory=list)
    recommended_comparisons: list[str] = Field(default_factory=list)
