"""Compatibility helpers for cursor-sdk bridge startup."""

from __future__ import annotations

import secrets


def cli_safe_auth_token() -> str:
    """Generate a bearer token that survives naive CLI parsers.

    cursor-sdk-bridge rejects argument values that start with ``-`` (see
    ``takeValue`` in cursor-sdk-bridge.js). ``secrets.token_urlsafe`` can
    produce such values ~1/64 of the time, which breaks bridge discovery.
    """
    while True:
        token = secrets.token_urlsafe(32)
        if token and not token.startswith("-"):
            return token


def patch_cursor_sdk_auth_tokens() -> None:
    """Patch cursor-sdk callback servers to use CLI-safe auth tokens."""
    import cursor_sdk._store_callback as store_callback
    import cursor_sdk._tool_callback as tool_callback

    store_callback._new_auth_token = cli_safe_auth_token
    tool_callback._new_auth_token = cli_safe_auth_token
