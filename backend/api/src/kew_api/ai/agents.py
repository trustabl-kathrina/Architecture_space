"""Google ADK agent definitions for interactive chat."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from kew_api.ai.prompts import load_prompt
from kew_api.config.settings import ApiSettings
from kew_api.schemas.chat import (
    AdvisorOutput,
    EditorPlanOutput,
    FolderAnalysisOutput,
    FolderExpertOutput,
    FolderPlanResult,
    IntentResult,
    TopicResearchOutput,
)


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


def build_folder_researcher_agent(settings: ApiSettings) -> LlmAgent:
    return LlmAgent(
        name="folder_researcher",
        model=settings.gemini_model_flash,
        description="Researches domain topics for folder planning.",
        instruction=load_prompt("folder_researcher"),
        output_key="research_output",
        output_schema=TopicResearchOutput,
    )


def build_folder_analyzer_agent(settings: ApiSettings) -> LlmAgent:
    return LlmAgent(
        name="folder_analyzer",
        model=settings.gemini_model_flash,
        description="Analyzes existing folder structure.",
        instruction=load_prompt("folder_analyzer"),
        output_key="analysis_output",
        output_schema=FolderAnalysisOutput,
    )


def build_folder_expert_agent(settings: ApiSettings) -> LlmAgent:
    return LlmAgent(
        name="folder_domain_expert",
        model=settings.gemini_model_flash,
        description="Provides domain expert recommendations for folder layout.",
        instruction=load_prompt("folder_domain_expert"),
        output_key="expert_output",
        output_schema=FolderExpertOutput,
    )


def build_folder_planner_agent(settings: ApiSettings) -> LlmAgent:
    return LlmAgent(
        name="folder_planner",
        model=settings.gemini_model_pro,
        description="Synthesizes target folder structure and reorganization plan.",
        instruction=load_prompt("folder_planner"),
        output_key="plan_output",
        output_schema=FolderPlanResult,
    )
