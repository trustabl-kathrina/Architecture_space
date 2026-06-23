"""Google ADK agent definitions for interactive chat."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from kew_api.ai.prompts import load_prompt
from kew_api.config.settings import ApiSettings
from kew_api.schemas.chat import AdvisorOutput, EditorPlanOutput, IntentResult


def build_orchestrator_agent(settings: ApiSettings) -> LlmAgent:
    return LlmAgent(
        name="chat_orchestrator",
        model=settings.gemini_model_flash,
        description="Classifies chat intents for documentation assistance.",
        instruction=load_prompt("orchestrator"),
        output_key="intent_output",
        output_schema=IntentResult,
    )


def build_advisor_agent(settings: ApiSettings) -> LlmAgent:
    return LlmAgent(
        name="chat_advisor",
        model=settings.gemini_model_flash,
        description="Answers advisory questions about architecture documentation.",
        instruction=load_prompt("advisor"),
        output_key="advisor_output",
        output_schema=AdvisorOutput,
    )


def build_editor_agent(settings: ApiSettings) -> LlmAgent:
    return LlmAgent(
        name="chat_editor",
        model=settings.gemini_model_pro,
        description="Produces document change plans without applying edits.",
        instruction=load_prompt("editor"),
        output_key="editor_output",
        output_schema=EditorPlanOutput,
    )
