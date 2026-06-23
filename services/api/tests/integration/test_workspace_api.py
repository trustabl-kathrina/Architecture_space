"""Integration tests for workspace API."""

from __future__ import annotations

from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from kew_api.config.settings import ApiSettings, clear_settings_cache
from kew_api.main import create_app


@pytest.fixture
def docs_tree(tmp_path: Path) -> Path:
  docs = tmp_path / "docs"
  docs.mkdir()
  (docs / "01_Data_Architecture").mkdir()
  (docs / "01_Data_Architecture" / "Overview.md").write_text("# Overview\n", encoding="utf-8")
  (docs / "02_Engineering").mkdir()
  return docs


@pytest.fixture
def client(docs_tree: Path, monkeypatch: pytest.MonkeyPatch) -> TestClient:
    monkeypatch.setenv("KEW_API_DOCS_ROOT", str(docs_tree))
    monkeypatch.setenv("KEW_API_REPO_ROOT", str(docs_tree.parent))
    clear_settings_cache()
    settings = ApiSettings()
    app = create_app(settings)
    with TestClient(app) as test_client:
        yield test_client
    clear_settings_cache()


def test_get_workspace(client: TestClient) -> None:
    response = client.get("/api/v1/workspace")
    assert response.status_code == 200
    assert "docs_root" in response.json()


def test_list_tree_root(client: TestClient) -> None:
    response = client.get("/api/v1/workspace/tree")
    assert response.status_code == 200
    nodes = response.json()["nodes"]
    assert len(nodes) == 2
    assert nodes[0]["type"] == "folder"


def test_create_folder_and_document(client: TestClient) -> None:
    folder_resp = client.post(
        "/api/v1/workspace/folders",
        json={"parent_path": "", "name": "03_New_Section"},
    )
    assert folder_resp.status_code == 201

    doc_resp = client.post(
        "/api/v1/workspace/documents",
        json={"parent_path": "03_New_Section", "name": "Intro"},
    )
    assert doc_resp.status_code == 201
    assert doc_resp.json()["name"] == "Intro.md"


def test_rename_document(client: TestClient) -> None:
    client.post(
        "/api/v1/workspace/documents",
        json={"parent_path": "", "name": "Temp_Doc"},
    )
    response = client.patch(
        "/api/v1/workspace/nodes",
        json={"path": "Temp_Doc.md", "new_name": "Renamed_Doc"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Renamed_Doc.md"


def test_move_document(client: TestClient) -> None:
    client.post("/api/v1/workspace/folders", json={"parent_path": "", "name": "Target"})
    client.post("/api/v1/workspace/documents", json={"parent_path": "", "name": "Movable"})
    response = client.patch(
        "/api/v1/workspace/nodes",
        json={"path": "Movable.md", "new_parent_path": "Target"},
    )
    assert response.status_code == 200
    assert response.json()["path"] == "Target/Movable.md"


def test_delete_empty_folder(client: TestClient) -> None:
    client.post("/api/v1/workspace/folders", json={"parent_path": "", "name": "Empty"})
    response = client.delete("/api/v1/workspace/nodes", params={"path": "Empty"})
    assert response.status_code == 200


def test_delete_nonempty_folder_fails(client: TestClient) -> None:
    client.post("/api/v1/workspace/folders", json={"parent_path": "", "name": "Parent"})
    client.post(
        "/api/v1/workspace/documents",
        json={"parent_path": "Parent", "name": "Child"},
    )
    response = client.delete("/api/v1/workspace/nodes", params={"path": "Parent"})
    assert response.status_code == 409
