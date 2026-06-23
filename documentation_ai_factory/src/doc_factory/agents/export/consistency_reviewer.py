"""ConsistencyReviewerAgent — cross-section QA (delegates to MVP reviewer)."""

from __future__ import annotations

from google.adk.agents import LlmAgent

from doc_factory.agents.factory import build_reviewer_agent
from doc_factory.config.settings import Settings
from doc_factory.models.content import DocumentationDraft
from doc_factory.models.export import ReviewFinding, ReviewReport


def build_consistency_reviewer_agent(settings: Settings | None = None) -> LlmAgent:
    """Build ADK reviewer agent for cross-section consistency."""
    return build_reviewer_agent(settings)


def review_consistency(draft: DocumentationDraft) -> ReviewReport:
    """Programmatic cross-section consistency checks without LLM."""
    findings: list[ReviewFinding] = []
    section_ids = {s.section_id for s in draft.sections}

    if len(draft.sections) < 3:
        findings.append(
            ReviewFinding(
                severity="blocker",
                message="Documentation draft has fewer than 3 sections.",
            )
        )

    titles = [s.title for s in draft.sections]
    if len(titles) != len(set(titles)):
        findings.append(
            ReviewFinding(
                severity="warning",
                message="Duplicate section titles detected.",
            )
        )

    for link in draft.cross_links:
        target = link.lstrip("#")
        if target and target not in section_ids:
            findings.append(
                ReviewFinding(
                    severity="warning",
                    message=f"Cross-link references missing section: {target}",
                )
            )

    blockers = [f for f in findings if f.severity == "blocker"]
    return ReviewReport(
        findings=findings,
        overall_score=max(0.0, 100.0 - len(findings) * 10),
        ready_for_export=len(blockers) == 0,
    )
