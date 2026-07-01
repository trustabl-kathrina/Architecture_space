"""Logging configuration.

Responsibility:
- Configure structured console and optional file logging from Settings.
"""

from __future__ import annotations

import logging
import sys

from doc_factory.config.settings import Settings


def configure_logging(settings: Settings) -> None:
    """Configure root logger level and handlers."""
    level = getattr(logging, settings.log_level.upper(), logging.INFO)
    handlers: list[logging.Handler] = [logging.StreamHandler(sys.stdout)]

    if settings.log_file is not None:
        settings.log_file.parent.mkdir(parents=True, exist_ok=True)
        handlers.append(logging.FileHandler(settings.log_file, encoding="utf-8"))

    logging.basicConfig(
        level=level,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        handlers=handlers,
        force=True,
    )
