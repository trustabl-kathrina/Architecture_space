"""Tests for execution trail planning."""

from __future__ import annotations

from kew_api.schemas.chat import AgentName, AgentStepStatus
from kew_api.services.execution_trail import (
    STEP_CLASSIFY_INTENT,
    STEP_READ_CONTEXT,
    ExecutionTrailBuilder,
)


def test_default_plan_has_orchestrator_steps() -> None:
    trail = ExecutionTrailBuilder()
    steps = trail.init_default_plan()
    assert len(steps) == 3
    assert all(step.status is AgentStepStatus.PENDING for step in steps)
    assert steps[0].id == STEP_READ_CONTEXT
    assert steps[1].id == STEP_CLASSIFY_INTENT


def test_plan_step_lifecycle_and_agent_handoff() -> None:
    trail = ExecutionTrailBuilder()
    trail.init_default_plan()

    running = trail.start(STEP_READ_CONTEXT, detail="loading")
    assert running.status is AgentStepStatus.RUNNING
    assert trail.active_step_id == STEP_READ_CONTEXT

    done = trail.complete(STEP_READ_CONTEXT, detail="loaded")
    assert done.status is AgentStepStatus.COMPLETED
    assert trail.active_step_id is None

    planner = trail.add(
        agent=AgentName.PLANNER,
        label="Plan document changes",
        detail="Waiting",
        status=AgentStepStatus.PENDING,
    )
    editor = trail.add(
        agent=AgentName.EDITOR,
        label="Build diff",
        detail="Waiting",
        status=AgentStepStatus.PENDING,
    )
    assert planner.agent is AgentName.PLANNER
    assert editor.agent is AgentName.EDITOR

    failed = trail.fail(planner.id, "parse error")
    assert failed.status is AgentStepStatus.FAILED
