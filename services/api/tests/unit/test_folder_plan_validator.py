"""Tests for folder plan directive validation."""

from __future__ import annotations

from kew_api.ai.folder_plan_validator import find_missing_directives
from kew_api.ai.folder_plan_runner import resolve_pipeline_mode, FolderPlanPipelineMode
from kew_api.schemas.chat import FolderPlanResult, FolderReorganizationItem


def test_resolve_pipeline_mode_refine_draft_when_plan_exists() -> None:
    mode = resolve_pipeline_mode(
        user_message="refine my structure",
        existing_plan="# Target structure\n\n02_Section/\n├── README.md\n",
    )
    assert mode is FolderPlanPipelineMode.REFINE_DRAFT


def test_resolve_pipeline_mode_quick_for_simple_design() -> None:
    mode = resolve_pipeline_mode(
        user_message="Design a simple folder structure",
        existing_plan=None,
    )
    assert mode is FolderPlanPipelineMode.QUICK


def test_resolve_pipeline_mode_full_for_research_request() -> None:
    mode = resolve_pipeline_mode(
        user_message="Do comprehensive research and greenfield structure",
        existing_plan=None,
    )
    assert mode is FolderPlanPipelineMode.FULL


def test_find_missing_directives_detects_absent_path() -> None:
    result = FolderPlanResult(
        summary="Plan",
        explanation="Generic plan",
        target_structure="section/\n├── README.md",
        reorganization=[],
        confidence=0.8,
    )
    missing = find_missing_directives(
        user_message="Add 10_Custom_Metrics.md and governance subfolder",
        existing_plan=None,
        result=result,
    )
    assert any("custom_metrics" in item for item in missing)


def test_find_missing_directives_passes_when_present() -> None:
    result = FolderPlanResult(
        summary="Plan",
        explanation="Includes custom metrics",
        target_structure="section/\n├── 10_Custom_Metrics.md\n├── README.md",
        reorganization=[
            FolderReorganizationItem(
                action="create",
                path="section/10_Custom_Metrics.md",
                rationale="user request",
            ),
        ],
        confidence=0.9,
    )
    missing = find_missing_directives(
        user_message="Add 10_Custom_Metrics.md",
        existing_plan=None,
        result=result,
    )
    assert "10_custom_metrics.md" not in missing
