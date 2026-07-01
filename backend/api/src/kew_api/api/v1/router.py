"""API v1 routers."""

from fastapi import APIRouter

from kew_api.api.v1.chat import router as chat_router
from kew_api.api.v1.documents import router as documents_router
from kew_api.api.v1.health import router as health_router
from kew_api.api.v1.workspace import router as workspace_router

api_v1_router = APIRouter()
api_v1_router.include_router(health_router)
api_v1_router.include_router(workspace_router)
api_v1_router.include_router(documents_router)
api_v1_router.include_router(chat_router)
