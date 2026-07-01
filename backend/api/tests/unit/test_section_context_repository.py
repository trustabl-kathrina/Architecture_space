"""Tests for section context storage."""

from __future__ import annotations

from pathlib import Path

import pytest

from kew_api.config.settings import ApiSettings, clear_settings_cache
from kew_api.schemas.chat import ChatMode, FolderPlanResult, FolderReorganizationItem
from kew_api.services.section_context_repository import (
    SectionContextRepository,
    section_context_storage_name,
)


@pytest.fixture
def repo(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> SectionContextRepository:
    data = tmp_path / ".data"
    data.mkdir()
    monkeypatch.setenv("KEW_API_DATA_ROOT", str(data))
    clear_settings_cache()
    return SectionContextRepository(ApiSettings())


def test_storage_name_sanitizes_slashes() -> None:
    name = section_context_storage_name(
        "folder",
        "04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling",
    )
    assert "/" not in name
    assert "Semantic_Modeling" in name


def test_record_folder_plan_nested_path(repo: SectionContextRepository) -> None:
    path = "04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling"
    result = FolderPlanResult(
        summary="Test plan",
        explanation="Details",
        target_structure="section/\n├── README.md",
        reorganization=[
            FolderReorganizationItem(action="create", path=f"{path}/README.md", rationale="index"),
        ],
        confidence=0.9,
    )
    saved = repo.record_folder_plan(
        scope_kind="folder",
        scope_path=path,
        chat_mode=ChatMode.PLAN,
        result=result,
    )
    assert saved.last_plan_summary == "Test plan"
    loaded = repo.get("folder", path)
    assert loaded is not None
    assert loaded.last_plan_summary == "Test plan"
