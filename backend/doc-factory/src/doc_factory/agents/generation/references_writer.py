"""ReferencesWriterAgent — bibliography assembly from sources and drafts."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.common import retry_config
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.content import BibliographyEntry, DocumentationDraft, SectionDraft
from doc_factory.models.research import RankedSourceCorpus


def build_references_writer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build ADK agent that assembles a references section."""
    settings = settings or get_settings()
    instruction = (
        "You are the References Writer for Architecture Space documentation.\n\n"
        "Using ranked sources and section drafts, produce a SectionDraft for the "
        "references section with bibliography entries cited inline.\n\n"
        "Ranked sources:\n{ranked_source_corpus}\n\n"
        "Section drafts:\n{section_drafts}\n\n"
        "Set section_id=references, template_type=references. Include Primary Sources "
        "and Further Reading headings."
    )
    return LlmAgent(
        name="references_writer_agent",
        model=settings.gemini_model_flash,
        description="Assembles bibliography and references section from sources.",
        instruction=instruction,
        output_key="references_section",
        output_schema=SectionDraft,
        retry_config=retry_config(settings),
    )


def build_bibliography(corpus: RankedSourceCorpus) -> list[BibliographyEntry]:
    """Build bibliography entries from ranked sources without LLM."""
    entries: list[BibliographyEntry] = []
    for ranked in corpus.ranked_sources:
        source = ranked.source
        entries.append(
            BibliographyEntry(
                source_id=source.source_id,
                citation_text=f"{source.title}. {source.domain}.",
                url=source.url,
            )
        )
    return entries


def merge_documentation_draft(
    sections: list[SectionDraft],
    corpus: RankedSourceCorpus,
) -> DocumentationDraft:
    """Merge section drafts into DocumentationDraft with bibliography."""
    bibliography = build_bibliography(corpus)
    cross_links = [f"#{s.section_id}" for s in sections]
    return DocumentationDraft(
        sections=sections,
        bibliography=bibliography,
        cross_links=cross_links,
        glossary=[],
    )
