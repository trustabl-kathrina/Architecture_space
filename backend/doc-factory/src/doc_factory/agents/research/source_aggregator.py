"""SourceAggregatorAgent — deduplicate and rank retrieved sources."""

from __future__ import annotations

from doc_factory.models.research import RankedSource, RankedSourceCorpus, SourceCorpus

_TRUSTED_DOMAINS = {
    "docs.aws.amazon.com",
    "cloud.google.com",
    "learn.microsoft.com",
    "kafka.apache.org",
    "flink.apache.org",
    "airflow.apache.org",
    "docs.getdbt.com",
    "martinfowler.com",
    "arxiv.org",
    "github.com",
    "confluent.io",
    "databricks.com",
    "snowflake.com",
}


def _authority_score(domain: str) -> float:
    domain = domain.lower().removeprefix("www.")
    if domain in _TRUSTED_DOMAINS:
        return 1.0
    if domain.endswith((".gov", ".edu")):
        return 0.9
    if domain.endswith((".org", ".io")):
        return 0.75
    return 0.5


def _relevance_score(snippet: str, title: str) -> float:
    length = len(snippet) + len(title)
    if length > 1500:
        return 0.95
    if length > 600:
        return 0.8
    if length > 200:
        return 0.65
    return 0.4


def aggregate_sources(corpus: SourceCorpus) -> RankedSourceCorpus:
    """Rank sources by authority and content richness."""
    ranked: list[RankedSource] = []
    for source in corpus.sources:
        authority = _authority_score(source.domain)
        relevance = _relevance_score(source.snippet, source.title)
        ranked.append(
            RankedSource(
                source=source,
                relevance_score=relevance,
                authority_score=authority,
            )
        )

    ranked.sort(
        key=lambda r: (r.authority_score * 0.6 + r.relevance_score * 0.4),
        reverse=True,
    )
    return RankedSourceCorpus(ranked_sources=ranked)
