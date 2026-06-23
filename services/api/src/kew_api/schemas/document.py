"""Document read/write schemas."""

from __future__ import annotations

from pydantic import BaseModel, Field


class DocumentMeta(BaseModel):
    path: str
    title: str
    checksum: str
    last_modified: str
    size_bytes: int


class DocumentResponse(BaseModel):
    path: str
    content: str
    checksum: str
    meta: DocumentMeta


class UpdateDocumentRequest(BaseModel):
    path: str = Field(min_length=1)
    content: str
    checksum: str | None = Field(
        default=None,
        description="Expected checksum for optimistic concurrency; omit to skip check",
    )


class UpdateDocumentResponse(BaseModel):
    path: str
    checksum: str
    meta: DocumentMeta
    disk_path: str | None = Field(
        default=None,
        description="Absolute filesystem path of the saved file",
    )
