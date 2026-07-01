"""Gemini API client adapter."""

from __future__ import annotations

import logging
from typing import Any

from google import genai
from google.genai import types

from doc_factory.config.settings import Settings, get_settings

logger = logging.getLogger(__name__)


class GeminiClient:
    """Thin wrapper around google-genai with flash/pro model routing."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        api_key = self._settings.gemini_api_key
        if api_key is None or not api_key.get_secret_value().strip():
            raise ValueError("GEMINI_API_KEY is required for GeminiClient.")
        self._client = genai.Client(api_key=api_key.get_secret_value())

    def generate_text(
        self,
        prompt: str,
        *,
        model: str | None = None,
        temperature: float = 0.2,
        max_output_tokens: int = 8192,
    ) -> str:
        """Generate text from a prompt using the configured Gemini model."""
        model_name = model or self._settings.gemini_model_flash
        logger.info("Gemini generate: model=%s", model_name)
        response = self._client.models.generate_content(
            model=model_name,
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=temperature,
                max_output_tokens=max_output_tokens,
            ),
        )
        return _extract_text(response)

    def flash(self, prompt: str, **kwargs: Any) -> str:
        """Generate using the flash model."""
        return self.generate_text(prompt, model=self._settings.gemini_model_flash, **kwargs)

    def pro(self, prompt: str, **kwargs: Any) -> str:
        """Generate using the pro model."""
        return self.generate_text(prompt, model=self._settings.gemini_model_pro, **kwargs)


def _extract_text(response: Any) -> str:
    text = getattr(response, "text", None)
    if text:
        return str(text)
    candidates = getattr(response, "candidates", None) or []
    for candidate in candidates:
        content = getattr(candidate, "content", None)
        if content is None:
            continue
        parts = getattr(content, "parts", None) or []
        for part in parts:
            part_text = getattr(part, "text", None)
            if part_text:
                return str(part_text)
    return ""
