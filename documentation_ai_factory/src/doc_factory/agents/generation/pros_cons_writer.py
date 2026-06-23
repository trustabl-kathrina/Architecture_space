"""ProsConsWriterAgent — tradeoff and selection guidance sections."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.generation._section_base import build_section_writer_agent
from doc_factory.config.settings import Settings

_EXTRA = (
    "Present balanced advantages, disadvantages, and when-to-use guidance. "
    "Include a comparison table (block_type=table) when multiple options exist."
)


def build_pros_cons_writer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build specialist writer for pros/cons tradeoff sections."""
    return build_section_writer_agent(
        settings,
        name="pros_cons_writer_agent",
        description="Writes balanced pros, cons, and selection guidance.",
        extra_instruction=_EXTRA,
    )
