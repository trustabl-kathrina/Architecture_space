"""DocumentationOutlineAgent — define Markdown file tree for a topic."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

import yaml
from google.adk.agents import LlmAgent

from doc_factory.agents.common import retry_config
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.planning import DocumentationOutline, OutlineNode, ResearchPlan
from doc_factory.models.topic import TaxonomyMapping
from doc_factory.prompts.registry import load_prompt

_TEMPLATE_CATALOG_PATH = (
    Path(__file__).resolve().parents[2] / "taxonomy" / "template_catalog.yaml"
)


@lru_cache
def _load_template_catalog() -> str:
    return _TEMPLATE_CATALOG_PATH.read_text(encoding="utf-8")


def build_outline_architect_agent(settings: Settings | None = None) -> LlmAgent:
    """Build ADK agent that designs the documentation file tree."""
    settings = settings or get_settings()
    instruction = (
        load_prompt("planning/outline_architect.txt")
        .replace("{{ research_plan_json }}", "{research_plan}")
        .replace("{{ template_catalog }}", _load_template_catalog())
        + "\n\nTaxonomy mapping:\n{taxonomy_mapping}\n\n"
        "Produce a hub README plus child nodes for each section in generation_sequence. "
        "Use snake_case filenames ending in .md."
    )
    return LlmAgent(
        name="outline_architect_agent",
        model=settings.gemini_model_flash,
        description="Designs documentation file tree aligned with Architecture Space templates.",
        instruction=instruction,
        output_key="documentation_outline",
        output_schema=DocumentationOutline,
        retry_config=retry_config(settings),
    )


def build_outline_fallback(
    research_plan: ResearchPlan,
    taxonomy: TaxonomyMapping,
    topic: str,
) -> DocumentationOutline:
    """Deterministic outline from research plan sequence."""
    slug = taxonomy.canonical_topic_slug
    nodes: list[OutlineNode] = []
    for index, section_id in enumerate(research_plan.generation_sequence, start=1):
        title = section_id.replace("_", " ").title()
        nodes.append(
            OutlineNode(
                node_id=section_id,
                title=title,
                filename=f"{index:02d}_{section_id}.md",
                template_type=_template_for_section(section_id),
            )
        )
    return DocumentationOutline(
        root_readme=f"{topic} — Learning Guide",
        nodes=nodes,
        estimated_page_count=len(nodes) + 1,
    )


def _template_for_section(section_id: str) -> str:
    mapping = {
        "overview": "overview",
        "architecture": "architecture",
        "scenarios": "scenarios",
        "implementation": "implementation",
        "benchmarks": "benchmarks",
        "comparisons": "comparisons",
        "best_practices": "best_practices",
        "poc_learning": "poc_learning",
        "references": "references",
        "pros_cons": "pros_cons",
    }
    for key, template in mapping.items():
        if key in section_id:
            return template
    return "concept"
