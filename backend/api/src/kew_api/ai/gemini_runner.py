"""Google ADK + Gemini structured agent runner."""

from __future__ import annotations

import logging
import os
import uuid
from typing import Any, TypeVar

from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types
from pydantic import BaseModel, ValidationError

from kew_api.ai.errors import AiRunnerError
from kew_api.config.settings import ApiSettings

logger = logging.getLogger(__name__)

T = TypeVar("T", bound=BaseModel)


def ensure_gemini_env(settings: ApiSettings) -> None:
    key = settings.gemini_api_key
    if key is None or not key.get_secret_value().strip():
        msg = "GEMINI_API_KEY is required when KEW_API_AI_PROVIDER=gemini."
        raise AiRunnerError(msg)
    os.environ.setdefault("GOOGLE_API_KEY", key.get_secret_value())


async def run_gemini_structured_agent(
    agent: LlmAgent,
    *,
    user_message: str,
    output_key: str,
    output_model: type[T],
    settings: ApiSettings,
    session_state: dict[str, Any] | None = None,
) -> T:
    """Execute one ADK agent turn and parse structured output from session state."""
    ensure_gemini_env(settings)

    session_service = InMemorySessionService()
    runner = Runner(agent=agent, app_name="kew_api", session_service=session_service)
    session_id = str(uuid.uuid4())

    await session_service.create_session(
        app_name="kew_api",
        user_id="local",
        session_id=session_id,
        state=session_state or {},
    )

    message = types.Content(role="user", parts=[types.Part(text=user_message)])

    async for event in runner.run_async(
        user_id="local",
        session_id=session_id,
        new_message=message,
    ):
        if getattr(event, "error_code", None):
            raise AiRunnerError(
                getattr(event, "error_message", None) or f"ADK agent error: {event}"
            )

    session = await session_service.get_session(
        app_name="kew_api",
        user_id="local",
        session_id=session_id,
    )
    if session is None:
        raise AiRunnerError("ADK session missing after agent run")

    raw = session.state.get(output_key)
    if raw is None:
        raise AiRunnerError(f"Missing output key in session state: {output_key}")

    try:
        if isinstance(raw, output_model):
            return raw
        if isinstance(raw, dict):
            return output_model.model_validate(raw)
        if isinstance(raw, str):
            return output_model.model_validate_json(raw)
    except ValidationError as exc:
        raise AiRunnerError(f"Invalid agent output for {output_key}") from exc

    raise AiRunnerError(f"Unsupported agent output type: {type(raw).__name__}")
