"""Tavily Search API client."""

from __future__ import annotations

import logging
from typing import Any, Literal
from urllib.parse import urlparse

from tavily import TavilyClient

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.mvp import SourceItem

logger = logging.getLogger(__name__)

SearchDepth = Literal["basic", "advanced"]


class TavilySearchClient:
    """Wrapper around tavily-python with quick and deep research profiles."""

    _OFFICIAL_DOMAIN_HINTS = (
        "apache.org",
        "kubernetes.io",
        "cncf.io",
        "cloud.google.com",
        "docs.aws.amazon.com",
        "learn.microsoft.com",
        "azure.microsoft.com",
        "github.com",
        "nist.gov",
        "opentelemetry.io",
    )

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        api_key = self._settings.tavily_api_key
        if api_key is None or not api_key.get_secret_value().strip():
            raise ValueError("TAVILY_API_KEY is required for research.")
        self._client = TavilyClient(api_key=api_key.get_secret_value())

    def search(
        self,
        query: str,
        max_results: int | None = None,
        *,
        depth: SearchDepth = "basic",
        include_raw_content: bool = False,
        include_answer: bool = False,
        intent: str = "",
    ) -> list[SourceItem]:
        """Execute one Tavily search and normalize results."""
        response = self._raw_search(
            query,
            max_results=max_results,
            depth=depth,
            include_raw_content=include_raw_content,
            include_answer=include_answer,
        )
        return self._normalize_results(
            response.get("results", []),
            query=query,
            intent=intent,
            include_raw_content=include_raw_content,
        )

    def _raw_search(
        self,
        query: str,
        *,
        max_results: int | None = None,
        depth: SearchDepth = "basic",
        include_raw_content: bool = False,
        include_answer: bool = False,
    ) -> dict[str, Any]:
        limit = max_results or self._settings.tavily_max_results
        logger.info("Tavily search: %s (max=%s, depth=%s)", query, limit, depth)
        return self._client.search(
            query=query,
            max_results=limit,
            search_depth=depth,
            include_answer=include_answer,
            include_raw_content=include_raw_content,
        )

    def deep_search(
        self,
        queries: list[tuple[str, str]],
        *,
        include_answer_on_first: bool = True,
    ) -> tuple[list[SourceItem], list[str], str | None]:
        """Run multiple advanced searches and deduplicate by URL."""
        seen: set[str] = set()
        collected: list[SourceItem] = []
        executed: list[str] = []
        answer: str | None = None

        for index, (query, intent) in enumerate(queries):
            response = self._raw_search(
                query,
                max_results=self._settings.tavily_deep_max_results,
                depth="advanced",
                include_raw_content=True,
                include_answer=include_answer_on_first and index == 0,
            )
            if answer is None and include_answer_on_first and index == 0:
                raw_answer = response.get("answer")
                if isinstance(raw_answer, str) and raw_answer.strip():
                    answer = raw_answer.strip()

            executed.append(query)
            items = self._normalize_results(
                response.get("results", []),
                query=query,
                intent=intent,
                include_raw_content=True,
            )
            for item in items:
                if item.url in seen:
                    continue
                seen.add(item.url)
                collected.append(item)

        collected.sort(
            key=lambda item: (item.score is None, -(item.score or 0.0)),
        )
        return collected, executed, answer

    def extract_urls(
        self,
        urls: list[str],
        *,
        focus_query: str = "",
        extract_depth: SearchDepth = "advanced",
    ) -> list[dict[str, Any]]:
        """Extract page content from URLs using Tavily Extract."""
        cleaned = [url.strip() for url in urls if url.strip()]
        if not cleaned:
            return []

        logger.info("Tavily extract: %d urls (focus=%s)", len(cleaned), focus_query or "none")
        kwargs: dict[str, Any] = {
            "urls": cleaned,
            "extract_depth": extract_depth,
        }
        if focus_query.strip():
            kwargs["query"] = focus_query.strip()
            kwargs["chunks_per_source"] = 3

        response: dict[str, Any] = self._client.extract(**kwargs)
        extractions: list[dict[str, Any]] = []
        for row in response.get("results", []):
            url = str(row.get("url", "")).strip()
            if not url:
                continue
            content = str(row.get("raw_content", row.get("content", ""))).strip()
            extractions.append(
                {
                    "url": url,
                    "title": str(row.get("title", "")).strip(),
                    "content": content[: self._settings.tavily_snippet_max_chars],
                    "focus_query": focus_query,
                }
            )
        return extractions

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

    def _normalize_results(
        self,
        rows: list[dict[str, Any]],
        *,
        query: str,
        intent: str,
        include_raw_content: bool,
    ) -> list[SourceItem]:
        items: list[SourceItem] = []
        max_chars = self._settings.tavily_snippet_max_chars
        for row in rows:
            url = str(row.get("url", "")).strip()
            if not url:
                continue
            snippet_source = row.get("content", row.get("snippet", ""))
            raw_content = ""
            if include_raw_content:
                raw_content = str(row.get("raw_content", snippet_source))[:max_chars]
            snippet = str(snippet_source)[:max_chars]
            if raw_content and len(raw_content) > len(snippet):
                snippet = raw_content[:max_chars]

            score_value = row.get("score")
            score = float(score_value) if score_value is not None else None
            items.append(
                SourceItem(
                    title=str(row.get("title", "Untitled")),
                    url=url,
                    snippet=snippet,
                    query=query,
                    score=score,
                    raw_content=raw_content,
                    intent=intent,
                    source_type=self._classify_source(url),
                )
            )
        return items

    @classmethod
    def _classify_source(cls, url: str) -> str:
        domain = urlparse(url).netloc.lower()
        if any(hint in domain for hint in cls._OFFICIAL_DOMAIN_HINTS):
            return "official"
        if domain.endswith(".gov") or domain.endswith(".edu"):
            return "standards"
        if "blog" in domain or "medium.com" in domain or "dev.to" in domain:
            return "engineering"
        return "unknown"
