"""Export writer output to staging Markdown files."""

from __future__ import annotations

from pathlib import Path

from doc_factory.models.mvp import WriterAgentOutput as MvpWriterOutput
from doc_factory.rendering.front_matter import build_front_matter


class MarkdownExporter:
    """Write MVP pipeline output to a directory tree."""

    def export(
        self,
        writer_output: MvpWriterOutput,
        output_dir: Path,
        *,
        section_prefix: str = "00",
    ) -> list[Path]:
        output_dir.mkdir(parents=True, exist_ok=True)
        written: list[Path] = []

        readme_path = output_dir / "README.md"
        readme_path.write_text(
            build_front_matter(
                title=f"{writer_output.topic} — Learning Guide",
                section=section_prefix,
                template="hub",
                tags=[_slug_tag(writer_output.topic)],
            )
            + writer_output.readme_markdown,
            encoding="utf-8",
        )
        written.append(readme_path)

        for index, section in enumerate(writer_output.sections, start=1):
            section_number = f"{section_prefix}.{index:02d}"
            path = output_dir / section.filename
            path.write_text(
                build_front_matter(
                    title=section.title,
                    section=section_number,
                    template=_template_for_section(section.section_id),
                    tags=[section.section_id, _slug_tag(writer_output.topic)],
                )
                + section.content_markdown,
                encoding="utf-8",
            )
            written.append(path)

        refs_path = output_dir / "references.md"
        refs_path.write_text(
            build_front_matter(
                title=f"{writer_output.topic} — References",
                section=f"{section_prefix}.99",
                template="overview",
                tags=["references", _slug_tag(writer_output.topic)],
            )
            + writer_output.references_markdown,
            encoding="utf-8",
        )
        written.append(refs_path)
        return written


def _slug_tag(topic: str) -> str:
    return topic.lower().replace(" ", "-")[:40]


def _template_for_section(section_id: str) -> str:
    mapping = {
        "overview": "overview",
        "architecture": "concept",
        "scenarios": "concept",
        "implementation": "concept",
        "benchmarks": "evaluation",
        "comparisons": "evaluation",
        "best_practices": "concept",
        "poc": "poc",
        "learning": "poc",
    }
    for key, template in mapping.items():
        if key in section_id:
            return template
    return "concept"
