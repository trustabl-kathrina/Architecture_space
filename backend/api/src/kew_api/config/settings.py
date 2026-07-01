"""API service settings via Pydantic Settings.

Configuration strategy (highest precedence last):
1. Field defaults on ``ApiSettings``.
2. ``.env`` files (monorepo root, then ``backend/api/.env``).
3. Environment variables with ``KEW_API_`` prefix (and selected unprefixed keys).
4. Optional ``KEW_ENV_FILE`` pointing at a custom dotenv path.

Secrets and engine keys (``GEMINI_API_KEY``, ``DOC_FACTORY_*``) are read from the
same monorepo ``.env`` when present; the API layer does not duplicate engine config.
"""

from __future__ import annotations

import logging
import os
from enum import StrEnum
from functools import lru_cache
from pathlib import Path
from typing import Annotated, Any, Self

from pydantic import BeforeValidator, Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, NoDecode, PydanticBaseSettingsSource, SettingsConfigDict


def _parse_cors_origins(value: object) -> list[str]:
    """Accept JSON arrays or comma-separated origin lists from env vars."""
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        stripped = value.strip()
        if stripped.startswith("["):
            import json

            parsed = json.loads(stripped)
            if not isinstance(parsed, list):
                msg = "cors_origins JSON value must be an array"
                raise TypeError(msg)
            return [str(item).strip() for item in parsed if str(item).strip()]
        return [origin.strip() for origin in value.split(",") if origin.strip()]
    msg = f"Unsupported cors_origins value type: {type(value).__name__}"
    raise TypeError(msg)

# backend/api/src/kew_api/config/settings.py → repo root is parents[5]
_CONFIG_DIR = Path(__file__).resolve().parent
_PACKAGE_ROOT = _CONFIG_DIR.parent
_SRC_ROOT = _PACKAGE_ROOT.parent
_API_ROOT = _SRC_ROOT.parent
_BACKEND_ROOT = _API_ROOT.parent
_REPO_ROOT = _BACKEND_ROOT.parent

_VALID_LOG_LEVELS = frozenset(logging.getLevelNamesMapping())


class Environment(StrEnum):
    """Deployment environment."""

    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"


class AiProvider(StrEnum):
    """Resolved AI backend for interactive chat."""

    MOCK = "mock"
    CURSOR = "cursor"
    GEMINI = "gemini"


class AiProviderPreference(StrEnum):
    """Explicit AI provider selection from env."""

    AUTO = "auto"
    CURSOR = "cursor"
    GEMINI = "gemini"


def discover_env_files() -> tuple[str, ...]:
    """Return existing dotenv files in load order (later overrides earlier)."""
    candidates: list[Path] = [
        _REPO_ROOT / ".env",
        _API_ROOT / ".env",
    ]

    custom = os.environ.get("KEW_ENV_FILE", "").strip()
    if custom:
        candidates.append(Path(custom))

    seen: set[Path] = set()
    resolved: list[str] = []
    for path in candidates:
        absolute = path.resolve()
        if absolute in seen:
            continue
        seen.add(absolute)
        if absolute.is_file():
            resolved.append(str(absolute))
    return tuple(resolved)


class ApiSettings(BaseSettings):
    """Typed configuration for the KEW FastAPI service."""

    model_config = SettingsConfigDict(
        env_file_encoding="utf-8",
        env_prefix="KEW_API_",
        env_nested_delimiter="__",
        extra="ignore",
        case_sensitive=False,
    )

    # --- Application ---------------------------------------------------------

    app_name: str = "Knowledge Engineering Workbench API"
    app_version: str = Field(default="0.1.0", description="API version string")
    environment: Environment = Environment.DEVELOPMENT
    debug: bool = False

    # --- Server --------------------------------------------------------------

    host: str = "127.0.0.1"
    port: int = Field(default=8000, ge=1, le=65535)
    reload: bool = True
    workers: int = Field(default=1, ge=1, le=32)

    # --- HTTP / WebSocket ----------------------------------------------------

    api_v1_prefix: str = "/api/v1"
    ws_prefix: str = "/ws"
    cors_origins: Annotated[list[str], NoDecode, BeforeValidator(_parse_cors_origins)] = Field(
        default_factory=lambda: [
            "http://127.0.0.1:5173",
            "http://localhost:5173",
        ]
    )
    ws_ping_interval_seconds: int = Field(default=30, ge=5, le=300)
    request_timeout_seconds: float = Field(default=120.0, ge=1.0)

    # --- Paths (resolved against monorepo root) ------------------------------

    repo_root: Path = Field(default=_REPO_ROOT)
    api_root: Path = Field(default=_API_ROOT)
    docs_root: Path | None = None
    data_root: Path | None = None

    # --- AI (Cursor SDK / Gemini ADK) ----------------------------------------

    ai_provider: AiProviderPreference = Field(
        default=AiProviderPreference.AUTO,
        description="AI backend: auto (prefer Cursor, then Gemini), cursor, or gemini",
    )
    cursor_api_key: SecretStr | None = Field(default=None, validation_alias="CURSOR_API_KEY")
    cursor_model: str = "composer-2.5"
    gemini_api_key: SecretStr | None = Field(default=None, validation_alias="GEMINI_API_KEY")
    gemini_model_flash: str = "gemini-2.0-flash"
    gemini_model_pro: str = "gemini-2.5-pro"
    ai_mock_mode: bool = Field(
        default=False,
        description="Return deterministic mock AI responses (for tests)",
    )

    # --- Logging -------------------------------------------------------------

    log_level: str = "INFO"
    log_file: Path | None = None
    log_json: bool = False

    # --- Health / observability ----------------------------------------------

    expose_error_details: bool = Field(
        default=True,
        description="Include exception detail in JSON error responses (disable in production)",
    )

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ) -> tuple[PydanticBaseSettingsSource, ...]:
        """Load dotenv files discovered at instantiation time (supports KEW_ENV_FILE)."""
        from pydantic_settings import DotEnvSettingsSource

        dynamic_dotenv = DotEnvSettingsSource(
            settings_cls,
            env_file=discover_env_files(),
            env_file_encoding="utf-8",
        )
        return (
            init_settings,
            env_settings,
            dynamic_dotenv,
            file_secret_settings,
        )

    @field_validator("environment", mode="before")
    @classmethod
    def _normalize_environment(cls, value: Any) -> Any:
        if isinstance(value, str):
            return value.strip().lower()
        return value

    @field_validator("repo_root", "api_root", mode="before")
    @classmethod
    def _coerce_required_path(cls, value: str | Path) -> Path:
        return Path(value).expanduser().resolve()

    @field_validator("docs_root", "data_root", "log_file", mode="before")
    @classmethod
    def _coerce_optional_path(cls, value: str | Path | None) -> Path | None:
        if value is None:
            return None
        if isinstance(value, str) and not value.strip():
            return None
        return Path(value).expanduser().resolve()

    @field_validator("log_level")
    @classmethod
    def _validate_log_level(cls, value: str) -> str:
        normalized = value.upper()
        if normalized not in _VALID_LOG_LEVELS:
            allowed = ", ".join(sorted(_VALID_LOG_LEVELS))
            msg = f"Invalid log level {value!r}; expected one of: {allowed}"
            raise ValueError(msg)
        return normalized

    @model_validator(mode="after")
    def _apply_environment_defaults(self) -> Self:
        if self.environment == Environment.PRODUCTION:
            object.__setattr__(self, "debug", False)
            object.__setattr__(self, "reload", False)
            object.__setattr__(self, "expose_error_details", False)
            object.__setattr__(self, "log_json", True)
        elif self.environment == Environment.DEVELOPMENT and not self.debug:
            object.__setattr__(self, "debug", True)
        return self

    @model_validator(mode="after")
    def _apply_ai_defaults(self) -> Self:
        """Resolve mock vs live AI from env + available provider keys."""
        has_gemini = self._has_secret(self.gemini_api_key)
        has_cursor = self._has_secret(self.cursor_api_key)
        mock_env = os.environ.get("KEW_API_AI_MOCK_MODE", "").strip().lower()

        if mock_env in ("true", "1"):
            object.__setattr__(self, "ai_mock_mode", True)
        elif mock_env in ("false", "0"):
            object.__setattr__(self, "ai_mock_mode", False)
        elif self.is_development and not has_gemini and not has_cursor:
            object.__setattr__(self, "ai_mock_mode", True)
        elif has_gemini or has_cursor:
            object.__setattr__(self, "ai_mock_mode", False)
        return self

    @staticmethod
    def _has_secret(value: SecretStr | None) -> bool:
        return value is not None and bool(value.get_secret_value().strip())

    @property
    def resolved_ai_provider(self) -> AiProvider:
        """Pick the live AI backend (mock mode bypasses this in ChatService)."""
        if self.ai_mock_mode:
            return AiProvider.MOCK

        has_gemini = self._has_secret(self.gemini_api_key)
        has_cursor = self._has_secret(self.cursor_api_key)

        if self.ai_provider == AiProviderPreference.CURSOR:
            return AiProvider.CURSOR if has_cursor else AiProvider.MOCK
        if self.ai_provider == AiProviderPreference.GEMINI:
            return AiProvider.GEMINI if has_gemini else AiProvider.MOCK

        if has_cursor:
            return AiProvider.CURSOR
        if has_gemini:
            return AiProvider.GEMINI
        return AiProvider.MOCK

    @property
    def is_development(self) -> bool:
        return self.environment == Environment.DEVELOPMENT

    @property
    def is_production(self) -> bool:
        return self.environment == Environment.PRODUCTION

    @property
    def resolved_docs_root(self) -> Path:
        return (self.docs_root or self.repo_root / "docs").resolve()

    @property
    def resolved_data_root(self) -> Path:
        return (self.data_root or self.repo_root / ".data").resolve()

    @property
    def resolved_runs_dir(self) -> Path:
        return (self.resolved_data_root / "runs").resolve()

    @property
    def resolved_output_dir(self) -> Path:
        return (self.resolved_data_root / "output").resolve()

    @property
    def resolved_conversations_dir(self) -> Path:
        return (self.resolved_data_root / "conversations").resolve()

    @property
    def resolved_edits_dir(self) -> Path:
        return (self.resolved_data_root / "edits").resolve()

    @property
    def resolved_log_file(self) -> Path | None:
        if self.log_file is not None:
            return self.log_file.resolve()
        if self.is_production:
            return (self.resolved_data_root / "logs" / "api.log").resolve()
        return None

    @property
    def server_url(self) -> str:
        return f"http://{self.host}:{self.port}"

    @property
    def openapi_url(self) -> str | None:
        return f"{self.api_v1_prefix}/openapi.json" if self.debug else None

    def ensure_runtime_directories(self) -> None:
        """Create data directories required at startup."""
        for path in (
            self.resolved_data_root,
            self.resolved_runs_dir,
            self.resolved_output_dir,
            self.resolved_conversations_dir,
            self.resolved_edits_dir,
            self.resolved_data_root / "section_context",
        ):
            path.mkdir(parents=True, exist_ok=True)
        log_target = self.resolved_log_file
        if log_target is not None:
            log_target.parent.mkdir(parents=True, exist_ok=True)


@lru_cache
def get_settings() -> ApiSettings:
    """Return cached API settings singleton."""
    settings = ApiSettings()
    settings.ensure_runtime_directories()
    return settings


def clear_settings_cache() -> None:
    """Clear settings cache (use in tests)."""
    get_settings.cache_clear()
