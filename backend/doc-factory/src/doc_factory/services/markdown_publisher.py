"""Publish reviewed documentation to staging Markdown files."""

from __future__ import annotations

import hashlib
import logging
from datetime import UTC, datetime
from pathlib import Path

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.pipeline import PublishedFile, PublishManifest, ReviewerAgentOutput
from doc_factory.rendering.front_matter import build_front_matter
from doc_factory.services.errors import PipelinePublishError

logger = logging.getLogger(__name__)


class MarkdownPublisher:
    """Merge reviewer output and write production Markdown artifacts."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()

    def publish(
        self,
        *,
        run_id: str,
        reviewer_output: ReviewerAgentOutput,
        output_dir: Path,
        section_prefix: str = "00",
    ) -> PublishManifest:
        if not reviewer_output.approved and not self._settings.pipeline_publish_on_review_warning:
            blockers = [f for f in reviewer_output.findings if f.severity == "blocker"]
            if blockers:
                raise PipelinePublishError(
                    f"Publishing blocked: {len(blockers)} reviewer blocker(s). "
                    "Set DOC_FACTORY_PIPELINE_PUBLISH_ON_REVIEW_WARNING=true to override.",
                    phase="publisher",
                    run_id=run_id,
                )

        output_dir.mkdir(parents=True, exist_ok=True)
        published: list[PublishedFile] = []
        tag = _slug_tag(reviewer_output.topic)

        def write(relative: str, content: str) -> PublishedFile:
            path = output_dir / relative
            return self._write_file(output_dir, path, content)

        published.append(
            write(
                "README.md",
                build_front_matter(
                    title=f"{reviewer_output.topic} — Learning Guide",
                    section=section_prefix,
                    template="hub",
                    tags=[tag],
                    status="draft" if not reviewer_output.approved else "review",
                )
                + reviewer_output.readme_markdown,
            )
        )

        for index, section in enumerate(reviewer_output.final_sections, start=1):
            section_number = f"{section_prefix}.{index:02d}"
            published.append(
                write(
                    section.filename,
                    build_front_matter(
                        title=section.title,
                        section=section_number,
                        template=_template_for_section(section.section_id),
                        tags=[section.section_id, tag],
                        status="draft" if not reviewer_output.approved else "review",
                    )
                    + section.content_markdown,
                )
            )

        published.append(
            write(
                "references.md",
                build_front_matter(
                    title=f"{reviewer_output.topic} — References",
                    section=f"{section_prefix}.99",
                    template="overview",
                    tags=["references", tag],
                )
                + reviewer_output.references_markdown,
            )
        )

        review_report = self._build_review_report(reviewer_output)
        published.append(write("REVIEW.md", review_report))

        manifest = PublishManifest(
            run_id=run_id,
            topic=reviewer_output.topic,
            output_dir=str(output_dir.resolve()),
            files=published,
            review_approved=reviewer_output.approved,
            published_at_iso=datetime.now(UTC).isoformat(),
        )
        logger.info(
            "Published %d files to %s (approved=%s)",
            len(published),
            output_dir,
            reviewer_output.approved,
        )
        return manifest

    @staticmethod
    def _write_file(base_dir: Path, path: Path, content: str) -> PublishedFile:
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            encoded = content.encode("utf-8")
            path.write_bytes(encoded)
            digest = hashlib.sha256(encoded).hexdigest()
            rel = path.relative_to(base_dir).as_posix()
            return PublishedFile(
                relative_path=rel,
                checksum_sha256=digest,
                byte_size=len(encoded),
            )
        except OSError as exc:
            raise PipelinePublishError(f"Failed to write {path}: {exc}", phase="publisher") from exc

    @staticmethod
    def _build_review_report(reviewer_output: ReviewerAgentOutput) -> str:
        lines = [
            "# Review Report",
            "",
            f"- **Approved:** {reviewer_output.approved}",
            f"- **Score:** {reviewer_output.overall_score:.1f}/100",
            "",
            "## Findings",
            "",
        ]
        if not reviewer_output.findings:
            lines.append("_No findings._")
        else:
            for finding in reviewer_output.findings:
                lines.append(
                    f"- **{finding.severity.upper()}**"
                    + (f" (`{finding.section_id}`)" if finding.section_id else "")
                    + f": {finding.message}"
                )
                if finding.suggestion:
                    lines.append(f"  - Suggestion: {finding.suggestion}")
        if reviewer_output.revision_notes:
            lines.extend(["", "## Revision Notes", "", reviewer_output.revision_notes])
        return "\n".join(lines) + "\n"


def _slug_tag(topic: str) -> str:
    return topic.lower().replace(" ", "-")[:40]


def _template_for_section(section_id: str) -> str:
    mapping = {
        "overview": "overview",
        "architecture": "concept",
        "scenarios": "concept",
        "implementation": "concept",
        "benchmarks": "evaluation",
        "benchmark": "evaluation",
        "comparisons": "evaluation",
        "comparison": "evaluation",
        "best_practices": "concept",
        "poc": "poc",
        "learning": "poc",
    }
    for key, template in mapping.items():
        if key in section_id:
            return template
    return "concept"
