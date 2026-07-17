"""Cursor SDK structured agent runner."""

from __future__ import annotations

import asyncio
import logging
from typing import TypeVar

from pydantic import BaseModel

from kew_api.ai.bridge_manager import get_bridge_endpoint, shutdown_bridge_daemon
from kew_api.ai.cursor_pool import get_process_pool
from kew_api.ai.cursor_worker import execute_cursor_prompt
from kew_api.ai.errors import AiRunnerError
from kew_api.ai.structured import build_structured_prompt, parse_structured_output
from kew_api.config.settings import ApiSettings

logger = logging.getLogger(__name__)

T = TypeVar("T", bound=BaseModel)

_CURSOR_RETRY_DELAYS_SEC = (0.0, 2.0, 5.0)
_TRANSIENT_CURSOR_MARKERS = (
    "internal error",
    "internal server error",
    "upstream error",
    "unavailable",
    "timeout",
    "rate limit",
    "agent busy",
    "run failed",
    "connection",
    "connect call failed",
    "broken pipe",
    "reset by peer",
)


def _is_transient_cursor_error(message: str) -> bool:
    lowered = message.lower()
    return any(marker in lowered for marker in _TRANSIENT_CURSOR_MARKERS)


def _cursor_failure_message(exc: Exception) -> str:
    message = str(exc)
    lowered = message.lower()
    if "internal error" in lowered:
        return (
            "Cursor AI is temporarily unavailable (internal error). "
            "Verify CURSOR_API_KEY at https://cursor.com/dashboard/api-keys, "
            "retry in a moment, or set GEMINI_API_KEY for automatic fallback."
        )
    if "run failed" in lowered:
        return (
            f"Cursor AI could not complete the request ({message}). "
            "The bridge was restarted automatically — please retry. "
            "If this persists, verify CURSOR_API_KEY at "
            "https://cursor.com/dashboard/api-keys or set GEMINI_API_KEY for fallback."
        )
    return message


def ensure_cursor_env(settings: ApiSettings) -> str:
    key = settings.cursor_api_key
    if key is None or not key.get_secret_value().strip():
        msg = (
            "CURSOR_API_KEY is required when KEW_API_AI_PROVIDER=cursor. "
            "Create one at https://cursor.com/dashboard/api-keys"
        )
        raise AiRunnerError(msg)
    return key.get_secret_value().strip()


async def _invoke_cursor_prompt(
    *,
    prompt: str,
    api_key: str,
    settings: ApiSettings,
    workspace: str,
    endpoint_url: str,
    endpoint_token: str,
) -> str:
    """Run Cursor Agent.prompt with retries on transient bridge/API failures.

    On the final retry the bridge daemon is restarted first: consecutive
    "run failed" errors usually mean the daemon's Cursor connection went stale.
    """
    loop = asyncio.get_running_loop()
    pool = get_process_pool()
    last_error: Exception | None = None
    last_attempt = len(_CURSOR_RETRY_DELAYS_SEC) - 1

    for attempt, delay in enumerate(_CURSOR_RETRY_DELAYS_SEC):
        if delay:
            await asyncio.sleep(delay)
        if attempt == last_attempt and last_error is not None:
            try:
                logger.warning("Restarting Cursor bridge daemon before final retry")
                shutdown_bridge_daemon()
                endpoint = await loop.run_in_executor(None, get_bridge_endpoint, workspace)
                endpoint_url, endpoint_token = endpoint.url, endpoint.auth_token
            except Exception as exc:
                raise AiRunnerError(f"Cursor bridge restart failed: {exc}") from exc
        try:
            raw = await loop.run_in_executor(
                pool,
                execute_cursor_prompt,
                prompt,
                api_key,
                settings.cursor_model,
                workspace,
                endpoint_url,
                endpoint_token,
            )
        except RuntimeError as exc:
            last_error = exc
            if _is_transient_cursor_error(str(exc)) and attempt < last_attempt:
                logger.warning(
                    "Cursor prompt failed (attempt %s/%s), retrying: %s",
                    attempt + 1,
                    len(_CURSOR_RETRY_DELAYS_SEC),
                    exc,
                )
                continue
            raise AiRunnerError(_cursor_failure_message(exc)) from exc
        except Exception as exc:
            raise AiRunnerError(f"Cursor agent error: {exc}") from exc
        else:
            return raw

    raise AiRunnerError(_cursor_failure_message(last_error or RuntimeError("Cursor agent failed")))


async def run_cursor_structured_agent(
    *,
    system_prompt: str,
    user_message: str,
    output_model: type[T],
    settings: ApiSettings,
) -> T:
    """Run a one-shot Cursor agent and parse JSON into a Pydantic model."""
    api_key = ensure_cursor_env(settings)
    prompt = build_structured_prompt(
        system=system_prompt,
        user_message=user_message,
        output_model=output_model,
    )
    logger.debug("Cursor structured prompt length=%s", len(prompt))

    workspace = str(settings.repo_root)
    loop = asyncio.get_running_loop()

    try:
        endpoint = await loop.run_in_executor(None, get_bridge_endpoint, workspace)
    except AiRunnerError:
        raise
    except Exception as exc:
        raise AiRunnerError(f"Cursor bridge error: {exc}") from exc

    repair_hint = ""

    for attempt in range(2):
        full_prompt = prompt + repair_hint
        raw = await _invoke_cursor_prompt(
            prompt=full_prompt,
            api_key=api_key,
            settings=settings,
            workspace=workspace,
            endpoint_url=endpoint.url,
            endpoint_token=endpoint.auth_token,
        )

        try:
            return parse_structured_output(raw, output_model)
        except AiRunnerError as exc:
            if attempt == 0:
                logger.warning("Cursor structured output parse failed, retrying once: %s", exc)
                repair_hint = (
                    "\n\n---\n"
                    "IMPORTANT: Your previous reply was NOT valid JSON. "
                    "Return ONLY a single JSON object matching the schema. "
                    "No markdown fences, no prose outside the JSON."
                )
                continue
            raise

    raise AiRunnerError("Cursor agent failed to return valid structured output")


async def run_cursor_text_agent(
    *,
    system_prompt: str,
    user_message: str,
    settings: ApiSettings,
) -> str:
    """Run a Cursor agent and return raw text (no JSON parsing)."""
    api_key = ensure_cursor_env(settings)
    prompt = f"{system_prompt.strip()}\n\n{user_message}"
    workspace = str(settings.repo_root)
    loop = asyncio.get_running_loop()

    endpoint = await loop.run_in_executor(None, get_bridge_endpoint, workspace)
    raw = await _invoke_cursor_prompt(
        prompt=prompt,
        api_key=api_key,
        settings=settings,
        workspace=workspace,
        endpoint_url=endpoint.url,
        endpoint_token=endpoint.auth_token,
    )

    text = raw.strip()
    if not text:
        raise AiRunnerError("AI returned empty output")
    return text


def shutdown_cursor_runtime() -> None:
    """Release Cursor bridge and worker pool resources."""
    from kew_api.ai.cursor_pool import shutdown_process_pool

    shutdown_process_pool()
    shutdown_bridge_daemon()
