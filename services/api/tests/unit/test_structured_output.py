"""Unit tests for structured JSON parsing from AI text output."""

from __future__ import annotations

import pytest

from kew_api.ai.errors import AiRunnerError
from kew_api.ai.structured import parse_structured_output
from kew_api.schemas.chat import AdvisorOutput, ChatIntent, IntentResult


def test_parse_structured_output_from_json_fence() -> None:
    raw = """Here is the result:
```json
{
  "intent": "advise",
  "confidence": 0.9,
  "rationale": "Question only",
  "requires_change_plan": false
}
```"""
    result = parse_structured_output(raw, IntentResult)
    assert result.intent is ChatIntent.ADVISE
    assert result.requires_change_plan is False


def test_advisor_output_accepts_plain_markdown() -> None:
    raw = "## Overview\n\nBatch ingestion moves data on a schedule."
    result = parse_structured_output(raw, AdvisorOutput)
    assert "Batch ingestion" in result.response


def test_advisor_output_accepts_alias_fields() -> None:
    raw = '{"answer": "Use idempotent loads and checkpoints."}'
    result = parse_structured_output(raw, AdvisorOutput)
    assert "idempotent" in result.response


def test_advisor_output_accepts_json_fence_with_markdown() -> None:
    raw = """```json
{"response": "Here is a ```mermaid` diagram in the answer."}
```"""
    result = parse_structured_output(raw, AdvisorOutput)
    assert "mermaid" in result.response


def test_intent_result_normalizes_intent_case() -> None:
    raw = '{"intent": "ADVISE", "confidence": 0.8, "rationale": "ok", "requires_change_plan": false}'
    result = parse_structured_output(raw, IntentResult)
    assert result.intent is ChatIntent.ADVISE


def test_rejects_empty_output() -> None:
    with pytest.raises(AiRunnerError, match="empty"):
        parse_structured_output("   ", AdvisorOutput)


def test_intent_result_fallback_from_unstructured_text() -> None:
    raw = "I think this is advise intent with requires_change_plan: false"
    result = parse_structured_output(raw, IntentResult)
    assert result.intent is ChatIntent.ADVISE
    assert result.requires_change_plan is False


def test_advisor_output_regex_extracts_response_field() -> None:
    raw = 'Sure! {"response": "Event-driven architecture decouples producers and consumers."}'
    result = parse_structured_output(raw, AdvisorOutput)
    assert "Event-driven" in result.response


def test_intent_heuristic_classifies_edit_request() -> None:
    from kew_api.ai.intent_heuristics import classify_intent_heuristic

    result = classify_intent_heuristic("Please expand the overview section in the document")
    assert result.requires_change_plan is True
    assert result.intent is ChatIntent.EXPAND
