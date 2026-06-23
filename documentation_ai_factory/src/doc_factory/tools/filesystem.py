"""Filesystem ADK tools for artifact read/write within run boundaries."""

from __future__ import annotations

import json
import logging
from pathlib import Path

from google.adk.tools import FunctionTool

from doc_factory.config.settings import Settings, get_settings

logger = logging.getLogger(__name__)

_run_dir: Path | None = None


def set_run_directory(run_dir: Path) -> None:
    """Set the active run directory for filesystem tools (testing/runtime)."""
    global _run_dir
    _run_dir = run_dir.resolve()


def _active_run_dir() -> Path:
    if _run_dir is not None:
        return _run_dir
    settings = get_settings()
    return settings.resolved_runs_dir


def _safe_path(relative: str) -> Path:
    base = _active_run_dir().resolve()
    target = (base / relative).resolve()
    if not str(target).startswith(str(base)):
        raise ValueError(f"Path escapes run directory: {relative}")
    return target


def read_artifact(relative_path: str) -> str:
    """Read a text artifact from the current run directory.

    Args:
        relative_path: Path relative to runs/{run_id}/ (e.g. state/topic_request.json).

    Returns:
        File contents as string, or JSON error object.
    """
    logger.info("read_artifact: %s", relative_path)
    try:
        path = _safe_path(relative_path)
        if not path.is_file():
            return json.dumps({"error": f"File not found: {relative_path}"})
        return path.read_text(encoding="utf-8")
    except ValueError as exc:
        return json.dumps({"error": str(exc)})


def write_artifact(relative_path: str, content: str) -> str:
    """Write a text artifact to the current run directory.

    Args:
        relative_path: Path relative to runs/{run_id}/.
        content: Text content to write.

    Returns:
        JSON status object with written path.
    """
    logger.info("write_artifact: %s", relative_path)
    try:
        path = _safe_path(relative_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return json.dumps({"status": "ok", "path": relative_path})
    except ValueError as exc:
        return json.dumps({"error": str(exc)})


def build_filesystem_tools() -> list[FunctionTool]:
    """Return ADK tools for bounded run-directory I/O."""
    return [FunctionTool(read_artifact), FunctionTool(write_artifact)]
