"""Tests for cursor-sdk bridge compatibility helpers."""

from __future__ import annotations

from kew_api.ai.cursor_bridge_compat import cli_safe_auth_token, patch_cursor_sdk_auth_tokens


def test_cli_safe_auth_token_never_starts_with_dash(monkeypatch) -> None:
    calls = {"n": 0}

    def fake_token(_nbytes: int) -> str:
        calls["n"] += 1
        return "-bad-token" if calls["n"] == 1 else "good-token"

    import secrets

    monkeypatch.setattr(secrets, "token_urlsafe", fake_token)
    assert cli_safe_auth_token() == "good-token"
    assert calls["n"] == 2


def test_patch_cursor_sdk_auth_tokens() -> None:
    import cursor_sdk._store_callback as store_callback
    import cursor_sdk._tool_callback as tool_callback

    patch_cursor_sdk_auth_tokens()
    assert store_callback._new_auth_token is cli_safe_auth_token
    assert tool_callback._new_auth_token is cli_safe_auth_token
    token = tool_callback._new_auth_token()
    assert not token.startswith("-")
