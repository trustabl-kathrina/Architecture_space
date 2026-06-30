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

SCOPE_INDEX_NAME = "_scope_index"


def build_scope_index_key(scope_kind: str, scope_path: str) -> str:
    """Unified scope key — Plan and Agent share one conversation per section."""
    return f"{scope_kind}:{scope_path}"


def build_legacy_scope_index_key(scope_kind: str, scope_path: str, chat_mode: str) -> str:
    return f"{scope_kind}:{scope_path}:{chat_mode}"


class JsonStore:
    def __init__(self, root: Path) -> None:
        self._root = root
        self._root.mkdir(parents=True, exist_ok=True)

    def write(self, name: str, model: BaseModel) -> None:
        path = self._root / f"{name}.json"
        path.parent.mkdir(parents=True, exist_ok=True)
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

    def _scope_index_path(self) -> Path:
        return self._store._root / f"{SCOPE_INDEX_NAME}.json"

    def _load_scope_index(self) -> dict[str, str]:
        path = self._scope_index_path()
        if not path.is_file():
            return {}
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return {}
        if not isinstance(data, dict):
            return {}
        return {str(key): str(value) for key, value in data.items()}

    def _save_scope_index(self, index: dict[str, str]) -> None:
        path = self._scope_index_path()
        path.write_text(json.dumps(index, indent=2, sort_keys=True), encoding="utf-8")

    def _register_scope(self, conversation: Conversation) -> None:
        if conversation.scope_kind is None:
            return
        index = self._load_scope_index()
        key = build_scope_index_key(conversation.scope_kind, conversation.scope_path or "")
        index[key] = conversation.id
        for mode in ("plan", "agent"):
            legacy_key = build_legacy_scope_index_key(
                conversation.scope_kind,
                conversation.scope_path or "",
                mode,
            )
            if index.get(legacy_key) == conversation.id:
                del index[legacy_key]
        self._save_scope_index(index)

    def _unregister_scope(self, conversation: Conversation) -> None:
        if conversation.scope_kind is None:
            return
        index = self._load_scope_index()
        key = build_scope_index_key(conversation.scope_kind, conversation.scope_path or "")
        if index.get(key) == conversation.id:
            del index[key]
        for mode in ("plan", "agent"):
            legacy_key = build_legacy_scope_index_key(
                conversation.scope_kind,
                conversation.scope_path or "",
                mode,
            )
            if index.get(legacy_key) == conversation.id:
                del index[legacy_key]
        self._save_scope_index(index)

    def _get_or_cleanup(self, conversation_id: str, index_key: str) -> Conversation | None:
        try:
            return self.get(conversation_id)
        except NodeNotFoundError:
            index = self._load_scope_index()
            if index.get(index_key) == conversation_id:
                del index[index_key]
                self._save_scope_index(index)
            return None

    @staticmethod
    def _merge_conversations(primary: Conversation, others: list[Conversation]) -> Conversation:
        seen_ids = {message.id for message in primary.messages}
        merged_messages = list(primary.messages)
        for other in others:
            if other.id == primary.id:
                continue
            for message in other.messages:
                if message.id in seen_ids:
                    continue
                merged_messages.append(message)
                seen_ids.add(message.id)
        merged_messages.sort(key=lambda message: message.timestamp)
        return primary.model_copy(update={"messages": merged_messages})

    def find_by_scope(self, scope_kind: str, scope_path: str) -> Conversation | None:
        index = self._load_scope_index()
        key = build_scope_index_key(scope_kind, scope_path)
        conversation_id = index.get(key)
        if conversation_id:
            return self._get_or_cleanup(conversation_id, key)

        legacy_conversations: list[tuple[str, Conversation]] = []
        for mode in ("plan", "agent"):
            legacy_key = build_legacy_scope_index_key(scope_kind, scope_path, mode)
            legacy_id = index.get(legacy_key)
            if not legacy_id:
                continue
            conversation = self._get_or_cleanup(legacy_id, legacy_key)
            if conversation is not None:
                legacy_conversations.append((legacy_key, conversation))

        if not legacy_conversations:
            return None

        primary_key, primary = max(
            legacy_conversations,
            key=lambda item: len(item[1].messages),
        )
        others = [conversation for _, conversation in legacy_conversations if conversation.id != primary.id]
        merged = self._merge_conversations(primary, others) if others else primary

        index[key] = merged.id
        for legacy_key, conversation in legacy_conversations:
            if index.get(legacy_key) == conversation.id:
                del index[legacy_key]
        self._save_scope_index(index)

        if merged is not primary or others:
            return self.save(merged)
        return merged

    def save(self, conversation: Conversation) -> Conversation:
        self._store.write(conversation.id, conversation)
        self._register_scope(conversation)
        return conversation

    def get(self, conversation_id: str) -> Conversation:
        return self._store.read(conversation_id, Conversation)

    def delete(self, conversation_id: str) -> None:
        try:
            conversation = self.get(conversation_id)
        except NodeNotFoundError:
            self._store.delete(conversation_id)
            return
        self._unregister_scope(conversation)
        self._store.delete(conversation_id)


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
