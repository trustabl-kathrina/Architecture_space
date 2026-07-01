"""Load prompt templates bundled with the API package."""

from __future__ import annotations

from functools import lru_cache
from importlib import resources


@lru_cache
def load_prompt(name: str) -> str:
    """Load ``prompts/{name}.txt`` from the kew_api package."""
    file_name = name if name.endswith(".txt") else f"{name}.txt"
    return resources.files("kew_api.prompts").joinpath(file_name).read_text(encoding="utf-8")
