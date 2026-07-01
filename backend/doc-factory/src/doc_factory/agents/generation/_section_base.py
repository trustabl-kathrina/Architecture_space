"""Shared section writer builder for specialist generation agents."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.common import retry_config
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.content import SectionDraft
from doc_factory.prompts.registry import load_prompt


def build_section_writer_agent(
    settings: Settings | None = None,
    *,
    name: str = "section_writer_agent",
    description: str = "Writes a generic documentation section.",
    extra_instruction: str = "",
    output_key: str = "section_draft",
) -> LlmAgent:
    """Build ADK agent for writing one SectionDraft from spec and research."""
    settings = settings or get_settings()
    base = (
        load_prompt("generation/section_writer.txt")
        .replace("{{ section_spec_json }}", "{section_spec}")
        .replace("{{ research_summary_json }}", "{research_summary}")
    )
    instruction = base
    if extra_instruction:
        instruction += f"\n\n{extra_instruction.strip()}"

    return LlmAgent(
        name=name,
        model=settings.gemini_model_pro,
        description=description,
        instruction=instruction,
        output_key=output_key,
        output_schema=SectionDraft,
        retry_config=retry_config(settings),
    )
