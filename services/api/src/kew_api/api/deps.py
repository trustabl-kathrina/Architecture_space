"""FastAPI dependency injection."""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends, Request

from kew_api.config.settings import ApiSettings, get_settings
from kew_api.services.document_service import DocumentService
from kew_api.services.workspace_service import WorkspaceService


def get_api_settings() -> ApiSettings:
    return get_settings()


def get_workspace_service(
    settings: Annotated[ApiSettings, Depends(get_api_settings)],
) -> WorkspaceService:
    return WorkspaceService(settings)


def get_document_service(
    settings: Annotated[ApiSettings, Depends(get_api_settings)],
) -> DocumentService:
    return DocumentService(settings)


def get_request_id(request: Request) -> str:
    return getattr(request.state, "request_id", "unknown")


SettingsDep = Annotated[ApiSettings, Depends(get_api_settings)]
WorkspaceDep = Annotated[WorkspaceService, Depends(get_workspace_service)]
DocumentServiceDep = Annotated[DocumentService, Depends(get_document_service)]
RequestIdDep = Annotated[str, Depends(get_request_id)]
