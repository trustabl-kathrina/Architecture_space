"""Validate folder plans honor explicit user directives."""

from __future__ import annotations

import re

from kew_api.schemas.chat import FolderPlanResult

_PATH_TOKEN = re.compile(
    r"(?:\b[\w][\w./_-]*\.md\b|"
    r"\b\d{2}_[\w]+\b|"
    r"\bREADME\.md\b|"
    r"[\w][\w/_-]*/[\w][\w/_-]*)",
    re.IGNORECASE,
)
_STOPWORDS = frozenset(
    {
        "the",
        "and",
        "for",
        "with",
        "this",
        "that",
        "from",
        "into",
        "folder",
        "structure",
        "please",
        "design",
        "update",
        "refine",
        "plan",
        "section",
        "docs",
        "modern",
        "architecture",
    }
)


def _extract_directive_tokens(*texts: str | None) -> list[str]:
    tokens: list[str] = []
    seen: set[str] = set()
    for text in texts:
        if not text or not text.strip():
            continue
        for match in _PATH_TOKEN.findall(text):
            normalized = match.strip().strip("/").lower()
            if len(normalized) < 4:
                continue
            base = normalized.split("/")[-1]
            if base in _STOPWORDS or normalized in _STOPWORDS:
                continue
            if normalized in seen:
                continue
            seen.add(normalized)
            tokens.append(normalized)
    return tokens[:24]


def find_missing_directives(
    *,
    user_message: str,
    existing_plan: str | None,
    result: FolderPlanResult,
) -> list[str]:
    """Return directive tokens absent from the planner output."""
    directives = _extract_directive_tokens(user_message, existing_plan)
    if not directives:
        return []

    haystack = "\n".join(
        [
            result.target_structure.lower(),
            result.explanation.lower(),
            *[item.path.lower() for item in result.reorganization],
            *[item.target_path.lower() for item in result.reorganization if item.target_path],
        ]
    )
    missing: list[str] = []
    for token in directives:
        leaf = token.split("/")[-1]
        if token in haystack or leaf in haystack:
            continue
        missing.append(token)
    return missing


def build_repair_prompt(missing: list[str]) -> str:
    items = "\n".join(f"- {token}" for token in missing)
    return (
        "\n\n---\n"
        "REPAIR REQUIRED: The previous plan omitted explicit user directives. "
        "Revise target_structure and reorganization so ALL of the following appear:\n"
        f"{items}\n"
        "Do not replace the user's draft with a generic template."
    )
