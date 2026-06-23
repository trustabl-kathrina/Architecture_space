"""Tests for Tavily client with mocked API."""

from unittest.mock import MagicMock, patch

import pytest

from doc_factory.models.mvp import SourceItem
from doc_factory.services.tavily_client import TavilySearchClient


@pytest.fixture
def tavily_settings(settings):
    from pydantic import SecretStr

    settings.tavily_api_key = SecretStr("test-key")
    settings.gemini_api_key = SecretStr("test-gemini")
    return settings


def test_tavily_search_normalizes_results(tavily_settings) -> None:
    mock_client = MagicMock()
    mock_client.search.return_value = {
        "results": [
            {
                "title": "Kafka Docs",
                "url": "https://kafka.apache.org/",
                "content": "Streaming platform",
            },
            {"title": "No URL", "url": "", "content": "skip"},
        ]
    }
    with patch("doc_factory.services.tavily_client.TavilyClient", return_value=mock_client):
        client = TavilySearchClient(tavily_settings)
        items = client.search("apache kafka architecture")
    assert len(items) == 1
    assert items[0].title == "Kafka Docs"
    assert items[0].query == "apache kafka architecture"


def test_tavily_dedupes_urls(tavily_settings) -> None:
    with patch("doc_factory.services.tavily_client.TavilyClient"):
        client = TavilySearchClient(tavily_settings)
        with patch.object(client, "search") as mock_search:
            mock_search.side_effect = [
                [SourceItem(title="A", url="https://a.com", snippet="a", query="q1")],
                [SourceItem(title="A dup", url="https://a.com", snippet="a", query="q2")],
                [SourceItem(title="B", url="https://b.com", snippet="b", query="q3")],
            ]
            items = client.search_queries(["q1", "q2", "q3"])
    assert len(items) == 2
