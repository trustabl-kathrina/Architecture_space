"""Dispatch structured AI tasks to the configured provider."""

from __future__ import annotations

from typing import Any, TypeVar

from google.adk.agents import LlmAgent
from pydantic import BaseModel

from kew_api.ai.errors import AdkRunnerError, AiRunnerError
from kew_api.config.settings import AiProvider, ApiSettings

T = TypeVar("T", bound=BaseModel)


async def run_structured_agent(
    agent: LlmAgent | None,
    *,
    user_message: str,
    output_key: str,
    output_model: type[T],
    settings: ApiSettings,
    session_state: dict[str, Any] | None = None,
    system_prompt: str | None = None,
) -> T:
    """Run a structured AI task using Cursor, Gemini, or raise if misconfigured."""
    provider = settings.resolved_ai_provider

    if provider == AiProvider.CURSOR:
        if not system_prompt:
            raise AiRunnerError("system_prompt is required for Cursor AI runs")
        from kew_api.ai.cursor_runner import run_cursor_structured_agent

        return await run_cursor_structured_agent(
            system_prompt=system_prompt,
            user_message=user_message,
            output_model=output_model,
            settings=settings,
        )

    if provider == AiProvider.GEMINI:
        if agent is None:
            raise AiRunnerError("ADK agent is required for Gemini AI runs")
        from kew_api.ai.gemini_runner import run_gemini_structured_agent

        return await run_gemini_structured_agent(
            agent,
            user_message=user_message,
            output_key=output_key,
            output_model=output_model,
            settings=settings,
            session_state=session_state,
        )

    raise AiRunnerError(
        "No AI provider is configured. Set CURSOR_API_KEY or GEMINI_API_KEY in .env, "
        "or enable KEW_API_AI_MOCK_MODE=true."
    )
