"""Keyword-based intent classification when structured LLM output fails."""

from __future__ import annotations

from kew_api.schemas.chat import ChatIntent, IntentResult

EDIT_HINTS = (
    "add to the document",
    "add to document",
    "add to the file",
    "add to file",
    "expand the",
    "generate section",
    "improve the",
    "update the doc",
    "insert section",
    "rewrite the",
    "apply to the file",
    "write to the document",
    "draft a section",
    "draft section",
    "update the document",
    "modify the document",
)

_DIAGRAM_ONLY_HINTS = (
    "mermaid diagram",
    "flowchart",
    "show me a diagram",
    "draw a diagram",
)


def classify_intent_heuristic(content: str) -> IntentResult:
    """Classify user intent from message text without calling the LLM."""
    lowered = content.lower()

    if any(hint in lowered for hint in EDIT_HINTS):
        return IntentResult(
            intent=ChatIntent.EXPAND,
            confidence=0.78,
            rationale="Heuristic: message requests a document change",
            requires_change_plan=True,
        )

    if any(hint in lowered for hint in ("improve", "rewrite", "clarity", "polish")):
        return IntentResult(
            intent=ChatIntent.IMPROVE,
            confidence=0.72,
            rationale="Heuristic: message requests quality improvements",
            requires_change_plan=False,
        )

    if "generate" in lowered and "section" in lowered:
        return IntentResult(
            intent=ChatIntent.GENERATE_SECTION,
            confidence=0.72,
            rationale="Heuristic: message requests new section content",
            requires_change_plan=True,
        )

    return IntentResult(
        intent=ChatIntent.ADVISE,
        confidence=0.75,
        rationale="Heuristic: advisory question or explanation",
        requires_change_plan=False,
    )
