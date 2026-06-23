"""CitationValidatorAgent — validate citation coverage in documentation drafts."""

from __future__ import annotations

import re

from doc_factory.models.content import DocumentationDraft
from doc_factory.models.export import CitationReport
from doc_factory.models.research import RankedSourceCorpus

_CITATION_PATTERN = re.compile(r"\[([a-zA-Z0-9_-]+)\]")
_CLAIM_PATTERN = re.compile(
    r"(?:^|\.\s+)([A-Z][^.!?]{20,}[.!?])",
    re.MULTILINE,
)


def validate_citations(
    draft: DocumentationDraft,
    corpus: RankedSourceCorpus,
) -> CitationReport:
    """Check citation coverage and orphan references in a documentation draft."""
    known_ids = {r.source.source_id for r in corpus.ranked_sources}
    cited_ids: set[str] = set()
    uncited_claims: list[str] = []

    for section in draft.sections:
        text = _section_text(section)
        section_citations = set(_CITATION_PATTERN.findall(text))
        cited_ids.update(section_citations)

        for ref in section.citations:
            cited_ids.add(ref.source_id)

        for match in _CLAIM_PATTERN.finditer(text):
            sentence = match.group(1).strip()
            if len(sentence) < 30:
                continue
            if not _CITATION_PATTERN.search(sentence):
                uncited_claims.append(f"[{section.section_id}] {sentence[:200]}")

    orphan_citations = sorted(cited_ids - known_ids)
    total_claims = len(uncited_claims) + len(cited_ids)
    cited_claims = max(len(cited_ids), 0)
    coverage = (cited_claims / total_claims * 100.0) if total_claims else 100.0

    return CitationReport(
        uncited_claims=uncited_claims[:25],
        orphan_citations=orphan_citations,
        coverage_pct=round(min(coverage, 100.0), 1),
    )


def _section_text(section) -> str:
    parts = [block.content for block in section.blocks]
    return "\n".join(parts)
