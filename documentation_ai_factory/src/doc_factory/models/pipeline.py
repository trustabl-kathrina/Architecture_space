"""Multi-agent pipeline output schemas."""

from __future__ import annotations

from pydantic import BaseModel, Field

from doc_factory.models.benchmark import (
    BenchmarkAgentOutput,
    TechnologyBenchmarkEvaluation,
)
from doc_factory.models.mvp import (
    MarkdownSection,
    PlannerAgentOutput,
    ResearchAgentOutput,
    SectionPlan,
    SourceItem,
)

__all__ = [
    "BenchmarkAgentOutput",
    "TechnologyBenchmarkEvaluation",
    "ComparisonAgentOutput",
    "ComparisonRow",
    "PipelineResult",
    "PublishManifest",
    "PublishedFile",
    "ReviewFinding",
    "ReviewerAgentOutput",
    "StructuredSection",
    "StructureAgentOutput",
    "WriterAgentOutput",
    "PlannerAgentOutput",
    "ResearchAgentOutput",
    "MarkdownSection",
    "SectionPlan",
    "SourceItem",
]


class StructuredSection(BaseModel):
    """Detailed section specification from the Structure Agent."""

    section_id: str
    title: str
    filename: str
    template_type: str
    headings: list[str] = Field(min_length=2)
    word_target: int = Field(default=600, ge=200)
    content_brief: str
    required_elements: list[str] = Field(default_factory=list)
    depends_on: list[str] = Field(default_factory=list)
    agent_owner: str = Field(
        default="writer_agent",
        description="Agent responsible: writer_agent, benchmark_agent, comparison_agent",
    )


class StructureAgentOutput(BaseModel):
    """Document structure produced after planning and research."""

    topic: str
    document_title: str
    hub_summary: str
    sections: list[StructuredSection] = Field(min_length=6, max_length=14)
    cross_links: list[str] = Field(default_factory=list)
    generation_order: list[str] = Field(
        default_factory=list,
        description="Ordered section_id values",
    )
    structure_notes: str = ""


class WriterAgentOutput(BaseModel):
    """Core documentation sections from the Writer Agent."""

    topic: str
    sections: list[MarkdownSection] = Field(min_length=3)
    writing_notes: str = ""


class ComparisonRow(BaseModel):
    """One row in a technology comparison matrix."""

    capability: str
    scores: dict[str, str] = Field(description="technology name -> rating or note")


class ComparisonAgentOutput(BaseModel):
    """Technology comparison section from the Comparison Agent."""

    topic: str
    section: MarkdownSection
    technologies: list[str] = Field(min_length=2, max_length=6)
    comparison_rows: list[ComparisonRow] = Field(min_length=4)
    selection_guidance: str
    comparison_notes: str = ""


class ReviewFinding(BaseModel):
    """QA finding from the Reviewer Agent."""

    severity: str = Field(description="info, warning, or blocker")
    section_id: str | None = None
    message: str
    suggestion: str | None = None


class ReviewerAgentOutput(BaseModel):
    """Final reviewed documentation package."""

    topic: str
    approved: bool
    overall_score: float = Field(ge=0.0, le=100.0)
    findings: list[ReviewFinding] = Field(default_factory=list)
    final_sections: list[MarkdownSection] = Field(min_length=6)
    readme_markdown: str
    references_markdown: str
    revision_notes: str = ""


class PublishedFile(BaseModel):
    """One file written by the Markdown Publisher."""

    relative_path: str
    checksum_sha256: str
    byte_size: int


class PublishManifest(BaseModel):
    """Publisher output manifest."""

    run_id: str
    topic: str
    output_dir: str
    files: list[PublishedFile] = Field(default_factory=list)
    review_approved: bool
    published_at_iso: str


class PipelineResult(BaseModel):
    """Complete multi-agent pipeline result."""

    run_id: str
    topic: str
    planner_output: PlannerAgentOutput
    research_output: ResearchAgentOutput
    structure_output: StructureAgentOutput
    writer_output: WriterAgentOutput
    benchmark_output: BenchmarkAgentOutput
    comparison_output: ComparisonAgentOutput
    reviewer_output: ReviewerAgentOutput
    publish_manifest: PublishManifest
    output_dir: str
