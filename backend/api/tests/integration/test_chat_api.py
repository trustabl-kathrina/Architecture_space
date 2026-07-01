"""Integration tests for AI chat with mock mode."""

from __future__ import annotations

from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from kew_api.config.settings import ApiSettings, clear_settings_cache
from kew_api.main import create_app


@pytest.fixture
def client(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> TestClient:
    docs = tmp_path / "docs"
    docs.mkdir()
    (docs / "Note.md").write_text("---\ntitle: Note\n---\n# Note\n\nBody\n", encoding="utf-8")
    data = tmp_path / ".data"
    data.mkdir()

    monkeypatch.setenv("KEW_API_DOCS_ROOT", str(docs))
    monkeypatch.setenv("KEW_API_REPO_ROOT", str(tmp_path))
    monkeypatch.setenv("KEW_API_DATA_ROOT", str(data))
    monkeypatch.setenv("KEW_API_AI_MOCK_MODE", "true")
    clear_settings_cache()

    app = create_app(ApiSettings())
    with TestClient(app) as test_client:
        yield test_client
    clear_settings_cache()


def test_chat_advisory_flow(client: TestClient) -> None:
    conv = client.post("/api/v1/chat/conversations", json={"document_path": "Note.md"})
    assert conv.status_code == 201
    conversation_id = conv.json()["id"]

    response = client.post(
        f"/api/v1/chat/conversations/{conversation_id}/messages",
        json={"content": "What is this document about?", "document_path": "Note.md"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["change_plan"] is None
    assert "Mock advisory" in body["message"]["content"]
    assert len(body["message"]["execution_trail"]) >= 2


def test_chat_folder_planning_flow(client: TestClient) -> None:
    conv = client.post(
        "/api/v1/chat/conversations",
        json={"folder_path": ""},
    )
    assert conv.status_code == 201
    conversation_id = conv.json()["id"]

    response = client.post(
        f"/api/v1/chat/conversations/{conversation_id}/messages",
        json={
            "content": "Design a semantic modeling documentation structure",
            "folder_path": "",
            "chat_mode": "plan",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["change_plan"] is None
    assert body["folder_plan_result"] is not None
    assert "target_structure" in body["folder_plan_result"]
    assert "Planned structure" in body["message"]["content"]
    assert len(body["message"]["execution_trail"]) >= 2


def test_chat_folder_plan_greeting_is_conversational(client: TestClient) -> None:
    conv = client.post(
        "/api/v1/chat/conversations/resolve",
        json={
            "scope_kind": "folder",
            "scope_path": "04_Data_Modeling_Architecture",
            "chat_mode": "plan",
        },
    ).json()

    response = client.post(
        f"/api/v1/chat/conversations/{conv['id']}/messages",
        json={
            "content": "Hi",
            "folder_path": "04_Data_Modeling_Architecture",
            "chat_mode": "plan",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["folder_plan_result"] is None
    assert "Planned structure" not in body["message"]["content"] or "design or reorganize" in body["message"]["content"]
    assert "Refined structure" not in body["message"]["content"]


def test_chat_change_plan_and_apply(client: TestClient) -> None:
    conv = client.post("/api/v1/chat/conversations", json={"document_path": "Note.md"}).json()

    response = client.post(
        f"/api/v1/chat/conversations/{conv['id']}/messages",
        json={"content": "Expand the overview section", "document_path": "Note.md"},
    )
    assert response.status_code == 200
    plan = response.json()["change_plan"]
    assert plan is not None
    assert plan.get("sections") is not None
    edit_id = plan["edit_id"]

    get_plan = client.get(f"/api/v1/edits/{edit_id}")
    assert get_plan.status_code == 200

    apply_resp = client.post(f"/api/v1/edits/{edit_id}/apply", json={})
    assert apply_resp.status_code == 200

    doc = client.get("/api/v1/documents", params={"path": "Note.md"})
    assert "AI Suggested Section" in doc.json()["content"]


def test_chat_folder_planning_honors_user_draft(client: TestClient) -> None:
    conv = client.post(
        "/api/v1/chat/conversations",
        json={"folder_path": "04_Data_Modeling_Architecture"},
    ).json()

    user_draft = (
        "# Target structure\n\n"
        "04_Data_Modeling_Architecture/\n"
        "├── 03_Modern/\n"
        "│   └── 02_Semantic_Modeling/\n"
        "│       ├── 10_Custom_Metrics.md\n"
        "│       └── README.md\n"
        "\n"
        "# Reorganization\n\n"
        "- [move] old_metrics.md -> 03_Modern/02_Semantic_Modeling/10_Custom_Metrics.md: user rename\n"
    )

    response = client.post(
        f"/api/v1/chat/conversations/{conv['id']}/messages",
        json={
            "content": "Keep my custom metrics file and add a governance subfolder",
            "folder_path": "04_Data_Modeling_Architecture",
            "folder_plan": user_draft,
            "chat_mode": "plan",
        },
    )
    assert response.status_code == 200
    body = response.json()["folder_plan_result"]
    assert body is not None
    assert "10_Custom_Metrics.md" in body["target_structure"]
    assert any("move" in item["action"] for item in body["reorganization"])


def test_resolve_conversation_is_stable_per_scope(client: TestClient) -> None:
    first = client.post(
        "/api/v1/chat/conversations/resolve",
        json={
            "scope_kind": "folder",
            "scope_path": "04_Data_Modeling_Architecture",
            "chat_mode": "plan",
        },
    )
    assert first.status_code == 200
    first_id = first.json()["id"]

    client.post(
        f"/api/v1/chat/conversations/{first_id}/messages",
        json={
            "content": "Remember this thread",
            "folder_path": "04_Data_Modeling_Architecture",
            "chat_mode": "plan",
        },
    )

    second = client.post(
        "/api/v1/chat/conversations/resolve",
        json={
            "scope_kind": "folder",
            "scope_path": "04_Data_Modeling_Architecture",
            "chat_mode": "agent",
        },
    )
    assert second.status_code == 200
    assert second.json()["id"] == first_id
    assert len(second.json()["messages"]) == 2


def test_plan_and_agent_share_one_conversation(client: TestClient) -> None:
    plan = client.post(
        "/api/v1/chat/conversations/resolve",
        json={
            "scope_kind": "folder",
            "scope_path": "03_Modern",
            "chat_mode": "plan",
        },
    ).json()

    client.post(
        f"/api/v1/chat/conversations/{plan['id']}/messages",
        json={
            "content": "Hi from plan mode",
            "folder_path": "03_Modern",
            "chat_mode": "plan",
        },
    )

    agent = client.post(
        "/api/v1/chat/conversations/resolve",
        json={
            "scope_kind": "folder",
            "scope_path": "03_Modern",
            "chat_mode": "agent",
        },
    ).json()
    assert agent["id"] == plan["id"]

    response = client.post(
        f"/api/v1/chat/conversations/{agent['id']}/messages",
        json={
            "content": "Hi from agent mode",
            "folder_path": "03_Modern",
            "chat_mode": "agent",
        },
    )
    assert response.status_code == 200
    history = client.get(f"/api/v1/chat/conversations/{agent['id']}").json()["messages"]
    assert len(history) == 4
    assert history[0]["content"] == "Hi from plan mode"
    assert history[0]["chat_mode"] == "plan"
    assert history[2]["content"] == "Hi from agent mode"
    assert history[2]["chat_mode"] == "agent"


def test_edit_message_truncates_history(client: TestClient) -> None:
    resolved = client.post(
        "/api/v1/chat/conversations/resolve",
        json={"scope_kind": "file", "scope_path": "Note.md", "chat_mode": "agent"},
    ).json()
    conversation_id = resolved["id"]

    client.post(
        f"/api/v1/chat/conversations/{conversation_id}/messages",
        json={"content": "First question", "document_path": "Note.md"},
    )
    second = client.post(
        f"/api/v1/chat/conversations/{conversation_id}/messages",
        json={"content": "Second question", "document_path": "Note.md"},
    ).json()
    user_message_id = second["user_message"]["id"]

    edited = client.patch(
        f"/api/v1/chat/conversations/{conversation_id}/messages/{user_message_id}",
        json={"content": "Revised second question"},
    )
    assert edited.status_code == 200
    messages = edited.json()["messages"]
    assert len(messages) == 3
    assert messages[-1]["role"] == "user"
    assert messages[-1]["content"] == "Revised second question"


def test_clear_conversation_wipes_messages(client: TestClient) -> None:
    resolved = client.post(
        "/api/v1/chat/conversations/resolve",
        json={"scope_kind": "file", "scope_path": "Note.md", "chat_mode": "plan"},
    ).json()
    conversation_id = resolved["id"]

    client.post(
        f"/api/v1/chat/conversations/{conversation_id}/messages",
        json={"content": "Hello", "document_path": "Note.md", "chat_mode": "plan"},
    )

    cleared = client.post(f"/api/v1/chat/conversations/{conversation_id}/clear")
    assert cleared.status_code == 200
    assert cleared.json()["messages"] == []


def test_apply_persists_even_if_disk_changed_since_plan(client: TestClient, tmp_path: Path) -> None:
    """Approved plans must write to disk without checksum rejection."""
    docs = tmp_path / "docs"
    note = docs / "Note.md"
    note.write_text("---\ntitle: Note\n---\n# Note\n\nBody\n", encoding="utf-8")

    conv = client.post("/api/v1/chat/conversations", json={"document_path": "Note.md"}).json()
    plan = client.post(
        f"/api/v1/chat/conversations/{conv['id']}/messages",
        json={"content": "Expand the overview section", "document_path": "Note.md"},
    ).json()["change_plan"]
    assert plan is not None

    note.write_text("---\ntitle: Note\n---\n# Note\n\nBody changed on disk\n", encoding="utf-8")

    apply_resp = client.post(f"/api/v1/edits/{plan['edit_id']}/apply", json={})
    assert apply_resp.status_code == 200

    saved = note.read_text(encoding="utf-8")
    assert "AI Suggested Section" in saved
