"""Run manifest persistence."""

from __future__ import annotations

import re
import uuid
from datetime import UTC, datetime
from pathlib import Path

from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.export import RunManifest
from doc_factory.services.artifact_store import ArtifactStore


def slugify(text: str, max_length: int = 60) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    return slug[:max_length] or "topic"


class RunRepository:
    """Create and track documentation runs on the filesystem."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        self.runs_dir = self._settings.resolved_runs_dir
        self.runs_dir.mkdir(parents=True, exist_ok=True)

    def create_run(self, topic: str) -> tuple[str, Path, ArtifactStore]:
        run_id = str(uuid.uuid4())
        run_dir = self.runs_dir / run_id
        run_dir.mkdir(parents=True, exist_ok=True)
        manifest = RunManifest(
            run_id=run_id,
            topic=topic,
            status="pending",
            current_phase="planner",
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        self._write_manifest(run_dir, manifest)
        return run_id, run_dir, ArtifactStore(run_dir)

    def get_run_dir(self, run_id: str) -> Path:
        path = self.runs_dir / run_id
        if not path.is_dir():
            raise FileNotFoundError(f"Run not found: {run_id}")
        return path

    def load_manifest(self, run_id: str) -> RunManifest:
        path = self.get_run_dir(run_id) / "run_manifest.json"
        return RunManifest.model_validate_json(path.read_text(encoding="utf-8"))

    def update_manifest(self, run_id: str, **updates: object) -> RunManifest:
        run_dir = self.get_run_dir(run_id)
        manifest = self.load_manifest(run_id)
        data = manifest.model_dump()
        data.update(updates)
        data["updated_at"] = datetime.now(UTC)
        updated = RunManifest.model_validate(data)
        self._write_manifest(run_dir, updated)
        return updated

    def list_runs(self, limit: int = 10) -> list[RunManifest]:
        manifests: list[RunManifest] = []
        for path in sorted(self.runs_dir.glob("*/run_manifest.json"), reverse=True):
            manifests.append(RunManifest.model_validate_json(path.read_text(encoding="utf-8")))
            if len(manifests) >= limit:
                break
        return manifests

    @staticmethod
    def _write_manifest(run_dir: Path, manifest: RunManifest) -> None:
        (run_dir / "run_manifest.json").write_text(
            manifest.model_dump_json(indent=2),
            encoding="utf-8",
        )
