"""Application settings via Pydantic Settings.

Responsibility:
- Load configuration from environment variables and optional .env file.
- Resolve filesystem paths (repo root, runs dir, output dir, templates).
- Provide typed access to Gemini/Tavily model names and pipeline limits.

Configuration strategy:
1. Secrets and overrides: environment variables (see .env.example).
2. Local overrides: `.env` in backend/doc-factory/ (gitignored).
3. Static defaults: `config/defaults.yaml` for non-secret pipeline defaults.
4. Runtime: `get_settings()` returns a cached Settings singleton.
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_PACKAGE_ROOT = Path(__file__).resolve().parents[2]
_FACTORY_ROOT = _PACKAGE_ROOT.parent
_REPO_ROOT = Path(__file__).resolve().parents[5]


class Settings(BaseSettings):
    """Typed configuration for Documentation AI Factory."""

    model_config = SettingsConfigDict(
        env_file=_FACTORY_ROOT / ".env",
        env_file_encoding="utf-8",
        env_prefix="DOC_FACTORY_",
        extra="ignore",
    )

    # API keys (required at pipeline runtime; optional for CLI --help during scaffolding)
    gemini_api_key: SecretStr | None = Field(default=None, validation_alias="GEMINI_API_KEY")
    tavily_api_key: SecretStr | None = Field(default=None, validation_alias="TAVILY_API_KEY")

    # Paths
    project_root: Path = Field(default=_FACTORY_ROOT)
    repo_root: Path = Field(default=_REPO_ROOT)
    runs_dir: Path | None = None
    output_dir: Path | None = None
    docs_root: Path | None = None
    templates_root: Path | None = None

    # Gemini models
    gemini_model_flash: str = "gemini-2.0-flash"
    gemini_model_pro: str = "gemini-2.5-pro"

    # Research
    tavily_max_results: int = 5
    research_cache_ttl_days: int = 7
    research_query_count: int = 10

    # Generation
    max_parallel_sections: int = 4
    min_section_words: int = 400

    # Pipeline resilience
    pipeline_max_retries: int = 3
    pipeline_retry_initial_delay: float = 2.0
    pipeline_retry_max_delay: float = 60.0
    pipeline_retry_backoff_factor: float = 2.0
    pipeline_publish_on_review_warning: bool = True

    # Logging
    log_level: str = "INFO"
    log_file: Path | None = None

    @field_validator("project_root", "repo_root", mode="before")
    @classmethod
    def _coerce_path(cls, value: str | Path) -> Path:
        return Path(value).resolve()

    @field_validator(
        "runs_dir",
        "output_dir",
        "docs_root",
        "templates_root",
        "log_file",
        mode="before",
    )
    @classmethod
    def _empty_path_to_none(cls, value: str | Path | None) -> Path | None:
        if value is None:
            return None
        if isinstance(value, str) and not value.strip():
            return None
        return Path(value)

    @property
    def resolved_runs_dir(self) -> Path:
        return (self.runs_dir or self.project_root / "runs").resolve()

    @property
    def resolved_output_dir(self) -> Path:
        return (self.output_dir or self.project_root / "output").resolve()

    @property
    def resolved_docs_root(self) -> Path:
        return (self.docs_root or self.repo_root / "docs").resolve()

    @property
    def resolved_templates_root(self) -> Path:
        return (self.templates_root or self.repo_root / "deployment" / "mkdocs" / "templates").resolve()

    @property
    def research_cache_dir(self) -> Path:
        return self.resolved_runs_dir / ".cache" / "tavily"


@lru_cache
def get_settings() -> Settings:
    """Return cached application settings."""
    return Settings()
