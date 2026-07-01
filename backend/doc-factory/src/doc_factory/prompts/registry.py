"""Load versioned prompt templates."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

_PROMPTS_DIR = Path(__file__).resolve().parent


@lru_cache
def load_prompt(relative_path: str) -> str:
    """Load a prompt text file relative to the prompts package."""
    path = _PROMPTS_DIR / relative_path
    return path.read_text(encoding="utf-8").strip()


def render_prompt(relative_path: str, **variables: str) -> str:
    """Load a prompt and substitute ``{{ key }}`` placeholders."""
    text = load_prompt(relative_path)
    for key, value in variables.items():
        text = text.replace(f"{{{{ {key} }}}}", value)
    return text
