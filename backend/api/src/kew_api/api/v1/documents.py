"""Document read/write endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Query

from kew_api.api.deps import DocumentServiceDep
from kew_api.schemas.document import DocumentResponse, UpdateDocumentRequest, UpdateDocumentResponse

router = APIRouter(prefix="/documents", tags=["documents"])


@router.get("", response_model=DocumentResponse)
def get_document(
    service: DocumentServiceDep,
    path: str = Query(..., min_length=1, description="Relative path under docs/"),
) -> DocumentResponse:
    return service.get_document(path)


@router.put("", response_model=UpdateDocumentResponse)
def update_document(
    body: UpdateDocumentRequest,
    service: DocumentServiceDep,
) -> UpdateDocumentResponse:
    return service.update_document(
        body.path,
        body.content,
        expected_checksum=body.checksum,
    )
