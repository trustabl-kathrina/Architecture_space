"""Content generation data contracts.

Responsibility:
- SectionDraft, DocumentationDraft, CitationRef, ContentBlock.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class CitationRef(BaseModel):
    """Reference to a source within generated content."""

    source_id: str
    quote: str | None = None
    locator: str | None = None


class ContentBlock(BaseModel):
    """Structured block within a section draft."""

    block_type: Literal["paragraph", "table", "mermaid", "code", "list"]
    content: str
    citations: list[CitationRef] = Field(default_factory=list)


class SectionDraft(BaseModel):
    """Draft content for one documentation section."""

    section_id: str
    title: str
    template_type: str
    blocks: list[ContentBlock] = Field(default_factory=list)
    word_count: int = 0
    citations: list[CitationRef] = Field(default_factory=list)
    status: Literal["draft", "reviewed"] = "draft"


class BibliographyEntry(BaseModel):
    """Formatted reference entry."""

    source_id: str
    citation_text: str
    url: str


class DocumentationDraft(BaseModel):
    """Merged draft across all sections."""

    sections: list[SectionDraft] = Field(default_factory=list)
    bibliography: list[BibliographyEntry] = Field(default_factory=list)
    cross_links: list[str] = Field(default_factory=list)
    glossary: list[str] = Field(default_factory=list)
