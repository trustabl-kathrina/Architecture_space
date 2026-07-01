"""Workspace and documentation tree endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Query

from kew_api.api.deps import WorkspaceDep
from kew_api.schemas.workspace import (
    CreateDocumentRequest,
    CreateFolderRequest,
    DeleteNodeResponse,
    TreeNode,
    TreeResponse,
    UpdateNodeRequest,
    WorkspaceInfo,
)

router = APIRouter(prefix="/workspace", tags=["workspace"])


@router.get("", response_model=WorkspaceInfo)
def get_workspace(service: WorkspaceDep) -> WorkspaceInfo:
    return service.get_workspace_info()


@router.get("/tree", response_model=TreeResponse)
def get_tree(
    service: WorkspaceDep,
    parent_path: str = Query(default="", description="Relative path under docs/"),
    depth: int = Query(default=1, ge=1, le=5),
) -> TreeResponse:
    return service.list_tree(parent_path=parent_path, depth=depth)


@router.post("/folders", response_model=TreeNode, status_code=201)
def create_folder(body: CreateFolderRequest, service: WorkspaceDep) -> TreeNode:
    return service.create_folder(parent_path=body.parent_path, name=body.name)


@router.post("/documents", response_model=TreeNode, status_code=201)
def create_document(body: CreateDocumentRequest, service: WorkspaceDep) -> TreeNode:
    return service.create_document(
        parent_path=body.parent_path,
        name=body.name,
        template_type=body.template_type,
    )


@router.patch("/nodes", response_model=TreeNode)
def update_node(body: UpdateNodeRequest, service: WorkspaceDep) -> TreeNode:
    return service.update_node(
        body.path,
        new_name=body.new_name,
        new_parent_path=body.new_parent_path,
    )


@router.delete("/nodes", response_model=DeleteNodeResponse)
def delete_node(
    service: WorkspaceDep,
    path: str = Query(min_length=1, description="Relative path under docs/"),
) -> DeleteNodeResponse:
    return service.delete_node(path)
