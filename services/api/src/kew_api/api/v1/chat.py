"""AI chat and change plan endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Response
from fastapi.responses import StreamingResponse

from kew_api.api.deps import get_api_settings, get_document_service, get_workspace_service
from kew_api.config.settings import ApiSettings
from kew_api.schemas.section_context import SectionContext
from kew_api.schemas.chat import (
    ApplyChangePlanRequest,
    ApplyChangePlanResponse,
    ChangePlan,
    Conversation,
    CreateConversationRequest,
    EditMessageRequest,
    RegenerateMessageRequest,
    ResolveConversationRequest,
    SendMessageRequest,
    SendMessageResponse,
)
from kew_api.services.chat_service import ChatService
from kew_api.services.chat_streaming import format_sse
from kew_api.services.document_service import DocumentService
from kew_api.services.workspace_service import WorkspaceService

router = APIRouter(tags=["chat"])


def get_chat_service(
    settings: Annotated[ApiSettings, Depends(get_api_settings)],
    document_service: Annotated[DocumentService, Depends(get_document_service)],
    workspace_service: Annotated[WorkspaceService, Depends(get_workspace_service)],
) -> ChatService:
    return ChatService(settings, document_service, workspace_service)


ChatServiceDep = Annotated[ChatService, Depends(get_chat_service)]


def _message_stream_response(service: ChatService, event_generator) -> StreamingResponse:
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/chat/section-context", response_model=SectionContext)
def get_section_context(
    scope_kind: str,
    service: ChatServiceDep,
    scope_path: str = "",
) -> SectionContext:
    return service.get_section_context(scope_kind, scope_path)


@router.post("/chat/conversations/resolve", response_model=Conversation)
def resolve_conversation(
    body: ResolveConversationRequest,
    service: ChatServiceDep,
) -> Conversation:
    return service.resolve_conversation(
        scope_kind=body.scope_kind,
        scope_path=body.scope_path,
        chat_mode=body.chat_mode,
    )


@router.post("/chat/conversations", response_model=Conversation, status_code=201)
def create_conversation(
    body: CreateConversationRequest,
    service: ChatServiceDep,
) -> Conversation:
    return service.create_conversation(
        document_path=body.document_path,
        folder_path=body.folder_path,
    )


@router.get("/chat/conversations/{conversation_id}", response_model=Conversation)
def get_conversation(conversation_id: str, service: ChatServiceDep) -> Conversation:
    return service.get_conversation(conversation_id)


@router.post("/chat/conversations/{conversation_id}/clear", response_model=Conversation)
def clear_conversation(conversation_id: str, service: ChatServiceDep) -> Conversation:
    return service.clear_conversation(conversation_id)


@router.delete("/chat/conversations/{conversation_id}", status_code=204)
def delete_conversation(conversation_id: str, service: ChatServiceDep) -> Response:
    service.delete_conversation(conversation_id)
    return Response(status_code=204)


@router.patch(
    "/chat/conversations/{conversation_id}/messages/{message_id}",
    response_model=Conversation,
)
def edit_message(
    conversation_id: str,
    message_id: str,
    body: EditMessageRequest,
    service: ChatServiceDep,
) -> Conversation:
    return service.edit_user_message(conversation_id, message_id, body.content)


@router.delete(
    "/chat/conversations/{conversation_id}/messages/{message_id}",
    response_model=Conversation,
)
def delete_message(
    conversation_id: str,
    message_id: str,
    service: ChatServiceDep,
) -> Conversation:
    return service.delete_from_message(conversation_id, message_id)


@router.post(
    "/chat/conversations/{conversation_id}/messages",
    response_model=SendMessageResponse,
)
async def send_message(
    conversation_id: str,
    body: SendMessageRequest,
    service: ChatServiceDep,
) -> SendMessageResponse:
    return await service.send_message(
        conversation_id,
        content=body.content,
        document_path=body.document_path,
        folder_path=body.folder_path,
        folder_plan=body.folder_plan,
        folder_contents=body.folder_contents,
        chat_mode=body.chat_mode,
        selection=body.selection,
        open_paths=body.open_paths,
        active_section=body.active_section,
        document_outline=body.document_outline,
    )


@router.post("/chat/conversations/{conversation_id}/messages/stream")
async def send_message_stream(
    conversation_id: str,
    body: SendMessageRequest,
    service: ChatServiceDep,
) -> StreamingResponse:
    async def event_generator():
        async for event in service.iter_message_events(
            conversation_id,
            content=body.content,
            document_path=body.document_path,
            folder_path=body.folder_path,
            folder_plan=body.folder_plan,
            folder_contents=body.folder_contents,
            chat_mode=body.chat_mode,
            selection=body.selection,
            open_paths=body.open_paths,
            active_section=body.active_section,
            document_outline=body.document_outline,
            stream_text=True,
        ):
            yield format_sse(event)

    return _message_stream_response(service, event_generator)


@router.post(
    "/chat/conversations/{conversation_id}/messages/{message_id}/regenerate/stream",
)
async def regenerate_message_stream(
    conversation_id: str,
    message_id: str,
    body: RegenerateMessageRequest,
    service: ChatServiceDep,
) -> StreamingResponse:
    async def event_generator():
        async for event in service.iter_regenerate_events(
            conversation_id,
            message_id,
            document_path=body.document_path,
            folder_path=body.folder_path,
            folder_plan=body.folder_plan,
            folder_contents=body.folder_contents,
            chat_mode=body.chat_mode,
            selection=body.selection,
            open_paths=body.open_paths,
            active_section=body.active_section,
            document_outline=body.document_outline,
            stream_text=True,
        ):
            yield format_sse(event)

    return _message_stream_response(service, event_generator)


@router.get("/edits/{edit_id}", response_model=ChangePlan)
def get_change_plan(edit_id: str, service: ChatServiceDep) -> ChangePlan:
    return service.get_change_plan(edit_id)


@router.post("/edits/{edit_id}/apply", response_model=ApplyChangePlanResponse)
def apply_change_plan(
    edit_id: str,
    body: ApplyChangePlanRequest,
    service: ChatServiceDep,
) -> ApplyChangePlanResponse:
    checksum, disk_path = service.apply_change_plan(edit_id, accepted_hunk_ids=body.accepted_hunk_ids)
    plan = service.get_change_plan(edit_id)
    return ApplyChangePlanResponse(
        edit_id=edit_id,
        document_path=plan.document_path,
        checksum=checksum,
        applied=True,
        disk_path=disk_path or None,
    )


@router.delete("/edits/{edit_id}", response_model=ChangePlan)
def discard_change_plan(edit_id: str, service: ChatServiceDep) -> ChangePlan:
    return service.discard_change_plan(edit_id)
