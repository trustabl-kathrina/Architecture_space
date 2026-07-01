#!/usr/bin/env python3
"""Generate README indexes for the architecture-first docs taxonomy."""

from __future__ import annotations

import re
from pathlib import Path

from doc_utils import (
    DOCS_ROOT,
    REPO_ROOT,
    SECTION_DESCRIPTIONS,
    count_statuses,
    iter_markdown_files,
    parse_front_matter,
    section_number,
    section_title,
)


def subsection_label(name: str) -> str:
    match = re.match(r"^\d{2}\.\d{2}_(.+)$", name)
    if match:
        return match.group(1).replace("_", " ")
    return name.replace("_", " ")


def find_start_here(section_dir: Path) -> list[str]:
    links: list[str] = []
    candidates = [
        p
        for p in sorted(section_dir.rglob("*.md"))
        if p.name != "README.md" and not any(part.startswith("_") for part in p.relative_to(section_dir).parts)
    ]
    non_stub = []
    for path in candidates:
        meta = parse_front_matter(path.read_text(encoding="utf-8"))
        if meta.get("status") != "stub":
            non_stub.append(path)
    for path in (non_stub or candidates)[:5]:
        rel = path.relative_to(section_dir).as_posix()
        title = path.stem.replace("_", " ")
        links.append(f"- [{title}]({rel})")
    return links[:4]


def build_section_readme(section_dir: Path) -> str:
    name = section_dir.name
    num = section_number(name)
    title = section_title(name)
    description = SECTION_DESCRIPTIONS.get(name, "Enterprise architecture documentation.")
    files = [
        p
        for p in iter_markdown_files(section_dir)
        if p.name != "README.md" and not any(part.startswith("_") for part in p.relative_to(section_dir).parts)
    ]
    statuses = count_statuses(files)
    total = sum(statuses.values())

    lines = [
        f"# {num} {title}",
        "",
        f"> Status: {statuses.get('complete', 0)} complete / "
        f"{statuses.get('draft', 0)} draft / "
        f"{statuses.get('review', 0)} review / "
        f"{statuses.get('stub', 0)} stub ({total} topics)",
        "",
        "## Purpose",
        "",
        description,
        "",
        "## Start here",
        "",
    ]
    start_links = find_start_here(section_dir)
    lines.extend(start_links or ["- Browse subsections below."])
    lines.extend(["", "## Subsections", "", "| # | Topic | Topics | Key doc | Status |", "| --- | --- | ---: | --- | --- |"])

    for sub in sorted(section_dir.iterdir()):
        if not sub.is_dir():
            continue
        if sub.name.startswith("_"):
            continue
        sub_files = [p for p in sub.rglob("*.md") if p.name != "README.md"]
        if not sub_files:
            sub_id = sub.name.split("_", 1)[0]
            lines.append(
                f"| {sub_id} | {subsection_label(sub.name)} | 0 |  | stub |"
            )
            continue
        key_doc = sorted(sub_files, key=lambda p: p.name)[0]
        key_meta = parse_front_matter(key_doc.read_text(encoding="utf-8"))
        key_status = key_meta.get("status", "stub")
        rel = key_doc.relative_to(section_dir).as_posix()
        sub_id = sub.name.split("_", 1)[0]
        lines.append(
            f"| {sub_id} | {subsection_label(sub.name)} | {len(sub_files)} | "
            f"[{key_doc.stem.replace('_', ' ')}]({rel}) | {key_status} |"
        )

    lines.extend(
        [
            "",
            "## Related",
            "",
            f"- [Architecture Space README](../README.md)",
            f"- [Repository README](../../README.md)",
            "",
        ]
    )
    return "\n".join(lines) + "\n"


def build_master_readme() -> str:
    lines = [
        "# Architecture Space",
        "",
        "Master index of the architecture-first documentation taxonomy.",
        "",
        "| # | Section | Topics | Description |",
        "| --- | --- | ---: | --- |",
    ]
    grand_total = 0
    for section_dir in sorted(DOCS_ROOT.iterdir()):
        if not section_dir.is_dir() or section_dir.name.startswith("_"):
            continue
        name = section_dir.name
        num = section_number(name)
        title = section_title(name)
        files = [p for p in iter_markdown_files(section_dir) if p.name != "README.md"]
        count = len(files)
        grand_total += count
        desc = SECTION_DESCRIPTIONS.get(name, "")
        lines.append(
            f"| {num} | [{title}]({name}/README.md) | {count} | {desc} |"
        )

    lines.extend(
        [
            "",
            f"**Total topics:** {grand_total}",
            "",
            "## Cross-cutting hubs",
            "",
            "- [Data Mesh Hub](_hubs/Data_Mesh_Hub.md)",
            "- [FinOps Hub](_hubs/FinOps_Hub.md)",
            "- [Agentic AI Hub](_hubs/Agentic_AI_Hub.md)",
            "- [Pluto MIND Hub](_hubs/Pluto_MIND_Hub.md)",
            "",
            "## Migration",
            "",
            "- [Taxonomy Registry](_meta/taxonomy.yaml)",
            "- [Migration Map](_meta/migration_map.yaml)",
            "- [Redirect Index](_meta/redirects.md)",
            "",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    for section_dir in sorted(DOCS_ROOT.iterdir()):
        if not section_dir.is_dir() or section_dir.name.startswith("_"):
            continue
        readme = section_dir / "README.md"
        readme.write_text(build_section_readme(section_dir), encoding="utf-8", newline="\n")
        print(f"Wrote {readme}")

    master = DOCS_ROOT / "README.md"
    master.write_text(build_master_readme(), encoding="utf-8", newline="\n")
    print(f"Wrote {master}")


if __name__ == "__main__":
    main()
