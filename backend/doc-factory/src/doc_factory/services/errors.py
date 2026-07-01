"""Pipeline error types."""

from __future__ import annotations


class PipelineError(Exception):
    """Base error for documentation pipeline failures."""

    def __init__(
        self,
        message: str,
        *,
        phase: str | None = None,
        run_id: str | None = None,
    ) -> None:
        super().__init__(message)
        self.phase = phase
        self.run_id = run_id


class PipelineConfigError(PipelineError):
    """Missing or invalid configuration."""


class PipelineStateError(PipelineError):
    """Shared state is missing or invalid."""


class PipelineAgentError(PipelineError):
    """An agent failed during execution."""

    def __init__(
        self,
        message: str,
        *,
        agent_name: str,
        phase: str | None = None,
        run_id: str | None = None,
        cause: Exception | None = None,
    ) -> None:
        super().__init__(message, phase=phase, run_id=run_id)
        self.agent_name = agent_name
        self.cause = cause


class PipelinePublishError(PipelineError):
    """Markdown publishing failed."""
