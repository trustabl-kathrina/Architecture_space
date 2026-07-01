"""Unit tests for API configuration."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from kew_api.config.settings import ApiSettings, Environment, clear_settings_cache, get_settings


@pytest.fixture(autouse=True)
def _reset_settings_cache() -> None:
    clear_settings_cache()
    yield
    clear_settings_cache()


def test_default_settings_resolve_monorepo_paths() -> None:
    settings = ApiSettings()
    assert settings.repo_root.name == "Architecture_space"
    assert settings.resolved_docs_root == settings.repo_root / "docs"
    assert settings.resolved_data_root == settings.repo_root / ".data"


def test_environment_normalization() -> None:
    settings = ApiSettings(environment="PRODUCTION")
    assert settings.environment == Environment.PRODUCTION
    assert settings.is_production is True
    assert settings.reload is False
    assert settings.expose_error_details is False


def test_cors_origins_parsed_from_comma_string(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("KEW_API_CORS_ORIGINS", "http://a.test, http://b.test")
    settings = ApiSettings()
    assert settings.cors_origins == ["http://a.test", "http://b.test"]


def test_invalid_log_level_rejected() -> None:
    with pytest.raises(ValueError, match="Invalid log level"):
        ApiSettings(log_level="NOT_A_LEVEL")


def test_get_settings_is_cached() -> None:
    assert get_settings() is get_settings()


def test_clear_settings_cache() -> None:
    first = get_settings()
    clear_settings_cache()
    second = get_settings()
    assert first is not second


def test_ensure_runtime_directories(tmp_path: Path) -> None:
    settings = ApiSettings(data_root=tmp_path / "data", environment=Environment.DEVELOPMENT)
    settings.ensure_runtime_directories()
    assert (tmp_path / "data" / "runs").is_dir()
    assert (tmp_path / "data" / "output").is_dir()


def test_custom_env_file(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    env_file = tmp_path / "custom.env"
    env_file.write_text("KEW_API_PORT=9999\n", encoding="utf-8")
    monkeypatch.setenv("KEW_ENV_FILE", str(env_file))
    clear_settings_cache()
    settings = ApiSettings()
    assert settings.port == 9999
