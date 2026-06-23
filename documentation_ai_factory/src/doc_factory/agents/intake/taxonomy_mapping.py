"""TaxonomyMappingAgent — map topic to Architecture Space section."""

from __future__ import annotations

import re
from functools import lru_cache
from pathlib import Path

import yaml

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.topic import TaxonomyMapping, TopicRequest

_SECTION_MAP_PATH = Path(__file__).resolve().parents[2] / "taxonomy" / "section_map.yaml"


@lru_cache
def _load_section_map() -> dict:
    data = yaml.safe_load(_SECTION_MAP_PATH.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else {}


def _slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug[:60] or "topic"


def map_topic_to_taxonomy(
    topic_request: TopicRequest,
    settings: Settings | None = None,
) -> TaxonomyMapping:
    """Map a TopicRequest to Architecture Space taxonomy using section_map.yaml."""
    settings = settings or get_settings()
    section_data = _load_section_map()
    mappings = section_data.get("mappings", [])
    fallback = section_data.get("fallback", {})

    haystack = " ".join(
        [topic_request.topic, *topic_request.synonyms, *topic_request.related_technologies]
    ).lower()

    best_prefix = str(fallback.get("section_prefix", "00_Architecture_Governance"))
    best_tags: list[str] = []
    needs_manual = bool(fallback.get("needs_manual_mapping", True))
    best_score = 0

    for entry in mappings:
        keywords = [str(k).lower() for k in entry.get("keywords", [])]
        score = sum(1 for kw in keywords if kw in haystack)
        if score > best_score:
            best_score = score
            best_prefix = str(entry.get("section_prefix", best_prefix))
            best_tags = [str(t) for t in entry.get("default_tags", [])]
            needs_manual = False

    slug = _slugify(topic_request.topic)
    suggested_path = f"{best_prefix}/Overview/{slug.title().replace('-', '_')}.md"

    template_mix = {
        "overview": 1,
        "concept": 2,
        "architecture": 1,
        "scenarios": 1,
        "implementation": 1,
        "evaluation": 1,
        "best_practices": 1,
        "poc_learning": 1,
        "references": 1,
    }
    if topic_request.depth == "overview":
        template_mix = {k: v for k, v in template_mix.items() if k in ("overview", "references")}
    elif topic_request.depth == "deep":
        template_mix["concept"] = 3

    return TaxonomyMapping(
        target_section_prefix=best_prefix,
        suggested_path=suggested_path,
        template_mix=template_mix,
        tags=best_tags or [_slugify(topic_request.topic)],
        canonical_topic_slug=slug,
        needs_manual_mapping=needs_manual and best_score == 0,
    )
