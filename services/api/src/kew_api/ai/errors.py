"""Shared AI runner errors."""


class AiRunnerError(RuntimeError):
    """Raised when an AI provider call fails or returns invalid output."""


# Backward-compatible alias for exception handlers and imports.
AdkRunnerError = AiRunnerError
