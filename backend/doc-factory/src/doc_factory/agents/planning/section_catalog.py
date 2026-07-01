"""SectionCatalogAgent — produce SectionCatalog from outline and templates."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.common import retry_config
from doc_factory.agents.factory import build_structure_agent
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.planning import (
    DocumentationOutline,
    ResearchPlan,
    SectionCatalog,
    SectionSpec,
)
from doc_factory.rendering.template_resolver import TemplateResolver


def build_section_catalog_agent(settings: Settings | None = None) -> LlmAgent:
    """Build ADK agent for section catalog (delegates to structure agent in MVP)."""
    return build_structure_agent(settings or get_settings())


def build_section_catalog(
    outline: DocumentationOutline,
    research_plan: ResearchPlan,
    settings: Settings | None = None,
) -> SectionCatalog:
    """Build SectionCatalog programmatically from outline and template requirements."""
    settings = settings or get_settings()
    resolver = TemplateResolver(settings)
    sections: list[SectionSpec] = []

    for node in outline.nodes:
        headings = resolver.required_headings(node.template_type)
        sections.append(
            SectionSpec(
                section_id=node.node_id,
                title=node.title,
                template_type=node.template_type,
                headings=headings,
                target_words=max(settings.min_section_words, 800),
                required_elements=headings,
                depends_on=_depends_on(node.node_id, research_plan.generation_sequence),
            )
        )

    hub = SectionSpec(
        section_id="hub_readme",
        title=outline.root_readme,
        template_type="hub",
        headings=resolver.required_headings("hub"),
        target_words=400,
        required_elements=["Prerequisites", "Modules", "Quick links"],
    )
    return SectionCatalog(sections=sections, hub_readme_spec=hub)


def _depends_on(section_id: str, sequence: list[str]) -> list[str]:
    if section_id not in sequence:
        return []
    index = sequence.index(section_id)
    if index == 0:
        return []
    return [sequence[index - 1]]
