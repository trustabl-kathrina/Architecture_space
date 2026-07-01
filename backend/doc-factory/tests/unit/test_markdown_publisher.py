"""Tests for Markdown publisher."""

from pathlib import Path

from doc_factory.models.mvp import MarkdownSection
from doc_factory.models.pipeline import ReviewerAgentOutput, ReviewFinding
from doc_factory.services.markdown_publisher import MarkdownPublisher


def _sample_reviewer() -> ReviewerAgentOutput:
    sections = [
        MarkdownSection(
            section_id="overview",
            title="Overview",
            filename="01_overview.md",
            content_markdown="## Definition\n\nOverview content.\n",
        ),
        MarkdownSection(
            section_id="architecture",
            title="Architecture",
            filename="02_architecture.md",
            content_markdown="## Components\n\nArchitecture content.\n",
        ),
        MarkdownSection(
            section_id="benchmarks",
            title="Benchmarks",
            filename="03_benchmarks.md",
            content_markdown="## Metrics\n\n| Metric | Value |\n|---|---|\n| TPS | 1M |\n",
        ),
        MarkdownSection(
            section_id="comparisons",
            title="Comparisons",
            filename="04_comparisons.md",
            content_markdown="## Matrix\n\nComparison table.\n",
        ),
        MarkdownSection(
            section_id="scenarios",
            title="Scenarios",
            filename="05_scenarios.md",
            content_markdown="## Enterprise\n\nScenario content.\n",
        ),
        MarkdownSection(
            section_id="implementation",
            title="Implementation",
            filename="06_implementation.md",
            content_markdown="## Examples\n\n```python\nprint('ok')\n```\n",
        ),
    ]
    return ReviewerAgentOutput(
        topic="Apache Kafka",
        approved=True,
        overall_score=85.0,
        findings=[ReviewFinding(severity="info", message="Minor style note")],
        final_sections=sections,
        readme_markdown="# Kafka Guide\n\n## Modules\n",
        references_markdown="## References\n\n1. [Kafka](https://kafka.apache.org/)\n",
    )


def test_publisher_writes_all_artifacts(tmp_path: Path, settings) -> None:
    settings.pipeline_publish_on_review_warning = True
    publisher = MarkdownPublisher(settings)
    manifest = publisher.publish(
        run_id="test-run-id",
        reviewer_output=_sample_reviewer(),
        output_dir=tmp_path,
    )
    assert manifest.review_approved is True
    assert len(manifest.files) >= 8
    assert (tmp_path / "README.md").exists()
    assert (tmp_path / "REVIEW.md").exists()
    assert (tmp_path / "references.md").exists()


def test_publisher_blocks_on_blockers(tmp_path: Path, settings) -> None:
    settings.pipeline_publish_on_review_warning = False
    reviewer = _sample_reviewer()
    reviewer.approved = False
    reviewer.findings.append(
        ReviewFinding(severity="blocker", message="Missing citations", section_id="overview")
    )
    publisher = MarkdownPublisher(settings)
    try:
        publisher.publish(
            run_id="test-run-id",
            reviewer_output=reviewer,
            output_dir=tmp_path,
        )
        raised = False
    except Exception:
        raised = True
    assert raised is True
