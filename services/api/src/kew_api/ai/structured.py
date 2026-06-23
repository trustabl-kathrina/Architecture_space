"""Parse structured JSON from model text output."""

from __future__ import annotations

import json
import logging
import re
from typing import Any, TypeVar

from pydantic import BaseModel, ValidationError

from kew_api.ai.errors import AiRunnerError
from kew_api.schemas.chat import ChatIntent

T = TypeVar("T", bound=BaseModel)

logger = logging.getLogger(__name__)

_JSON_FENCE = re.compile(r"```(?:json)?\s*([\s\S]*?)\s*```", re.IGNORECASE)
_TRAILING_COMMA = re.compile(r",(\s*[}\]])")
_STRING_FIELD = re.compile(
    r'"(?:response|answer|content|message|text|reply)"\s*:\s*"((?:\\.|[^"\\])*)"',
    re.DOTALL,
)
_EDITOR_STRING_FIELD = re.compile(
    r'"(?:proposed_body|proposedBody|body|markdown|content)"\s*:\s*"((?:\\.|[^"\\])*)"',
    re.DOTALL,
)
_SUMMARY_FIELD = re.compile(r'"(?:summary|title|headline)"\s*:\s*"((?:\\.|[^"\\])*)"', re.DOTALL)
_EXPLANATION_FIELD = re.compile(
    r'"(?:explanation|detail|rationale|description)"\s*:\s*"((?:\\.|[^"\\])*)"',
    re.DOTALL,
)

_INTENT_ALIASES: dict[str, ChatIntent] = {
    "advisory": ChatIntent.ADVISE,
    "advice": ChatIntent.ADVISE,
    "question": ChatIntent.ADVISE,
    "explain": ChatIntent.ADVISE,
    "explanation": ChatIntent.ADVISE,
    "qna": ChatIntent.ADVISE,
    "suggestion": ChatIntent.SUGGEST,
    "suggestions": ChatIntent.SUGGEST,
    "generate": ChatIntent.GENERATE_SECTION,
    "new_section": ChatIntent.GENERATE_SECTION,
    "edit": ChatIntent.EXPAND,
    "update": ChatIntent.IMPROVE,
    "rewrite": ChatIntent.IMPROVE,
}


def build_structured_prompt(*, system: str, user_message: str, output_model: type[BaseModel]) -> str:
    schema = json.dumps(output_model.model_json_schema(), indent=2)
    return (
        f"{system.strip()}\n\n"
        "Respond with ONLY valid JSON matching this schema. "
        "No markdown fences, no commentary before or after the JSON.\n"
        f"{schema}\n\n"
        "---\n"
        f"{user_message}"
    )


def _strip_outer_fences(text: str) -> str:
    fence = _JSON_FENCE.search(text)
    if fence:
        return fence.group(1).strip()
    return text.strip()


def _parse_first_json_value(text: str) -> Any | None:
    for start_char, end_char in (("{", "}"), ("[", "]")):
        start = text.find(start_char)
        if start == -1:
            continue
        try:
            value, _ = json.JSONDecoder().raw_decode(text[start:])
            return value
        except json.JSONDecodeError:
            end = text.rfind(end_char)
            if end > start:
                snippet = text[start : end + 1]
                try:
                    return _loads_lenient(snippet)
                except json.JSONDecodeError:
                    continue
    return None


def _loads_lenient(text: str) -> Any:
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        cleaned = _TRAILING_COMMA.sub(r"\1", text)
        return json.loads(cleaned)


def _normalize_intent_value(value: object) -> object:
    if not isinstance(value, str):
        return value
    normalized = value.lower().strip().replace("-", "_").replace(" ", "_")
    if normalized in {intent.value for intent in ChatIntent}:
        return normalized
    if normalized in _INTENT_ALIASES:
        return _INTENT_ALIASES[normalized].value
    for intent in ChatIntent:
        if normalized == intent.value or normalized in intent.value:
            return intent.value
    return value


def _coerce_for_model(data: Any, output_model: type[BaseModel]) -> Any:
    name = output_model.__name__

    if name == "AdvisorOutput":
        if isinstance(data, str) and data.strip():
            return {"response": data.strip()}
        if isinstance(data, dict):
            for key in ("response", "answer", "content", "message", "text", "reply"):
                value = data.get(key)
                if isinstance(value, str) and value.strip():
                    return {"response": value.strip()}

    if name == "IntentResult" and isinstance(data, dict):
        intent = _normalize_intent_value(data.get("intent", ""))
        merged = {**data, "intent": intent}
        if "requires_change_plan" not in merged:
            merged["requires_change_plan"] = False
        if "confidence" not in merged:
            merged["confidence"] = 0.7
        if "rationale" not in merged:
            merged["rationale"] = "Inferred from model output"
        if isinstance(merged.get("requires_change_plan"), str):
            merged["requires_change_plan"] = merged["requires_change_plan"].lower() in {
                "true",
                "1",
                "yes",
            }
        return merged

    if name == "EditorPlanOutput" and isinstance(data, dict):
        merged = dict(data)
        if "summary" not in merged:
            for key in ("title", "headline"):
                if key in merged:
                    merged["summary"] = merged[key]
                    break
        if "explanation" not in merged:
            for key in ("detail", "rationale", "description"):
                if key in merged:
                    merged["explanation"] = merged[key]
                    break
        if "proposed_body" not in merged:
            for key in ("proposedBody", "body", "markdown", "content"):
                if key in merged and isinstance(merged[key], str):
                    merged["proposed_body"] = merged[key]
                    break
        return merged

    return data


def _regex_extract_string_field(text: str) -> str | None:
    match = _STRING_FIELD.search(text)
    if not match:
        return None
    return _unescape_json_string(match.group(1))


def _unescape_json_string(value: str) -> str:
    try:
        return json.loads(f'"{value}"')
    except json.JSONDecodeError:
        return value.replace('\\"', '"').replace("\\n", "\n").replace("\\t", "\t")


def _looks_like_markdown_body(text: str) -> bool:
    stripped = text.strip()
    if not stripped:
        return False
    if stripped.startswith(("#", "-", "*", "|", ">")):
        return True
    return "\n## " in stripped or "\n# " in stripped or stripped.count("\n") >= 2


def _fallback_editor_output(raw: str) -> BaseModel | None:
    from kew_api.schemas.chat import EditorPlanOutput

    text = raw.strip()
    if not text:
        return None

    proposed = _regex_extract_editor_body(text)
    summary = _regex_extract_named_field(_SUMMARY_FIELD, text)
    explanation = _regex_extract_named_field(_EXPLANATION_FIELD, text)

    if proposed and proposed.strip():
        return EditorPlanOutput(
            summary=summary or _first_heading(proposed) or "Document update",
            explanation=explanation or "Inferred from partial editor JSON.",
            proposed_body=proposed.strip(),
            confidence=0.68,
        )

    stripped = _strip_outer_fences(text)
    if _looks_like_markdown_body(stripped):
        return EditorPlanOutput(
            summary=_first_heading(stripped) or "Document update",
            explanation="Inferred from markdown body in model output.",
            proposed_body=stripped,
            confidence=0.65,
        )

    return None


def _regex_extract_editor_body(text: str) -> str | None:
    match = _EDITOR_STRING_FIELD.search(text)
    if not match:
        return None
    return _unescape_json_string(match.group(1))


def _regex_extract_named_field(pattern: re.Pattern[str], text: str) -> str | None:
    match = pattern.search(text)
    if not match:
        return None
    value = _unescape_json_string(match.group(1)).strip()
    return value or None


def _first_heading(markdown: str) -> str | None:
    for line in markdown.splitlines():
        heading = line.strip()
        if heading.startswith("#"):
            title = heading.lstrip("#").strip()
            if title:
                return title[:160]
    return None


def _fallback_advisor_output(raw: str) -> BaseModel | None:
    from kew_api.schemas.chat import AdvisorOutput

    text = raw.strip()
    if not text:
        return None

    extracted = _regex_extract_string_field(text)
    if extracted and extracted.strip():
        return AdvisorOutput(response=extracted.strip())

    stripped = _strip_outer_fences(text)
    extracted = _regex_extract_string_field(stripped)
    if extracted and extracted.strip():
        return AdvisorOutput(response=extracted.strip())

    if stripped.startswith("{") or stripped.startswith("["):
        return None

    return AdvisorOutput(response=stripped)


def _fallback_intent_result(raw: str) -> BaseModel | None:
    from kew_api.schemas.chat import IntentResult

    text = raw.lower()
    requires_plan = any(
        token in text
        for token in (
            '"requires_change_plan": true',
            '"requires_change_plan":true',
            "requires_change_plan: true",
        )
    )
    intent = ChatIntent.EXPAND if requires_plan else ChatIntent.ADVISE
    for candidate in ChatIntent:
        if candidate.value in text:
            intent = candidate
            break

    return IntentResult(
        intent=intent,
        confidence=0.65,
        rationale="Inferred from unstructured model output",
        requires_change_plan=requires_plan,
    )


def _fallback_plain_text(raw: str, output_model: type[BaseModel]) -> BaseModel | None:
    name = output_model.__name__
    if name == "AdvisorOutput":
        return _fallback_advisor_output(raw)
    if name == "IntentResult":
        return _fallback_intent_result(raw)
    if name == "EditorPlanOutput":
        return _fallback_editor_output(raw)
    return None


def parse_structured_output(raw: str, output_model: type[T]) -> T:
    text = raw.strip()
    if not text:
        raise AiRunnerError("AI returned empty output")

    candidate = _strip_outer_fences(text)
    data = _parse_first_json_value(candidate)

    if data is None:
        fallback = _fallback_plain_text(raw, output_model)
        if fallback is not None:
            return fallback  # type: ignore[return-value]
        fallback = _fallback_plain_text(candidate, output_model)
        if fallback is not None:
            return fallback  # type: ignore[return-value]
        preview = raw.strip()[:200].replace("\n", " ")
        logger.warning("Structured parse failed (no JSON). preview=%r", preview)
        raise AiRunnerError(_friendly_parse_error(preview)) from None

    data = _coerce_for_model(data, output_model)

    try:
        return output_model.model_validate(data)
    except ValidationError as exc:
        fallback = _fallback_plain_text(raw, output_model)
        if fallback is not None:
            logger.info(
                "Structured validation failed for %s; using text fallback",
                output_model.__name__,
            )
            return fallback  # type: ignore[return-value]

        preview = raw.strip()[:200].replace("\n", " ")
        logger.warning(
            "Structured validation failed for %s: %s preview=%r",
            output_model.__name__,
            exc,
            preview,
        )
        raise AiRunnerError(_friendly_parse_error(preview)) from exc


def _friendly_parse_error(preview: str) -> str:
    lowered = preview.lower()
    if lowered.startswith("```mermaid") or "flowchart" in lowered:
        return (
            "The model returned a diagram instead of structured JSON. "
            "Rephrase as a question (e.g. 'show me an example flow') for a chat answer, "
            "or explicitly ask to 'add this to the document' for an edit plan."
        )
    return "The assistant returned an invalid response format. Please try again."
