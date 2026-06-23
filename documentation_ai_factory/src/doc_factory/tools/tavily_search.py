"""Tavily search tool for ADK Research Agent."""

from __future__ import annotations

import json
import logging

from google.adk.tools import FunctionTool

from doc_factory.services.tavily_client import TavilySearchClient

logger = logging.getLogger(__name__)

_tavily_client: TavilySearchClient | None = None


def _get_client() -> TavilySearchClient:
    global _tavily_client
    if _tavily_client is None:
        _tavily_client = TavilySearchClient()
    return _tavily_client


def search_web(query: str) -> str:
    """Search the web for enterprise architecture information about a topic.

    Args:
        query: A specific search query (architecture, benchmarks, comparisons, etc.).

    Returns:
        JSON list of sources with title, url, and snippet fields.
    """
    logger.info("search_web tool called: %s", query)
    results = _get_client().search(query)
    payload = [item.model_dump() for item in results]
    return json.dumps(payload, indent=2)


def build_tavily_tool() -> FunctionTool:
    """Return ADK FunctionTool wrapping Tavily search."""
    return FunctionTool(search_web)


def reset_tavily_client() -> None:
    """Reset cached client (for tests)."""
    global _tavily_client
    _tavily_client = None
