"""AI chat orchestration and change plan generation."""

from __future__ import annotations

import logging
import uuid
from collections.abc import AsyncIterator, Callable
from datetime import UTC, datetime

from kew_api.ai.folder_implement_runner import (
    _requests_folder_implement,
    apply_folder_plan,
    format_folder_implement_message,
)
from kew_api.ai.folder_plan_runner import (
    format_folder_plan_message,
    render_tree_text,
    run_folder_plan_pipeline,
)
from kew_api.ai.agents import build_advisor_agent, build_orchestrator_agent
from kew_api.ai.editor_runner import run_editor_plan
from kew_api.ai.errors import AiRunnerError
from kew_api.ai.prompts import load_prompt
from kew_api.ai.runner import run_structured_agent
from kew_api.config.settings import ApiSettings
from kew_api.exceptions import InvalidChatOperationError, NodeConflictError, NodeNotFoundError
from kew_api.schemas.chat import (
    AdvisorOutput,
    AgentName,
    AgentStepStatus,
    ChangePlan,
    ChatIntent,
    ChatMessageRecord,
    ChatMode,
    ChatStreamEvent,
    ChatStreamEventType,
    Conversation,
    FolderImplementResult,
    FolderPlanResult,
    IntentResult,
    SendMessageResponse,
)
from kew_api.services.markdown_normalize import normalize_document_body, normalize_markdown_text
from kew_api.services.chat_repository import ChangePlanRepository, ConversationRepository
from kew_api.schemas.section_context import FolderPlanAgentInputs
from kew_api.services.section_context_repository import SectionContextRepository
from kew_api.services.chat_streaming import stream_text_chunks
from kew_api.services.diff_service import build_change_hunks
from kew_api.services.section_diff import apply_section_changes, build_section_changes
from kew_api.services.document_service import DocumentService
from kew_api.services.workspace_service import WorkspaceService
from kew_api.services.execution_trail import (
    STEP_CLASSIFY_INTENT,
    STEP_READ_CONTEXT,
    STEP_RESPOND,
    ExecutionTrailBuilder,
)
from kew_api.services.markdown_utils import split_front_matter

logger = logging.getLogger(__name__)

from kew_api.ai.intent_heuristics import classify_intent_heuristic


class ChatService:
    """Process chat messages: intent detection -> advisory or change plan."""

    def __init__(
        self,
        settings: ApiSettings,
        document_service: DocumentService,
        workspace_service: WorkspaceService,
    ) -> None:
        self._settings = settings
        self._documents = document_service
        self._workspace = workspace_service
        self._conversations = ConversationRepository(settings)
        self._plans = ChangePlanRepository(settings)
        self._section_context = SectionContextRepository(settings)

    def create_conversation(
        self,
        document_path: str | None = None,
        folder_path: str | None = None,
    ) -> Conversation:
        conversation = Conversation(
            id=str(uuid.uuid4()),
            document_path=document_path or folder_path,
        )
        return self._conversations.save(conversation)

    def resolve_conversation(
        self,
        *,
        scope_kind: str,
        scope_path: str,
        chat_mode: ChatMode,
    ) -> Conversation:
        """Return existing conversation for tab scope or create and index a new one."""
        existing = self._conversations.find_by_scope(scope_kind, scope_path)
        if existing is not None:
            if existing.chat_mode != chat_mode:
                existing = existing.model_copy(update={"chat_mode": chat_mode})
                return self._conversations.save(existing)
            return existing

        conversation = Conversation(
            id=str(uuid.uuid4()),
            scope_kind=scope_kind,  # type: ignore[arg-type]
            scope_path=scope_path,
            chat_mode=chat_mode,
            document_path=scope_path if scope_kind == "file" else scope_path or None,
        )
        return self._conversations.save(conversation)

    def clear_conversation(self, conversation_id: str) -> Conversation:
        conversation = self.get_conversation(conversation_id)
        cleared = conversation.model_copy(
            update={"messages": [], "updated_at": datetime.now(UTC)},
        )
        return self._conversations.save(cleared)

    def delete_conversation(self, conversation_id: str) -> None:
        self._conversations.delete(conversation_id)

    @staticmethod
    def _message_index(conversation: Conversation, message_id: str) -> int:
        for index, message in enumerate(conversation.messages):
            if message.id == message_id:
                return index
        raise NodeNotFoundError(message_id)

    def edit_user_message(
        self,
        conversation_id: str,
        message_id: str,
        content: str,
    ) -> Conversation:
        """Edit a user message and truncate all messages after it."""
        conversation = self.get_conversation(conversation_id)
        index = self._message_index(conversation, message_id)
        message = conversation.messages[index]
        if message.role != "user":
            raise InvalidChatOperationError("Only user messages can be edited")

        updated_message = message.model_copy(
            update={"content": content.strip(), "timestamp": datetime.now(UTC)},
        )
        truncated = conversation.messages[: index + 1]
        truncated[index] = updated_message
        updated = conversation.model_copy(
            update={"messages": truncated, "updated_at": datetime.now(UTC)},
        )
        return self._conversations.save(updated)

    def delete_from_message(self, conversation_id: str, message_id: str) -> Conversation:
        """Remove a message and all messages after it (branch reset)."""
        conversation = self.get_conversation(conversation_id)
        index = self._message_index(conversation, message_id)
        truncated = conversation.messages[:index]
        updated = conversation.model_copy(
            update={"messages": truncated, "updated_at": datetime.now(UTC)},
        )
        return self._conversations.save(updated)

    def get_conversation(self, conversation_id: str) -> Conversation:
        return self._conversations.get(conversation_id)

    async def iter_regenerate_events(
        self,
        conversation_id: str,
        message_id: str,
        *,
        document_path: str | None = None,
        folder_path: str | None = None,
        folder_plan: str | None = None,
        folder_contents: list[str] | None = None,
        chat_mode: ChatMode | None = None,
        selection: str | None = None,
        open_paths: list[str] | None = None,
        active_section: str | None = None,
        document_outline: list[str] | None = None,
        stream_text: bool = True,
    ) -> AsyncIterator[ChatStreamEvent]:
        conversation = self.get_conversation(conversation_id)
        index = self._message_index(conversation, message_id)
        message = conversation.messages[index]
        if message.role != "user":
            raise InvalidChatOperationError("Only user messages can be regenerated")

        async for event in self.iter_message_events(
            conversation_id,
            content=message.content,
            document_path=document_path,
            folder_path=folder_path,
            folder_plan=folder_plan,
            folder_contents=folder_contents,
            chat_mode=chat_mode,
            selection=selection,
            open_paths=open_paths,
            active_section=active_section,
            document_outline=document_outline,
            stream_text=stream_text,
            append_user_message=False,
        ):
            yield event

    async def send_message(
        self,
        conversation_id: str,
        *,
        content: str,
        document_path: str | None = None,
        folder_path: str | None = None,
        folder_plan: str | None = None,
        folder_contents: list[str] | None = None,
        chat_mode: ChatMode | None = None,
        selection: str | None = None,
        open_paths: list[str] | None = None,
        active_section: str | None = None,
        document_outline: list[str] | None = None,
    ) -> SendMessageResponse:
        result: SendMessageResponse | None = None
        async for event in self.iter_message_events(
            conversation_id,
            content=content,
            document_path=document_path,
            folder_path=folder_path,
            folder_plan=folder_plan,
            folder_contents=folder_contents,
            chat_mode=chat_mode,
            selection=selection,
            open_paths=open_paths,
            active_section=active_section,
            document_outline=document_outline,
            stream_text=False,
        ):
            if event.type == ChatStreamEventType.DONE and event.response:
                result = event.response
            if event.type == ChatStreamEventType.ERROR:
                raise AiRunnerError(event.message or "Chat failed")
        if result is None:
            raise AiRunnerError("Chat completed without a response")
        return result

    async def iter_message_events(
        self,
        conversation_id: str,
        *,
        content: str,
        document_path: str | None = None,
        folder_path: str | None = None,
        folder_plan: str | None = None,
        folder_contents: list[str] | None = None,
        chat_mode: ChatMode | None = None,
        selection: str | None = None,
        open_paths: list[str] | None = None,
        active_section: str | None = None,
        document_outline: list[str] | None = None,
        stream_text: bool = True,
        append_user_message: bool = True,
    ) -> AsyncIterator[ChatStreamEvent]:
        conversation = self.get_conversation(conversation_id)
        doc_path = document_path or (conversation.document_path if folder_path is None else None)
        if not doc_path and folder_path is not None and open_paths:
            for path in open_paths:
                if path.lower().endswith(".md"):
                    doc_path = path
                    break
        open_files = open_paths or ([doc_path] if doc_path else [])
        trail = ExecutionTrailBuilder()

        user_message: ChatMessageRecord | None = None
        active_chat_mode = chat_mode or conversation.chat_mode or ChatMode.AGENT
        if append_user_message:
            user_message = ChatMessageRecord(
                id=str(uuid.uuid4()),
                role="user",
                content=content,
                chat_mode=active_chat_mode,
            )
            conversation.messages.append(user_message)

        try:
            plan = trail.init_default_plan()
            yield ChatStreamEvent(type=ChatStreamEventType.EXECUTION_PLAN, steps=plan)
            yield ChatStreamEvent(
                type=ChatStreamEventType.STATUS,
                message="Execution plan ready — starting workflow…",
            )

            yield ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.start(
                    STEP_READ_CONTEXT,
                    detail="Loading open tabs and document context…",
                ),
            )
            base_context = self._build_context(
                doc_path,
                folder_path=folder_path,
                folder_plan=folder_plan,
                folder_contents=folder_contents or [],
                selection=selection,
                open_paths=open_files,
                active_section=active_section,
                document_outline=document_outline or [],
            )
            conversation_history = self._format_conversation_history(
                conversation,
                max_turns=20 if folder_path is not None else 12,
                max_chars_per_message=6000 if folder_path is not None else 2500,
            )
            intent_context = base_context
            if conversation_history:
                intent_context = f"{intent_context}\n\n## Conversation history\n{conversation_history}"
            workspace_detail = self._workspace_summary(
                doc_path,
                open_files,
                active_section,
                document_outline,
                folder_path=folder_path,
            )
            yield ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.complete(STEP_READ_CONTEXT, detail=workspace_detail),
            )

            folder_plan_scope = folder_path is not None and active_chat_mode == ChatMode.PLAN

            yield ChatStreamEvent(
                type=ChatStreamEventType.STATUS,
                message="Orchestrator: classifying your request…",
            )
            yield ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.start(
                    STEP_CLASSIFY_INTENT,
                    detail="Coordinator routing to the right workflow…",
                ),
            )
            intent = await self._detect_intent(
                content,
                intent_context,
                folder_plan_scope=folder_plan_scope,
            )
            requested_file_edit = intent.requires_change_plan
            if active_chat_mode == ChatMode.PLAN and folder_path is None:
                intent = intent.model_copy(
                    update={
                        "requires_change_plan": False,
                        "requires_folder_plan": False,
                        "rationale": f"{intent.rationale} (Plan mode: advisory only)",
                    }
                )
            elif active_chat_mode == ChatMode.PLAN and folder_path is not None:
                intent = intent.model_copy(update={"requires_change_plan": False})
            elif active_chat_mode == ChatMode.AGENT:
                intent = intent.model_copy(
                    update={
                        "requires_folder_plan": False,
                        "rationale": (
                            f"{intent.rationale} (Agent mode on folder scope)"
                            if not doc_path and folder_path is not None
                            else intent.rationale
                        ),
                    }
                )

            run_folder_plan = folder_plan_scope and intent.requires_folder_plan

            effective_folder_plan = (folder_plan or "").strip()
            if not effective_folder_plan and folder_path:
                section_ctx = self._section_context.get("folder", folder_path or "")
                if section_ctx and section_ctx.last_target_structure:
                    effective_folder_plan = (
                        f"# Target structure\n\n{section_ctx.last_target_structure.strip()}\n"
                    )

            run_folder_implement = (
                folder_path is not None
                and active_chat_mode == ChatMode.AGENT
                and bool(effective_folder_plan)
                and _requests_folder_implement(content)
            )
            cross_mode_context = self._build_cross_mode_context(
                conversation,
                chat_mode=active_chat_mode,
                include_plan_details=run_folder_plan or active_chat_mode == ChatMode.AGENT,
            )
            context = base_context
            if cross_mode_context:
                context = f"{context}\n\n{cross_mode_context}"
            if conversation_history:
                context = f"{context}\n\n## Conversation history\n{conversation_history}"
            intent_detail = (
                f"{intent.intent.value.replace('_', ' ')} "
                f"({int(intent.confidence * 100)}% confidence). {intent.rationale}"
            )
            yield ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.complete(
                    STEP_CLASSIFY_INTENT,
                    label="Classified user intent",
                    detail=intent_detail,
                ),
            )
            respond_step = trail.set_respond_step(
                agent=AgentName.EDITOR
                if run_folder_implement
                else AgentName.PLANNER
                if intent.requires_change_plan or run_folder_plan
                else AgentName.ADVISOR,
                label=(
                    "Implement planned folder structure"
                    if run_folder_implement
                    else "Multi-agent folder planning"
                    if run_folder_plan
                    else "Plan and draft document changes"
                    if intent.requires_change_plan
                    else "Draft advisory answer"
                ),
                detail=(
                    "Sync disk to Planned structure — create missing files, archive extras"
                    if run_folder_implement
                    else "Research → analyze → expert → synthesize"
                    if run_folder_plan
                    else "Planner and editor will propose an approval-gated change plan"
                    if intent.requires_change_plan
                    else "Advisor will answer using document context"
                ),
            )
            yield ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=respond_step)
            async for chunk in stream_text_chunks(intent_detail):
                yield ChatStreamEvent(
                    type=ChatStreamEventType.AGENT_THOUGHT,
                    agent=AgentName.ORCHESTRATOR,
                    content=chunk,
                )

            change_plan: ChangePlan | None = None
            folder_plan_result: FolderPlanResult | None = None
            folder_implement_result: FolderImplementResult | None = None
            plan_agent_inputs: FolderPlanAgentInputs | None = None
            assistant_content = ""

            if run_folder_implement:
                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.start(STEP_RESPOND, detail="Applying folder plan on disk…"),
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.STATUS,
                    message="Agent: implementing planned structure…",
                )
                folder_implement_result = apply_folder_plan(
                    folder_path=folder_path or "",
                    folder_plan=effective_folder_plan,
                    workspace=self._workspace,
                    settings=self._settings,
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.complete(
                        STEP_RESPOND,
                        label="Folder plan implemented",
                        detail=folder_implement_result.summary,
                        target_path=folder_path,
                    ),
                )
                assistant_content = format_folder_implement_message(folder_implement_result)

            elif run_folder_plan:
                queued_folder_events: list[ChatStreamEvent] = []

                def queue_folder_event(event: ChatStreamEvent) -> None:
                    queued_folder_events.append(event)

                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.start(STEP_RESPOND, detail="Starting folder planning pipeline…"),
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.STATUS,
                    message="Planner: researching topic, analyzing structure, drafting plan…",
                )

                disk_context, current_tree_text = self._build_folder_disk_context(folder_path)
                enriched_context = f"{context}\n\n{disk_context}"

                folder_plan_result, plan_agent_inputs = await run_folder_plan_pipeline(
                    user_message=content,
                    folder_path=folder_path,
                    workspace_context=enriched_context,
                    current_tree_text=current_tree_text,
                    existing_plan=folder_plan,
                    conversation_history=conversation_history,
                    settings=self._settings,
                    trail=trail,
                    queue_event=queue_folder_event,
                )
                for event in queued_folder_events:
                    yield event

                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.complete(
                        STEP_RESPOND,
                        label="Folder plan complete",
                        detail=folder_plan_result.summary,
                        target_path=folder_path,
                    ),
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.STATUS,
                    message="Planner: finalizing structure recommendation…",
                )
                thought = (
                    f"**{folder_plan_result.summary}**\n\n"
                    f"{folder_plan_result.explanation[:1200]}"
                )
                async for chunk in stream_text_chunks(thought):
                    yield ChatStreamEvent(
                        type=ChatStreamEventType.AGENT_THOUGHT,
                        agent=AgentName.PLANNER,
                        content=chunk,
                    )
                assistant_content = format_folder_plan_message(folder_plan_result)

            elif intent.requires_change_plan:
                queued_events: list[ChatStreamEvent] = []

                def queue_event(event: ChatStreamEvent) -> None:
                    queued_events.append(event)

                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.start(STEP_RESPOND, detail="Starting planner workflow…"),
                )
                assistant, change_plan, respond_detail = await self._handle_edit_intent(
                    doc_path=doc_path,
                    open_files=open_files,
                    content=content,
                    intent=intent,
                    context=context,
                    trail=trail,
                    active_section=active_section,
                    queue_event=queue_event,
                )
                for event in queued_events:
                    yield event

                if change_plan is not None:
                    yield ChatStreamEvent(
                        type=ChatStreamEventType.TRAIL_STEP,
                        step=trail.complete(
                            STEP_RESPOND,
                            label="Change plan ready for review",
                            detail=change_plan.summary,
                            target_path=change_plan.document_path,
                        ),
                    )
                    yield ChatStreamEvent(
                        type=ChatStreamEventType.STATUS,
                        message="Planner: sharing reasoning…",
                    )
                    thought = (
                        f"**Summary:** {change_plan.summary}\n\n"
                        f"{change_plan.explanation}"
                    )
                    async for chunk in stream_text_chunks(thought):
                        yield ChatStreamEvent(
                            type=ChatStreamEventType.AGENT_THOUGHT,
                            agent=AgentName.PLANNER,
                            content=chunk,
                        )
                elif respond_detail:
                    yield ChatStreamEvent(
                        type=ChatStreamEventType.TRAIL_STEP,
                        step=trail.fail(STEP_RESPOND, respond_detail),
                    )
                    blocked = trail.add(
                        agent=AgentName.EDITOR,
                        label="Change plan blocked",
                        detail=respond_detail,
                        status=AgentStepStatus.SKIPPED,
                    )
                    yield ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=blocked)

                assistant_content = normalize_markdown_text(assistant.content)
            else:
                yield ChatStreamEvent(
                    type=ChatStreamEventType.STATUS,
                    message="Advisor: drafting answer…",
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.start(STEP_RESPOND, detail="Generating response…"),
                )
                advisory, respond_detail, respond_label = await self._run_advisor(
                    content,
                    context,
                    intent,
                    folder_plan_scope=folder_plan_scope,
                    requested_file_edit=requested_file_edit,
                    active_chat_mode=active_chat_mode,
                    folder_path=folder_path,
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.complete(
                        STEP_RESPOND,
                        label=respond_label,
                        detail=respond_detail,
                    ),
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.STATUS,
                    message="Advisor: composing final answer…",
                )
                assistant_content = normalize_markdown_text(advisory.response)

            if stream_text and assistant_content:
                async for chunk in stream_text_chunks(assistant_content):
                    yield ChatStreamEvent(
                        type=ChatStreamEventType.ASSISTANT_DELTA,
                        content=chunk,
                    )
            elif not stream_text:
                yield ChatStreamEvent(
                    type=ChatStreamEventType.ASSISTANT_DELTA,
                    content=assistant_content,
                )

            assistant = ChatMessageRecord(
                id=str(uuid.uuid4()),
                role="assistant",
                content=assistant_content,
                chat_mode=active_chat_mode,
                intent=intent.intent,
                change_plan_id=change_plan.edit_id if change_plan else None,
                execution_trail=trail.steps,
            )

            conversation = conversation.model_copy(
                update={
                    "messages": conversation.messages,
                    "updated_at": datetime.now(UTC),
                    "chat_mode": active_chat_mode,
                    "document_path": doc_path or conversation.document_path,
                }
            )
            conversation.messages.append(assistant)
            self._conversations.save(conversation)
            self._record_section_lineage(
                conversation=conversation,
                chat_mode=active_chat_mode,
                assistant_content=assistant_content,
                folder_plan_result=folder_plan_result,
                folder_implement_result=folder_implement_result,
                change_plan=change_plan,
                agent_inputs=plan_agent_inputs if run_folder_plan else None,
            )

            response = SendMessageResponse(
                message=assistant,
                change_plan=change_plan,
                folder_plan_result=folder_plan_result,
                folder_implement_result=folder_implement_result,
                user_message=user_message,
            )
            yield ChatStreamEvent(type=ChatStreamEventType.DONE, response=response)

        except AiRunnerError as exc:
            if trail.active_step_id:
                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.fail(trail.active_step_id, str(exc)),
                )
            yield ChatStreamEvent(type=ChatStreamEventType.ERROR, message=str(exc))
        except Exception as exc:
            logger.exception("Chat stream failed")
            message = str(exc) if self._settings.expose_error_details else "Chat failed"
            if trail.active_step_id:
                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.fail(trail.active_step_id, message),
                )
            yield ChatStreamEvent(type=ChatStreamEventType.ERROR, message=message)

    async def _handle_edit_intent(
        self,
        *,
        doc_path: str | None,
        open_files: list[str],
        content: str,
        intent: IntentResult,
        context: str,
        trail: ExecutionTrailBuilder,
        active_section: str | None,
        queue_event: Callable[[ChatStreamEvent], None] | None = None,
    ) -> tuple[ChatMessageRecord, ChangePlan | None, str | None]:
        if not doc_path:
            detail = "No active document in the editor."
            return (
                ChatMessageRecord(
                    id=str(uuid.uuid4()),
                    role="assistant",
                    content="Open a Markdown document first so I can propose a change plan.",
                    intent=intent.intent,
                    execution_trail=trail.steps,
                ),
                None,
                detail,
            )

        if open_files and doc_path not in open_files:
            detail = f"{doc_path} is not in the open editor tabs."
            return (
                ChatMessageRecord(
                    id=str(uuid.uuid4()),
                    role="assistant",
                    content=(
                        "I can only propose edits for files that are **open in your editor tabs**. "
                        f"Open `{doc_path}` in a tab and try again."
                    ),
                    intent=intent.intent,
                    execution_trail=trail.steps,
                ),
                None,
                detail,
            )

        change_plan = await self._build_change_plan(
            doc_path=doc_path,
            user_prompt=content,
            intent=intent,
            context=context,
            active_section=active_section,
            trail=trail,
            queue_event=queue_event,
        )
        assistant = ChatMessageRecord(
            id=str(uuid.uuid4()),
            role="assistant",
            content=self._format_plan_message(change_plan),
            intent=intent.intent,
            change_plan_id=change_plan.edit_id,
            execution_trail=trail.steps,
        )
        return assistant, change_plan, None

    async def _detect_intent(
        self,
        content: str,
        context: str,
        *,
        folder_plan_scope: bool = False,
    ) -> IntentResult:
        if self._settings.ai_mock_mode:
            return classify_intent_heuristic(content, folder_plan_scope=folder_plan_scope)

        agent = build_orchestrator_agent(self._settings)
        scope_hint = ""
        if folder_plan_scope:
            scope_hint = (
                "\n\nScope: Plan mode on an active folder tab. "
                "Set requires_folder_plan=true only for explicit structure planning requests."
            )
        prompt = f"Document context:\n{context}{scope_hint}\n\nUser message:\n{content}"
        try:
            return await run_structured_agent(
                agent,
                user_message=prompt,
                output_key="intent_output",
                output_model=IntentResult,
                settings=self._settings,
                system_prompt=load_prompt("orchestrator"),
            )
        except AiRunnerError as exc:
            logger.warning("Orchestrator structured output failed, using heuristics: %s", exc)
            result = classify_intent_heuristic(content, folder_plan_scope=folder_plan_scope)
            result = result.model_copy(
                update={"rationale": f"{result.rationale} (LLM parse fallback: {exc})"}
            )
            return result

    async def _run_advisor(
        self,
        content: str,
        context: str,
        intent: IntentResult,
        *,
        folder_plan_scope: bool = False,
        requested_file_edit: bool = False,
        active_chat_mode: ChatMode | None = None,
        folder_path: str | None = None,
    ) -> tuple[AdvisorOutput, str, str]:
        if self._settings.ai_mock_mode:
            excerpt = self._mock_context_excerpt(context)
            if folder_plan_scope and not intent.requires_folder_plan:
                return (
                    AdvisorOutput(
                        response=(
                            f"Hello! I'm your planning assistant for this section"
                            f"{f' ({excerpt})' if excerpt else ''}. "
                            "Ask me to **design or reorganize** the folder structure when you're ready — "
                            "I'll put the full plan in **Planned structure** on the left. "
                            "For now, what would you like to explore?"
                        )
                    ),
                    "Conversational reply in Plan mode. No structure planning triggered.",
                    "Drafted advisory answer",
                )
            return (
                AdvisorOutput(
                    response=(
                        f"[Mock advisory] Intent={intent.intent.value}. "
                        f"Based on the active document"
                        f"{f' ({excerpt})' if excerpt else ''}, "
                        "here is a concise architecture-focused answer to your question. "
                        "Ask me to **add**, **expand**, or **rewrite** a section when you want "
                        "an approval-gated edit plan."
                    )
                ),
                "Answered using the active document context. No files were modified.",
                "Drafted advisory answer",
            )

        agent = build_advisor_agent(self._settings)
        plan_mode_guidance = ""
        if folder_plan_scope and not intent.requires_folder_plan:
            plan_mode_guidance = (
                "\n\nPlan mode guidance: respond conversationally. Do not propose folder structures, "
                "target trees, or reorganization lists unless the user explicitly asked for structure "
                "planning. Mention that structure plans appear in the section planner panel when relevant."
            )
        if requested_file_edit and active_chat_mode == ChatMode.PLAN and folder_path is None:
            plan_mode_guidance += (
                "\n\nThe user asked to modify the open document, but Plan mode is active. "
                "Explain that file edits require **Agent mode** (toggle at the top of chat). "
                "You can still advise on what to change, but no change plan will be generated."
            )
        prompt = (
            f"Document context:\n{context}\n\n"
            f"Classified intent: {intent.intent}\n\n"
            f"User message:\n{content}\n\n"
            "If shared section context includes a folder plan from Plan mode, "
            "explain how to implement it when the user asks for execution."
            f"{plan_mode_guidance}"
        )
        try:
            output = await run_structured_agent(
                agent,
                user_message=prompt,
                output_key="advisor_output",
                output_model=AdvisorOutput,
                settings=self._settings,
                system_prompt=load_prompt("advisor"),
            )
            return (
                output.model_copy(update={"response": normalize_markdown_text(output.response)}),
                "Answered using the active document and section context. No files were modified.",
                "Drafted advisory answer",
            )
        except AiRunnerError as exc:
            logger.warning("Advisor structured output failed, using plain text: %s", exc)
            from kew_api.ai.cursor_runner import run_cursor_text_agent
            from kew_api.ai.gemini_runner import run_gemini_structured_agent

            try:
                text = await run_cursor_text_agent(
                    system_prompt=(
                        f"{load_prompt('advisor')}\n\n"
                        "Respond in clear markdown for the user. "
                        "Do not wrap your answer in JSON or code fences."
                    ),
                    user_message=prompt,
                    settings=self._settings,
                )
            except AiRunnerError as text_exc:
                if self._settings._has_secret(self._settings.gemini_api_key):
                    output = await run_gemini_structured_agent(
                        agent,
                        user_message=prompt,
                        output_key="advisor_output",
                        output_model=AdvisorOutput,
                        settings=self._settings,
                    )
                    return (
                        output.model_copy(update={"response": normalize_markdown_text(output.response)}),
                        "Advisor fallback used Gemini after Cursor was unavailable.",
                        "Drafted advisory answer (Gemini fallback)",
                    )
                raise text_exc from exc
            return (
                AdvisorOutput(response=normalize_markdown_text(text)),
                f"Structured JSON was unavailable ({exc}); returned direct model text.",
                "Drafted advisory answer (plain text)",
            )

    async def _build_change_plan(
        self,
        *,
        doc_path: str,
        user_prompt: str,
        intent: IntentResult,
        context: str,
        active_section: str | None,
        trail: ExecutionTrailBuilder,
        queue_event: Callable[[ChatStreamEvent], None] | None = None,
    ) -> ChangePlan:
        def emit(event: ChatStreamEvent) -> None:
            if queue_event is not None:
                queue_event(event)

        load_step = trail.add(
            agent=AgentName.PLANNER,
            label="Load document snapshot",
            detail="Reading file from corpus",
            status=AgentStepStatus.PENDING,
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=trail.start(load_step.id)))

        document = self._documents.get_document(doc_path)
        _front, body = split_front_matter(document.content)
        line_count = len(body.splitlines())
        emit(
            ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.complete(
                    load_step.id,
                    detail=f"Loaded {doc_path} ({line_count} lines)",
                    target_path=doc_path,
                ),
            )
        )

        plan_step = trail.add(
            agent=AgentName.PLANNER,
            label="Plan document changes",
            detail="Calling editor model to draft updates",
            status=AgentStepStatus.PENDING,
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.STATUS, message="Planner: analyzing your edit request…"))
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=trail.start(plan_step.id)))

        prompt = (
            f"Document path: {doc_path}\n"
            f"Intent: {intent.intent}\n"
            f"Active section: {active_section or 'not specified'}\n"
            f"Current body:\n{body}\n\n"
            f"Additional context:\n{context}\n\n"
            f"User instruction:\n{user_prompt}"
        )
        editor_output, editor_mode = await run_editor_plan(
            user_message=prompt,
            current_body=body,
            settings=self._settings,
        )
        if editor_mode == "markdown_fallback":
            logger.info("Editor used markdown fallback for change plan on %s", doc_path)
        proposed_body = normalize_document_body(editor_output.proposed_body)

        emit(
            ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.complete(
                    plan_step.id,
                    label="Planned document changes",
                    detail=f"{editor_output.summary} (mode: {editor_mode})",
                ),
            )
        )

        diff_step = trail.add(
            agent=AgentName.EDITOR,
            label="Build line-level diff",
            detail="Computing connected change blocks",
            status=AgentStepStatus.PENDING,
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.STATUS, message="Editor: building change blocks…"))
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=trail.start(diff_step.id)))

        edit_id = str(uuid.uuid4())
        hunks = build_change_hunks(body, proposed_body)
        sections = build_section_changes(body, proposed_body)

        emit(
            ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.complete(
                    diff_step.id,
                    detail=f"{len(hunks)} change block(s) ready for per-line review",
                    target_path=doc_path,
                ),
            )
        )

        review_step = trail.add(
            agent=AgentName.EDITOR,
            label="Ready for your review",
            detail=(
                f"{editor_output.summary}. "
                f"{len(hunks)} change block(s) — accept each block or use Accept all."
            ),
            target_path=doc_path,
            status=AgentStepStatus.COMPLETED,
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=review_step))

        plan = ChangePlan(
            edit_id=edit_id,
            document_path=doc_path,
            base_checksum=document.checksum,
            base_body=body,
            intent=intent.intent,
            summary=editor_output.summary,
            explanation=editor_output.explanation,
            sections=sections,
            hunks=hunks,
            proposed_body=proposed_body,
            confidence=editor_output.confidence,
        )
        saved = self._plans.save(plan)
        return saved

    def get_change_plan(self, edit_id: str) -> ChangePlan:
        return self._plans.get(edit_id)

    def discard_change_plan(self, edit_id: str) -> ChangePlan:
        return self._plans.discard(edit_id)

    def apply_change_plan(
        self,
        edit_id: str,
        *,
        accepted_hunk_ids: list[str] | None = None,
    ) -> tuple[str, str]:
        plan = self._plans.get(edit_id)
        if plan.status != "pending":
            raise NodeConflictError(f"Change plan is not pending: {plan.status}")

        document = self._documents.get_document(plan.document_path)
        front, current_body = split_front_matter(document.content)
        base_body = plan.base_body or current_body

        if plan.hunks:
            if accepted_hunk_ids is None:
                accepted = {hunk.id for hunk in plan.hunks}
            elif not accepted_hunk_ids:
                raise NodeConflictError("No changes accepted for commit")
            else:
                accepted = set(accepted_hunk_ids)
            from kew_api.services.diff_service import apply_hunks

            new_body = apply_hunks(base_body, plan.hunks, accepted)
        elif plan.sections:
            if accepted_hunk_ids is None:
                accepted = {section.id for section in plan.sections}
            elif not accepted_hunk_ids:
                raise NodeConflictError("No changes accepted for commit")
            else:
                accepted = set(accepted_hunk_ids)
            new_body = apply_section_changes(
                base_body,
                plan.proposed_body,
                plan.sections,
                accepted,
            )
        else:
            new_body = plan.proposed_body

        from kew_api.services.markdown_utils import join_front_matter

        new_content = join_front_matter(front, new_body)
        result = self._documents.update_document(
            plan.document_path,
            new_content,
            expected_checksum=None,
        )
        self._plans.mark_applied(edit_id)
        disk_path = result.disk_path or ""
        logger.info(
            "Applied change plan %s to %s (checksum %s, disk=%s)",
            edit_id,
            plan.document_path,
            result.checksum,
            disk_path,
        )
        return result.checksum, disk_path

    def get_section_context(self, scope_kind: str, scope_path: str):
        return self._section_context.get_or_create(scope_kind, scope_path)

    def _record_section_lineage(
        self,
        *,
        conversation: Conversation,
        chat_mode: ChatMode | None,
        assistant_content: str,
        folder_plan_result: FolderPlanResult | None,
        folder_implement_result: FolderImplementResult | None,
        change_plan: ChangePlan | None,
        agent_inputs: FolderPlanAgentInputs | None = None,
    ) -> None:
        if conversation.scope_kind is None or conversation.scope_path is None:
            return
        mode = chat_mode or conversation.chat_mode or ChatMode.PLAN
        scope_kind = conversation.scope_kind
        scope_path = conversation.scope_path

        if folder_implement_result is not None:
            self._section_context.append_event(
                scope_kind=scope_kind,
                scope_path=scope_path,
                chat_mode=mode,
                event_type="folder_implement",
                agent=AgentName.EDITOR,
                summary=folder_implement_result.summary,
                detail=folder_implement_result.explanation[:2000],
            )
            return

        if folder_plan_result is not None:
            self._section_context.record_folder_plan(
                scope_kind=scope_kind,
                scope_path=scope_path,
                chat_mode=mode,
                result=folder_plan_result,
                agent_inputs=agent_inputs,
            )
            return

        if change_plan is not None:
            self._section_context.append_event(
                scope_kind=scope_kind,
                scope_path=scope_path,
                chat_mode=mode,
                event_type="change_plan",
                agent=AgentName.EDITOR,
                summary=change_plan.summary,
                detail=change_plan.explanation[:2000],
            )
            return

        summary_line = next(
            (line.strip().lstrip("#").strip() for line in assistant_content.splitlines() if line.strip()),
            "Assistant response",
        )
        self._section_context.append_event(
            scope_kind=scope_kind,
            scope_path=scope_path,
            chat_mode=mode,
            event_type="advisory",
            agent=AgentName.ADVISOR if mode == ChatMode.AGENT else AgentName.PLANNER,
            summary=summary_line[:500],
            detail=assistant_content[:2000],
        )

    def _build_cross_mode_context(
        self,
        conversation: Conversation,
        *,
        chat_mode: ChatMode | None,
        include_plan_details: bool = True,
    ) -> str:
        if conversation.scope_kind is None or conversation.scope_path is None:
            return ""

        scope_kind = conversation.scope_kind
        scope_path = conversation.scope_path
        current_mode = chat_mode or conversation.chat_mode or ChatMode.PLAN

        parts: list[str] = [
            "## Shared section context",
            f"Current mode: **{current_mode.value}**. "
            "Plan and Agent share this chat thread — prior messages from both modes are in conversation history.",
            "Plan mode designs structure; Agent mode implements it on disk.",
        ]

        section = self._section_context.get(scope_kind, scope_path)
        if section and include_plan_details:
            if section.last_plan_summary:
                parts.append(f"### Last folder plan\n{section.last_plan_summary}")
            if section.last_target_structure:
                parts.append(
                    f"### Target structure\n```\n{section.last_target_structure.strip()}\n```"
                )
            if section.lineage:
                parts.append("### Recent lineage")
                for event in section.lineage[-8:]:
                    parts.append(
                        f"- [{event.chat_mode.value}] {event.event_type}: {event.summary}"
                    )
        elif section and section.last_plan_summary:
            parts.append(
                "### Note\nA folder plan exists for this section (see Planned structure panel). "
                "Reference it only if the user asks about structure or implementation."
            )

        if current_mode == ChatMode.AGENT:
            parts.append(
                "### Agent mode directive\n"
                "Implement recommendations from Plan mode: apply reorganization items, "
                "create missing files/folders, and edit open documents when the user requests execution."
            )

        return "\n\n".join(parts)

    def _build_folder_disk_context(self, folder_path: str) -> tuple[str, str]:
        """Load recursive tree, sibling patterns, parent README, and file samples."""
        try:
            tree_response = self._workspace.list_tree(folder_path, depth=6)
        except NodeNotFoundError:
            return "Folder not found on disk.", "(missing)"

        tree_lines = render_tree_text(tree_response.nodes)
        current_tree_text = "\n".join(tree_lines) if tree_lines else "(empty)"

        samples: list[str] = []
        self._collect_file_samples(tree_response.nodes, samples, limit=48)
        sample_block = "\n".join(samples) if samples else "(no markdown files)"
        disk_context = (
            f"On-disk tree (depth 6):\n{current_tree_text}\n\n"
            f"Sample files in section (title, status, excerpt):\n{sample_block}"
        )

        sibling_context = self._build_sibling_reference_context(folder_path)
        if sibling_context:
            disk_context = f"{disk_context}\n\n{sibling_context}"

        parent_readme = self._load_parent_readme_excerpt(folder_path)
        if parent_readme:
            disk_context = f"{disk_context}\n\n## Parent section README excerpt\n{parent_readme}"

        return disk_context, current_tree_text

    def _build_sibling_reference_context(self, folder_path: str) -> str:
        if not folder_path or "/" not in folder_path:
            return ""
        parent = folder_path.rsplit("/", 1)[0]
        try:
            tree_response = self._workspace.list_tree(parent, depth=1)
        except NodeNotFoundError:
            return ""

        parts = ["## Corpus reference patterns (sibling sections)"]
        for node in tree_response.nodes:
            if node.type != "folder" or node.path == folder_path:
                continue
            try:
                sub = self._workspace.list_tree(node.path, depth=2)
                lines = render_tree_text(sub.nodes)
                tree_preview = "\n".join(lines[:30]) if lines else "(empty)"
                parts.append(f"### {node.name}\n```\n{tree_preview}\n```")
            except NodeNotFoundError:
                continue
        return "\n\n".join(parts) if len(parts) > 1 else ""

    def _load_parent_readme_excerpt(self, folder_path: str) -> str:
        if not folder_path or "/" not in folder_path:
            return ""
        parent = folder_path.rsplit("/", 1)[0]
        readme_path = f"{parent}/README.md"
        try:
            document = self._documents.get_document(readme_path)
            _front, body = split_front_matter(document.content)
            return body[:3000].strip()
        except NodeNotFoundError:
            return ""

    @staticmethod
    def _format_conversation_history(
        conversation: Conversation,
        *,
        max_turns: int = 12,
        max_chars_per_message: int = 2500,
    ) -> str:
        """Format prior turns so follow-up recommendations are not lost."""
        lines: list[str] = []
        for message in conversation.messages[:-1]:
            role = "User" if message.role == "user" else "Assistant"
            mode_suffix = f" [{message.chat_mode.value}]" if message.chat_mode else ""
            text = message.content.strip()
            if not text:
                continue
            if len(text) > max_chars_per_message:
                text = f"{text[:max_chars_per_message]}…"
            lines.append(f"{role}{mode_suffix}: {text}")
        return "\n\n".join(lines[-max_turns:])

    def _collect_file_samples(
        self,
        nodes: list,
        samples: list[str],
        *,
        limit: int,
    ) -> None:
        if len(samples) >= limit:
            return
        for node in nodes:
            if len(samples) >= limit:
                return
            if node.type == "file" and node.path.lower().endswith(".md"):
                try:
                    document = self._documents.get_document(node.path)
                    _front, body = split_front_matter(document.content)
                    title_line = next(
                        (line.strip() for line in body.splitlines() if line.strip().startswith("#")),
                        node.name,
                    )
                    status = "unknown"
                    for line in document.content.splitlines()[:12]:
                        if line.strip().startswith("status:"):
                            status = line.split(":", 1)[1].strip()
                            break
                    excerpt = " ".join(
                        line.strip()
                        for line in body.splitlines()
                        if line.strip() and not line.strip().startswith("#")
                    )[:240]
                    samples.append(
                        f"- {node.path} | {title_line} | status={status}\n  excerpt: {excerpt}"
                    )
                except NodeNotFoundError:
                    samples.append(f"- {node.path} | (unreadable)")
            if node.children:
                self._collect_file_samples(node.children, samples, limit=limit)

    def _build_context(
        self,
        document_path: str | None,
        *,
        folder_path: str | None = None,
        folder_plan: str | None = None,
        folder_contents: list[str],
        selection: str | None,
        open_paths: list[str],
        active_section: str | None,
        document_outline: list[str],
    ) -> str:
        parts: list[str] = []

        if folder_path is not None:
            label = folder_path or "(docs root)"
            parts.append(f"Active folder / section: {label}")
            if folder_contents:
                parts.append("Folder contents on disk:")
                for entry in folder_contents[:80]:
                    parts.append(f"- {entry}")
            if folder_plan and folder_plan.strip():
                parts.append(f"User's planned folder structure:\n{folder_plan.strip()[:8000]}")

        if open_paths:
            parts.append("Open editor tabs (only these files may be edited):")
            for path in open_paths:
                marker = " (active)" if path == document_path else ""
                parts.append(f"- {path}{marker}")
        else:
            parts.append("Open editor tabs: none")

        if active_section:
            parts.append(f"Active section / topic: {active_section}")

        if document_outline:
            parts.append("Document outline (headings):")
            for heading in document_outline[:40]:
                parts.append(f"- {heading}")

        if not document_path:
            if folder_path is None:
                parts.append("No document is currently active in the editor.")
            return "\n\n".join(parts)

        try:
            document = self._documents.get_document(document_path)
        except NodeNotFoundError:
            parts.append(f"Active document not found: {document_path}")
            return "\n".join(parts)

        _front, body = split_front_matter(document.content)
        preview = body[:6000]
        parts.append(f"Active document path: {document_path}")
        parts.append(f"Active document body preview:\n{preview}")
        if selection:
            parts.append(f"User selection in editor:\n{selection}")
        return "\n\n".join(parts)

    @staticmethod
    def _workspace_summary(
        doc_path: str | None,
        open_paths: list[str],
        active_section: str | None,
        document_outline: list[str] | None,
        folder_path: str | None = None,
    ) -> str:
        open_count = len(open_paths)
        section = active_section or "not specified"
        active = doc_path or "none"
        folder = folder_path if folder_path is not None else "none"
        if folder == "":
            folder = "(docs root)"
        outline_count = len(document_outline or [])
        return (
            f"Active file: {active}. Active folder: {folder}. Open tabs: {open_count}. "
            f"Section: {section}. Outline headings: {outline_count}."
        )

    @staticmethod
    def _mock_context_excerpt(context: str) -> str:
        for line in context.splitlines():
            stripped = line.strip()
            if stripped.startswith("Active document path:"):
                return stripped.removeprefix("Active document path:").strip()
        return ""

    @staticmethod
    def _format_plan_message(plan: ChangePlan) -> str:
        return (
            f"I prepared a change plan: **{plan.summary}**\n\n"
            f"{plan.explanation}\n\n"
            f"Review the diff and approve or reject before anything is written to disk."
        )
