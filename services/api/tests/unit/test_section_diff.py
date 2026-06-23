"""Tests for section-level document diffs."""

from __future__ import annotations

from kew_api.services.section_diff import (
    apply_section_changes,
    build_section_changes,
    parse_sections,
)


def test_parse_sections_with_intro_and_headings() -> None:
    body = "Intro line\n\n## Overview\n\nBody text\n\n### Details\n\nMore"
    sections = parse_sections(body)
    assert [section.path for section in sections] == ["__intro__", "Overview", "Overview/Details"]
    assert sections[1].title == "Overview"


def test_build_section_changes_detects_new_and_modified() -> None:
    original = "## Overview\n\nOld text"
    proposed = "## Overview\n\nNew text\n\n## Architecture\n\nFresh section"
    changes = build_section_changes(original, proposed)
    kinds = {change.change_type for change in changes}
    assert kinds == {"modified", "new"}
    assert any(change.section_title == "Architecture" for change in changes)


def test_apply_section_changes_partial_accept() -> None:
    original = "## Overview\n\nOld"
    proposed = "## Overview\n\nNew\n\n## Architecture\n\nFresh"
    changes = build_section_changes(original, proposed)
    modified = next(change for change in changes if change.change_type == "modified")
    new_section = next(change for change in changes if change.change_type == "new")
    result = apply_section_changes(
        original,
        proposed,
        changes,
        {modified.id},
    )
    assert "New" in result
    assert "Architecture" not in result
    assert "Old" not in result


def test_apply_section_changes_all_accepted_matches_proposed() -> None:
    original = "## Overview\n\nOld"
    proposed = "## Overview\n\nNew\n\n## Architecture\n\nFresh"
    changes = build_section_changes(original, proposed)
    accepted = {change.id for change in changes}
    result = apply_section_changes(original, proposed, changes, accepted)
    assert "New" in result
    assert "Architecture" in result
    assert "Fresh" in result
