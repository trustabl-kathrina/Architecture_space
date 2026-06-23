"""WebResearcherAgent — execute Tavily searches from a query plan."""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from urllib.parse import urlparse

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.research import ResearchQueryPlan, SourceCorpus, SourceRecord
from doc_factory.services.research_cache import ResearchCache
from doc_factory.services.tavily_client import TavilySearchClient

logger = logging.getLogger(__name__)


def _domain(url: str) -> str:
    try:
        return urlparse(url).netloc or "unknown"
    except ValueError:
        return "unknown"


def execute_web_research(
    plan: ResearchQueryPlan,
    settings: Settings | None = None,
    *,
    use_cache: bool = True,
) -> SourceCorpus:
    """Execute Tavily searches for each query in the plan and return a SourceCorpus."""
    settings = settings or get_settings()
    client = TavilySearchClient(settings)
    cache = ResearchCache(settings) if use_cache else None

    sources: list[SourceRecord] = []
    seen_urls: set[str] = set()
    duplicate_count = 0

    for query in plan.queries:
        cached = cache.get(query.text) if cache else None
        if cached is not None:
            items = cached
        else:
            items = client.search(query.text, max_results=plan.max_results_per_query)
            if cache:
                cache.put(query.text, items)

        for index, item in enumerate(items):
            if item.url in seen_urls:
                duplicate_count += 1
                continue
            seen_urls.add(item.url)
            source_id = f"{query.query_id}-{index + 1}"
            sources.append(
                SourceRecord(
                    source_id=source_id,
                    url=item.url,
                    title=item.title,
                    snippet=item.snippet,
                    domain=_domain(item.url),
                    retrieved_at=datetime.now(UTC),
                    query_id=query.query_id,
                )
            )

    logger.info(
        "Web research complete: %d sources (%d duplicates skipped)",
        len(sources),
        duplicate_count,
    )
    return SourceCorpus(
        sources=sources,
        dedupe_stats={"duplicates_skipped": duplicate_count, "unique_urls": len(sources)},
    )
