"""Tavily search tools for ADK Research Agent — quick, deep, and extract."""

from __future__ import annotations

import json
import logging
import re
from typing import Any

from google.adk.tools import FunctionTool

from doc_factory.config.settings import Settings, get_settings
from doc_factory.services.research_cache import ResearchCache
from doc_factory.services.tavily_client import TavilySearchClient

logger = logging.getLogger(__name__)

_tavily_client: TavilySearchClient | None = None
_research_cache: ResearchCache | None = None


def _get_client() -> TavilySearchClient:
    global _tavily_client
    if _tavily_client is None:
        _tavily_client = TavilySearchClient()
    return _tavily_client


def _get_cache() -> ResearchCache:
    global _research_cache
    if _research_cache is None:
        _research_cache = ResearchCache()
    return _research_cache


def _json_response(payload: dict[str, Any]) -> str:
    return json.dumps(payload, indent=2)


def _normalize_label(value: str) -> str:
    text = value.strip()
    if not text:
        return ""
    text = re.sub(r"\.md$", "", text, flags=re.IGNORECASE)
    text = text.replace("_", " ").replace("-", " ")
    text = re.sub(r"^\d+\s*", "", text)
    return re.sub(r"\s+", " ", text).strip()


def _parse_urls(urls: str) -> list[str]:
    text = urls.strip()
    if not text:
        return []
    if text.startswith("["):
        try:
            parsed = json.loads(text)
            if isinstance(parsed, list):
                return [str(url).strip() for url in parsed if str(url).strip()]
        except json.JSONDecodeError:
            pass
    return [part.strip() for part in re.split(r"[\n,]+", text) if part.strip()]


def _build_deep_queries(
    *,
    topic: str,
    query: str,
    capability: str,
    section: str,
    subsection: str,
    file_context: str,
    research_intent: str,
    settings: Settings,
) -> list[tuple[str, str]]:
    """Build diversified enterprise research queries from documentation context."""
    topic_label = _normalize_label(topic) or _normalize_label(query)
    if not topic_label:
        raise ValueError("topic or query is required for deep research.")

    candidates: list[tuple[str, str]] = []
    seen: set[str] = set()

    def add(query_text: str, intent: str) -> None:
        normalized = query_text.strip().lower()
        if not normalized or normalized in seen:
            return
        seen.add(normalized)
        candidates.append((query_text.strip(), intent))

    if query.strip():
        add(query.strip(), research_intent or "primary_query")

    capability_label = _normalize_label(capability)
    section_label = _normalize_label(section)
    subsection_label = _normalize_label(subsection)
    file_label = _normalize_label(file_context)
    intent_label = _normalize_label(research_intent)

    scope_parts = [part for part in (section_label, subsection_label, file_label) if part]
    scope = " ".join(scope_parts)

    add(f"{topic_label} enterprise architecture reference", "reference_architecture")
    add(f"{topic_label} architecture patterns components integration", "architecture")
    if capability_label:
        add(f"{topic_label} {capability_label} enterprise capability patterns", "capability")
    if scope:
        add(f"{topic_label} {scope} documentation enterprise", "section_scope")
    if intent_label:
        add(f"{topic_label} {intent_label} enterprise architecture", intent_label)
    else:
        add(f"{topic_label} implementation deployment operations best practices", "implementation")
        add(f"{topic_label} benchmarks performance scalability cost enterprise", "benchmarks")
        add(f"{topic_label} comparison alternatives selection criteria enterprise", "comparisons")

    add(f"{topic_label} governance security compliance enterprise platform", "governance")
    add(f"{topic_label} real-world enterprise use cases architecture scenarios", "scenarios")

    return candidates[: settings.tavily_deep_max_queries]


def search_web(query: str) -> str:
    """Run a focused web search for enterprise architecture evidence.

    Use for a single planned query from the research plan. For section-level
    or file-level gaps, prefer `deep_research` to fan out across angles.

    Args:
        query: Specific search query (architecture, benchmarks, comparisons, etc.).

    Returns:
        JSON with query, sources (title, url, snippet, score, source_type), and stats.
    """
    logger.info("search_web tool called: %s", query)
    cache = _get_cache()
    cached = cache.get(query)
    if cached is not None:
        sources = cached
    else:
        sources = _get_client().search(
            query,
            depth="advanced",
            include_raw_content=True,
        )
        cache.put(query, sources)

    return _json_response(
        {
            "mode": "quick",
            "query": query,
            "sources": [item.model_dump() for item in sources],
            "stats": {"source_count": len(sources)},
        }
    )


def deep_research(
    topic: str,
    query: str = "",
    capability: str = "",
    section: str = "",
    subsection: str = "",
    file_context: str = "",
    research_intent: str = "",
) -> str:
    """Run deep multi-query web research for a topic, capability, or doc section.

    Fans out across enterprise architecture angles (reference architecture,
    implementation, benchmarks, comparisons, governance, scenarios) scoped to
    the provided section, subsection, or target file. Returns richer snippets,
    relevance scores, optional Tavily answer synthesis, and extracted content
    from top authoritative URLs.

    Args:
        topic: Primary documentation topic or technology name.
        query: Optional primary query to run first (e.g. from research_queries).
        capability: Enterprise capability lens (e.g. semantic layer, CDC, lineage).
        section: Planned section title or section_id (e.g. Reference Architecture).
        subsection: Planned heading or subsection within the section.
        file_context: Target filename or path (e.g. 03_Reference_Architecture.md).
        research_intent: Evidence intent (overview, architecture, implementation,
            benchmarks, comparisons, governance, scenarios, best_practices).

    Returns:
        JSON with context, queries_executed, sources, extractions, answer, stats.
    """
    settings = get_settings()
    logger.info(
        "deep_research tool called: topic=%s section=%s file=%s intent=%s",
        topic,
        section,
        file_context,
        research_intent,
    )

    try:
        planned_queries = _build_deep_queries(
            topic=topic,
            query=query,
            capability=capability,
            section=section,
            subsection=subsection,
            file_context=file_context,
            research_intent=research_intent,
            settings=settings,
        )
    except ValueError as exc:
        return _json_response({"error": str(exc)})

    client = _get_client()
    sources, executed, answer = client.deep_search(planned_queries)

    top_urls = [
        item.url
        for item in sources[: settings.tavily_deep_extract_urls]
        if item.url
    ]
    focus = query.strip() or _normalize_label(research_intent) or topic
    extractions = client.extract_urls(top_urls, focus_query=focus) if top_urls else []

    for extraction in extractions:
        url = extraction.get("url", "")
        content = str(extraction.get("content", "")).strip()
        if not url or not content:
            continue
        for item in sources:
            if item.url == url and len(content) > len(item.snippet):
                item.snippet = content[: settings.tavily_snippet_max_chars]
                item.raw_content = content[: settings.tavily_snippet_max_chars]
                break

    return _json_response(
        {
            "mode": "deep",
            "context": {
                "topic": topic,
                "query": query,
                "capability": capability,
                "section": section,
                "subsection": subsection,
                "file_context": file_context,
                "research_intent": research_intent,
            },
            "queries_executed": executed,
            "answer": answer,
            "sources": [item.model_dump() for item in sources],
            "extractions": extractions,
            "stats": {
                "queries_run": len(executed),
                "unique_sources": len(sources),
                "urls_extracted": len(extractions),
            },
        }
    )


def extract_web_pages(urls: str, focus_query: str = "") -> str:
    """Extract detailed page content from specific URLs found during research.

    Use after search when a source URL needs full context (official docs,
    architecture guides, standards). Accepts comma- or newline-separated URLs
    or a JSON array string.

    Args:
        urls: One or more URLs to extract.
        focus_query: Optional query to pull the most relevant chunks per page.

    Returns:
        JSON with extractions (url, title, content) and stats.
    """
    parsed_urls = _parse_urls(urls)
    logger.info("extract_web_pages tool called: %d urls", len(parsed_urls))
    if not parsed_urls:
        return _json_response({"error": "No valid URLs provided.", "extractions": []})

    extractions = _get_client().extract_urls(parsed_urls, focus_query=focus_query)
    return _json_response(
        {
            "mode": "extract",
            "focus_query": focus_query,
            "extractions": extractions,
            "stats": {"urls_requested": len(parsed_urls), "urls_extracted": len(extractions)},
        }
    )


def build_tavily_tools() -> list[FunctionTool]:
    """Return ADK tools for quick search, deep research, and page extraction."""
    return [
        FunctionTool(search_web),
        FunctionTool(deep_research),
        FunctionTool(extract_web_pages),
    ]


def build_tavily_tool() -> FunctionTool:
    """Return primary Tavily tool (quick search) for backward compatibility."""
    return FunctionTool(search_web)


def reset_tavily_client() -> None:
    """Reset cached client and cache (for tests)."""
    global _tavily_client, _research_cache
    _tavily_client = None
    _research_cache = None
