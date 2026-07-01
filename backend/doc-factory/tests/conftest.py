"""Shared pytest fixtures."""

from __future__ import annotations

from pathlib import Path

import pytest

from doc_factory.config.settings import Settings


@pytest.fixture
def settings(tmp_path: Path) -> Settings:
    """Settings with isolated runs/output directories."""
    return Settings(
        runs_dir=tmp_path / "runs",
        output_dir=tmp_path / "output",
    )
