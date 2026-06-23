"""Tests for markdown normalization."""

from __future__ import annotations

from kew_api.services.markdown_normalize import normalize_document_body, normalize_markdown_text


def test_unwraps_json_response_field() -> None:
    raw = '{"response": "## Title\\n\\nParagraph text."}'
    assert "## Title" in normalize_markdown_text(raw)


def test_strips_markdown_fence() -> None:
    raw = "```markdown\n## Section\n\nBody\n```"
    result = normalize_markdown_text(raw)
    assert result.startswith("## Section")
    assert "```" not in result


def test_document_body_strips_front_matter() -> None:
    raw = "---\ntitle: Test\n---\n\n## Body\n"
    assert normalize_document_body(raw) == "## Body"


def test_preserves_plain_markdown() -> None:
    raw = "## Overview\n\n- item one\n- item two"
    assert normalize_markdown_text(raw) == raw
