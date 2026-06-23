"""TemplateComplianceAgent — validate front matter and required headings."""

from __future__ import annotations

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.content import DocumentationDraft, SectionDraft
from doc_factory.models.export import ReviewFinding, ReviewReport
from doc_factory.rendering.template_resolver import TemplateResolver


def validate_template_compliance(
    draft: DocumentationDraft,
    settings: Settings | None = None,
) -> ReviewReport:
    """Validate sections against template_catalog required headings."""
    settings = settings or get_settings()
    resolver = TemplateResolver(settings)
    findings: list[ReviewFinding] = []
    min_words = settings.min_section_words

    for section in draft.sections:
        findings.extend(_check_section(section, resolver, min_words))

    blockers = [f for f in findings if f.severity == "blocker"]
    warnings = [f for f in findings if f.severity == "warning"]
    score = max(0.0, 100.0 - len(blockers) * 25 - len(warnings) * 5)

    return ReviewReport(
        findings=findings,
        overall_score=score,
        ready_for_export=len(blockers) == 0,
    )


def _check_section(
    section: SectionDraft,
    resolver: TemplateResolver,
    min_words: int,
) -> list[ReviewFinding]:
    findings: list[ReviewFinding] = []
    required = resolver.required_headings(section.template_type)
    body = "\n".join(b.content for b in section.blocks)

    for heading in required:
        if heading.lower() not in body.lower():
            findings.append(
                ReviewFinding(
                    severity="warning",
                    message=f"Missing required heading: {heading}",
                    section_id=section.section_id,
                    suggestion=f"Add a '## {heading}' section.",
                )
            )

    if section.word_count < min_words and len(body.split()) < min_words:
        findings.append(
            ReviewFinding(
                severity="warning",
                message=(
                    f"Section below minimum word count "
                    f"({len(body.split())} < {min_words})"
                ),
                section_id=section.section_id,
            )
        )

    if not section.blocks:
        findings.append(
            ReviewFinding(
                severity="blocker",
                message="Section has no content blocks.",
                section_id=section.section_id,
            )
        )

    return findings
