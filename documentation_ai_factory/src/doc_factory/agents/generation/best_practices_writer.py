"""BestPracticesWriterAgent — governance, operations, and security practices."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.generation._section_base import build_section_writer_agent
from doc_factory.config.settings import Settings

_EXTRA = (
    "Cover design, operations, and security best practices for enterprise adoption. "
    "Use actionable bullet lists and call out anti-patterns to avoid."
)


def build_best_practices_writer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build specialist writer for best-practices sections."""
    return build_section_writer_agent(
        settings,
        name="best_practices_writer_agent",
        description="Writes governance, operations, and security best practices.",
        extra_instruction=_EXTRA,
    )
