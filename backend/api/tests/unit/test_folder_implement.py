"""Tests for folder plan implementation."""

from pathlib import Path

import pytest

from kew_api.ai.folder_implement_runner import (
    _parse_planned_paths_from_text,
    _requests_folder_implement,
    apply_folder_plan,
)
from kew_api.config.settings import ApiSettings
from kew_api.services.workspace_service import WorkspaceService


@pytest.fixture
def workspace(tmp_path: Path) -> WorkspaceService:
    docs = tmp_path / "docs"
    docs.mkdir()
    settings = ApiSettings(docs_root=docs, repo_root=tmp_path)
    return WorkspaceService(settings)


def test_requests_folder_implement_detects_phrases() -> None:
    assert _requests_folder_implement("Please implement the plan on disk")
    assert _requests_folder_implement("sync folder structure with the plan")
    assert not _requests_folder_implement("what is a data mesh?")


def test_parse_flat_target_structure_list() -> None:
    scope = "04_Data_Modeling_Architecture/03_Modern/02_Semantic_Modeling"
    text = """
README.md — hub page
01_Business_Glossary.md  [complete] — glossary artifact
02_Metrics_Layer.md [complete]
09_Semantic_Data_Products.md [complete]
"""
    paths = _parse_planned_paths_from_text(scope, text)
    assert f"{scope}/README.md" in paths
    assert f"{scope}/01_Business_Glossary.md" in paths
    assert f"{scope}/09_Semantic_Data_Products.md" in paths
    assert len(paths) == 4


def test_apply_folder_plan_creates_files(workspace: WorkspaceService, tmp_path: Path) -> None:
    section = "02_Example"
    (tmp_path / "docs" / section).mkdir()
    plan = f"""# Target structure

{section}/
README.md
01_Overview.md

# Reorganization

- [create] {section}/README.md: Section index
- [create] {section}/01_Overview.md: Overview doc
"""
    settings = ApiSettings(docs_root=tmp_path / "docs", repo_root=tmp_path)
    result = apply_folder_plan(
        folder_path=section,
        folder_plan=plan,
        workspace=workspace,
        settings=settings,
    )
    assert result.applied_count == 2
    assert (tmp_path / "docs" / section / "README.md").is_file()
    assert (tmp_path / "docs" / section / "01_Overview.md").is_file()


def test_apply_folder_plan_archives_unplanned_files(workspace: WorkspaceService, tmp_path: Path) -> None:
    section = "02_Example"
    section_dir = tmp_path / "docs" / section
    section_dir.mkdir()
    (section_dir / "README.md").write_text("---\ntitle: x\n---\n", encoding="utf-8")
    (section_dir / "99_Legacy.md").write_text("---\ntitle: legacy\n---\n", encoding="utf-8")

    plan = f"""# Target structure

README.md
01_Overview.md
"""
    settings = ApiSettings(docs_root=tmp_path / "docs", repo_root=tmp_path)
    result = apply_folder_plan(
        folder_path=section,
        folder_plan=plan,
        workspace=workspace,
        settings=settings,
    )
    assert result.applied_count >= 2
    assert (section_dir / "01_Overview.md").is_file()
    assert (section_dir / "_archive" / "99_Legacy.md").is_file()
    assert not (section_dir / "99_Legacy.md").exists()
