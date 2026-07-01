"""Persist shared Plan ↔ Agent lineage per file/folder scope."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from kew_api.config.settings import ApiSettings
from kew_api.schemas.chat import AgentName, ChatMode, FolderPlanResult
from kew_api.schemas.section_context import FolderPlanAgentInputs, SectionContext, SectionLineageEvent
from kew_api.services.chat_repository import JsonStore


def section_context_key(scope_kind: str, scope_path: str) -> str:
    """Logical scope key (may contain slashes)."""
    return f"{scope_kind}:{scope_path}"


def section_context_storage_name(scope_kind: str, scope_path: str) -> str:
    """Filesystem-safe storage id for nested folder paths."""
    safe_path = scope_path.replace("/", "__").strip("_") if scope_path else "_root"
    return f"{scope_kind}__{safe_path}"


class SectionContextRepository:
    def __init__(self, settings: ApiSettings) -> None:
        root = settings.resolved_data_root / "section_context"
        self._store = JsonStore(root)

    def get(self, scope_kind: str, scope_path: str) -> SectionContext | None:
        storage_name = section_context_storage_name(scope_kind, scope_path)
        try:
            return self._store.read(storage_name, SectionContext)
        except Exception:
            return None

    def save(self, context: SectionContext) -> SectionContext:
        storage_name = section_context_storage_name(context.scope_kind, context.scope_path)
        updated = context.model_copy(update={"updated_at": datetime.now(UTC)})
        self._store.write(storage_name, updated)
        return updated

    def get_or_create(self, scope_kind: str, scope_path: str) -> SectionContext:
        existing = self.get(scope_kind, scope_path)
        if existing is not None:
            return existing
        return SectionContext(scope_kind=scope_kind, scope_path=scope_path)  # type: ignore[arg-type]

    def append_event(
        self,
        *,
        scope_kind: str,
        scope_path: str,
        chat_mode: ChatMode,
        event_type: str,
        summary: str,
        detail: str = "",
        agent: AgentName | None = None,
    ) -> SectionContext:
        context = self.get_or_create(scope_kind, scope_path)
        event = SectionLineageEvent(
            id=str(uuid.uuid4()),
            chat_mode=chat_mode,
            event_type=event_type,  # type: ignore[arg-type]
            agent=agent,
            summary=summary[:500],
            detail=detail[:4000],
        )
        lineage = [*context.lineage, event][-40:]
        return self.save(context.model_copy(update={"lineage": lineage}))

    def record_folder_plan(
        self,
        *,
        scope_kind: str,
        scope_path: str,
        chat_mode: ChatMode,
        result: FolderPlanResult,
        agent_inputs: FolderPlanAgentInputs | None = None,
    ) -> SectionContext:
        context = self.get_or_create(scope_kind, scope_path)
        event = SectionLineageEvent(
            id=str(uuid.uuid4()),
            chat_mode=chat_mode,
            event_type="folder_plan",
            agent=AgentName.PLANNER,
            summary=result.summary,
            detail=result.explanation[:2000],
        )
        lineage = [*context.lineage, event][-40:]
        return self.save(
            context.model_copy(
                update={
                    "last_plan_summary": result.summary,
                    "last_plan_explanation": result.explanation[:8000],
                    "last_target_structure": result.target_structure[:12000],
                    "last_agent_inputs": agent_inputs,
                    "lineage": lineage,
                }
            )
        )
