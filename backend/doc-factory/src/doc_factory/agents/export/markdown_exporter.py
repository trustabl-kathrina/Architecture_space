"""MarkdownExporterAgent — write DocumentationDraft to staging Markdown files."""

from __future__ import annotations

import hashlib
from pathlib import Path

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.content import ContentBlock, DocumentationDraft, SectionDraft
from doc_factory.models.export import ExportFile, ExportManifest
from doc_factory.rendering.front_matter import build_front_matter
from doc_factory.rendering.section_index import render_hub_readme
from doc_factory.services.run_repository import slugify


class GranularMarkdownExporter:
    """Export granular DocumentationDraft to staging directory."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()

    def export(
        self,
        draft: DocumentationDraft,
        *,
        run_id: str,
        topic: str,
        section_prefix: str = "00",
        output_dir: Path | None = None,
    ) -> ExportManifest:
        """Write draft sections and bibliography to staging Markdown files."""
        slug = slugify(topic)
        staging = output_dir or (self._settings.resolved_output_dir / f"{slug}_{run_id[:8]}")
        staging.mkdir(parents=True, exist_ok=True)

        files: list[ExportFile] = []
        tag = slug.replace("_", "-")

        hub_body = render_hub_readme(draft, topic)
        files.append(
            self._write(
                staging,
                "README.md",
                build_front_matter(
                    title=f"{topic} — Learning Guide",
                    section=section_prefix,
                    template="hub",
                    tags=[tag],
                )
                + hub_body,
            )
        )

        for index, section in enumerate(draft.sections, start=1):
            section_number = f"{section_prefix}.{index:02d}"
            body = _render_section(section)
            files.append(
                self._write(
                    staging,
                    f"{index:02d}_{section.section_id}.md",
                    build_front_matter(
                        title=section.title,
                        section=section_number,
                        template=section.template_type,
                        tags=[section.section_id, tag],
                    )
                    + body,
                )
            )

        if draft.bibliography:
            refs_md = "## Primary Sources\n\n"
            for entry in draft.bibliography:
                refs_md += f"- [{entry.citation_text}]({entry.url}) [{entry.source_id}]\n"
            refs_md += "\n## Further Reading\n\n"
            for link in draft.cross_links:
                refs_md += f"- {link}\n"
            files.append(
                self._write(
                    staging,
                    "references.md",
                    build_front_matter(
                        title=f"{topic} — References",
                        section=f"{section_prefix}.99",
                        template="references",
                        tags=["references", tag],
                    )
                    + refs_md,
                )
            )

        return ExportManifest(
            run_id=run_id,
            files=files,
            staging_root=str(staging),
            promotion_target=None,
        )

    def _write(self, root: Path, relative: str, content: str) -> ExportFile:
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        checksum = hashlib.sha256(content.encode("utf-8")).hexdigest()
        return ExportFile(
            relative_path=relative,
            front_matter={},
            body_markdown=content,
            checksum=checksum,
        )


def _render_section(section: SectionDraft) -> str:
    parts: list[str] = [f"# {section.title}\n"]
    for block in section.blocks:
        parts.append(_render_block(block))
    return "\n\n".join(parts) + "\n"


def _render_block(block: ContentBlock) -> str:
    if block.block_type == "mermaid":
        return f"```mermaid\n{block.content}\n```"
    if block.block_type == "code":
        return f"```\n{block.content}\n```"
    if block.block_type == "table":
        return block.content
    if block.block_type == "list":
        return block.content
    return block.content
