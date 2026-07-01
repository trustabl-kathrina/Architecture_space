"""Research cache — TTL-based Tavily response cache."""

from __future__ import annotations

import hashlib
import json
import logging
from datetime import UTC, datetime, timedelta
from pathlib import Path

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.mvp import SourceItem

logger = logging.getLogger(__name__)


class ResearchCache:
    """File-based TTL cache for Tavily search results."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        self._cache_dir = self._settings.research_cache_dir
        self._cache_dir.mkdir(parents=True, exist_ok=True)
        self._ttl = timedelta(days=self._settings.research_cache_ttl_days)

    def _path_for(self, query: str) -> Path:
        digest = hashlib.sha256(query.encode("utf-8")).hexdigest()
        return self._cache_dir / f"{digest}.json"

    def get(self, query: str) -> list[SourceItem] | None:
        """Return cached results if present and not expired."""
        path = self._path_for(query)
        if not path.is_file():
            return None
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            cached_at = datetime.fromisoformat(payload["cached_at"])
            if datetime.now(UTC) - cached_at > self._ttl:
                path.unlink(missing_ok=True)
                return None
            return [SourceItem.model_validate(item) for item in payload["items"]]
        except (json.JSONDecodeError, KeyError, ValueError) as exc:
            logger.warning("Invalid cache entry %s: %s", path.name, exc)
            path.unlink(missing_ok=True)
            return None

    def put(self, query: str, items: list[SourceItem]) -> None:
        """Store search results in cache."""
        path = self._path_for(query)
        payload = {
            "query": query,
            "cached_at": datetime.now(UTC).isoformat(),
            "items": [item.model_dump() for item in items],
        }
        path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def clear(self) -> int:
        """Remove all cache files; returns count removed."""
        removed = 0
        for path in self._cache_dir.glob("*.json"):
            path.unlink(missing_ok=True)
            removed += 1
        return removed
