"""Domain exceptions for the KEW API."""

from __future__ import annotations


class KewApiError(Exception):
    """Base exception for API domain errors."""

    def __init__(self, message: str, *, code: str = "api_error") -> None:
        super().__init__(message)
        self.message = message
        self.code = code


class PathTraversalError(KewApiError):
    def __init__(self, path: str) -> None:
        super().__init__(f"Path escapes workspace boundary: {path}", code="path_traversal")
        self.path = path


class NodeNotFoundError(KewApiError):
    def __init__(self, path: str) -> None:
        super().__init__(f"Node not found: {path}", code="not_found")
        self.path = path


class NodeAlreadyExistsError(KewApiError):
    def __init__(self, path: str) -> None:
        super().__init__(f"Node already exists: {path}", code="already_exists")
        self.path = path


class NodeConflictError(KewApiError):
    def __init__(self, message: str) -> None:
        super().__init__(message, code="conflict")


class InvalidNameError(KewApiError):
    def __init__(self, name: str, reason: str) -> None:
        super().__init__(f"Invalid name {name!r}: {reason}", code="invalid_name")
        self.name = name


class AiServiceError(KewApiError):
    def __init__(self, message: str) -> None:
        super().__init__(message, code="ai_unavailable")
