"""Normalize model output into clean markdown for display and .md storage."""

from __future__ import annotations

import json
import re

from kew_api.services.markdown_utils import split_front_matter

_JSON_FENCE = re.compile(r"```json\s*([\s\S]*?)\s*```", re.IGNORECASE)
_MARKDOWN_FENCE = re.compile(r"^```(?:markdown|md)?\s*\n([\s\S]*?)\n```\s*$", re.IGNORECASE)
_HTML_TAG = re.compile(r"<br\s*/?>", re.IGNORECASE)

_MARKDOWN_KEYS = (
    "response",
    "answer",
    "content",
    "message",
    "text",
    "reply",
    "proposed_body",
    "proposedBody",
    "body",
    "markdown",
)


def normalize_markdown_text(text: str, *, body_only: bool = False) -> str:
    """Coerce assistant/editor output into renderable markdown text."""
    cleaned = _unwrap_model_payload(text.strip())
    cleaned = _strip_code_fences(cleaned)
    cleaned = _HTML_TAG.sub("\n", cleaned)

    if body_only:
        _front, body = split_front_matter(cleaned)
        if body.strip():
            return body.strip()
        return cleaned.strip()

    return cleaned.strip()


def normalize_document_body(text: str) -> str:
    """Normalize markdown intended for the document body (no YAML front matter)."""
    return normalize_markdown_text(text, body_only=True)


def _unwrap_model_payload(text: str) -> str:
    if not text:
        return ""

    fence = _JSON_FENCE.search(text)
    if fence:
        inner = fence.group(1).strip()
        unwrapped = _extract_markdown_from_json(inner)
        if unwrapped:
            return unwrapped
        if not inner.startswith("{"):
            return inner

    if text.startswith("{"):
        unwrapped = _extract_markdown_from_json(text)
        if unwrapped:
            return unwrapped

    return text


def _extract_markdown_from_json(text: str) -> str | None:
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end <= start:
            return None
        try:
            data = json.loads(text[start : end + 1])
        except json.JSONDecodeError:
            return None

    if isinstance(data, str) and data.strip():
        return data.strip()

    if isinstance(data, dict):
        for key in _MARKDOWN_KEYS:
            value = data.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()

    return None


def _strip_code_fences(text: str) -> str:
    match = _MARKDOWN_FENCE.match(text)
    if match:
        return match.group(1).strip()

    if text.startswith("```"):
        lines = text.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        return "\n".join(lines).strip()

    return text
