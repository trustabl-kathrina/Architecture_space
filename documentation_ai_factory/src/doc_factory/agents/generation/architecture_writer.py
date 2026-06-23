"""ArchitectureWriterAgent — reference architecture sections with Mermaid diagrams."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.generation._section_base import build_section_writer_agent
from doc_factory.config.settings import Settings

_EXTRA = (
    "Focus on reference architecture, component boundaries, and data flow. "
    "Include at least one mermaid diagram block (block_type=mermaid) showing "
    "components and integration points. Cover enterprise deployment patterns."
)


def build_architecture_writer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build specialist writer for architecture sections."""
    return build_section_writer_agent(
        settings,
        name="architecture_writer_agent",
        description="Writes reference architecture sections with Mermaid diagrams.",
        extra_instruction=_EXTRA,
    )
