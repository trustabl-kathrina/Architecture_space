"""Shared pipeline state keys and envelope."""

from __future__ import annotations

from typing import Final


class StateKeys:
    """Canonical ADK session.state keys for inter-agent communication."""

    TOPIC: Final[str] = "topic"
    PLANNER_OUTPUT: Final[str] = "planner_output"
    RESEARCH_OUTPUT: Final[str] = "research_output"
    STRUCTURE_OUTPUT: Final[str] = "structure_output"
    WRITER_OUTPUT: Final[str] = "writer_output"
    BENCHMARK_EVALUATION: Final[str] = "benchmark_evaluation"
    BENCHMARK_OUTPUT: Final[str] = "benchmark_output"
    COMPARISON_OUTPUT: Final[str] = "comparison_output"
    REVIEWER_OUTPUT: Final[str] = "reviewer_output"
    PUBLISH_MANIFEST: Final[str] = "publish_manifest"

    ALL_OUTPUT_KEYS: Final[tuple[str, ...]] = (
        PLANNER_OUTPUT,
        RESEARCH_OUTPUT,
        STRUCTURE_OUTPUT,
        WRITER_OUTPUT,
        BENCHMARK_OUTPUT,
        COMPARISON_OUTPUT,
        REVIEWER_OUTPUT,
        PUBLISH_MANIFEST,
    )


AGENT_PHASE_MAP: dict[str, str] = {
    "planner_agent": "planner",
    "research_agent": "research",
    "structure_agent": "structure",
    "writer_agent": "writer",
    "benchmark_agent": "benchmark",
    "comparison_agent": "comparison",
    "reviewer_agent": "reviewer",
    "markdown_publisher": "publisher",
}

PIPELINE_AGENT_ORDER: tuple[str, ...] = (
    "planner_agent",
    "research_agent",
    "structure_agent",
    "writer_agent",
    "benchmark_agent",
    "comparison_agent",
    "reviewer_agent",
    "markdown_publisher",
)
