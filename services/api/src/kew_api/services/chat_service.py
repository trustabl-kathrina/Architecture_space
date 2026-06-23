"""AI chat orchestration and change plan generation."""

from __future__ import annotations

import logging
import uuid
from collections.abc import AsyncIterator, Callable
from datetime import UTC, datetime

from kew_api.ai.agents import build_advisor_agent, build_orchestrator_agent
from kew_api.ai.editor_runner import run_editor_plan
from kew_api.ai.errors import AiRunnerError
from kew_api.ai.prompts import load_prompt
from kew_api.ai.runner import run_structured_agent
from kew_api.config.settings import ApiSettings
from kew_api.exceptions import NodeConflictError, NodeNotFoundError
from kew_api.schemas.chat import (
    AdvisorOutput,
    AgentName,
    AgentStepStatus,
    ChangePlan,
    ChatIntent,
    ChatMessageRecord,
    ChatStreamEvent,
    ChatStreamEventType,
    Conversation,
    IntentResult,
    SendMessageResponse,
)
from kew_api.services.markdown_normalize import normalize_document_body, normalize_markdown_text
from kew_api.services.chat_repository import ChangePlanRepository, ConversationRepository
from kew_api.services.chat_streaming import stream_text_chunks
from kew_api.services.diff_service import build_change_hunks
from kew_api.services.section_diff import apply_section_changes, build_section_changes
from kew_api.services.document_service import DocumentService
from kew_api.services.execution_trail import (
    STEP_CLASSIFY_INTENT,
    STEP_READ_CONTEXT,
    ExecutionTrailBuilder,
)
from kew_api.services.markdown_utils import split_front_matter

logger = logging.getLogger(__name__)

from kew_api.ai.intent_heuristics import EDIT_HINTS, classify_intent_heuristic


class ChatService:
    """Process chat messages: intent detection -> advisory or change plan."""

    def __init__(
        self,
        settings: ApiSettings,
        document_service: DocumentService,
    ) -> None:
        self._settings = settings
        self._documents = document_service
        self._conversations = ConversationRepository(settings)
        self._plans = ChangePlanRepository(settings)

    def create_conversation(self, document_path: str | None = None) -> Conversation:
        conversation = Conversation(
            id=str(uuid.uuid4()),
            document_path=document_path,
        )
        return self._conversations.save(conversation)

    def get_conversation(self, conversation_id: str) -> Conversation:
        return self._conversations.get(conversation_id)

    async def send_message(
        self,
        conversation_id: str,
        *,
        content: str,
        document_path: str | None = None,
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
        selection: str | None = None,
        open_paths: list[str] | None = None,
        active_section: str | None = None,
        document_outline: list[str] | None = None,
        stream_text: bool = True,
    ) -> AsyncIterator[ChatStreamEvent]:
        conversation = self.get_conversation(conversation_id)
        doc_path = document_path or conversation.document_path
        open_files = open_paths or ([doc_path] if doc_path else [])
        trail = ExecutionTrailBuilder()

        user_message = ChatMessageRecord(
            id=str(uuid.uuid4()),
            role="user",
            content=content,
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
            context = self._build_context(
                doc_path,
                selection=selection,
                open_paths=open_files,
                active_section=active_section,
                document_outline=document_outline or [],
            )
            workspace_detail = self._workspace_summary(
                doc_path, open_files, active_section, document_outline
            )
            yield ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.complete(STEP_READ_CONTEXT, detail=workspace_detail),
            )

            yield ChatStreamEvent(
                type=ChatStreamEventType.STATUS,
                message="Orchestrator: classifying your request…",
            )
            yield ChatStreamEvent(
                type=ChatStreamEventType.TRAIL_STEP,
                step=trail.start(STEP_CLASSIFY_INTENT, detail="Routing to advisor or editor…"),
            )
            intent = await self._detect_intent(content, context)
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
            async for chunk in stream_text_chunks(intent_detail):
                yield ChatStreamEvent(
                    type=ChatStreamEventType.AGENT_THOUGHT,
                    agent=AgentName.ORCHESTRATOR,
                    content=chunk,
                )

            change_plan: ChangePlan | None = None
            assistant_content = ""

            if intent.requires_change_plan:
                queued_events: list[ChatStreamEvent] = []

                def queue_event(event: ChatStreamEvent) -> None:
                    queued_events.append(event)

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
                    blocked = trail.add(
                        agent=AgentName.EDITOR,
                        label="Change plan blocked",
                        detail=respond_detail,
                        status=AgentStepStatus.SKIPPED,
                    )
                    yield ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=blocked)

                assistant_content = normalize_markdown_text(assistant.content)
            else:
                advisor_step = trail.add(
                    agent=AgentName.ADVISOR,
                    label="Draft advisory answer",
                    detail="Advisor will answer using document context",
                    status=AgentStepStatus.PENDING,
                )
                yield ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=advisor_step)
                yield ChatStreamEvent(
                    type=ChatStreamEventType.STATUS,
                    message="Advisor: drafting answer…",
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.start(advisor_step.id, detail="Generating response…"),
                )
                advisory, respond_detail, respond_label = await self._run_advisor(
                    content, context, intent
                )
                yield ChatStreamEvent(
                    type=ChatStreamEventType.TRAIL_STEP,
                    step=trail.complete(
                        advisor_step.id,
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
                intent=intent.intent,
                change_plan_id=change_plan.edit_id if change_plan else None,
                execution_trail=trail.steps,
            )

            conversation.messages.append(assistant)
            conversation.updated_at = datetime.now(UTC)
            if doc_path:
                conversation.document_path = doc_path
            self._conversations.save(conversation)

            response = SendMessageResponse(
                message=assistant,
                change_plan=change_plan,
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
    ) -> IntentResult:
        if self._settings.ai_mock_mode:
            lowered = content.lower()
            if any(hint in lowered for hint in EDIT_HINTS):
                result = IntentResult(
                    intent=ChatIntent.EXPAND,
                    confidence=0.9,
                    rationale="Mock: explicit edit request detected",
                    requires_change_plan=True,
                )
            else:
                result = IntentResult(
                    intent=ChatIntent.ADVISE,
                    confidence=0.9,
                    rationale="Mock: advisory question",
                    requires_change_plan=False,
                )
            return result

        agent = build_orchestrator_agent(self._settings)
        prompt = f"Document context:\n{context}\n\nUser message:\n{content}"
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
            result = classify_intent_heuristic(content)
            result = result.model_copy(
                update={"rationale": f"{result.rationale} (LLM parse fallback: {exc})"}
            )
            return result

    async def _run_advisor(
        self,
        content: str,
        context: str,
        intent: IntentResult,
    ) -> tuple[AdvisorOutput, str, str]:
        if self._settings.ai_mock_mode:
            return (
                AdvisorOutput(
                    response=(
                        f"[Mock advisory] Intent={intent.intent}. "
                        "Based on the current document, focus on clarifying architecture "
                        "decisions and adding measurable outcomes."
                    )
                ),
                "Answered using the active document context. No files were modified.",
                "Drafted advisory answer",
            )

        agent = build_advisor_agent(self._settings)
        prompt = (
            f"Document context:\n{context}\n\n"
            f"Classified intent: {intent.intent}\n\n"
            f"User message:\n{content}"
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

            text = await run_cursor_text_agent(
                system_prompt=(
                    f"{load_prompt('advisor')}\n\n"
                    "Respond in clear markdown for the user. "
                    "Do not wrap your answer in JSON or code fences."
                ),
                user_message=prompt,
                settings=self._settings,
            )
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

    def _build_context(
        self,
        document_path: str | None,
        *,
        selection: str | None,
        open_paths: list[str],
        active_section: str | None,
        document_outline: list[str],
    ) -> str:
        parts: list[str] = []

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
            parts.append("No document is currently active in the editor.")
            return "\n".join(parts)

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
    ) -> str:
        open_count = len(open_paths)
        section = active_section or "not specified"
        active = doc_path or "none"
        outline_count = len(document_outline or [])
        return (
            f"Active file: {active}. Open tabs: {open_count}. "
            f"Section: {section}. Outline headings: {outline_count}."
        )

    @staticmethod
    def _format_plan_message(plan: ChangePlan) -> str:
        return (
            f"I prepared a change plan: **{plan.summary}**\n\n"
            f"{plan.explanation}\n\n"
            f"Review the diff and approve or reject before anything is written to disk."
        )
