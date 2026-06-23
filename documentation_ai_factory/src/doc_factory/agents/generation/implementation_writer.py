"""ImplementationWriterAgent — configuration and code example sections."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.generation._section_base import build_section_writer_agent
from doc_factory.config.settings import Settings

_EXTRA = (
    "Include practical implementation guidance with at least one code block "
    "(block_type=code) for configuration or IaC. Cover prerequisites, "
    "environment setup, and validation steps."
)


def build_implementation_writer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build specialist writer for implementation sections."""
    return build_section_writer_agent(
        settings,
        name="implementation_writer_agent",
        description="Writes implementation guides with configuration and code examples.",
        extra_instruction=_EXTRA,
    )
