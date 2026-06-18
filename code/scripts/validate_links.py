#!/usr/bin/env python3
"""Validate relative markdown links in the documentation corpus."""

from __future__ import annotations

import sys
from pathlib import Path
from urllib.parse import unquote

from doc_utils import DOCS_ROOT, LINK_RE, iter_markdown_files


def resolve_link(source: Path, target: str) -> Path | None:
    target = target.split("#", 1)[0].strip()
    if not target or target.startswith(("http://", "https://", "mailto:")):
        return None
    if target.startswith("/"):
        resolved = DOCS_ROOT / target.lstrip("/")
    else:
        resolved = (source.parent / target).resolve()
    return resolved


def main() -> int:
    broken: list[tuple[str, str, str]] = []
    checked = 0

    for path in iter_markdown_files():
        text = path.read_text(encoding="utf-8")
        for label, href in LINK_RE.findall(text):
            resolved = resolve_link(path, unquote(href))
            if resolved is None:
                continue
            checked += 1
            if not resolved.exists():
                rel = path.relative_to(DOCS_ROOT)
                broken.append((str(rel), label, href))

    print(f"Checked {checked} relative links")
    if broken:
        print(f"BROKEN: {len(broken)}")
        for src, label, href in broken:
            print(f"  {src}: [{label}]({href})")
        return 1

    print("All relative links resolve.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
