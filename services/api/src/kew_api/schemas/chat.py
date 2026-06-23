"""Chat and document change plan schemas."""

from __future__ import annotations

from datetime import UTC, datetime
from enum import StrEnum
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


class ChatIntent(StrEnum):
    ADVISE = "advise"
    SUGGEST = "suggest"
    GENERATE_SECTION = "generate_section"
    EXPAND = "expand"
    IMPROVE = "improve"


class AgentName(StrEnum):
    ORCHESTRATOR = "orchestrator"
    PLANNER = "planner"
    ADVISOR = "advisor"
    EDITOR = "editor"


class AgentStepStatus(StrEnum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    SKIPPED = "skipped"
    FAILED = "failed"


class IntentResult(BaseModel):
    intent: ChatIntent
    confidence: float = Field(ge=0.0, le=1.0)
    rationale: str
    requires_change_plan: bool

    @field_validator("intent", mode="before")
    @classmethod
    def normalize_intent(cls, value: object) -> object:
        if isinstance(value, str):
            return value.lower().strip()
        return value


class AdvisorOutput(BaseModel):
    response: str = Field(min_length=1)

    @model_validator(mode="before")
    @classmethod
    def coerce_response(cls, data: object) -> object:
        if isinstance(data, str) and data.strip():
            return {"response": data.strip()}
        if isinstance(data, dict):
            for key in ("response", "answer", "content", "message", "text", "reply"):
                value = data.get(key)
                if isinstance(value, str) and value.strip():
                    return {"response": value.strip()}
        return data


class EditorPlanOutput(BaseModel):
    summary: str = Field(min_length=1)
    explanation: str = Field(min_length=1)
    proposed_body: str = Field(description="Full markdown body after the proposed change")
    confidence: float = Field(ge=0.0, le=1.0, default=0.8)

    @model_validator(mode="before")
    @classmethod
    def coerce_editor_fields(cls, data: object) -> object:
        if isinstance(data, str) and data.strip():
            body = data.strip()
            first_line = next((line.lstrip("#").strip() for line in body.splitlines() if line.strip()), "")
            return {
                "summary": first_line[:160] if first_line else "Document update",
                "explanation": "Inferred from markdown body in model output.",
                "proposed_body": body,
            }
        if not isinstance(data, dict):
            return data
        merged = dict(data)
        if "summary" not in merged:
            for key in ("title", "headline"):
                if key in merged:
                    merged["summary"] = merged[key]
                    break
        if "explanation" not in merged:
            for key in ("detail", "rationale", "description"):
                if key in merged:
                    merged["explanation"] = merged[key]
                    break
        if "proposed_body" not in merged:
            for key in ("proposedBody", "body", "markdown", "content"):
                if key in merged and isinstance(merged[key], str):
                    merged["proposed_body"] = merged[key]
                    break
        return merged


class AgentExecutionStep(BaseModel):
    id: str
    agent: AgentName
    label: str
    status: AgentStepStatus = AgentStepStatus.COMPLETED
    detail: str = ""
    target_path: str | None = None
    timestamp: datetime = Field(default_factory=lambda: datetime.now(UTC))


class SectionChange(BaseModel):
    id: str
    change_type: Literal["new", "modified", "deleted"]
    section_title: str
    section_path: str = Field(description="Hierarchical path, e.g. Overview/Benefits")
    heading_level: int = Field(ge=0, le=6, default=0)
    original: str = ""
    proposed: str = ""
    start_line: int = Field(ge=1)


class ChangePlanHunk(BaseModel):
    id: str
    type: Literal["insert", "replace", "delete"]
    start_line: int = Field(ge=1)
    end_line: int = Field(ge=1)
    original: str = ""
    proposed: str = ""


class ChangePlan(BaseModel):
    edit_id: str
    document_path: str
    base_checksum: str
    base_body: str = ""
    intent: ChatIntent
    summary: str
    explanation: str
    sections: list[SectionChange] = Field(default_factory=list)
    hunks: list[ChangePlanHunk] = Field(default_factory=list)
    proposed_body: str
    confidence: float
    status: Literal["pending", "applied", "discarded"] = "pending"
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class ChatMessageRecord(BaseModel):
    id: str
    role: Literal["user", "assistant"]
    content: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(UTC))
    intent: ChatIntent | None = None
    change_plan_id: str | None = None
    execution_trail: list[AgentExecutionStep] = Field(default_factory=list)


class Conversation(BaseModel):
    id: str
    document_path: str | None = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    messages: list[ChatMessageRecord] = Field(default_factory=list)


class CreateConversationRequest(BaseModel):
    document_path: str | None = None


class SendMessageRequest(BaseModel):
    content: str = Field(min_length=1, max_length=8000)
    document_path: str | None = None
    selection: str | None = Field(default=None, max_length=4000)
    open_paths: list[str] = Field(default_factory=list)
    active_section: str | None = Field(default=None, max_length=500)
    document_outline: list[str] = Field(default_factory=list)


class SendMessageResponse(BaseModel):
    message: ChatMessageRecord
    change_plan: ChangePlan | None = None
    user_message: ChatMessageRecord | None = None


class ChatStreamEventType(StrEnum):
    STATUS = "status"
    EXECUTION_PLAN = "execution_plan"
    TRAIL_STEP = "trail_step"
    AGENT_THOUGHT = "agent_thought"
    ASSISTANT_DELTA = "assistant_delta"
    DONE = "done"
    ERROR = "error"


class ChatStreamEvent(BaseModel):
    type: ChatStreamEventType
    message: str | None = None
    agent: AgentName | None = None
    step: AgentExecutionStep | None = None
    steps: list[AgentExecutionStep] | None = None
    content: str | None = None
    response: SendMessageResponse | None = None


class ApplyChangePlanRequest(BaseModel):
    accepted_hunk_ids: list[str] | None = Field(
        default=None,
        description="If omitted, all hunks are accepted",
    )


class ApplyChangePlanResponse(BaseModel):
    edit_id: str
    document_path: str
    checksum: str
    applied: bool
    disk_path: str | None = Field(
        default=None,
        description="Absolute filesystem path where the document was written",
    )
