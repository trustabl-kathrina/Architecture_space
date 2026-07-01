"""Planning phase data contracts.

Responsibility:
- ResearchPlan, DocumentationOutline, SectionCatalog, SectionSpec.
"""

from __future__ import annotations

from pydantic import BaseModel, Field


class ResearchPlan(BaseModel):
    """Research-driven plan for documentation generation."""

    objectives: list[str] = Field(default_factory=list)
    gaps: list[str] = Field(default_factory=list)
    generation_sequence: list[str] = Field(default_factory=list)
    risk_flags: list[str] = Field(default_factory=list)


class OutlineNode(BaseModel):
    """Node in the documentation file tree."""

    node_id: str
    title: str
    filename: str
    template_type: str
    children: list[OutlineNode] = Field(default_factory=list)


class DocumentationOutline(BaseModel):
    """Target Markdown file tree for a topic."""

    root_readme: str
    nodes: list[OutlineNode] = Field(default_factory=list)
    estimated_page_count: int = 0


class SectionSpec(BaseModel):
    """Specification for one generated section."""

    section_id: str
    title: str
    template_type: str
    headings: list[str] = Field(default_factory=list)
    target_words: int = 800
    required_elements: list[str] = Field(default_factory=list)
    depends_on: list[str] = Field(default_factory=list)


class SectionCatalog(BaseModel):
    """Canonical list of sections to generate."""

    sections: list[SectionSpec] = Field(default_factory=list)
    hub_readme_spec: SectionSpec | None = None
