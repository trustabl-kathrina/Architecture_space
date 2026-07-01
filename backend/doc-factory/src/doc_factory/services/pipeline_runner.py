"""Multi-agent pipeline orchestration via Google ADK."""

from __future__ import annotations

import logging
import os
from typing import Any

from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types
from pydantic import ValidationError
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from doc_factory.agents.factory import build_documentation_workflow
from doc_factory.agents.generation.benchmark_agent import finalize_benchmark_output
from doc_factory.config.logging import configure_logging
from doc_factory.config.settings import Settings, get_settings
from doc_factory.models.benchmark import BenchmarkAgentOutput, TechnologyBenchmarkEvaluation
from doc_factory.models.mvp import PlannerAgentOutput, ResearchAgentOutput
from doc_factory.models.pipeline import (
    ComparisonAgentOutput,
    PipelineResult,
    ReviewerAgentOutput,
    StructureAgentOutput,
    WriterAgentOutput,
)
from doc_factory.models.state import AGENT_PHASE_MAP, StateKeys
from doc_factory.services.artifact_store import ArtifactStore
from doc_factory.services.errors import (
    PipelineAgentError,
    PipelineConfigError,
    PipelineError,
    PipelinePublishError,
    PipelineStateError,
)
from doc_factory.services.markdown_publisher import MarkdownPublisher
from doc_factory.services.run_repository import RunRepository, slugify
from doc_factory.services.shared_state import SharedStateStore, parse_state_model
from doc_factory.tools.tavily_search import reset_tavily_client

logger = logging.getLogger(__name__)

_OUTPUT_MODELS: dict[str, type] = {
    StateKeys.PLANNER_OUTPUT: PlannerAgentOutput,
    StateKeys.RESEARCH_OUTPUT: ResearchAgentOutput,
    StateKeys.STRUCTURE_OUTPUT: StructureAgentOutput,
    StateKeys.WRITER_OUTPUT: WriterAgentOutput,
    StateKeys.COMPARISON_OUTPUT: ComparisonAgentOutput,
    StateKeys.REVIEWER_OUTPUT: ReviewerAgentOutput,
}


def _ensure_api_keys(settings: Settings) -> None:
    gemini = settings.gemini_api_key
    tavily = settings.tavily_api_key
    if gemini is None or not gemini.get_secret_value().strip():
        raise PipelineConfigError(
            "GEMINI_API_KEY is required. Set it in documentation_ai_factory/.env"
        )
    if tavily is None or not tavily.get_secret_value().strip():
        raise PipelineConfigError(
            "TAVILY_API_KEY is required. Set it in documentation_ai_factory/.env"
        )
    os.environ.setdefault("GOOGLE_API_KEY", gemini.get_secret_value())


class PipelineRunner:
    """Execute the full multi-agent documentation pipeline."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        self._run_repo = RunRepository(self._settings)
        self._publisher = MarkdownPublisher(self._settings)

    async def run(self, topic: str, *, run_id: str | None = None) -> PipelineResult:
        configure_logging(self._settings)
        _ensure_api_keys(self._settings)
        reset_tavily_client()

        if run_id:
            run_dir = self._run_repo.get_run_dir(run_id)
            manifest = self._run_repo.load_manifest(run_id)
            topic = manifest.topic
            store = ArtifactStore(run_dir)
        else:
            run_id, run_dir, store = self._run_repo.create_run(topic)

        state_store = SharedStateStore(store)
        self._run_repo.update_manifest(run_id, status="running", current_phase="planner")
        logger.info("Starting pipeline run_id=%s topic=%s", run_id, topic)

        try:
            session_state = await self._execute_workflow(topic, run_id)
        except PipelineError:
            self._run_repo.update_manifest(run_id, status="failed", current_phase="failed")
            raise
        except Exception as exc:
            self._run_repo.update_manifest(run_id, status="failed", current_phase="failed")
            raise PipelineAgentError(
                f"Unexpected pipeline failure: {exc}",
                agent_name="workflow",
                run_id=run_id,
                cause=exc,
            ) from exc

        try:
            outputs = self._extract_outputs(session_state)
        except (PipelineStateError, ValidationError) as exc:
            self._run_repo.update_manifest(run_id, status="failed")
            raise PipelineStateError(str(exc), phase="extract", run_id=run_id) from exc

        for key, model in outputs.items():
            state_store.persist_output(key, model)

        slug = slugify(topic)
        output_dir = self._settings.resolved_output_dir / f"{slug}_{run_id[:8]}"

        try:
            self._run_repo.update_manifest(run_id, current_phase="publisher")
            publish_manifest = self._publisher.publish(
                run_id=run_id,
                reviewer_output=outputs[StateKeys.REVIEWER_OUTPUT],
                output_dir=output_dir,
            )
        except PipelinePublishError:
            self._run_repo.update_manifest(run_id, status="failed", current_phase="publisher")
            raise

        state_store.persist_output(StateKeys.PUBLISH_MANIFEST, publish_manifest)

        result = PipelineResult(
            run_id=run_id,
            topic=topic,
            planner_output=outputs[StateKeys.PLANNER_OUTPUT],
            research_output=outputs[StateKeys.RESEARCH_OUTPUT],
            structure_output=outputs[StateKeys.STRUCTURE_OUTPUT],
            writer_output=outputs[StateKeys.WRITER_OUTPUT],
            benchmark_output=outputs[StateKeys.BENCHMARK_OUTPUT],
            comparison_output=outputs[StateKeys.COMPARISON_OUTPUT],
            reviewer_output=outputs[StateKeys.REVIEWER_OUTPUT],
            publish_manifest=publish_manifest,
            output_dir=str(output_dir),
        )
        store.write_model("pipeline_result", result)
        self._run_repo.update_manifest(run_id, status="exported", current_phase="complete")
        logger.info("Pipeline complete. Output: %s", output_dir)
        return result

    async def _execute_workflow(self, topic: str, run_id: str) -> dict[str, Any]:
        session_service = InMemorySessionService()
        workflow = build_documentation_workflow(self._settings)
        runner = Runner(
            agent=workflow,
            app_name="documentation_ai_factory",
            session_service=session_service,
        )

        session = await session_service.create_session(
            app_name="documentation_ai_factory",
            user_id="local",
            session_id=run_id,
            state={StateKeys.TOPIC: topic},
        )

        message = types.Content(
            role="user",
            parts=[types.Part(text=f"Create enterprise architecture documentation for: {topic}")],
        )

        @retry(
            retry=retry_if_exception_type((ConnectionError, TimeoutError, OSError)),
            stop=stop_after_attempt(self._settings.pipeline_max_retries),
            wait=wait_exponential(
                multiplier=self._settings.pipeline_retry_initial_delay,
                max=self._settings.pipeline_retry_max_delay,
            ),
            reraise=True,
        )
        async def _run_adk() -> None:
            async for event in runner.run_async(
                user_id="local",
                session_id=session.id,
                new_message=message,
            ):
                author = getattr(event, "author", None)
                if author and author in AGENT_PHASE_MAP:
                    self._run_repo.update_manifest(
                        run_id,
                        current_phase=AGENT_PHASE_MAP[author],
                    )
                if getattr(event, "error_code", None):
                    raise PipelineAgentError(
                        f"Agent error: {getattr(event, 'error_message', event)}",
                        agent_name=str(author or "unknown"),
                        run_id=run_id,
                    )
                logger.debug("ADK event author=%s type=%s", author, type(event).__name__)

        try:
            await _run_adk()
        except PipelineAgentError:
            raise
        except Exception as exc:
            raise PipelineAgentError(
                f"ADK workflow failed: {exc}",
                agent_name="workflow",
                run_id=run_id,
                cause=exc,
            ) from exc

        session = await session_service.get_session(
            app_name="documentation_ai_factory",
            user_id="local",
            session_id=run_id,
        )
        if session is None:
            raise PipelineStateError("Session not found after workflow run.", run_id=run_id)
        return dict(session.state)

    def _extract_outputs(self, state: dict[str, Any]) -> dict[str, Any]:
        outputs: dict[str, Any] = {}
        for key, model_type in _OUTPUT_MODELS.items():
            outputs[key] = parse_state_model(state.get(key), model_type, key=key)

        raw_benchmark = state.get(StateKeys.BENCHMARK_EVALUATION) or state.get(
            StateKeys.BENCHMARK_OUTPUT
        )
        if raw_benchmark is not None:
            if isinstance(raw_benchmark, BenchmarkAgentOutput):
                outputs[StateKeys.BENCHMARK_OUTPUT] = raw_benchmark
            else:
                evaluation = parse_state_model(
                    raw_benchmark,
                    TechnologyBenchmarkEvaluation,
                    key=StateKeys.BENCHMARK_EVALUATION,
                )
                outputs[StateKeys.BENCHMARK_OUTPUT] = finalize_benchmark_output(evaluation)
        else:
            raise PipelineStateError("Missing state key: benchmark_evaluation")

        return outputs


async def run_pipeline(topic: str, *, run_id: str | None = None) -> PipelineResult:
    """Run the full multi-agent documentation pipeline."""
    return await PipelineRunner().run(topic, run_id=run_id)


# Backward-compatible alias
async def run_mvp_pipeline(topic: str, *, run_id: str | None = None) -> PipelineResult:
    return await run_pipeline(topic, run_id=run_id)
