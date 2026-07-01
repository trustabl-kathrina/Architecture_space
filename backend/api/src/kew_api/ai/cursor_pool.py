"""Process pool for Cursor SDK calls (Windows + uvicorn safe)."""

from __future__ import annotations

import concurrent.futures
import logging

logger = logging.getLogger(__name__)

_pool: concurrent.futures.ProcessPoolExecutor | None = None


def get_process_pool() -> concurrent.futures.ProcessPoolExecutor:
    """Return a singleton process pool for isolated Cursor bridge runs."""
    global _pool
    if _pool is None:
        logger.debug("Creating Cursor process pool")
        _pool = concurrent.futures.ProcessPoolExecutor(max_workers=1)
    return _pool


def shutdown_process_pool() -> None:
    """Shut down the Cursor process pool."""
    global _pool
    if _pool is not None:
        _pool.shutdown(wait=False, cancel_futures=True)
        _pool = None
