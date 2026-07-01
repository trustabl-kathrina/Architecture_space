"""Template resolver — maps template_type to deployment/mkdocs/templates/ structures."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

import yaml

from doc_factory.config.settings import Settings, get_settings

_TEMPLATE_CATALOG_PATH = (
    Path(__file__).resolve().parents[1] / "taxonomy" / "template_catalog.yaml"
)


@lru_cache
def _load_catalog() -> dict:
    data = yaml.safe_load(_TEMPLATE_CATALOG_PATH.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else {}


class TemplateResolver:
    """Resolve template metadata and load base templates from the repo."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        self._catalog = _load_catalog()

    def required_headings(self, template_type: str) -> list[str]:
        """Return required headings for a template type."""
        templates = self._catalog.get("templates", {})
        entry = templates.get(template_type, {})
        headings = entry.get("required_headings", [])
        return [str(h) for h in headings]

    def source_template(self, template_type: str) -> str | None:
        """Return source template filename, if any."""
        templates = self._catalog.get("templates", {})
        entry = templates.get(template_type, {})
        value = entry.get("source_template")
        return str(value) if value else None

    def load_template_body(self, template_type: str) -> str | None:
        """Load template Markdown from deployment/mkdocs/templates/ if configured."""
        filename = self.source_template(template_type)
        if not filename:
            return None
        path = self._settings.resolved_templates_root / filename
        if not path.is_file():
            return None
        return path.read_text(encoding="utf-8")

    def list_template_types(self) -> list[str]:
        """Return all known template types."""
        templates = self._catalog.get("templates", {})
        return sorted(str(k) for k in templates)
