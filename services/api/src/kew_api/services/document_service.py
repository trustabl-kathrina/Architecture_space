"""Read and write Markdown documents on the local filesystem."""

from __future__ import annotations

import hashlib
import logging
from datetime import UTC, datetime
from pathlib import Path

from kew_api.config.settings import ApiSettings
from kew_api.exceptions import NodeConflictError, NodeNotFoundError
from kew_api.schemas.document import DocumentMeta, DocumentResponse, UpdateDocumentResponse
from kew_api.services.filesystem_guard import normalize_relative_path, resolve_under_root

logger = logging.getLogger(__name__)


def content_checksum(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


class DocumentService:
    """Load and persist Markdown files under docs_root."""

    def __init__(self, settings: ApiSettings) -> None:
        self._docs_root = settings.resolved_docs_root

    def get_document(self, path: str) -> DocumentResponse:
        file_path = self._resolve_markdown_path(path)
        if not file_path.is_file():
            raise NodeNotFoundError(path)

        content = file_path.read_text(encoding="utf-8")
        checksum = content_checksum(content)
        stat = file_path.stat()

        return DocumentResponse(
            path=normalize_relative_path(path),
            content=content,
            checksum=checksum,
            meta=self._build_meta(file_path, checksum, stat.st_size),
        )

    def update_document(
        self,
        path: str,
        content: str,
        *,
        expected_checksum: str | None = None,
    ) -> UpdateDocumentResponse:
        file_path = self._resolve_markdown_path(path)
        relative = normalize_relative_path(path)

        if file_path.is_file() and expected_checksum:
            current = file_path.read_text(encoding="utf-8")
            current_checksum = content_checksum(current)
            if current_checksum != expected_checksum:
                raise NodeConflictError(
                    "Document changed since last load; reload and retry",
                )

        if not file_path.parent.is_dir():
            raise NodeNotFoundError(str(Path(relative).parent))

        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content, encoding="utf-8", newline="\n")
        new_checksum = content_checksum(content)
        stat = file_path.stat()
        logger.info("Saved document to disk: %s (%s bytes)", file_path.resolve(), stat.st_size)

        return UpdateDocumentResponse(
            path=relative,
            checksum=new_checksum,
            meta=self._build_meta(file_path, new_checksum, stat.st_size),
            disk_path=str(file_path.resolve()),
        )

    def _resolve_markdown_path(self, path: str) -> Path:
        relative = normalize_relative_path(path)
        if not relative.lower().endswith(".md"):
            raise NodeConflictError("Only Markdown (.md) documents are supported")
        return resolve_under_root(self._docs_root, relative)

    def _build_meta(self, file_path: Path, checksum: str, size_bytes: int) -> DocumentMeta:
        relative = file_path.relative_to(self._docs_root.resolve()).as_posix()
        modified = datetime.fromtimestamp(file_path.stat().st_mtime, tz=UTC).isoformat()
        return DocumentMeta(
            path=relative,
            title=file_path.stem.replace("_", " "),
            checksum=checksum,
            last_modified=modified,
            size_bytes=size_bytes,
        )
