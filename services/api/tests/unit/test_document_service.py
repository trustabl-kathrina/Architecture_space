"""Unit tests for document service."""

from __future__ import annotations

from pathlib import Path

import pytest

from kew_api.config.settings import ApiSettings
from kew_api.exceptions import NodeConflictError, NodeNotFoundError
from kew_api.services.document_service import DocumentService, content_checksum


@pytest.fixture
def service(tmp_path: Path) -> DocumentService:
    docs = tmp_path / "docs"
    docs.mkdir()
    (docs / "Note.md").write_text("# Note\n", encoding="utf-8")
    settings = ApiSettings(repo_root=tmp_path, docs_root=docs, data_root=tmp_path / ".data")
    return DocumentService(settings)


def test_get_document(service: DocumentService) -> None:
    doc = service.get_document("Note.md")
    assert doc.content.startswith("# Note")
    assert doc.checksum == content_checksum(doc.content)


def test_checksum_conflict(service: DocumentService) -> None:
    with pytest.raises(NodeConflictError):
        service.update_document("Note.md", "# Note\n\nchanged\n", expected_checksum="wrong")


def test_missing_document(service: DocumentService) -> None:
    with pytest.raises(NodeNotFoundError):
        service.get_document("Missing.md")
