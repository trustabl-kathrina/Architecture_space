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


def ensure_cursor_env(settings: ApiSettings) -> str:
    key = settings.cursor_api_key
    if key is None or not key.get_secret_value().strip():
        msg = (
            "CURSOR_API_KEY is required when KEW_API_AI_PROVIDER=cursor. "
            "Create one at https://cursor.com/dashboard/api-keys"
        )
        raise AiRunnerError(msg)
    return key.get_secret_value().strip()


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

    pool = get_process_pool()
    repair_hint = ""

    for attempt in range(2):
        full_prompt = prompt + repair_hint
        try:
            raw = await loop.run_in_executor(
                pool,
                execute_cursor_prompt,
                full_prompt,
                api_key,
                settings.cursor_model,
                workspace,
                endpoint.url,
                endpoint.auth_token,
            )
        except RuntimeError as exc:
            raise AiRunnerError(str(exc)) from exc
        except Exception as exc:
            raise AiRunnerError(f"Cursor agent error: {exc}") from exc

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
    pool = get_process_pool()

    try:
        raw = await loop.run_in_executor(
            pool,
            execute_cursor_prompt,
            prompt,
            api_key,
            settings.cursor_model,
            workspace,
            endpoint.url,
            endpoint.auth_token,
        )
    except RuntimeError as exc:
        raise AiRunnerError(str(exc)) from exc
    except Exception as exc:
        raise AiRunnerError(f"Cursor agent error: {exc}") from exc

    text = raw.strip()
    if not text:
        raise AiRunnerError("AI returned empty output")
    return text


def shutdown_cursor_runtime() -> None:
    """Release Cursor bridge and worker pool resources."""
    from kew_api.ai.cursor_pool import shutdown_process_pool

    shutdown_process_pool()
    shutdown_bridge_daemon()
