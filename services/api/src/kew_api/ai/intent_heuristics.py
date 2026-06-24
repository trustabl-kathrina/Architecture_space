"""Keyword-based intent classification when structured LLM output fails."""

from __future__ import annotations

import re

from kew_api.schemas.chat import ChatIntent, IntentResult

EDIT_HINTS = (
    "add to the document",
    "add to document",
    "add to the file",
    "add to file",
    "add a section",
    "add section",
    "create a section",
    "create section",
    "new section",
    "insert section",
    "insert a section",
    "append section",
    "append to the",
    "append to document",
    "expand the",
    "expand this",
    "expand section",
    "generate section",
    "improve the",
    "update the doc",
    "update the document",
    "update this document",
    "update section",
    "edit the document",
    "edit this document",
    "edit the file",
    "modify the document",
    "modify this section",
    "rewrite the",
    "rewrite this",
    "apply to the file",
    "write to the document",
    "write into the document",
    "draft a section",
    "draft section",
    "put this in the document",
    "change the document",
)

IMPROVE_HINTS = (
    "improve clarity",
    "improve the clarity",
    "improve this section",
    "improve readability",
    "make it clearer",
    "polish the",
    "polish this",
    "rephrase",
    "fix grammar",
    "fix typos",
    "clean up the writing",
)

_DIAGRAM_ONLY_HINTS = (
    "mermaid diagram",
    "flowchart",
    "show me a diagram",
    "draw a diagram",
)

_EDIT_VERB_RE = re.compile(
    r"\b(add|create|insert|append|expand|update|edit|modify|rewrite|draft|write)\b",
    re.IGNORECASE,
)
_SECTION_NOUN_RE = re.compile(r"\b(section|paragraph|heading|subsection|content)\b", re.IGNORECASE)


def _requests_document_edit(content: str) -> bool:
    lowered = content.lower()
    if any(hint in lowered for hint in EDIT_HINTS):
        return True
    if "generate" in lowered and "section" in lowered:
        return True
    if _EDIT_VERB_RE.search(content) and _SECTION_NOUN_RE.search(content):
        return True
    if any(hint in lowered for hint in IMPROVE_HINTS):
        return True
    if any(word in lowered for word in ("rewrite", "rephrase", "polish")) and any(
        word in lowered for word in ("document", "section", "paragraph", "content", "doc")
    ):
        return True
    return False


def classify_intent_heuristic(content: str) -> IntentResult:
    """Classify user intent from message text without calling the LLM."""
    lowered = content.lower()

    if _requests_document_edit(content):
        if any(hint in lowered for hint in IMPROVE_HINTS) or (
            any(word in lowered for word in ("improve", "rewrite", "rephrase", "polish"))
            and any(word in lowered for word in ("document", "section", "paragraph", "content"))
        ):
            return IntentResult(
                intent=ChatIntent.IMPROVE,
                confidence=0.8,
                rationale="Heuristic: message requests document quality improvements",
                requires_change_plan=True,
            )

        if "generate" in lowered and "section" in lowered:
            return IntentResult(
                intent=ChatIntent.GENERATE_SECTION,
                confidence=0.8,
                rationale="Heuristic: message requests new section content",
                requires_change_plan=True,
            )

        if any(word in lowered for word in ("expand", "elaborate", "add detail", "add more")):
            return IntentResult(
                intent=ChatIntent.EXPAND,
                confidence=0.78,
                rationale="Heuristic: message requests expanding existing content",
                requires_change_plan=True,
            )

        return IntentResult(
            intent=ChatIntent.EXPAND,
            confidence=0.78,
            rationale="Heuristic: message requests a document change",
            requires_change_plan=True,
        )

    if any(hint in lowered for hint in _DIAGRAM_ONLY_HINTS):
        return IntentResult(
            intent=ChatIntent.ADVISE,
            confidence=0.7,
            rationale="Heuristic: diagram or explanation request (no file edit)",
            requires_change_plan=False,
        )

    return IntentResult(
        intent=ChatIntent.ADVISE,
        confidence=0.75,
        rationale="Heuristic: advisory question or explanation",
        requires_change_plan=False,
    )
