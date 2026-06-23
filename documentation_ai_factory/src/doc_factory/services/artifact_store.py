"""Filesystem artifact persistence."""

from __future__ import annotations

import json
from pathlib import Path
from typing import TypeVar

from pydantic import BaseModel

T = TypeVar("T", bound=BaseModel)


class ArtifactStore:
    """Read/write Pydantic models as JSON under a run directory."""

    def __init__(self, run_dir: Path) -> None:
        self.run_dir = run_dir.resolve()
        self.state_dir = self.run_dir / "state"
        self.state_dir.mkdir(parents=True, exist_ok=True)

    def write_model(self, name: str, model: BaseModel) -> Path:
        path = self.state_dir / f"{name}.json"
        path.write_text(model.model_dump_json(indent=2), encoding="utf-8")
        return path

    def read_model(self, name: str, model_type: type[T]) -> T:
        path = self.state_dir / f"{name}.json"
        return model_type.model_validate_json(path.read_text(encoding="utf-8"))

    def write_json(self, name: str, data: dict) -> Path:
        path = self.state_dir / f"{name}.json"
        path.write_text(json.dumps(data, indent=2), encoding="utf-8")
        return path
