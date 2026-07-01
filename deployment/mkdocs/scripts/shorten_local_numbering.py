#!/usr/bin/env python3
"""Shorten docs paths to 2-digit local numbering at each folder/file level.

Example:
  02.01.02.01.01.03_Event_vs_Message.md  ->  03_Event_vs_Message.md
  02.01.02.01.01_Overview/               ->  01_Overview/
  02.01.02_Streaming/                      ->  02_Streaming/

Top-level entries like 02_Data_Engineering_Architecture are unchanged (already one segment).
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

TOOLS_DOCS_ROOT = Path(__file__).resolve().parent.parent
REPO_ROOT = TOOLS_DOCS_ROOT.parent.parent
DOCS_ROOT = REPO_ROOT / "docs"

def as_extended(path: Path) -> Path:
    """Enable Windows extended-length paths (>260 chars)."""
    if sys.platform != "win32":
        return path
    text = str(path.resolve())
    if text.startswith("\\\\?\\"):
        return path
    return Path("\\\\?\\" + text)


def path_exists(path: Path) -> bool:
    try:
        return as_extended(path).exists()
    except OSError:
        return False


def rename_path(old: Path, new: Path) -> None:
    old_ext = as_extended(old)
    new_ext = as_extended(new)
    new_ext.parent.mkdir(parents=True, exist_ok=True)
    old_ext.rename(new_ext)


LONG_PREFIX_RE = re.compile(r"^(\d{2}(?:\.\d{2})+)_(.+)$")
TEXT_SUFFIXES = {".md", ".yaml", ".yml", ".json", ".txt", ".py", ".ts", ".tsx", ".js", ".html"}
SKIP_DIR_NAMES = {
    ".git",
    ".venv",
    "node_modules",
    ".pytest_cache",
    ".ruff_cache",
    "__pycache__",
    "archive",
    "Archive",
}


def read_text(path: Path) -> str:
    return as_extended(path).read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    as_extended(path).write_text(text, encoding="utf-8", newline="\n")


def display_path(path: Path) -> Path:
    text = str(path)
    if text.startswith("\\\\?\\"):
        return Path(text[4:])
    return path


def iter_paths(root: Path) -> list[Path]:
    """Walk tree without following broken symlinks; skip vendor dirs."""
    found: list[Path] = []
    stack = [as_extended(root)]
    while stack:
        current = stack.pop()
        try:
            with os.scandir(current) as scan:
                entries = list(scan)
        except OSError:
            continue
        for entry in entries:
            if entry.name in SKIP_DIR_NAMES:
                continue
            child = Path(entry.path)
            found.append(display_path(child))
            if entry.is_dir(follow_symlinks=False):
                stack.append(child)
    return found


def shorten_segment_name(name: str) -> str | None:
    match = LONG_PREFIX_RE.match(name)
    if not match:
        return None
    prefix, rest = match.group(1), match.group(2)
    local = prefix.split(".")[-1]
    return f"{local}_{rest}"


def collect_renames(root: Path) -> list[tuple[Path, Path]]:
    """Return (old_path, new_path) pairs sorted deepest-first."""
    renames: list[tuple[Path, Path]] = []

    for path in sorted(iter_paths(root), key=lambda p: len(p.parts), reverse=True):
        if not path_exists(path):
            continue
        new_name = shorten_segment_name(path.name)
        if new_name is None or new_name == path.name:
            continue
        renames.append((path, path.with_name(new_name)))

    # Deepest paths first
    renames.sort(key=lambda pair: len(pair[0].parts), reverse=True)
    return renames


def detect_conflicts(renames: list[tuple[Path, Path]]) -> list[str]:
    errors: list[str] = []
    targets: dict[Path, Path] = {}
    for old, new in renames:
        if new in targets and targets[new] != old:
            errors.append(f"Collision: {targets[new]} and {old} -> {new}")
        targets[new] = old
        if path_exists(new) and new != old:
            errors.append(f"Target already exists: {new} (from {old})")
    return errors


def apply_renames(renames: list[tuple[Path, Path]], *, dry_run: bool) -> dict[str, str]:
    """Rename files/folders; return old_rel_posix -> new_rel_posix map."""
    mapping: dict[str, str] = {}

    for old, new in renames:
        old_rel = old.relative_to(DOCS_ROOT).as_posix()
        new_rel = new.relative_to(DOCS_ROOT).as_posix()
        mapping[old_rel] = new_rel
        if not dry_run:
            if not path_exists(old):
                print(f"SKIP missing: {old_rel}", file=sys.stderr)
                continue
            rename_path(old, new)

    return mapping


def build_replacement_pairs(mapping: dict[str, str]) -> list[tuple[str, str]]:
    pairs: list[tuple[str, str]] = []
    for old_rel, new_rel in mapping.items():
        pairs.append((old_rel, new_rel))
        old_name = Path(old_rel).name
        new_name = Path(new_rel).name
        if old_name != new_name:
            pairs.append((old_name, new_name))
        # Windows and URL variants
        pairs.append((old_rel.replace("/", "\\"), new_rel.replace("/", "\\")))
    # Longest first to avoid partial replacements
    pairs.sort(key=lambda p: len(p[0]), reverse=True)
    # Deduplicate while preserving order
    seen: set[str] = set()
    unique: list[tuple[str, str]] = []
    for old, new in pairs:
        if old in seen or old == new:
            continue
        seen.add(old)
        unique.append((old, new))
    return unique


def update_references(
    mapping: dict[str, str],
    *,
    dry_run: bool,
    roots: list[Path],
) -> int:
    if not mapping:
        return 0

    pairs = build_replacement_pairs(mapping)
    updated_files = 0

    for root in roots:
        if not path_exists(root):
            continue
        paths: list[Path]
        if root.is_file():
            paths = [root]
        else:
            paths = [p for p in iter_paths(root) if path_exists(p) and p.is_file()]
        for path in sorted(paths):
            if path.suffix.lower() not in TEXT_SUFFIXES:
                continue
            try:
                text = read_text(path)
            except (OSError, UnicodeDecodeError):
                continue

            original = text
            for old, new in pairs:
                if old in text:
                    text = text.replace(old, new)

            if text != original:
                updated_files += 1
                if not dry_run:
                    write_text(path, text)

    return updated_files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Report only; do not modify files")
    parser.add_argument(
        "--skip-rename",
        action="store_true",
        help="Only update references using existing mapping file",
    )
    parser.add_argument(
        "--mapping-out",
        type=Path,
        default=DOCS_ROOT / "_meta" / "local_numbering_map.yaml",
        help="Write path mapping YAML for audit",
    )
    args = parser.parse_args()

    renames = collect_renames(DOCS_ROOT)
    conflicts = detect_conflicts(renames)
    if conflicts:
        for msg in conflicts[:20]:
            print(f"ERROR: {msg}", file=sys.stderr)
        print(f"Aborting: {len(conflicts)} conflict(s)", file=sys.stderr)
        return 1

    print(f"Planned renames: {len(renames)}")
    if args.dry_run:
        for old, new in renames[:15]:
            print(f"  {old.relative_to(DOCS_ROOT)} -> {new.name}")
        if len(renames) > 15:
            print(f"  ... and {len(renames) - 15} more")

    mapping: dict[str, str] = {}
    if not args.skip_rename:
        mapping = apply_renames(renames, dry_run=args.dry_run)

    ref_roots = [
        DOCS_ROOT,
        REPO_ROOT / "documentation_ai_factory" / "src",
        REPO_ROOT / "tools" / "docs",
        REPO_ROOT / "apps",
        REPO_ROOT / "services",
        REPO_ROOT / "README.md",
        REPO_ROOT / "docs" / "README.md",
    ]
    if args.dry_run:
        return 0

    ref_count = update_references(mapping, dry_run=False, roots=ref_roots)
    print(f"Reference files updated: {ref_count}")

    if mapping and not args.dry_run:
        args.mapping_out.parent.mkdir(parents=True, exist_ok=True)
        lines = ["# Auto-generated local numbering path map", "paths:"]
        for old, new in sorted(mapping.items()):
            lines.append(f'  - old: "{old}"')
            lines.append(f'    new: "{new}"')
        args.mapping_out.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"Wrote mapping: {args.mapping_out.relative_to(REPO_ROOT)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
