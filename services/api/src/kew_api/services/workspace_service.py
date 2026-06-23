"""Documentation tree operations against the local filesystem corpus."""

from __future__ import annotations

import logging
import shutil
from datetime import UTC, datetime
from pathlib import Path

from kew_api.config.settings import ApiSettings
from kew_api.exceptions import (
    InvalidNameError,
    NodeAlreadyExistsError,
    NodeConflictError,
    NodeNotFoundError,
)
from kew_api.schemas.workspace import DeleteNodeResponse, TreeNode, TreeResponse, WorkspaceInfo
from kew_api.services.filesystem_guard import (
    normalize_relative_path,
    resolve_under_root,
    to_relative_path,
    validate_node_name,
)

logger = logging.getLogger(__name__)

_DOCUMENT_TEMPLATE = """---
title: {title}
status: draft
template: {template_type}
last_reviewed: {last_reviewed}
owner: architecture-team
tags: []
---
# {title}

## Overview

"""


class WorkspaceService:
    """CRUD and tree navigation for Markdown documentation on disk."""

    def __init__(self, settings: ApiSettings) -> None:
        self._settings = settings
        self._docs_root = settings.resolved_docs_root

    @property
    def docs_root(self) -> Path:
        return self._docs_root

    def get_workspace_info(self) -> WorkspaceInfo:
        return WorkspaceInfo(
            root=str(self._settings.repo_root),
            name=self._settings.repo_root.name,
            docs_root=str(self._docs_root),
        )

    def list_tree(self, parent_path: str = "", depth: int = 1) -> TreeResponse:
        parent_relative = normalize_relative_path(parent_path)
        parent_dir = resolve_under_root(self._docs_root, parent_relative)
        if parent_relative and not parent_dir.is_dir():
            raise NodeNotFoundError(parent_relative)

        nodes = self._list_children(parent_dir, parent_relative, depth=max(1, depth))
        return TreeResponse(parent_path=parent_relative, nodes=nodes)

    def create_folder(self, parent_path: str, name: str) -> TreeNode:
        folder_name = validate_node_name(name)
        parent_relative = normalize_relative_path(parent_path)
        parent_dir = resolve_under_root(self._docs_root, parent_relative)
        if not parent_dir.is_dir():
            raise NodeNotFoundError(parent_relative)

        target = parent_dir / folder_name
        relative = to_relative_path(self._docs_root, target)
        if target.exists():
            raise NodeAlreadyExistsError(relative)

        target.mkdir(parents=False, exist_ok=False)
        logger.info("Created folder: %s", relative)
        return self._node_for_path(target, "folder")

    def create_document(
        self,
        parent_path: str,
        name: str,
        template_type: str = "overview",
    ) -> TreeNode:
        doc_name = validate_node_name(name)
        if not doc_name.lower().endswith(".md"):
            doc_name = f"{doc_name}.md"

        parent_relative = normalize_relative_path(parent_path)
        parent_dir = resolve_under_root(self._docs_root, parent_relative)
        if not parent_dir.is_dir():
            raise NodeNotFoundError(parent_relative)

        target = parent_dir / doc_name
        relative = to_relative_path(self._docs_root, target)
        if target.exists():
            raise NodeAlreadyExistsError(relative)

        title = Path(doc_name).stem.replace("_", " ")
        content = _DOCUMENT_TEMPLATE.format(
            title=title,
            template_type=template_type,
            last_reviewed=datetime.now(UTC).date().isoformat(),
        )
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        logger.info("Created document: %s", relative)
        return self._node_for_path(target, "file")

    def update_node(
        self,
        path: str,
        *,
        new_name: str | None = None,
        new_parent_path: str | None = None,
    ) -> TreeNode:
        if new_name is None and new_parent_path is None:
            raise NodeConflictError("Provide new_name and/or new_parent_path")

        source_relative = normalize_relative_path(path)
        source = resolve_under_root(self._docs_root, source_relative)
        if not source.exists():
            raise NodeNotFoundError(source_relative)

        node_type: str = "folder" if source.is_dir() else "file"
        target_parent_relative = (
            normalize_relative_path(new_parent_path)
            if new_parent_path is not None
            else str(Path(source_relative).parent).replace("\\", "/")
        )
        if target_parent_relative == ".":
            target_parent_relative = ""

        target_parent = resolve_under_root(self._docs_root, target_parent_relative)
        if not target_parent.is_dir():
            raise NodeNotFoundError(target_parent_relative)

        if new_name is not None:
            validated = validate_node_name(new_name)
            if node_type == "file" and not validated.lower().endswith(".md"):
                validated = f"{validated}.md"
            destination = target_parent / validated
        else:
            destination = target_parent / source.name

        destination_relative = to_relative_path(self._docs_root, destination)
        if destination.resolve() == source.resolve():
            return self._node_for_path(source, node_type)  # type: ignore[arg-type]

        if destination.exists():
            raise NodeAlreadyExistsError(destination_relative)

        if node_type == "folder" and str(destination.resolve()).startswith(str(source.resolve())):
            raise NodeConflictError("Cannot move a folder into itself or its descendant")

        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(destination))
        logger.info("Moved/renamed node: %s -> %s", source_relative, destination_relative)
        return self._node_for_path(destination, node_type)  # type: ignore[arg-type]

    def delete_node(self, path: str) -> DeleteNodeResponse:
        relative = normalize_relative_path(path)
        target = resolve_under_root(self._docs_root, relative)
        if not target.exists():
            raise NodeNotFoundError(relative)

        if target.is_dir():
            if any(target.iterdir()):
                raise NodeConflictError("Folder is not empty; delete children first")
            target.rmdir()
            node_type = "folder"
        else:
            target.unlink()
            node_type = "file"

        logger.info("Deleted %s: %s", node_type, relative)
        return DeleteNodeResponse(deleted=relative, type=node_type)  # type: ignore[arg-type]

    def _list_children(self, directory: Path, parent_relative: str, *, depth: int) -> list[TreeNode]:
        if not directory.is_dir():
            return []

        entries: list[Path] = []
        for entry in directory.iterdir():
            if entry.name.startswith("."):
                continue
            if entry.is_dir():
                entries.append(entry)
            elif entry.suffix.lower() == ".md":
                entries.append(entry)

        entries.sort(key=lambda p: (0 if p.is_dir() else 1, p.name.lower()))

        nodes: list[TreeNode] = []
        for entry in entries:
            relative = to_relative_path(self._docs_root, entry)
            node_type = "folder" if entry.is_dir() else "file"
            has_children = False
            children: list[TreeNode] | None = None

            if entry.is_dir():
                child_entries = [
                    child
                    for child in entry.iterdir()
                    if not child.name.startswith(".")
                    and (child.is_dir() or child.suffix.lower() == ".md")
                ]
                has_children = len(child_entries) > 0
                if depth > 1:
                    children = self._list_children(entry, relative, depth=depth - 1)

            nodes.append(
                TreeNode(
                    id=relative,
                    name=entry.name,
                    path=relative,
                    type=node_type,  # type: ignore[arg-type]
                    has_children=has_children,
                    children=children,
                )
            )
        return nodes

    def _node_for_path(self, path: Path, node_type: str) -> TreeNode:
        relative = to_relative_path(self._docs_root, path)
        has_children = False
        if path.is_dir():
            has_children = any(
                not child.name.startswith(".")
                and (child.is_dir() or child.suffix.lower() == ".md")
                for child in path.iterdir()
            )
        return TreeNode(
            id=relative,
            name=path.name,
            path=relative,
            type=node_type,  # type: ignore[arg-type]
            has_children=has_children,
        )
