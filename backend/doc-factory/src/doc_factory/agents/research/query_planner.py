"""ResearchQueryPlannerAgent — generate diversified Tavily queries."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.common import retry_config
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.research import ResearchQueryPlan
from doc_factory.prompts.registry import load_prompt


def build_query_planner_agent(settings: Settings | None = None) -> LlmAgent:
    """Build ADK agent that plans diversified web research queries."""
    settings = settings or get_settings()
    query_count = str(settings.research_query_count)
    instruction = (
        load_prompt("research/query_planner.txt")
        .replace("{{ query_count }}", query_count)
        .replace("{{ topic }}", "{topic_request.topic}")
        .replace("{{ taxonomy_section }}", "{taxonomy_mapping.target_section_prefix}")
        + f"\n\nGenerate exactly {query_count} queries with unique query_id values "
        "(q1, q2, ...). Set max_results_per_query from settings context."
    )
    return LlmAgent(
        name="query_planner_agent",
        model=settings.gemini_model_flash,
        description="Plans diversified Tavily research queries for a documentation topic.",
        instruction=instruction,
        output_key="research_query_plan",
        output_schema=ResearchQueryPlan,
        retry_config=retry_config(settings),
    )
