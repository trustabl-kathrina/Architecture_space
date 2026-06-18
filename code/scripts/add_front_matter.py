#!/usr/bin/env python3
"""Add or update YAML front matter on all markdown files."""

from __future__ import annotations

import argparse
from datetime import date

from doc_utils import (
    DOCS_ROOT,
    detect_template,
    has_front_matter,
    infer_section_id,
    is_complete_content,
    iter_markdown_files,
    strip_front_matter,
)


def build_front_matter(path, body: str) -> str:
    title = path.stem.replace("_", " ")
    section = infer_section_id(path)
    template = detect_template(path, body)
    status = "complete" if is_complete_content(body) else "stub"
    if path.name == "README.md":
        template = "overview"
        status = "complete"

    tags: list[str] = []
    name_lower = path.name.lower()
    if "rag" in name_lower or "retrieval" in name_lower:
        tags.extend(["rag", "genai"])
    if "stream" in name_lower or "event" in name_lower:
        tags.extend(["streaming", "events"])
    if "vendor" in name_lower or "evaluation" in name_lower:
        tags.append("vendor-evaluation")
    if "adr" in name_lower:
        tags.append("adr")

    tag_line = f"tags: [{', '.join(tags)}]" if tags else "tags: []"

    return (
        "---\n"
        f"title: {title}\n"
        f'section: "{section}"\n'
        f"status: {status}\n"
        f"template: {template}\n"
        f"last_reviewed: {date.today().isoformat()}\n"
        "owner: architecture-team\n"
        f"{tag_line}\n"
        "---\n"
    )


def process_file(path, dry_run: bool = False, force: bool = False) -> str:
    text = path.read_text(encoding="utf-8")
    body = strip_front_matter(text) if has_front_matter(text) else text
    if has_front_matter(text) and not force:
        return "skipped"
    front = build_front_matter(path, body)
    new_text = front + body.lstrip("\n")
    if not dry_run:
        path.write_text(new_text, encoding="utf-8", newline="\n")
    return "updated"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    counts = {"updated": 0, "skipped": 0}
    for path in iter_markdown_files():
        if path.name == "README.md" and path.parent == DOCS_ROOT:
            continue
        result = process_file(path, dry_run=args.dry_run, force=args.force)
        counts[result] = counts.get(result, 0) + 1

    print(f"Processed under {DOCS_ROOT}")
    print(counts)


if __name__ == "__main__":
    main()
