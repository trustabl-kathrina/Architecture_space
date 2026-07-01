"""ResearchPlannerAgent — build ResearchPlan from topic and research summary."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.common import retry_config
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.planning import ResearchPlan
from doc_factory.models.research import ResearchSummary
from doc_factory.models.topic import TopicRequest


def build_research_planner_agent(settings: Settings | None = None) -> LlmAgent:
    """Build ADK agent that creates a ResearchPlan from intake and synthesis."""
    settings = settings or get_settings()
    instruction = (
        "You are the Research Planner for an enterprise Architecture Space documentation factory.\n\n"
        "Given the topic request and research summary, produce a ResearchPlan with:\n"
        "- objectives: 4-8 documentation goals informed by research themes\n"
        "- gaps: areas where sources are thin or contradictory\n"
        "- generation_sequence: ordered section_ids to write (overview first)\n"
        "- risk_flags: factual uncertainty, vendor bias, or compliance concerns\n\n"
        "Topic request:\n{topic_request}\n\n"
        "Research summary:\n{research_summary}\n\n"
        "Return only structured JSON matching the output schema."
    )
    return LlmAgent(
        name="research_planner_agent",
        model=settings.gemini_model_flash,
        description="Builds research-driven documentation generation plan.",
        instruction=instruction,
        output_key="research_plan",
        output_schema=ResearchPlan,
        retry_config=retry_config(settings),
    )


def build_research_plan_fallback(
    topic_request: TopicRequest,
    research_summary: ResearchSummary,
) -> ResearchPlan:
    """Deterministic ResearchPlan when LLM is not used."""
    sequence = [
        "overview",
        "architecture",
        "scenarios",
        "implementation",
        "benchmarks",
        "comparisons",
        "best_practices",
        "poc_learning",
        "references",
    ]
    objectives = [
        f"Document {topic_request.topic} for {topic_request.audience} audience",
        *[f"Cover theme: {t.title}" for t in research_summary.themes[:4]],
    ]
    gaps = research_summary.open_questions[:5]
    risk_flags: list[str] = []
    if len(research_summary.themes) < 3:
        risk_flags.append("Limited source diversity — expand research before export.")
    return ResearchPlan(
        objectives=objectives,
        gaps=gaps,
        generation_sequence=sequence,
        risk_flags=risk_flags,
    )
