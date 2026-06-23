"""Health check endpoints."""

from __future__ import annotations

from fastapi import APIRouter

from kew_api.api.deps import SettingsDep

router = APIRouter(tags=["health"])


@router.get("/health")
def health(settings: SettingsDep) -> dict[str, str]:
    return {
        "status": "ok",
        "service": "kew-api",
        "environment": settings.environment.value,
    }


@router.get("/ready")
def ready(settings: SettingsDep) -> dict[str, str | bool]:
    docs_exists = settings.resolved_docs_root.is_dir()
    return {
        "status": "ready" if docs_exists else "degraded",
        "docs_root": str(settings.resolved_docs_root),
        "docs_accessible": docs_exists,
    }
