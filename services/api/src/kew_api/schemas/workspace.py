"""Workspace / documentation tree schemas."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class WorkspaceInfo(BaseModel):
    root: str
    name: str
    docs_root: str


class TreeNode(BaseModel):
    id: str
    name: str
    path: str
    type: Literal["folder", "file"]
    has_children: bool = False
    children: list[TreeNode] | None = None


class TreeResponse(BaseModel):
    parent_path: str
    nodes: list[TreeNode]


class CreateFolderRequest(BaseModel):
    parent_path: str = ""
    name: str = Field(min_length=1, max_length=255)


class CreateDocumentRequest(BaseModel):
    parent_path: str = ""
    name: str = Field(min_length=1, max_length=255)
    template_type: str = "overview"


class UpdateNodeRequest(BaseModel):
    path: str = Field(min_length=1)
    new_name: str | None = Field(default=None, min_length=1, max_length=255)
    new_parent_path: str | None = None


class DeleteNodeResponse(BaseModel):
    deleted: str
    type: Literal["folder", "file"]
