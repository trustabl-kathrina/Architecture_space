"""Line-based diff utilities for document change plans."""

from __future__ import annotations

import difflib
import uuid

from kew_api.schemas.chat import ChangePlanHunk


def build_change_hunks(original: str, proposed: str) -> list[ChangePlanHunk]:
    """Compute insert/replace/delete hunks between two markdown bodies."""
    original_lines = original.splitlines()
    proposed_lines = proposed.splitlines()
    matcher = difflib.SequenceMatcher(a=original_lines, b=proposed_lines)
    hunks: list[ChangePlanHunk] = []

    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            continue

        hunk_type = "replace"
        if tag == "insert":
            hunk_type = "insert"
        elif tag == "delete":
            hunk_type = "delete"

        start_line = i1 + 1 if original_lines else max(j1 + 1, 1)
        end_line = i2 if i2 > i1 else i1

        hunks.append(
            ChangePlanHunk(
                id=f"hunk_{uuid.uuid4().hex[:8]}",
                type=hunk_type,  # type: ignore[arg-type]
                start_line=start_line,
                end_line=max(end_line, start_line),
                original="\n".join(original_lines[i1:i2]),
                proposed="\n".join(proposed_lines[j1:j2]),
            )
        )

    return hunks


def apply_hunks(original: str, hunks: list[ChangePlanHunk], accepted_ids: set[str]) -> str:
    """Apply accepted hunks to original body. Falls back to full replace hunks only."""
    if not accepted_ids:
        return original

    lines = original.splitlines()
    # Apply from bottom to top to preserve line numbers
    selected = [h for h in hunks if h.id in accepted_ids]
    for hunk in sorted(selected, key=lambda h: h.start_line, reverse=True):
        start_idx = max(hunk.start_line - 1, 0)
        end_idx = hunk.end_line if hunk.end_line > start_idx else start_idx
        proposed_lines = hunk.proposed.splitlines()

        if hunk.type == "insert":
            lines[start_idx:start_idx] = proposed_lines
        elif hunk.type == "delete":
            del lines[start_idx:end_idx]
        else:
            lines[start_idx:end_idx] = proposed_lines

    return "\n".join(lines)
