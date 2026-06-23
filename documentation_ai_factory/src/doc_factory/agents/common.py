"""Shared helpers for ADK agent construction."""

from __future__ import annotations

from google.adk.workflow._retry_config import RetryConfig

from doc_factory.config.settings import Settings


def retry_config(settings: Settings) -> RetryConfig:
    """Build ADK retry configuration from application settings."""
    return RetryConfig(
        max_attempts=settings.pipeline_max_retries,
        initial_delay=settings.pipeline_retry_initial_delay,
        max_delay=settings.pipeline_retry_max_delay,
        backoff_factor=settings.pipeline_retry_backoff_factor,
    )
