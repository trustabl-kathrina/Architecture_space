"""ResearchSummaryAgent — synthesize ranked sources into themes and facts."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.common import retry_config
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.research import RankedSourceCorpus, ResearchSummary
from doc_factory.prompts.registry import load_prompt


def build_research_summarizer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build ADK agent that synthesizes ranked sources into ResearchSummary."""
    settings = settings or get_settings()
    instruction = (
        load_prompt("research/research_summarizer.txt")
        .replace("{{ sources_json }}", "{ranked_source_corpus}")
        + "\n\nCluster findings into 4-8 themes. Every key_fact must reference "
        "at least one source_id. Identify open_questions and recommended_comparisons."
    )
    return LlmAgent(
        name="research_summarizer_agent",
        model=settings.gemini_model_flash,
        description="Synthesizes web research into themes, facts, and open questions.",
        instruction=instruction,
        output_key="research_summary",
        output_schema=ResearchSummary,
        retry_config=retry_config(settings),
    )


def summarize_sources_programmatic(
    corpus: RankedSourceCorpus,
    *,
    max_themes: int = 6,
) -> ResearchSummary:
    """Lightweight fallback summarizer when LLM is unavailable."""
    from doc_factory.models.research import ResearchTheme

    themes: list[ResearchTheme] = []
    for index, ranked in enumerate(corpus.ranked_sources[:max_themes]):
        source = ranked.source
        themes.append(
            ResearchTheme(
                theme_id=f"theme-{index + 1}",
                title=source.title[:120],
                summary=source.snippet[:500],
                source_ids=[source.source_id],
                confidence="medium",
            )
        )

    key_facts = [
        f"{r.source.title}: {r.source.snippet[:200]}"
        for r in corpus.ranked_sources[:10]
    ]
    return ResearchSummary(
        themes=themes,
        key_facts=key_facts,
        open_questions=["Validate vendor claims against independent benchmarks."],
        recommended_comparisons=[],
    )
