"""Safe path resolution within the documentation corpus root."""

from __future__ import annotations

import re
from pathlib import Path

from kew_api.exceptions import InvalidNameError, PathTraversalError

_INVALID_NAME_CHARS = re.compile(r'[<>:"|?*\x00-\x1f]')
_RESERVED_WINDOWS_NAMES = frozenset(
    {"CON", "PRN", "AUX", "NUL", *(f"COM{i}" for i in range(1, 10)), *(f"LPT{i}" for i in range(1, 10))}
)


def normalize_relative_path(relative: str) -> str:
    """Normalize a workspace-relative path to forward-slash POSIX form."""
    cleaned = relative.strip().replace("\\", "/").strip("/")
    if not cleaned:
        return ""
    parts = [part for part in cleaned.split("/") if part and part != "."]
    if any(part == ".." for part in parts):
        msg = "Path must not contain parent references"
        raise PathTraversalError(relative)
    return "/".join(parts)


def resolve_under_root(root: Path, relative: str) -> Path:
    """Resolve *relative* under *root*; reject traversal escapes."""
    normalized = normalize_relative_path(relative)
    docs_root = root.resolve()
    target = (docs_root / normalized).resolve() if normalized else docs_root
    try:
        target.relative_to(docs_root)
    except ValueError as exc:
        raise PathTraversalError(relative) from exc
    return target


def validate_node_name(name: str) -> str:
    """Validate and return a trimmed node name (folder or file stem)."""
    trimmed = name.strip()
    if not trimmed:
        raise InvalidNameError(name, "name must not be empty")
    if "/" in trimmed or "\\" in trimmed:
        raise InvalidNameError(name, "name must not contain path separators")
    if _INVALID_NAME_CHARS.search(trimmed):
        raise InvalidNameError(name, "name contains invalid characters")
    stem = Path(trimmed).stem if trimmed.lower().endswith(".md") else trimmed
    if stem.upper() in _RESERVED_WINDOWS_NAMES:
        raise InvalidNameError(name, "name is reserved by the operating system")
    return trimmed


def to_relative_path(root: Path, absolute: Path) -> str:
    """Convert an absolute path to a workspace-relative POSIX path."""
    docs_root = root.resolve()
    resolved = absolute.resolve()
    relative = resolved.relative_to(docs_root).as_posix()
    return "" if relative == "." else relative
