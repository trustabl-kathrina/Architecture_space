"""MVP v1 agent output schemas."""

from __future__ import annotations

from pydantic import BaseModel, Field


class SectionPlan(BaseModel):
    """One planned documentation section."""

    section_id: str = Field(description="Slug identifier, e.g. architecture")
    title: str
    description: str = Field(description="What this section should cover")
    headings: list[str] = Field(min_length=2, max_length=8)
    required_elements: list[str] = Field(
        default_factory=list,
        description="e.g. mermaid diagram, comparison table, code example",
    )


class PlannerAgentOutput(BaseModel):
    """Structured output from the Planner Agent."""

    topic: str
    topic_summary: str = Field(description="2-3 sentence understanding of the topic")
    audience: str = Field(default="enterprise architects")
    objectives: list[str] = Field(min_length=2, max_length=6)
    sections: list[SectionPlan] = Field(min_length=4, max_length=10)
    research_queries: list[str] = Field(
        min_length=4,
        max_length=12,
        description="Diversified Tavily search queries",
    )
    research_plan: str = Field(description="How research will inform each section")


class SourceItem(BaseModel):
    """One web source collected during research."""

    title: str
    url: str
    snippet: str
    query: str = ""


class ResearchAgentOutput(BaseModel):
    """Structured output from the Research Agent."""

    queries_executed: list[str] = Field(default_factory=list)
    sources: list[SourceItem] = Field(default_factory=list)
    themes: list[str] = Field(min_length=2, max_length=8)
    key_facts: list[str] = Field(min_length=5, max_length=20)
    summary: str
    open_questions: list[str] = Field(default_factory=list)


class MarkdownSection(BaseModel):
    """One generated Markdown document."""

    section_id: str
    title: str
    filename: str
    content_markdown: str = Field(description="Full markdown body without front matter")


class WriterAgentOutput(BaseModel):
    """Structured output from the Writer Agent."""

    topic: str
    readme_markdown: str = Field(description="Hub README with module index")
    sections: list[MarkdownSection] = Field(min_length=4)
    references_markdown: str = Field(description="References section with URLs")


class PipelineResult(BaseModel):
    """End-to-end MVP pipeline result."""

    run_id: str
    topic: str
    planner_output: PlannerAgentOutput
    research_output: ResearchAgentOutput
    writer_output: WriterAgentOutput
    output_dir: str
