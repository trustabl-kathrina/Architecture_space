"""Smoke tests for project scaffolding."""

from doc_factory import __version__
from doc_factory.config.settings import Settings


def test_package_version() -> None:
    assert __version__ == "0.1.0"


def test_settings_resolve_paths(settings: Settings) -> None:
    assert settings.resolved_runs_dir == settings.runs_dir
    assert settings.resolved_output_dir == settings.output_dir
    assert settings.resolved_docs_root.name == "docs"
    assert settings.resolved_templates_root.parts[-3:] == ("tools", "docs", "templates")
