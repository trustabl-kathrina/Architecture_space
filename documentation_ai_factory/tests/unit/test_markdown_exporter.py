"""Tests for legacy Markdown exporter (writer-only path)."""

from pathlib import Path

from doc_factory.models.mvp import MarkdownSection
from doc_factory.models.mvp import WriterAgentOutput as MvpWriterOutput
from doc_factory.rendering.markdown_renderer import MarkdownExporter


def test_markdown_exporter_writes_files(tmp_path: Path) -> None:
    writer_output = MvpWriterOutput(
        topic="Apache Kafka",
        readme_markdown="# Kafka Guide\n\n## Modules\n",
        sections=[
            MarkdownSection(
                section_id="overview",
                title="Overview",
                filename="01_overview.md",
                content_markdown=(
                    "## Definition\n\nKafka is a distributed event streaming platform.\n"
                ),
            ),
            MarkdownSection(
                section_id="architecture",
                title="Architecture",
                filename="02_architecture.md",
                content_markdown="## Components\n\nBrokers, producers, consumers.\n",
            ),
            MarkdownSection(
                section_id="scenarios",
                title="Scenarios",
                filename="03_scenarios.md",
                content_markdown="## Use cases\n\nEvent-driven microservices.\n",
            ),
            MarkdownSection(
                section_id="implementation",
                title="Implementation",
                filename="04_implementation.md",
                content_markdown="## Examples\n\n```yaml\nreplicas: 3\n```\n",
            ),
        ],
        references_markdown="## References\n\n1. [Kafka Docs](https://kafka.apache.org/)\n",
    )

    paths = MarkdownExporter().export(writer_output, tmp_path)
    assert len(paths) == 6  # README + 4 sections + references
    readme = (tmp_path / "README.md").read_text(encoding="utf-8")
    assert readme.startswith("---\n")
    assert "title: Apache Kafka" in readme
    assert (tmp_path / "02_architecture.md").exists()
