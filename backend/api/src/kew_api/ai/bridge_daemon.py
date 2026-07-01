"""Long-lived Cursor SDK bridge daemon (run in a child process).

Prints JSON ``{url, auth_token}`` on stdout, then stays alive until terminated.
Uses asyncio subprocess I/O (Windows-safe) instead of selector-based pipe reads.
"""

from __future__ import annotations

import asyncio
import json
import sys


async def _run(workspace: str) -> None:
    from cursor_sdk import AsyncBridge

    from kew_api.ai.cursor_bridge_compat import patch_cursor_sdk_auth_tokens

    patch_cursor_sdk_auth_tokens()
    bridge = await AsyncBridge.launch(workspace=workspace, timeout=90)
    payload = {
        "url": bridge.endpoint.url,
        "auth_token": bridge.endpoint.auth_token,
    }
    print(json.dumps(payload), flush=True)

    try:
        await asyncio.Event().wait()
    finally:
        await bridge.aclose()


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: python -m kew_api.ai.bridge_daemon <workspace>", file=sys.stderr)
        raise SystemExit(2)

    workspace = sys.argv[1]
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
    asyncio.run(_run(workspace))


if __name__ == "__main__":
    main()
