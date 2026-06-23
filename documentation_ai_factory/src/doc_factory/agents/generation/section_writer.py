"""GenericSectionWriterAgent — fallback writer for any section type."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.generation._section_base import build_section_writer_agent
from doc_factory.config.settings import Settings


def build_generic_section_writer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build generic section writer ADK agent."""
    return build_section_writer_agent(settings)
