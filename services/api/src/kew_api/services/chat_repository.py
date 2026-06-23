"""Persist conversations and change plans on the local filesystem."""

from __future__ import annotations

import json
from pathlib import Path
from typing import TypeVar

from pydantic import BaseModel

from kew_api.config.settings import ApiSettings
from kew_api.exceptions import NodeNotFoundError
from kew_api.schemas.chat import ChangePlan, Conversation

T = TypeVar("T", bound=BaseModel)


class JsonStore:
    def __init__(self, root: Path) -> None:
        self._root = root
        self._root.mkdir(parents=True, exist_ok=True)

    def write(self, name: str, model: BaseModel) -> None:
        path = self._root / f"{name}.json"
        path.write_text(model.model_dump_json(indent=2), encoding="utf-8")

    def read(self, name: str, model_type: type[T]) -> T:
        path = self._root / f"{name}.json"
        if not path.is_file():
            raise NodeNotFoundError(name)
        return model_type.model_validate_json(path.read_text(encoding="utf-8"))

    def delete(self, name: str) -> None:
        path = self._root / f"{name}.json"
        if path.is_file():
            path.unlink()


class ConversationRepository:
    def __init__(self, settings: ApiSettings) -> None:
        self._store = JsonStore(settings.resolved_conversations_dir)

    def save(self, conversation: Conversation) -> Conversation:
        self._store.write(conversation.id, conversation)
        return conversation

    def get(self, conversation_id: str) -> Conversation:
        return self._store.read(conversation_id, Conversation)


class ChangePlanRepository:
    def __init__(self, settings: ApiSettings) -> None:
        self._store = JsonStore(settings.resolved_edits_dir)

    def save(self, plan: ChangePlan) -> ChangePlan:
        self._store.write(plan.edit_id, plan)
        return plan

    def get(self, edit_id: str) -> ChangePlan:
        return self._store.read(edit_id, ChangePlan)

    def discard(self, edit_id: str) -> ChangePlan:
        plan = self.get(edit_id)
        updated = plan.model_copy(update={"status": "discarded"})
        self._store.write(edit_id, updated)
        return updated

    def mark_applied(self, edit_id: str) -> ChangePlan:
        plan = self.get(edit_id)
        updated = plan.model_copy(update={"status": "applied"})
        self._store.write(edit_id, updated)
        return updated
