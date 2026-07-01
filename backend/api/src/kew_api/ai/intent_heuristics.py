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

_GREETING_RE = re.compile(
    r"^\s*(hi|hello|hey|yo|howdy|greetings|good\s+(morning|afternoon|evening)|thanks|thank\s+you)\s*[!?.]*\s*$",
    re.IGNORECASE,
)

_FOLDER_PLAN_HINTS = (
    "design a folder",
    "design the folder",
    "design a structure",
    "design the structure",
    "design a simple folder",
    "folder structure",
    "section structure",
    "documentation structure",
    "reorganize",
    "reorganise",
    "reorganisation",
    "reorganization",
    "structure plan",
    "plan the structure",
    "propose structure",
    "proposed structure",
    "target structure",
    "update structure",
    "recommend structure",
    "recommend alternative",
    "refine structure",
    "restructure",
    "layout for this",
    "folder layout",
    "plan this folder",
    "plan the folder",
    "organize this folder",
    "organise this folder",
    "subfolder",
    "sub-folder",
    "add a folder",
    "add folder",
    "governance folder",
    "keep my",
    "move ",
    "rename ",
    "refine my",
    "refine the",
    "use my",
    "use the",
    "try again",
    "instead of",
    "instead,",
    "ignore previous",
    "ignore the previous",
    "update the plan",
    "update my plan",
    "you ignored",
    "wrong structure",
    "not what i asked",
    "follow my",
    "apply my",
)


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


def _requests_folder_plan(content: str) -> bool:
    lowered = content.lower()
    if any(hint in lowered for hint in _FOLDER_PLAN_HINTS):
        return True
    if "structure" in lowered and any(
        word in lowered
        for word in ("design", "propose", "recommend", "update", "refine", "reorganize", "reorganise", "plan")
    ):
        return True
    return False


def classify_intent_heuristic(
    content: str,
    *,
    folder_plan_scope: bool = False,
) -> IntentResult:
    """Classify user intent from message text without calling the LLM."""
    lowered = content.lower()

    if folder_plan_scope:
        if _GREETING_RE.match(content.strip()):
            return IntentResult(
                intent=ChatIntent.ADVISE,
                confidence=0.95,
                rationale="Heuristic: greeting or small talk in Plan mode",
                requires_change_plan=False,
                requires_folder_plan=False,
            )
        if _requests_folder_plan(content):
            return IntentResult(
                intent=ChatIntent.SUGGEST,
                confidence=0.85,
                rationale="Heuristic: message requests folder/section structure planning",
                requires_change_plan=False,
                requires_folder_plan=True,
            )
        return IntentResult(
            intent=ChatIntent.ADVISE,
            confidence=0.8,
            rationale="Heuristic: conversational or advisory message in Plan mode",
            requires_change_plan=False,
            requires_folder_plan=False,
        )

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
                requires_folder_plan=False,
            )

        if "generate" in lowered and "section" in lowered:
            return IntentResult(
                intent=ChatIntent.GENERATE_SECTION,
                confidence=0.8,
                rationale="Heuristic: message requests new section content",
                requires_change_plan=True,
                requires_folder_plan=False,
            )

        if any(word in lowered for word in ("expand", "elaborate", "add detail", "add more")):
            return IntentResult(
                intent=ChatIntent.EXPAND,
                confidence=0.78,
                rationale="Heuristic: message requests expanding existing content",
                requires_change_plan=True,
                requires_folder_plan=False,
            )

        return IntentResult(
            intent=ChatIntent.EXPAND,
            confidence=0.78,
            rationale="Heuristic: message requests a document change",
            requires_change_plan=True,
            requires_folder_plan=False,
        )

    if any(hint in lowered for hint in _DIAGRAM_ONLY_HINTS):
        return IntentResult(
            intent=ChatIntent.ADVISE,
            confidence=0.7,
            rationale="Heuristic: diagram or explanation request (no file edit)",
            requires_change_plan=False,
            requires_folder_plan=False,
        )

    return IntentResult(
        intent=ChatIntent.ADVISE,
        confidence=0.75,
        rationale="Heuristic: advisory question or explanation",
        requires_change_plan=False,
        requires_folder_plan=False,
    )
