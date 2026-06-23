"""Tavily Search API client."""

from __future__ import annotations

import logging
from typing import Any

from tavily import TavilyClient

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.mvp import SourceItem

logger = logging.getLogger(__name__)


class TavilySearchClient:
    """Thin wrapper around tavily-python."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        api_key = self._settings.tavily_api_key
        if api_key is None or not api_key.get_secret_value().strip():
            raise ValueError("TAVILY_API_KEY is required for research.")
        self._client = TavilyClient(api_key=api_key.get_secret_value())

    def search(self, query: str, max_results: int | None = None) -> list[SourceItem]:
        """Execute one Tavily search and normalize results."""
        limit = max_results or self._settings.tavily_max_results
        logger.info("Tavily search: %s (max=%s)", query, limit)
        response: dict[str, Any] = self._client.search(
            query=query,
            max_results=limit,
            include_answer=False,
        )
        items: list[SourceItem] = []
        for row in response.get("results", []):
            url = str(row.get("url", "")).strip()
            if not url:
                continue
            items.append(
                SourceItem(
                    title=str(row.get("title", "Untitled")),
                    url=url,
                    snippet=str(row.get("content", row.get("snippet", "")))[:2000],
                    query=query,
                )
            )
        return items

    def search_queries(self, queries: list[str]) -> list[SourceItem]:
        """Run multiple queries and deduplicate by URL."""
        seen: set[str] = set()
        collected: list[SourceItem] = []
        for query in queries:
            for item in self.search(query):
                if item.url in seen:
                    continue
                seen.add(item.url)
                collected.append(item)
        return collected
