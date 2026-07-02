"""HTTP exception handlers and error response mapping."""

from __future__ import annotations

import logging
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from kew_api.config.settings import ApiSettings, get_settings
from kew_api.exceptions import (
    AiServiceError,
    InvalidNameError,
    KewApiError,
    NodeAlreadyExistsError,
    NodeConflictError,
    NodeNotFoundError,
    PathTraversalError,
)
from kew_api.schemas.common import ApiErrorResponse

logger = logging.getLogger(__name__)


def _format_validation_errors(errors: list[dict[str, object]]) -> str:
    parts: list[str] = []
    for error in errors:
        loc = error.get("loc", ())
        field = ".".join(str(part) for part in loc if part != "body") or "request"
        msg = str(error.get("msg", "invalid value"))
        parts.append(f"{field}: {msg}")
    if not parts:
        return "Request validation failed"
    return f"Request validation failed — {'; '.join(parts)}"


def _error_payload(code: str, message: str, details: dict[str, Any] | None = None) -> dict[str, Any]:
    return ApiErrorResponse(code=code, message=message, details=details or {}).model_dump()


def register_exception_handlers(app: FastAPI) -> None:
    from kew_api.ai.errors import AiRunnerError

    @app.exception_handler(AiRunnerError)
    async def ai_runner_error_handler(_request: Request, exc: AiRunnerError) -> JSONResponse:
        logger.warning("AI runner error: %s", exc)
        return JSONResponse(
            status_code=503,
            content=_error_payload("ai_unavailable", str(exc)),
        )

    @app.exception_handler(OSError)
    async def os_error_handler(_request: Request, exc: OSError) -> JSONResponse:
        logger.warning("OS error during request: %s", exc)
        return JSONResponse(
            status_code=503,
            content=_error_payload(
                "ai_unavailable",
                "Cursor bridge error. Ensure Cursor IDE is installed and restart the API.",
            ),
        )

    @app.exception_handler(NotImplementedError)
    async def not_implemented_handler(_request: Request, exc: NotImplementedError) -> JSONResponse:
        logger.warning("Not implemented during request: %s", exc)
        return JSONResponse(
            status_code=503,
            content=_error_payload(
                "ai_unavailable",
                "Cursor bridge is unavailable on this server setup. "
                "Restart the API after updating, or set KEW_API_AI_MOCK_MODE=true.",
            ),
        )

    @app.exception_handler(KewApiError)
    async def kew_api_error_handler(_request: Request, exc: KewApiError) -> JSONResponse:
        status_code = _status_for_domain_error(exc)
        logger.warning("Domain error [%s]: %s", exc.code, exc.message)
        return JSONResponse(
            status_code=status_code,
            content=_error_payload(exc.code, exc.message),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(
        _request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        return JSONResponse(
            status_code=422,
            content=_error_payload(
                "validation_error",
                _format_validation_errors(exc.errors()),
                {"errors": exc.errors()},
            ),
        )

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(
        _request: Request, exc: StarletteHTTPException
    ) -> JSONResponse:
        detail = exc.detail if isinstance(exc.detail, str) else str(exc.detail)
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_payload("http_error", detail),
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        settings = get_settings()
        logger.exception("Unhandled error on %s", request.url.path)
        message = str(exc) if settings.expose_error_details else "Internal server error"
        return JSONResponse(
            status_code=500,
            content=_error_payload("internal_error", message),
        )


def _status_for_domain_error(exc: KewApiError) -> int:
    if isinstance(exc, NodeNotFoundError):
        return 404
    if isinstance(exc, (NodeAlreadyExistsError, NodeConflictError)):
        return 409
    if isinstance(exc, (PathTraversalError, InvalidNameError)):
        return 400
    if isinstance(exc, AiServiceError):
        return 503
    return 400


def register_middleware(app: FastAPI, settings: ApiSettings) -> None:
    from starlette.middleware.cors import CORSMiddleware

    import uuid

    from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
    from starlette.requests import Request
    from starlette.responses import Response

    class RequestIdMiddleware(BaseHTTPMiddleware):
        async def dispatch(
            self, request: Request, call_next: RequestResponseEndpoint
        ) -> Response:
            request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
            request.state.request_id = request_id
            response = await call_next(request)
            response.headers["X-Request-ID"] = request_id
            return response

    app.add_middleware(RequestIdMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
