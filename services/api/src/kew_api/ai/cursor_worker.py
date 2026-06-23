"""Cursor SDK worker entrypoint (runs in a child process on Windows)."""

from __future__ import annotations


def execute_cursor_prompt(
    prompt: str,
    api_key: str,
    model: str,
    workspace: str,
    bridge_url: str,
    bridge_token: str,
) -> str:
    """Run a one-shot Cursor agent prompt via a pre-started bridge daemon."""
    from cursor_sdk import Agent, AgentOptions, Client, CursorAgentError, LocalAgentOptions

    client = Client(
        base_url=bridge_url,
        auth_token=bridge_token,
        allow_api_key_env_fallback=False,
    )

    try:
        result = Agent.prompt(
            prompt,
            AgentOptions(
                api_key=api_key,
                model=model,
                local=LocalAgentOptions(
                    cwd=workspace,
                    setting_sources=[],
                ),
            ),
            client=client,
        )
    except CursorAgentError as exc:
        msg = f"Cursor agent failed: {exc.message}"
        raise RuntimeError(msg) from exc
    finally:
        client.close()

    if result.status == "error":
        msg = f"Cursor agent run failed (run_id={result.id})"
        raise RuntimeError(msg)

    return result.result
