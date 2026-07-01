"""Integration tests for documents API."""

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
    (docs / "Sample.md").write_text("# Sample\n\nHello world\n", encoding="utf-8")
    return docs


@pytest.fixture
def client(docs_tree: Path, monkeypatch: pytest.MonkeyPatch) -> TestClient:
    monkeypatch.setenv("KEW_API_DOCS_ROOT", str(docs_tree))
    monkeypatch.setenv("KEW_API_REPO_ROOT", str(docs_tree.parent))
    clear_settings_cache()
    app = create_app(ApiSettings())
    with TestClient(app) as test_client:
        yield test_client
    clear_settings_cache()


def test_get_document(client: TestClient) -> None:
    response = client.get("/api/v1/documents", params={"path": "Sample.md"})
    assert response.status_code == 200
    body = response.json()
    assert "Hello world" in body["content"]
    assert len(body["checksum"]) == 64


def test_put_document(client: TestClient) -> None:
    get_resp = client.get("/api/v1/documents", params={"path": "Sample.md"})
    checksum = get_resp.json()["checksum"]

    put_resp = client.put(
        "/api/v1/documents",
        json={
            "path": "Sample.md",
            "content": "# Sample\n\nUpdated content\n",
            "checksum": checksum,
        },
    )
    assert put_resp.status_code == 200
    assert put_resp.json()["checksum"] != checksum


def test_put_conflict(client: TestClient) -> None:
    response = client.put(
        "/api/v1/documents",
        json={
            "path": "Sample.md",
            "content": "# Sample\n\nConflict\n",
            "checksum": "deadbeef",
        },
    )
    assert response.status_code == 409
