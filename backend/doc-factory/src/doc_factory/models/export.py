"""QA and export data contracts.

Responsibility:
- ReviewReport, ExportManifest, RunManifest, PhaseCheckpoint.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Literal

from pydantic import BaseModel, Field


class ReviewFinding(BaseModel):
    """Single QA finding."""

    severity: Literal["info", "warning", "blocker"]
    message: str
    section_id: str | None = None
    suggestion: str | None = None


class ReviewReport(BaseModel):
    """Quality review output."""

    findings: list[ReviewFinding] = Field(default_factory=list)
    overall_score: float = 0.0
    ready_for_export: bool = False


class CitationReport(BaseModel):
    """Citation validation output."""

    uncited_claims: list[str] = Field(default_factory=list)
    orphan_citations: list[str] = Field(default_factory=list)
    coverage_pct: float = 0.0


class ExportFile(BaseModel):
    """One exported Markdown file."""

    relative_path: str
    front_matter: dict[str, str]
    body_markdown: str
    checksum: str


class ExportManifest(BaseModel):
    """Manifest of exported staging files."""

    run_id: str
    files: list[ExportFile] = Field(default_factory=list)
    staging_root: str
    promotion_target: str | None = None
    exported_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class RunManifest(BaseModel):
    """Top-level run metadata."""

    run_id: str
    topic: str
    status: Literal["pending", "running", "awaiting_review", "exported", "failed"] = "pending"
    current_phase: str = "intake"
    version: int = 1
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class PhaseCheckpoint(BaseModel):
    """Checkpoint after a pipeline phase completes."""

    phase_name: str
    completed_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    artifact_paths: dict[str, str] = Field(default_factory=dict)
