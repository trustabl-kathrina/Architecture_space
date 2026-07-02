"""ADK agent factory for the multi-agent documentation pipeline."""

from __future__ import annotations

from google.adk import Workflow
from google.adk.agents import LlmAgent
from google.adk.workflow._retry_config import RetryConfig

from doc_factory.agents.generation.benchmark_agent import build_benchmark_evaluation_agent
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.mvp import PlannerAgentOutput, ResearchAgentOutput
from doc_factory.models.pipeline import (
    ComparisonAgentOutput,
    ReviewerAgentOutput,
    StructureAgentOutput,
    WriterAgentOutput,
)
from doc_factory.prompts.registry import load_prompt
from doc_factory.tools.tavily_search import build_tavily_tools


def _retry(settings: Settings) -> RetryConfig:
    return RetryConfig(
        max_attempts=settings.pipeline_max_retries,
        initial_delay=settings.pipeline_retry_initial_delay,
        max_delay=settings.pipeline_retry_max_delay,
        backoff_factor=settings.pipeline_retry_backoff_factor,
    )


def build_planner_agent(settings: Settings) -> LlmAgent:
    return LlmAgent(
        name="planner_agent",
        model=settings.gemini_model_flash,
        description="Understands topics and creates documentation plans.",
        instruction=load_prompt("mvp/planner.txt"),
        output_key="planner_output",
        output_schema=PlannerAgentOutput,
        retry_config=_retry(settings),
    )


def build_research_agent(settings: Settings) -> LlmAgent:
    return LlmAgent(
        name="research_agent",
        model=settings.gemini_model_flash,
        description="Researches topics via Tavily and synthesizes findings.",
        instruction=load_prompt("mvp/research.txt"),
        tools=build_tavily_tools(),
        output_key="research_output",
        output_schema=ResearchAgentOutput,
        retry_config=_retry(settings),
    )


def build_structure_agent(settings: Settings) -> LlmAgent:
    return LlmAgent(
        name="structure_agent",
        model=settings.gemini_model_flash,
        description="Designs document structure from plan and research.",
        instruction=load_prompt("mvp/structure.txt"),
        output_key="structure_output",
        output_schema=StructureAgentOutput,
        retry_config=_retry(settings),
    )


def build_writer_agent(settings: Settings) -> LlmAgent:
    return LlmAgent(
        name="writer_agent",
        model=settings.gemini_model_pro,
        description="Writes core enterprise documentation sections.",
        instruction=load_prompt("mvp/writer.txt"),
        output_key="writer_output",
        output_schema=WriterAgentOutput,
        retry_config=_retry(settings),
    )


def build_benchmark_agent(settings: Settings) -> LlmAgent:
    return build_benchmark_evaluation_agent(settings, standalone=False)


def build_comparison_agent(settings: Settings) -> LlmAgent:
    return LlmAgent(
        name="comparison_agent",
        model=settings.gemini_model_pro,
        description="Produces technology comparison matrices.",
        instruction=load_prompt("mvp/comparison.txt"),
        output_key="comparison_output",
        output_schema=ComparisonAgentOutput,
        retry_config=_retry(settings),
    )


def build_reviewer_agent(settings: Settings) -> LlmAgent:
    return LlmAgent(
        name="reviewer_agent",
        model=settings.gemini_model_pro,
        description="Reviews, merges, and approves final documentation.",
        instruction=load_prompt("mvp/reviewer.txt"),
        output_key="reviewer_output",
        output_schema=ReviewerAgentOutput,
        retry_config=_retry(settings),
    )


def build_documentation_workflow(settings: Settings | None = None) -> Workflow:
    """Build the full multi-agent documentation pipeline workflow."""
    settings = settings or get_settings()

    planner = build_planner_agent(settings)
    research = build_research_agent(settings)
    structure = build_structure_agent(settings)
    writer = build_writer_agent(settings)
    benchmark = build_benchmark_agent(settings)
    comparison = build_comparison_agent(settings)
    reviewer = build_reviewer_agent(settings)

    return Workflow(
        name="documentation_factory_pipeline",
        description=(
            "Multi-agent pipeline: Planner -> Research -> Structure -> Writer -> "
            "Benchmark -> Comparison -> Reviewer"
        ),
        edges=[
            (
                "START",
                planner,
                research,
                structure,
                writer,
                benchmark,
                comparison,
                reviewer,
            ),
        ],
    )


root_agent = build_documentation_workflow()
