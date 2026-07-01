"""Settings tests for automatic AI mock mode and provider resolution."""

from __future__ import annotations

import pytest

from kew_api.config.settings import AiProvider, ApiSettings, Environment, clear_settings_cache


@pytest.fixture(autouse=True)
def _reset_settings_cache(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("kew_api.config.settings.discover_env_files", lambda: ())
    clear_settings_cache()
    yield
    clear_settings_cache()


def test_development_enables_mock_mode_without_keys(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    monkeypatch.delenv("CURSOR_API_KEY", raising=False)
    monkeypatch.delenv("KEW_API_AI_MOCK_MODE", raising=False)
    settings = ApiSettings(environment=Environment.DEVELOPMENT)
    assert settings.ai_mock_mode is True
    assert settings.resolved_ai_provider is AiProvider.MOCK


def test_development_uses_cursor_when_cursor_key_present(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    monkeypatch.setenv("CURSOR_API_KEY", "cursor_test_key")
    monkeypatch.setenv("KEW_API_AI_MOCK_MODE", "false")
    settings = ApiSettings(environment=Environment.DEVELOPMENT)
    assert settings.ai_mock_mode is False
    assert settings.resolved_ai_provider is AiProvider.CURSOR


def test_development_uses_gemini_when_only_gemini_key_present(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GEMINI_API_KEY", "test-key")
    monkeypatch.delenv("CURSOR_API_KEY", raising=False)
    monkeypatch.setenv("KEW_API_AI_MOCK_MODE", "false")
    settings = ApiSettings(environment=Environment.DEVELOPMENT)
    assert settings.ai_mock_mode is False
    assert settings.resolved_ai_provider is AiProvider.GEMINI


def test_auto_prefers_cursor_when_both_keys_present(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GEMINI_API_KEY", "test-key")
    monkeypatch.setenv("CURSOR_API_KEY", "cursor_test_key")
    monkeypatch.setenv("KEW_API_AI_MOCK_MODE", "false")
    settings = ApiSettings(environment=Environment.DEVELOPMENT, ai_provider="auto")
    assert settings.resolved_ai_provider is AiProvider.CURSOR
