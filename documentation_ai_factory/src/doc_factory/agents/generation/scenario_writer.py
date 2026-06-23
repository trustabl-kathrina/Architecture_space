"""ScenarioWriterAgent — enterprise use-case and decision-trigger sections."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.generation._section_base import build_section_writer_agent
from doc_factory.config.settings import Settings

_EXTRA = (
    "Write realistic enterprise scenarios with decision triggers, stakeholders, "
    "constraints, and outcomes. Use tables for scenario comparison where helpful."
)


def build_scenario_writer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build specialist writer for scenario sections."""
    return build_section_writer_agent(
        settings,
        name="scenario_writer_agent",
        description="Writes enterprise scenario and decision-trigger documentation.",
        extra_instruction=_EXTRA,
    )
