"""Build agent execution trails for chat responses."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from kew_api.schemas.chat import AgentExecutionStep, AgentName, AgentStepStatus

STEP_READ_CONTEXT = "read_context"
STEP_CLASSIFY_INTENT = "classify_intent"
STEP_RESPOND = "respond"


class ExecutionTrailBuilder:
    """Tracks a planned multi-agent workflow with live status updates."""

    def __init__(self) -> None:
        self._steps: dict[str, AgentExecutionStep] = {}
        self._order: list[str] = []
        self._active_step_id: str | None = None

    @property
    def active_step_id(self) -> str | None:
        return self._active_step_id

    @property
    def steps(self) -> list[AgentExecutionStep]:
        return [self._steps[step_id] for step_id in self._order if step_id in self._steps]

    def init_default_plan(self) -> list[AgentExecutionStep]:
        """Create the orchestrator workflow plan (routing steps only)."""
        planned = [
            self._make_step(
                STEP_READ_CONTEXT,
                agent=AgentName.ORCHESTRATOR,
                label="Read workspace context",
                status=AgentStepStatus.PENDING,
                detail="Load open tabs, active section, and document preview",
            ),
            self._make_step(
                STEP_CLASSIFY_INTENT,
                agent=AgentName.ORCHESTRATOR,
                label="Classify user intent",
                status=AgentStepStatus.PENDING,
                detail="Decide: advisory answer or document edit",
            ),
        ]
        self._steps.clear()
        self._order.clear()
        for step in planned:
            self._steps[step.id] = step
            self._order.append(step.id)
        return self.steps

    def set_respond_step(
        self,
        *,
        agent: AgentName,
        label: str,
        detail: str,
    ) -> AgentExecutionStep:
        """Update the final step once intent routing is known."""
        return self._replace(
            STEP_RESPOND,
            agent=agent,
            label=label,
            detail=detail,
            status=AgentStepStatus.PENDING,
        )

    def start(self, step_id: str, *, detail: str | None = None) -> AgentExecutionStep:
        self._active_step_id = step_id
        updates: dict[str, object] = {
            "status": AgentStepStatus.RUNNING,
            "timestamp": datetime.now(UTC),
        }
        if detail is not None:
            updates["detail"] = detail
        return self._replace(step_id, **updates)

    def complete(
        self,
        step_id: str,
        *,
        label: str | None = None,
        detail: str | None = None,
        target_path: str | None = None,
        status: AgentStepStatus = AgentStepStatus.COMPLETED,
    ) -> AgentExecutionStep:
        if self._active_step_id == step_id:
            self._active_step_id = None
        updates: dict[str, object] = {
            "status": status,
            "timestamp": datetime.now(UTC),
        }
        if label is not None:
            updates["label"] = label
        if detail is not None:
            updates["detail"] = detail
        if target_path is not None:
            updates["target_path"] = target_path
        return self._replace(step_id, **updates)

    def fail(self, step_id: str, detail: str) -> AgentExecutionStep:
        return self.complete(
            step_id,
            detail=detail,
            status=AgentStepStatus.FAILED,
        )

    def add(
        self,
        *,
        agent: AgentName,
        label: str,
        detail: str = "",
        target_path: str | None = None,
        status: AgentStepStatus = AgentStepStatus.COMPLETED,
    ) -> AgentExecutionStep:
        """Append an extra step (e.g. blocked edit) after the planned workflow."""
        step_id = str(uuid.uuid4())
        step = self._make_step(
            step_id,
            agent=agent,
            label=label,
            status=status,
            detail=detail,
            target_path=target_path,
        )
        self._steps[step_id] = step
        self._order.append(step_id)
        return step

    def update_running_detail(self, step_id: str, detail: str) -> AgentExecutionStep:
        """Append live progress to a running step without changing status."""
        current = self._steps[step_id]
        merged = current.detail
        if merged and not merged.endswith(detail):
            merged = f"{merged}\n{detail}"
        else:
            merged = detail
        return self._replace(step_id, detail=merged)

    def get(self, step_id: str) -> AgentExecutionStep:
        return self._steps[step_id]

    def _replace(self, step_id: str, **updates: object) -> AgentExecutionStep:
        current = self._steps[step_id]
        updated = current.model_copy(update=updates)
        self._steps[step_id] = updated
        return updated

    @staticmethod
    def _make_step(
        step_id: str,
        *,
        agent: AgentName,
        label: str,
        status: AgentStepStatus,
        detail: str = "",
        target_path: str | None = None,
    ) -> AgentExecutionStep:
        return AgentExecutionStep(
            id=step_id,
            agent=agent,
            label=label,
            status=status,
            detail=detail,
            target_path=target_path,
            timestamp=datetime.now(UTC),
        )
