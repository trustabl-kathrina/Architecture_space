#!/usr/bin/env python3
"""Report duplicate markdown filenames across sections."""

from __future__ import annotations

from collections import defaultdict

from doc_utils import DOCS_ROOT, iter_markdown_files


def main() -> None:
    by_name: dict[str, list[str]] = defaultdict(list)
    for path in iter_markdown_files():
        if path.name == "README.md":
            continue
        by_name[path.name].append(str(path.relative_to(DOCS_ROOT)))

    duplicates = {k: v for k, v in by_name.items() if len(v) > 1}
    print(f"Duplicate filenames: {len(duplicates)}")
    for name in sorted(duplicates, key=lambda k: len(duplicates[k]), reverse=True)[:30]:
        paths = duplicates[name]
        print(f"\n{name} ({len(paths)} copies)")
        for p in paths[:6]:
            print(f"  - {p}")
        if len(paths) > 6:
            print(f"  ... and {len(paths) - 6} more")


if __name__ == "__main__":
    main()
