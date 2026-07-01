"""Run the editor agent with JSON + markdown fallbacks."""

from __future__ import annotations

import logging

from kew_api.ai.agents import build_editor_agent
from kew_api.ai.cursor_runner import run_cursor_text_agent
from kew_api.ai.errors import AiRunnerError
from kew_api.ai.prompts import load_prompt
from kew_api.ai.runner import run_structured_agent
from kew_api.config.settings import ApiSettings
from kew_api.schemas.chat import EditorPlanOutput
from kew_api.services.markdown_normalize import normalize_document_body, normalize_markdown_text

logger = logging.getLogger(__name__)


def _sanitize_proposed_body(raw: str) -> str:
    return normalize_document_body(raw)


def _infer_summary(proposed_body: str, user_prompt: str) -> str:
    for line in proposed_body.splitlines():
        heading = line.strip()
        if heading.startswith("#"):
            title = heading.lstrip("#").strip()
            if title:
                return title[:160]
    compact = " ".join(user_prompt.split())
    return compact[:160] if compact else "Document update"


def _markdown_system_prompt() -> str:
    base = load_prompt("editor")
    return (
        f"{base}\n\n"
        "IMPORTANT: Return ONLY the full updated markdown document BODY.\n"
        "- Do NOT use JSON.\n"
        "- Do NOT wrap the answer in code fences.\n"
        "- Do NOT include YAML front matter (--- blocks).\n"
        "- Output raw markdown text the editor can save directly."
    )


async def run_editor_plan(
    *,
    user_message: str,
    current_body: str,
    settings: ApiSettings,
) -> tuple[EditorPlanOutput, str]:
    """Return editor output and a short note on how it was produced."""
    if settings.ai_mock_mode:
        proposed_body = f"{current_body.rstrip()}\n\n## AI Suggested Section\n\nMock expansion content.\n"
        return (
            EditorPlanOutput(
                summary="Add AI Suggested Section",
                explanation="Mock change plan for testing.",
                proposed_body=proposed_body,
                confidence=0.85,
            ),
            "mock",
        )

    agent = build_editor_agent(settings)
    structured_error: AiRunnerError | None = None
    try:
        output = await run_structured_agent(
            agent,
            user_message=user_message,
            output_key="editor_output",
            output_model=EditorPlanOutput,
            settings=settings,
            system_prompt=load_prompt("editor"),
        )
        body = _sanitize_proposed_body(output.proposed_body)
        if not body.strip():
            raise AiRunnerError("Editor returned an empty proposed body")
        return (
            output.model_copy(update={"proposed_body": body}),
            "structured_json",
        )
    except AiRunnerError as exc:
        structured_error = exc
        logger.warning("Editor structured JSON failed, using markdown fallback: %s", exc)

    try:
        raw = await run_cursor_text_agent(
            system_prompt=_markdown_system_prompt(),
            user_message=user_message,
            settings=settings,
        )
    except AiRunnerError as markdown_exc:
        if settings._has_secret(settings.gemini_api_key):
            try:
                output = await run_structured_agent(
                    agent,
                    user_message=user_message,
                    output_key="editor_output",
                    output_model=EditorPlanOutput,
                    settings=settings,
                    system_prompt=_markdown_system_prompt(),
                )
                body = _sanitize_proposed_body(output.proposed_body)
                if body.strip():
                    return (
                        output.model_copy(update={"proposed_body": body}),
                        "gemini_fallback",
                    )
            except AiRunnerError as gemini_exc:
                logger.warning("Gemini markdown-path fallback failed: %s", gemini_exc)
        raise markdown_exc from structured_error
    proposed_body = _sanitize_proposed_body(raw)
    if not proposed_body.strip():
        raise AiRunnerError(
            "Editor could not produce a valid document body. "
            "Try a shorter, more specific edit request."
        ) from structured_error

    summary = _infer_summary(proposed_body, user_message)
    fallback_note = str(structured_error) if structured_error else "structured JSON unavailable"
    return (
        EditorPlanOutput(
            summary=summary,
            explanation=(
                "Change plan generated from markdown output because structured JSON "
                f"was invalid ({fallback_note})."
            ),
            proposed_body=proposed_body,
            confidence=0.72,
        ),
        "markdown_fallback",
    )
