"""Markdown body utilities shared by documents and AI services."""

from __future__ import annotations

import re

FRONT_MATTER_PATTERN = re.compile(r"^---\r?\n([\s\S]*?)\r?\n---\r?\n?")


def split_front_matter(content: str) -> tuple[str | None, str]:
    match = FRONT_MATTER_PATTERN.match(content)
    if not match:
        return None, content
    front = f"---\n{match.group(1)}\n---\n"
    body = content[match.end() :]
    return front, body


def join_front_matter(front_matter: str | None, body: str) -> str:
    if not front_matter:
        return body
    separator = "" if body.startswith("\n") else "\n"
    return f"{front_matter}{separator}{body}"
