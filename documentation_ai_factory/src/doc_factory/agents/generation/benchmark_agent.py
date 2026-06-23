"""Benchmark Agent — technology evaluation and comparison."""

from __future__ import annotations

from google.adk.agents import LlmAgent
from google.adk.workflow._retry_config import RetryConfig

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.benchmark import (
    BenchmarkAgentOutput,
    TechnologyBenchmarkEvaluation,
    apply_computed_rankings,
)
from doc_factory.prompts.registry import load_prompt
from doc_factory.rendering.benchmark_renderer import BenchmarkMarkdownRenderer


def _retry(settings: Settings) -> RetryConfig:
    return RetryConfig(
        max_attempts=settings.pipeline_max_retries,
        initial_delay=settings.pipeline_retry_initial_delay,
        max_delay=settings.pipeline_retry_max_delay,
        backoff_factor=settings.pipeline_retry_backoff_factor,
    )


def build_benchmark_evaluation_agent(
    settings: Settings | None = None,
    *,
    standalone: bool = False,
    topic: str | None = None,
) -> LlmAgent:
    """Build the Benchmark Agent for pipeline or standalone topic evaluation."""
    settings = settings or get_settings()
    instruction = load_prompt("benchmark/evaluation.txt")
    if standalone and topic:
        instruction = (
            instruction.replace("{topic}", topic)
            .replace("{planner_output}", "N/A")
            .replace("{research_output}", "N/A")
            .replace("{structure_output}", "N/A")
            .replace("{writer_output}", "N/A")
        )
    else:
        instruction = instruction.replace("{topic}", "{planner_output.topic}")

    return LlmAgent(
        name="benchmark_agent",
        model=settings.gemini_model_pro,
        description=(
            "Evaluates technologies with weighted scoring, comparison matrices, "
            "and enterprise adoption analysis."
        ),
        instruction=instruction,
        output_key="benchmark_evaluation",
        output_schema=TechnologyBenchmarkEvaluation,
        retry_config=_retry(settings),
    )


def finalize_benchmark_output(
    evaluation: TechnologyBenchmarkEvaluation,
    *,
    methodology: str = "",
    benchmark_notes: str = "",
) -> BenchmarkAgentOutput:
    """Apply computed rankings and render Markdown section."""
    normalized = apply_computed_rankings(evaluation)
    section = BenchmarkMarkdownRenderer().render_section(normalized)
    return BenchmarkAgentOutput(
        topic=normalized.topic,
        evaluation=normalized,
        section=section,
        methodology=methodology or (
            "Weighted multi-criteria decision analysis across 10 enterprise "
            "scoring categories with normalized weights summing to 1.0."
        ),
        benchmark_notes=benchmark_notes,
    )
