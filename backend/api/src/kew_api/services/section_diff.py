"""Markdown section parsing and section-level diff for change plans."""

from __future__ import annotations

import re
import uuid
from dataclasses import dataclass

from kew_api.schemas.chat import SectionChange

_HEADING_RE = re.compile(r"^(#{1,6})\s+(.+)$")
_INTRO_PATH = "__intro__"
_INTRO_TITLE = "(Introduction)"


@dataclass
class ParsedSection:
    title: str
    level: int
    path: str
    lines: list[str]
    start_line: int


def parse_sections(body: str) -> list[ParsedSection]:
    """Split a markdown body into heading-delimited sections."""
    lines = body.splitlines()
    if not lines:
        return []

    sections: list[ParsedSection] = []
    path_stack: list[tuple[int, str]] = []
    current_lines: list[str] = []
    current_title = _INTRO_TITLE
    current_level = 0
    current_path = _INTRO_PATH
    current_start = 1

    def flush(end_line: int) -> None:
        nonlocal current_lines, current_title, current_level, current_path, current_start
        if not current_lines and current_path != _INTRO_PATH:
            return
        sections.append(
            ParsedSection(
                title=current_title,
                level=current_level,
                path=current_path,
                lines=current_lines,
                start_line=current_start,
            )
        )

    for index, line in enumerate(lines, start=1):
        match = _HEADING_RE.match(line)
        if match:
            if current_lines or current_path != _INTRO_PATH or index == 1:
                flush(index - 1 if current_lines else index)

            level = len(match.group(1))
            title = match.group(2).strip()
            while path_stack and path_stack[-1][0] >= level:
                path_stack.pop()
            path_stack.append((level, title))
            current_path = "/".join(segment for _, segment in path_stack)
            current_title = title
            current_level = level
            current_start = index
            current_lines = [line]
            continue

        if not current_lines and current_path == _INTRO_PATH:
            current_start = index
        current_lines.append(line)

    flush(len(lines))
    return sections


def _section_text(section: ParsedSection) -> str:
    return "\n".join(section.lines).strip()


def _ordered_paths(original: str, proposed: str) -> list[str]:
    orig = parse_sections(original)
    prop = parse_sections(proposed)
    seen: set[str] = set()
    ordered: list[str] = []

    for section in prop:
        if section.path not in seen:
            ordered.append(section.path)
            seen.add(section.path)

    for section in orig:
        if section.path not in seen:
            ordered.append(section.path)
            seen.add(section.path)

    return ordered


def build_section_changes(original: str, proposed: str) -> list[SectionChange]:
    """Build accept/reject units grouped by markdown section."""
    orig_map = {section.path: section for section in parse_sections(original)}
    prop_map = {section.path: section for section in parse_sections(proposed)}
    changes: list[SectionChange] = []

    for path in _ordered_paths(original, proposed):
        orig_section = orig_map.get(path)
        prop_section = prop_map.get(path)
        original_text = _section_text(orig_section) if orig_section else ""
        proposed_text = _section_text(prop_section) if prop_section else ""

        if orig_section and prop_section:
            if original_text == proposed_text:
                continue
            change_type = "modified"
            title = prop_section.title
            level = prop_section.level
            start_line = orig_section.start_line
        elif prop_section and not orig_section:
            change_type = "new"
            title = prop_section.title
            level = prop_section.level
            start_line = prop_section.start_line
        elif orig_section and not prop_section:
            change_type = "deleted"
            title = orig_section.title
            level = orig_section.level
            start_line = orig_section.start_line
        else:
            continue

        changes.append(
            SectionChange(
                id=f"section_{uuid.uuid4().hex[:8]}",
                change_type=change_type,  # type: ignore[arg-type]
                section_title=title,
                section_path=path,
                heading_level=level,
                original=original_text,
                proposed=proposed_text,
                start_line=start_line,
            )
        )

    return changes


def apply_section_changes(
    original: str,
    proposed: str,
    changes: list[SectionChange],
    accepted_ids: set[str],
) -> str:
    """Rebuild markdown body from accepted section-level changes."""
    if not changes:
        return proposed if accepted_ids else original

    if not accepted_ids:
        return original

    accepted_changes = {change.id for change in changes if change.id in accepted_ids}
    if not accepted_changes:
        return original

    if len(accepted_changes) == len(changes):
        return proposed

    orig_map = {section.path: section for section in parse_sections(original)}
    prop_map = {section.path: section for section in parse_sections(proposed)}
    change_by_path = {change.section_path: change for change in changes}

    output: list[str] = []
    for path in _ordered_paths(original, proposed):
        change = change_by_path.get(path)
        orig_section = orig_map.get(path)
        prop_section = prop_map.get(path)

        if change is None:
            section = prop_section or orig_section
            if section and section.lines:
                output.append("\n".join(section.lines))
            continue

        if change.id not in accepted_changes:
            if orig_section and orig_section.lines:
                output.append("\n".join(orig_section.lines))
            continue

        if change.change_type == "deleted":
            continue

        if prop_section and prop_section.lines:
            output.append("\n".join(prop_section.lines))

    return "\n\n".join(part for part in output if part.strip()).strip() + ("\n" if output else "")
