"""POCLearningWriterAgent — proof-of-concept and learning exercise sections."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.generation._section_base import build_section_writer_agent
from doc_factory.config.settings import Settings

_EXTRA = (
    "Structure as a hands-on POC guide: overview, numbered steps, and learning "
    "exercises with expected outcomes. Keep exercises achievable in 2-4 hours."
)


def build_poc_learning_writer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build specialist writer for POC and learning sections."""
    return build_section_writer_agent(
        settings,
        name="poc_learning_writer_agent",
        description="Writes POC guides and hands-on learning exercises.",
        extra_instruction=_EXTRA,
    )
