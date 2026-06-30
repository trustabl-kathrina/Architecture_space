"""Tests for keyword-based intent classification."""

from __future__ import annotations

from kew_api.ai.intent_heuristics import classify_intent_heuristic
from kew_api.schemas.chat import ChatIntent


def test_add_section_routes_to_change_plan() -> None:
    result = classify_intent_heuristic("Add a section about Kafka connectors")
    assert result.requires_change_plan is True
    assert result.intent in {ChatIntent.EXPAND, ChatIntent.GENERATE_SECTION}


def test_expand_section_routes_to_change_plan() -> None:
    result = classify_intent_heuristic("Please expand the overview section in the document")
    assert result.requires_change_plan is True
    assert result.intent is ChatIntent.EXPAND


def test_improve_section_routes_to_change_plan() -> None:
    result = classify_intent_heuristic("Improve clarity in this section")
    assert result.requires_change_plan is True
    assert result.intent is ChatIntent.IMPROVE


def test_question_stays_advisory() -> None:
    result = classify_intent_heuristic("What is event ingestion?")
    assert result.requires_change_plan is False
    assert result.intent is ChatIntent.ADVISE


def test_plan_mode_greeting_is_conversational() -> None:
    result = classify_intent_heuristic("Hi", folder_plan_scope=True)
    assert result.intent is ChatIntent.ADVISE
    assert result.requires_folder_plan is False


def test_plan_mode_structure_request_triggers_folder_plan() -> None:
    result = classify_intent_heuristic(
        "Design a semantic modeling documentation structure",
        folder_plan_scope=True,
    )
    assert result.requires_folder_plan is True
    assert result.requires_change_plan is False
