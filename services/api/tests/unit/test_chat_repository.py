"""Tests for scoped conversation persistence."""

from __future__ import annotations

from pathlib import Path

import pytest

from kew_api.config.settings import ApiSettings, clear_settings_cache
from kew_api.schemas.chat import ChatMessageRecord, ChatMode, Conversation
from kew_api.services.chat_repository import (
    ConversationRepository,
    build_legacy_scope_index_key,
    build_scope_index_key,
)


@pytest.fixture
def repo(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> ConversationRepository:
    data = tmp_path / ".data"
    data.mkdir()
    monkeypatch.setenv("KEW_API_DATA_ROOT", str(data))
    clear_settings_cache()
    return ConversationRepository(ApiSettings())


def test_scope_index_returns_same_conversation(repo: ConversationRepository) -> None:
    conversation = Conversation(
        id="conv-1",
        scope_kind="folder",
        scope_path="04_Data_Modeling_Architecture",
        chat_mode=ChatMode.PLAN,
    )
    repo.save(conversation)

    found = repo.find_by_scope("folder", "04_Data_Modeling_Architecture")
    assert found is not None
    assert found.id == "conv-1"


def test_scope_index_key_is_unified_per_section() -> None:
    assert build_scope_index_key("file", "docs/foo.md") == "file:docs/foo.md"
    assert build_legacy_scope_index_key("file", "docs/foo.md", "agent") == "file:docs/foo.md:agent"


def test_delete_removes_scope_index(repo: ConversationRepository) -> None:
    conversation = Conversation(
        id="conv-2",
        scope_kind="file",
        scope_path="Note.md",
        chat_mode=ChatMode.AGENT,
    )
    repo.save(conversation)
    repo.delete("conv-2")
    assert repo.find_by_scope("file", "Note.md") is None


def test_legacy_plan_and_agent_threads_merge(repo: ConversationRepository) -> None:
    plan = Conversation(
        id="conv-plan",
        scope_kind="folder",
        scope_path="02_Semantic_Modeling",
        chat_mode=ChatMode.PLAN,
        messages=[
            ChatMessageRecord(id="u1", role="user", content="Design structure", chat_mode=ChatMode.PLAN),
        ],
    )
    agent = Conversation(
        id="conv-agent",
        scope_kind="folder",
        scope_path="02_Semantic_Modeling",
        chat_mode=ChatMode.AGENT,
        messages=[
            ChatMessageRecord(id="u2", role="user", content="Apply the plan", chat_mode=ChatMode.AGENT),
        ],
    )
    index = repo._load_scope_index()
    index[build_legacy_scope_index_key("folder", "02_Semantic_Modeling", "plan")] = plan.id
    index[build_legacy_scope_index_key("folder", "02_Semantic_Modeling", "agent")] = agent.id
    repo._save_scope_index(index)
    repo._store.write(plan.id, plan)
    repo._store.write(agent.id, agent)

    merged = repo.find_by_scope("folder", "02_Semantic_Modeling")
    assert merged is not None
    assert len(merged.messages) == 2
    assert {message.id for message in merged.messages} == {"u1", "u2"}
