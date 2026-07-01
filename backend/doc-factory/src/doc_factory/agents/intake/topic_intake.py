"""TopicIntakeAgent — normalize user topic into TopicRequest."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.common import retry_config
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.topic import TopicRequest
from doc_factory.prompts.registry import load_prompt


def build_topic_intake_agent(settings: Settings | None = None) -> LlmAgent:
    """Build ADK agent that normalizes raw topic input into TopicRequest."""
    settings = settings or get_settings()
    instruction = (
        load_prompt("intake/topic_intake.txt")
        .replace("{{ topic }}", "{topic}")
        .replace("{{ audience }}", "architect")
        .replace("{{ depth }}", "standard")
        + "\n\nInfer synonyms, scope boundaries, related technologies, and preferred "
        "clouds from the topic when not explicitly provided."
    )
    return LlmAgent(
        name="topic_intake_agent",
        model=settings.gemini_model_flash,
        description="Normalizes user documentation topics into structured TopicRequest.",
        instruction=instruction,
        output_key="topic_request",
        output_schema=TopicRequest,
        retry_config=retry_config(settings),
    )
