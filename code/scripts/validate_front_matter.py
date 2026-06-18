#!/usr/bin/env python3
"""Validate required YAML front matter fields on all markdown files."""

from __future__ import annotations

import sys

from doc_utils import DOCS_ROOT, VALID_STATUS, VALID_TEMPLATES, iter_markdown_files, parse_front_matter

REQUIRED = {"title", "section", "status", "template", "last_reviewed", "owner"}


def main() -> int:
    errors: list[str] = []
    for path in iter_markdown_files():
        rel_parts = path.relative_to(DOCS_ROOT).parts
        if path.name == "README.md" or rel_parts[0] == "_meta":
            continue
        meta = parse_front_matter(path.read_text(encoding="utf-8"))
        if not meta:
            errors.append(f"{path.relative_to(DOCS_ROOT.parent)}: missing front matter")
            continue
        missing = REQUIRED - set(meta)
        if missing:
            errors.append(f"{path.relative_to(DOCS_ROOT.parent)}: missing {sorted(missing)}")
        if meta.get("status") not in VALID_STATUS:
            errors.append(f"{path.relative_to(DOCS_ROOT.parent)}: invalid status")
        if meta.get("template") not in VALID_TEMPLATES:
            errors.append(f"{path.relative_to(DOCS_ROOT.parent)}: invalid template")

    if errors:
        print(f"ERRORS: {len(errors)}")
        for err in errors[:50]:
            print(f"  {err}")
        if len(errors) > 50:
            print(f"  ... and {len(errors) - 50} more")
        return 1

    print("All files have valid front matter.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
