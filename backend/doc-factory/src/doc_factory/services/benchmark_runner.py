"""Standalone Benchmark Agent runner."""

from __future__ import annotations

import logging
import os
import uuid
from pathlib import Path

from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types
from pydantic import ValidationError

from doc_factory.agents.generation.benchmark_agent import (
    build_benchmark_evaluation_agent,
    finalize_benchmark_output,
)
from doc_factory.config.logging import configure_logging
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.benchmark import BenchmarkAgentOutput, TechnologyBenchmarkEvaluation
from doc_factory.rendering.benchmark_renderer import BenchmarkMarkdownRenderer
from doc_factory.services.errors import PipelineAgentError, PipelineConfigError, PipelineStateError
from doc_factory.services.shared_state import parse_state_model

logger = logging.getLogger(__name__)


class BenchmarkRunner:
    """Run the Benchmark Agent for a single technology topic."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        self._renderer = BenchmarkMarkdownRenderer()

    async def run(self, topic: str, *, output_dir: Path | None = None) -> BenchmarkAgentOutput:
        configure_logging(self._settings)
        self._ensure_gemini_key()

        session_id = str(uuid.uuid4())
        session_service = InMemorySessionService()
        agent = build_benchmark_evaluation_agent(self._settings, standalone=True, topic=topic)

        runner = Runner(
            agent=agent,
            app_name="documentation_ai_factory_benchmark",
            session_service=session_service,
        )

        await session_service.create_session(
            app_name="documentation_ai_factory_benchmark",
            user_id="local",
            session_id=session_id,
            state={"topic": topic},
        )

        message = types.Content(
            role="user",
            parts=[types.Part(text=f"Evaluate and benchmark: {topic}")],
        )

        try:
            async for event in runner.run_async(
                user_id="local",
                session_id=session_id,
                new_message=message,
            ):
                if getattr(event, "error_code", None):
                    raise PipelineAgentError(
                        f"Benchmark agent error: {getattr(event, 'error_message', event)}",
                        agent_name="benchmark_agent",
                    )
        except PipelineAgentError:
            raise
        except Exception as exc:
            raise PipelineAgentError(
                f"Benchmark agent failed: {exc}",
                agent_name="benchmark_agent",
                cause=exc,
            ) from exc

        session = await session_service.get_session(
            app_name="documentation_ai_factory_benchmark",
            user_id="local",
            session_id=session_id,
        )
        if session is None:
            raise PipelineStateError("Session missing after benchmark run.")

        try:
            evaluation = parse_state_model(
                session.state.get("benchmark_evaluation"),
                TechnologyBenchmarkEvaluation,
                key="benchmark_evaluation",
            )
        except (PipelineStateError, ValidationError) as exc:
            raise PipelineStateError(f"Invalid benchmark output: {exc}") from exc

        result = finalize_benchmark_output(evaluation)
        target_dir = output_dir or (
            self._settings.resolved_output_dir / f"benchmark_{_slug(topic)}_{session_id[:8]}"
        )
        self._write_output(result, target_dir)
        logger.info("Benchmark complete: %s", target_dir)
        return result

    def _write_output(self, result: BenchmarkAgentOutput, output_dir: Path) -> None:
        output_dir.mkdir(parents=True, exist_ok=True)
        md_path = output_dir / result.section.filename
        md_path.write_text(result.section.content_markdown, encoding="utf-8")
        json_path = output_dir / "benchmark_evaluation.json"
        json_path.write_text(result.evaluation.model_dump_json(indent=2), encoding="utf-8")
        summary_path = output_dir / "README.md"
        summary_path.write_text(
            f"# {result.topic} Benchmark\n\n"
            f"**Recommended:** {result.evaluation.recommended_technology}\n\n"
            f"See `{result.section.filename}` for full Markdown tables.\n",
            encoding="utf-8",
        )

    @staticmethod
    def _ensure_gemini_key() -> None:
        settings = get_settings()
        gemini = settings.gemini_api_key
        if gemini is None or not gemini.get_secret_value().strip():
            raise PipelineConfigError("GEMINI_API_KEY is required for benchmark runs.")
        os.environ.setdefault("GOOGLE_API_KEY", gemini.get_secret_value())


def _slug(text: str) -> str:
    return text.lower().replace(" ", "_")[:40]


async def run_benchmark(topic: str, *, output_dir: Path | None = None) -> BenchmarkAgentOutput:
    """Convenience entrypoint for standalone benchmark evaluation."""
    return await BenchmarkRunner().run(topic, output_dir=output_dir)
