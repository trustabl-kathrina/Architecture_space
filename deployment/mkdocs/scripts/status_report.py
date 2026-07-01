#!/usr/bin/env python3
"""Print documentation completion dashboard by section."""

from __future__ import annotations

from doc_utils import DOCS_ROOT, count_statuses, iter_markdown_files, section_title


def main() -> None:
    print("Architecture Space — Content Status Report")
    print("=" * 72)
    print(f"{'Section':<50} {'Complete':>8} {'Draft':>8} {'Stub':>8} {'Total':>8} {'%':>6}")
    print("-" * 72)

    totals = {"complete": 0, "draft": 0, "review": 0, "stub": 0, "archived": 0, "all": 0}
    for section_dir in sorted(DOCS_ROOT.iterdir()):
        if not section_dir.is_dir() or section_dir.name.startswith("_"):
            continue
        files = [p for p in iter_markdown_files(section_dir) if p.name != "README.md"]
        counts = count_statuses(files)
        total = sum(counts.values())
        complete = counts.get("complete", 0)
        draft = counts.get("draft", 0)
        stub = counts.get("stub", 0)
        pct = (complete / total * 100) if total else 0
        label = f"{section_dir.name.split('_', 1)[0]} {section_title(section_dir.name)[:40]}"
        print(f"{label:<50} {complete:>8} {draft:>8} {stub:>8} {total:>8} {pct:>5.1f}%")
        for key in totals:
            if key == "all":
                totals["all"] += total
            else:
                totals[key] += counts.get(key, 0)

    print("-" * 72)
    pct_all = (totals["complete"] / totals["all"] * 100) if totals["all"] else 0
    print(
        f"{'TOTAL':<50} {totals['complete']:>8} {totals['draft']:>8} {totals['stub']:>8} "
        f"{totals['all']:>8} {pct_all:>5.1f}%"
    )


if __name__ == "__main__":
    main()
