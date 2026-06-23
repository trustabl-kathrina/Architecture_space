"""SSE helpers for chat streaming."""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator

from kew_api.schemas.chat import ChatStreamEvent


def format_sse(event: ChatStreamEvent) -> str:
    return f"data: {event.model_dump_json()}\n\n"


async def stream_text_chunks(text: str, *, chunk_size: int = 28) -> AsyncIterator[str]:
    """Yield text in small chunks for a typing effect in the UI."""
    for index in range(0, len(text), chunk_size):
        yield text[index : index + chunk_size]
        await asyncio.sleep(0.012)
