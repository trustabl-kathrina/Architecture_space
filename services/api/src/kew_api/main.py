"""FastAPI application factory."""

from __future__ import annotations

import asyncio
import sys
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from kew_api.ai.cursor_runner import shutdown_cursor_runtime
from kew_api.api.errors import register_exception_handlers, register_middleware
from kew_api.api.v1.router import api_v1_router
from kew_api.config.logging import configure_logging
from kew_api.config.settings import AiProvider, ApiSettings, get_settings

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    configure_logging(settings)
    settings.ensure_runtime_directories()
    try:
        yield
    finally:
        if settings.resolved_ai_provider == AiProvider.CURSOR:
            shutdown_cursor_runtime()


def create_app(settings: ApiSettings | None = None) -> FastAPI:
    """Build and configure the FastAPI application."""
    resolved = settings or get_settings()

    app = FastAPI(
        title=resolved.app_name,
        version=resolved.app_version,
        debug=resolved.debug,
        lifespan=lifespan,
        docs_url="/docs" if resolved.debug else None,
        redoc_url="/redoc" if resolved.debug else None,
        openapi_url=resolved.openapi_url,
    )

    register_middleware(app, resolved)
    register_exception_handlers(app)
    app.include_router(api_v1_router, prefix=resolved.api_v1_prefix)

    return app


app = create_app()


def run() -> None:
    """CLI entrypoint: uvicorn kew_api.main:app."""
    import uvicorn

    settings = get_settings()
    reload_dirs = [str(settings.api_root / "src")] if settings.reload else None
    uvicorn.run(
        "kew_api.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.reload,
        reload_dirs=reload_dirs,
        workers=1 if settings.reload else settings.workers,
        log_level=settings.log_level.lower(),
    )


if __name__ == "__main__":
    run()
