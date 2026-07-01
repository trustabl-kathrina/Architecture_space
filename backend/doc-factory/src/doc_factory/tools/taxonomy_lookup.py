"""Taxonomy lookup ADK tool — query section_map.yaml."""

from __future__ import annotations

import json
import logging
from functools import lru_cache
from pathlib import Path

import yaml
from google.adk.tools import FunctionTool

logger = logging.getLogger(__name__)

_SECTION_MAP_PATH = (
    Path(__file__).resolve().parents[1] / "taxonomy" / "section_map.yaml"
)


@lru_cache
def _load_section_map() -> dict:
    data = yaml.safe_load(_SECTION_MAP_PATH.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else {}


def lookup_taxonomy(topic: str) -> str:
    """Look up Architecture Space section prefix for a topic keyword.

    Args:
        topic: Documentation topic or technology name.

    Returns:
        JSON with section_prefix, tags, and needs_manual_mapping flag.
    """
    logger.info("lookup_taxonomy: %s", topic)
    section_data = _load_section_map()
    mappings = section_data.get("mappings", [])
    fallback = section_data.get("fallback", {})
    haystack = topic.lower()

    best = {
        "section_prefix": fallback.get("section_prefix", "00_Architecture_Governance"),
        "tags": [],
        "needs_manual_mapping": fallback.get("needs_manual_mapping", True),
        "matched_keywords": [],
    }
    best_score = 0

    for entry in mappings:
        keywords = [str(k).lower() for k in entry.get("keywords", [])]
        matched = [kw for kw in keywords if kw in haystack]
        if len(matched) > best_score:
            best_score = len(matched)
            best = {
                "section_prefix": entry.get("section_prefix"),
                "tags": entry.get("default_tags", []),
                "needs_manual_mapping": False,
                "matched_keywords": matched,
            }

    return json.dumps(best, indent=2)


def build_taxonomy_lookup_tool() -> FunctionTool:
    """Return ADK FunctionTool for taxonomy section lookup."""
    return FunctionTool(lookup_taxonomy)
