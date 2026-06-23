"""Tests for shared state parsing."""

import pytest

from doc_factory.models.mvp import PlannerAgentOutput
from doc_factory.services.errors import PipelineStateError
from doc_factory.services.shared_state import parse_state_model


def _planner_dict() -> dict:
    section = {
        "section_id": "overview",
        "title": "Overview",
        "description": "Intro",
        "headings": ["Definition", "Scope"],
    }
    return {
        "topic": "Kafka",
        "topic_summary": "Streaming platform.",
        "objectives": ["Explain", "Compare"],
        "sections": [section, section, section, section],
        "research_queries": ["q1", "q2", "q3", "q4"],
        "research_plan": "Research first.",
    }


def test_parse_state_model_from_dict() -> None:
    result = parse_state_model(_planner_dict(), PlannerAgentOutput, key="planner_output")
    assert result.topic == "Kafka"


def test_parse_state_model_missing_raises() -> None:
    with pytest.raises(PipelineStateError):
        parse_state_model(None, PlannerAgentOutput, key="planner_output")
