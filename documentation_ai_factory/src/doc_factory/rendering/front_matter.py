"""YAML front matter builder aligned with Architecture Space conventions."""

from __future__ import annotations

from datetime import date


def build_front_matter(
    *,
    title: str,
    section: str,
    template: str,
    status: str = "draft",
    owner: str = "architecture-team",
    tags: list[str] | None = None,
    canonical: bool = False,
) -> str:
    """Return YAML front matter block for a Markdown file."""
    tag_list = tags or []
    tags_yaml = "[" + ", ".join(tag_list) + "]" if tag_list else "[]"
    today = date.today().isoformat()
    return (
        "---\n"
        f"title: {title}\n"
        f"section: \"{section}\"\n"
        f"status: {status}\n"
        f"template: {template}\n"
        f"last_reviewed: {today}\n"
        f"owner: {owner}\n"
        f"tags: {tags_yaml}\n"
        f"canonical: {'true' if canonical else 'false'}\n"
        "---\n"
    )
