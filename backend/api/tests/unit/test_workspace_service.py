"""Unit tests for workspace service."""

from __future__ import annotations

from pathlib import Path

import pytest

from kew_api.config.settings import ApiSettings
from kew_api.exceptions import NodeConflictError, NodeNotFoundError
from kew_api.services.workspace_service import WorkspaceService


@pytest.fixture
def service(tmp_path: Path) -> WorkspaceService:
    docs = tmp_path / "docs"
    docs.mkdir()
    settings = ApiSettings(
        repo_root=tmp_path,
        docs_root=docs,
        data_root=tmp_path / ".data",
    )
    return WorkspaceService(settings)


def test_create_and_list(service: WorkspaceService) -> None:
    service.create_folder("", "Alpha")
    tree = service.list_tree()
    assert any(node.name == "Alpha" for node in tree.nodes)


def test_delete_missing_raises(service: WorkspaceService) -> None:
    with pytest.raises(NodeNotFoundError):
        service.delete_node("missing.md")


def test_delete_nonempty_folder(service: WorkspaceService) -> None:
    service.create_folder("", "Parent")
    service.create_document("Parent", "Child")
    with pytest.raises(NodeConflictError):
        service.delete_node("Parent")
