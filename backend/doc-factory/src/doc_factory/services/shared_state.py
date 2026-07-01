"""Shared pipeline state helpers for ADK session.state and artifacts."""

from __future__ import annotations

import json
import logging
from typing import Any

from pydantic import BaseModel, ValidationError

from doc_factory.models.state import StateKeys
from doc_factory.services.errors import PipelineStateError

logger = logging.getLogger(__name__)


def parse_state_model[T: BaseModel](value: Any, model_type: type[T], *, key: str) -> T:
    """Parse a session.state value into a Pydantic model."""
    if value is None:
        raise PipelineStateError(f"Missing state key: {key}")
    try:
        if isinstance(value, model_type):
            return value
        if isinstance(value, dict):
            return model_type.model_validate(value)
        if isinstance(value, str):
            return model_type.model_validate_json(value)
    except ValidationError as exc:
        raise PipelineStateError(f"Invalid state for {key}: {exc}") from exc
    raise PipelineStateError(f"Cannot parse {key} from type {type(value).__name__}")


def state_to_jsonable(value: Any) -> Any:
    """Convert state values to JSON-serializable form."""
    if isinstance(value, BaseModel):
        return value.model_dump(mode="json")
    if isinstance(value, dict):
        return {k: state_to_jsonable(v) for k, v in value.items()}
    if isinstance(value, list):
        return [state_to_jsonable(v) for v in value]
    return value


def dump_state_snapshot(state: dict[str, Any]) -> str:
    """Serialize shared state for checkpoint logging."""
    payload = {k: state_to_jsonable(v) for k, v in state.items() if k in StateKeys.ALL_OUTPUT_KEYS}
    return json.dumps(payload, indent=2, default=str)


class SharedStateStore:
    """Bridge between ADK session.state and filesystem artifacts."""

    def __init__(self, artifact_store: Any) -> None:
        self._store = artifact_store

    def persist_output(self, key: str, model: BaseModel) -> None:
        artifact_name = key.removesuffix("_output") if key.endswith("_output") else key
        path = self._store.write_model(artifact_name, model)
        logger.info("Persisted artifact %s -> %s", key, path)

    def persist_from_session(self, state: dict[str, Any]) -> list[str]:
        """Persist all known output keys present in session state."""
        saved: list[str] = []
        for key in StateKeys.ALL_OUTPUT_KEYS:
            value = state.get(key)
            if value is None:
                continue
            model = value if isinstance(value, BaseModel) else None
            if model is None and isinstance(value, dict):
                continue
            if model is not None:
                self.persist_output(key, model)
                saved.append(key)
        return saved
