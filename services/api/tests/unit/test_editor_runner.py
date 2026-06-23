"""Tests for editor plan runner and parsing fallbacks."""

from __future__ import annotations

import pytest

from kew_api.ai.structured import parse_structured_output
from kew_api.schemas.chat import EditorPlanOutput


def test_editor_output_accepts_raw_markdown_body() -> None:
    raw = "## Overview\n\nBatch ingestion runs on a schedule.\n"
    result = parse_structured_output(raw, EditorPlanOutput)
    assert result.summary == "Overview"
    assert "Batch ingestion" in result.proposed_body


def test_editor_output_extracts_partial_json_fields() -> None:
    raw = (
        '{"summary": "Add overview", "explanation": "Stub needs content", '
        '"proposed_body": "## Overview\\n\\nNew section text."}'
    )
    result = parse_structured_output(raw, EditorPlanOutput)
    assert result.summary == "Add overview"
    assert "New section" in result.proposed_body


def test_editor_output_from_markdown_fence() -> None:
    raw = """```markdown
## Event-Driven Architecture

Events are immutable facts.
```"""
    result = parse_structured_output(raw, EditorPlanOutput)
    assert "Event-Driven Architecture" in result.proposed_body


def test_editor_output_rejects_empty_body() -> None:
    with pytest.raises(Exception):
        parse_structured_output("{}", EditorPlanOutput)
