"""Hub README and section index generator."""

from __future__ import annotations

from doc_factory.models.content import DocumentationDraft


def render_hub_readme(draft: DocumentationDraft, topic: str) -> str:
    """Generate learning-guide style hub README with module table."""
    lines = [
        f"# {topic} — Learning Guide\n",
        "## Prerequisites\n",
        "Familiarity with enterprise data architecture concepts.\n",
        "## Modules\n",
        "| # | Section | Description |",
        "|---|---------|-------------|",
    ]

    for index, section in enumerate(draft.sections, start=1):
        description = _first_paragraph(section)
        filename = f"{index:02d}_{section.section_id}.md"
        lines.append(f"| {index} | [{section.title}]({filename}) | {description} |")

    lines.extend(
        [
            "\n## Quick links\n",
        ]
    )
    for link in draft.cross_links[:10]:
        lines.append(f"- {link}")

    if draft.glossary:
        lines.append("\n## Glossary\n")
        for term in draft.glossary:
            lines.append(f"- {term}")

    return "\n".join(lines) + "\n"


def _first_paragraph(section) -> str:
    for block in section.blocks:
        if block.block_type == "paragraph" and block.content.strip():
            text = block.content.strip().replace("\n", " ")
            return text[:120] + ("..." if len(text) > 120 else "")
    return section.title
