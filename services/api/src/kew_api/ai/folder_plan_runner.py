"""Multi-agent folder structure planning pipeline."""

from __future__ import annotations

import logging
import re
from collections.abc import Callable
from typing import TYPE_CHECKING

from kew_api.ai.agents import (
    build_folder_analyzer_agent,
    build_folder_expert_agent,
    build_folder_planner_agent,
    build_folder_researcher_agent,
)
from kew_api.ai.errors import AiRunnerError
from kew_api.ai.prompts import load_prompt
from kew_api.ai.runner import run_structured_agent
from kew_api.config.settings import ApiSettings
from kew_api.schemas.chat import (
    AgentName,
    AgentStepStatus,
    ChatStreamEvent,
    ChatStreamEventType,
    FolderAnalysisOutput,
    FolderExpertOutput,
    FolderPlanResult,
    FolderReorganizationItem,
    TopicResearchOutput,
)
from kew_api.schemas.workspace import TreeNode

if TYPE_CHECKING:
    from kew_api.services.execution_trail import ExecutionTrailBuilder

logger = logging.getLogger(__name__)


def render_tree_text(nodes: list[TreeNode], prefix: str = "") -> list[str]:
    """Render nodes as ASCII tree lines."""
    lines: list[str] = []
    for index, node in enumerate(nodes):
        is_last = index == len(nodes) - 1
        branch = "└── " if is_last else "├── "
        suffix = "/" if node.type == "folder" else ""
        lines.append(f"{prefix}{branch}{node.name}{suffix}")
        if node.children:
            child_prefix = prefix + ("    " if is_last else "│   ")
            lines.extend(render_tree_text(node.children, child_prefix))
    return lines


def flatten_tree_paths(nodes: list[TreeNode]) -> list[str]:
    paths: list[str] = []
    for node in nodes:
        paths.append(f"{node.type}:{node.path}")
        if node.children:
            paths.extend(flatten_tree_paths(node.children))
    return paths


def _extract_target_structure_from_plan(plan_text: str) -> str | None:
    """Pull the target structure block from a user draft plan."""
    lines = plan_text.splitlines()
    captured: list[str] = []
    in_target = False
    for line in lines:
        normalized = line.strip().lower()
        if normalized.startswith("# target structure"):
            in_target = True
            continue
        if in_target and line.strip().startswith("# ") and "target structure" not in normalized:
            break
        if in_target:
            captured.append(line)
    text = "\n".join(captured).strip()
    return text or None


def _parse_reorg_from_draft_plan(plan_text: str) -> list[FolderReorganizationItem]:
    """Parse [action] lines from the user's draft reorganization section."""
    items: list[FolderReorganizationItem] = []
    pattern = re.compile(
        r"^\s*-\s*\[(?P<action>keep|rename|move|merge|split|create|archive|delete)\]\s+"
        r"(?P<path>.+?)(?:\s+->\s+(?P<target>.+?))?\s*:\s*(?P<rationale>.+?)\s*$",
        re.IGNORECASE,
    )
    for line in plan_text.splitlines():
        match = pattern.match(line)
        if not match:
            continue
        items.append(
            FolderReorganizationItem(
                action=match.group("action").lower(),  # type: ignore[arg-type]
                path=match.group("path").strip(),
                target_path=match.group("target").strip() if match.group("target") else None,
                rationale=match.group("rationale").strip(),
            )
        )
    return items


def build_user_directives_block(
    *,
    user_message: str,
    existing_plan: str | None,
    conversation_history: str | None,
) -> str:
    """Build a high-priority block that must flow through every agent stage."""
    parts = [
        "## USER DIRECTIVES (highest priority — must be reflected in final output)",
        "",
        "### Latest request",
        user_message.strip(),
    ]
    if conversation_history and conversation_history.strip():
        parts.extend(["", "### Prior conversation", conversation_history.strip()])
    if existing_plan and existing_plan.strip():
        parts.extend(
            [
                "",
                "### User draft plan (preserve, refine, and complete — do not discard)",
                existing_plan.strip()[:12_000],
            ]
        )
    return "\n".join(parts)


def _mock_folder_plan(
    *,
    folder_path: str,
    user_message: str,
    current_tree_text: str,
    existing_plan: str | None = None,
    conversation_history: str | None = None,
) -> FolderPlanResult:
    section = folder_path.split("/")[-1] if folder_path else "docs"
    draft_target = _extract_target_structure_from_plan(existing_plan or "")
    draft_reorg = _parse_reorg_from_draft_plan(existing_plan or "")

    if draft_target:
        target = draft_target
    else:
        target = f"""{section}/
├── README.md
├── 01_Fundamentals/
│   ├── README.md
│   ├── 01_Overview.md
│   └── 02_Core_Concepts.md
├── 02_Implementation/
│   ├── README.md
│   └── 01_Patterns.md
└── 03_Reference_Architectures/
    ├── README.md
    └── 01_Enterprise_Pattern.md"""

    reorganization = list(draft_reorg)
    if not any(item.action == "create" and item.path.endswith("README.md") for item in reorganization):
        reorganization.append(
            FolderReorganizationItem(
                action="create",
                path=f"{folder_path}/README.md" if folder_path else "README.md",
                rationale="Section index missing",
            )
        )

    history_note = ""
    if conversation_history and conversation_history.strip():
        history_note = f"\n\n### Prior conversation\n{conversation_history.strip()[:1500]}"

    draft_note = ""
    if existing_plan and existing_plan.strip():
        draft_note = "\n\n### User draft plan applied\nYour draft structure was used as the base target tree."

    return FolderPlanResult(
        summary=f"Refined structure for {section} incorporating your recommendations",
        explanation=(
            f"## User directives applied\n\n"
            f"- Latest request: {user_message}\n"
            f"{history_note}"
            f"{draft_note}\n\n"
            f"## Current structure\n\n```\n{current_tree_text or '(empty)'}\n```\n\n"
            "## Recommendations\n\n"
            "- Structure built from your draft plan where provided\n"
            "- Prior chat messages inform topic coverage\n"
            "- Add README.md at section root if missing\n"
            "- Renumber existing files to match corpus conventions where needed"
        ),
        target_structure=target,
        reorganization=reorganization,
        confidence=0.75,
    )


async def _run_stage(
    *,
    agent_builder,
    output_key: str,
    output_model,
    prompt_name: str,
    user_message: str,
    settings: ApiSettings,
) -> object:
    agent = agent_builder(settings)
    return await run_structured_agent(
        agent,
        user_message=user_message,
        output_key=output_key,
        output_model=output_model,
        settings=settings,
        system_prompt=load_prompt(prompt_name),
    )


def _emit_agent_thought(
    emit: Callable[[ChatStreamEvent], None],
    *,
    agent: AgentName,
    content: str,
) -> None:
    if content.strip():
        emit(
            ChatStreamEvent(
                type=ChatStreamEventType.AGENT_THOUGHT,
                agent=agent,
                content=content.strip(),
            )
        )


def _format_research_thought(research: TopicResearchOutput) -> str:
    return (
        f"**Topic:** {research.topic_summary}\n\n"
        f"**Key concepts:** {', '.join(research.key_concepts) or '—'}\n"
        f"**Standards:** {', '.join(research.industry_standards) or '—'}\n"
        f"**Recommended depth:** {research.recommended_depth or '—'}"
    )


def _format_analysis_thought(analysis: FolderAnalysisOutput) -> str:
    return (
        f"**Structure:** {analysis.current_structure_summary}\n\n"
        f"**Strengths:** {', '.join(analysis.strengths) or '—'}\n"
        f"**Gaps:** {', '.join(analysis.gaps) or '—'}\n"
        f"**Redundancies:** {', '.join(analysis.redundancies) or '—'}"
    )


def _format_expert_thought(expert: FolderExpertOutput) -> str:
    return (
        f"**Perspective:** {expert.domain_perspective}\n\n"
        f"**Pillars:** {', '.join(expert.recommended_pillars) or '—'}\n"
        f"**Critical topics:** {', '.join(expert.critical_topics) or '—'}\n"
        f"**Anti-patterns:** {', '.join(expert.anti_patterns) or '—'}"
    )


async def run_folder_plan_pipeline(
    *,
    user_message: str,
    folder_path: str,
    workspace_context: str,
    current_tree_text: str,
    existing_plan: str | None,
    conversation_history: str | None = None,
    settings: ApiSettings,
    trail: ExecutionTrailBuilder,
    queue_event: Callable[[ChatStreamEvent], None] | None = None,
) -> FolderPlanResult:
    """Execute research → analyze → expert → synthesize folder planning pipeline."""

    def emit(event: ChatStreamEvent) -> None:
        if queue_event:
            queue_event(event)

    if settings.ai_mock_mode:
        step = trail.add(
            agent=AgentName.PLANNER,
            label="Mock folder planning",
            detail="Generating sample structure (mock mode)",
            status=AgentStepStatus.RUNNING,
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=step))
        result = _mock_folder_plan(
            folder_path=folder_path,
            user_message=user_message,
            current_tree_text=current_tree_text,
            existing_plan=existing_plan,
            conversation_history=conversation_history,
        )
        _emit_agent_thought(
            emit,
            agent=AgentName.PLANNER,
            content=f"**{result.summary}**\n\n{result.explanation[:800]}",
        )
        step = trail.complete(step.id, label="Mock folder plan ready", detail=result.summary)
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=step))
        return result

    user_directives = build_user_directives_block(
        user_message=user_message,
        existing_plan=existing_plan,
        conversation_history=conversation_history,
    )

    base_context = (
        f"Folder path: {folder_path or '(docs root)'}\n\n"
        f"Workspace context:\n{workspace_context}\n\n"
        f"Current on-disk tree:\n{current_tree_text or '(empty)'}\n\n"
        f"{user_directives}\n"
    )

    def with_directives(stage_context: str) -> str:
        return f"{stage_context}\n\n{user_directives}"

    # Stage 1: Research
    research_step = trail.add(
        agent=AgentName.RESEARCHER,
        label="Research domain topic",
        detail="Analyzing subject matter and standards",
        status=AgentStepStatus.RUNNING,
    )
    emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=research_step))
    try:
        research = await _run_stage(
            agent_builder=build_folder_researcher_agent,
            output_key="research_output",
            output_model=TopicResearchOutput,
            prompt_name="folder_researcher",
            user_message=base_context,
            settings=settings,
        )
        assert isinstance(research, TopicResearchOutput)
        thought = _format_research_thought(research)
        _emit_agent_thought(emit, agent=AgentName.RESEARCHER, content=thought)
        research_step = trail.complete(
            research_step.id,
            label="Research complete",
            detail=research.topic_summary[:500],
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=research_step))
    except AiRunnerError as exc:
        logger.warning("Folder research failed: %s", exc)
        trail.fail(research_step.id, str(exc))
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=trail.get(research_step.id)))
        research = TopicResearchOutput(
            topic_summary=f"Research fallback for {folder_path}",
            key_concepts=["overview", "patterns", "governance"],
            industry_standards=["DAMA", "TOGAF"],
            recommended_depth="2-3 levels",
        )

    research_context = (
        f"{base_context}\n\n## Research findings\n"
        f"Summary: {research.topic_summary}\n"
        f"Key concepts: {', '.join(research.key_concepts)}\n"
        f"Standards: {', '.join(research.industry_standards)}\n"
        f"Depth: {research.recommended_depth}\n"
    )

    # Stage 2: Analyze current structure
    analysis_step = trail.add(
        agent=AgentName.ANALYST,
        label="Analyze current structure",
        detail="Reviewing existing folders and files",
        status=AgentStepStatus.RUNNING,
    )
    emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=analysis_step))
    try:
        analysis = await _run_stage(
            agent_builder=build_folder_analyzer_agent,
            output_key="analysis_output",
            output_model=FolderAnalysisOutput,
            prompt_name="folder_analyzer",
            user_message=research_context,
            settings=settings,
        )
        assert isinstance(analysis, FolderAnalysisOutput)
        thought = _format_analysis_thought(analysis)
        _emit_agent_thought(emit, agent=AgentName.ANALYST, content=thought)
        analysis_step = trail.complete(
            analysis_step.id,
            label="Structure analysis complete",
            detail=analysis.current_structure_summary[:500],
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=analysis_step))
    except AiRunnerError as exc:
        logger.warning("Folder analysis failed: %s", exc)
        trail.fail(analysis_step.id, str(exc))
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=trail.get(analysis_step.id)))
        analysis = FolderAnalysisOutput(
            current_structure_summary="Could not fully analyze structure; using tree snapshot.",
            gaps=["Missing section README"],
            strengths=["Existing topic files present"],
        )

    analysis_context = (
        f"{research_context}\n\n## Structure analysis\n"
        f"Summary: {analysis.current_structure_summary}\n"
        f"Strengths: {', '.join(analysis.strengths)}\n"
        f"Gaps: {', '.join(analysis.gaps)}\n"
        f"Redundancies: {', '.join(analysis.redundancies)}\n"
        f"Naming issues: {', '.join(analysis.naming_issues)}\n"
    )

    # Stage 3: Domain expert
    expert_step = trail.add(
        agent=AgentName.DOMAIN_EXPERT,
        label="Apply domain expertise",
        detail="Recommending pillars and critical topics",
        status=AgentStepStatus.RUNNING,
    )
    emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=expert_step))
    try:
        expert = await _run_stage(
            agent_builder=build_folder_expert_agent,
            output_key="expert_output",
            output_model=FolderExpertOutput,
            prompt_name="folder_domain_expert",
            user_message=analysis_context,
            settings=settings,
        )
        assert isinstance(expert, FolderExpertOutput)
        thought = _format_expert_thought(expert)
        _emit_agent_thought(emit, agent=AgentName.DOMAIN_EXPERT, content=thought)
        expert_step = trail.complete(
            expert_step.id,
            label="Domain recommendations ready",
            detail=expert.domain_perspective[:500],
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=expert_step))
    except AiRunnerError as exc:
        logger.warning("Folder expert failed: %s", exc)
        trail.fail(expert_step.id, str(exc))
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=trail.get(expert_step.id)))
        expert = FolderExpertOutput(
            domain_perspective="Enterprise architecture documentation section",
            recommended_pillars=["Fundamentals", "Patterns", "Governance"],
            critical_topics=["Overview", "Standards", "Reference architectures"],
        )

    synthesis_context = with_directives(
        f"{analysis_context}\n\n## Domain expert view\n"
        f"Perspective: {expert.domain_perspective}\n"
        f"Pillars: {', '.join(expert.recommended_pillars)}\n"
        f"Critical topics: {', '.join(expert.critical_topics)}\n"
        f"Anti-patterns: {', '.join(expert.anti_patterns)}\n"
    )

    # Stage 4: Synthesize plan
    planner_step = trail.add(
        agent=AgentName.PLANNER,
        label="Synthesize folder plan",
        detail="Producing target tree and reorganization",
        status=AgentStepStatus.RUNNING,
    )
    emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=planner_step))
    try:
        plan = await _run_stage(
            agent_builder=build_folder_planner_agent,
            output_key="plan_output",
            output_model=FolderPlanResult,
            prompt_name="folder_planner",
            user_message=synthesis_context,
            settings=settings,
        )
        assert isinstance(plan, FolderPlanResult)
        _emit_agent_thought(
            emit,
            agent=AgentName.PLANNER,
            content=f"**{plan.summary}**\n\n{plan.explanation[:1200]}",
        )
        planner_step = trail.complete(
            planner_step.id,
            label="Folder plan ready",
            detail=plan.summary,
            target_path=folder_path,
        )
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=planner_step))
        return plan
    except AiRunnerError as exc:
        logger.warning("Folder planner failed: %s", exc)
        trail.fail(planner_step.id, str(exc))
        emit(ChatStreamEvent(type=ChatStreamEventType.TRAIL_STEP, step=trail.get(planner_step.id)))
        raise


def format_folder_plan_message(result: FolderPlanResult) -> str:
    """Brief chat response; full plan lives in the section planner panel."""
    first_block = result.explanation.strip().split("\n\n")[0]
    if len(first_block) > 500:
        first_block = f"{first_block[:497]}..."

    return (
        f"{result.summary}\n\n"
        f"{first_block}\n\n"
        "The full target structure and reorganization details are in **Planned structure** "
        "in the section planner — review and edit there, then ask me to refine."
    )


def compose_plan_textarea(result: FolderPlanResult) -> str:
    """Text for the folder planning panel textarea."""
    lines = [
        "# Target structure",
        "",
        result.target_structure.strip(),
        "",
        "# Reorganization",
        "",
    ]
    for item in result.reorganization:
        target = f" -> {item.target_path}" if item.target_path else ""
        lines.append(f"- [{item.action}] {item.path}{target}: {item.rationale}")
    lines.extend(["", "# Notes", "", result.explanation.strip()])
    return "\n".join(lines).strip() + "\n"
