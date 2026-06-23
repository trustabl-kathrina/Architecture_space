"""API request/response schemas."""

from kew_api.schemas.common import ApiErrorResponse
from kew_api.schemas.workspace import (
    CreateDocumentRequest,
    CreateFolderRequest,
    DeleteNodeResponse,
    TreeNode,
    TreeResponse,
    UpdateNodeRequest,
    WorkspaceInfo,
)

__all__ = [
    "ApiErrorResponse",
    "CreateDocumentRequest",
    "CreateFolderRequest",
    "DeleteNodeResponse",
    "TreeNode",
    "TreeResponse",
    "UpdateNodeRequest",
    "WorkspaceInfo",
]
