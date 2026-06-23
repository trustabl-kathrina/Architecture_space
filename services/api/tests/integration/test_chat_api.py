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
