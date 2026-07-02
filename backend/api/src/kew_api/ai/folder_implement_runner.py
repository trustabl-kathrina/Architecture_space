"""Apply folder plans to the documentation corpus on disk."""

from __future__ import annotations

import logging
import re
from pathlib import PurePosixPath

from kew_api.ai.folder_plan_runner import (
    _extract_target_structure_from_plan,
    _parse_reorg_from_draft_plan,
    flatten_tree_paths,
)
from kew_api.config.settings import ApiSettings
from kew_api.exceptions import (
    InvalidNameError,
    NodeAlreadyExistsError,
    NodeConflictError,
    NodeNotFoundError,
)
from kew_api.schemas.chat import FolderImplementResult, FolderReorganizationItem
from kew_api.services.workspace_service import WorkspaceService

logger = logging.getLogger(__name__)

_PLANNED_FILE_RE = re.compile(
    r"(?P<name>(?:README|\d{2}_[A-Za-z0-9_.-]+)\.md)",
    re.IGNORECASE,
)


def _requests_folder_implement(content: str) -> bool:
    lowered = content.lower().strip()
    hints = (
        "implement the plan",
        "implement plan",
        "implement this plan",
        "execute the plan",
        "execute plan",
        "apply the plan",
        "apply plan",
        "apply the structure",
        "apply structure",
        "sync the plan",
        "sync folder",
        "sync structure",
        "align with the plan",
        "align folder",
        "match the plan",
        "match the structure",
        "reorganize",
        "reorganise",
        "clean up folder",
        "clean up structure",
        "create the folders",
        "create the files",
        "scaffold",
        "build the structure",
        "build out the structure",
        "make the changes",
        "make these changes",
        "go ahead",
        "proceed",
        "carry out",
        "put this on disk",
        "on disk",
        "update folder structure",
        "update the structure",
        "maintain only",
        "only planned",
    )
    if any(hint in lowered for hint in hints):
        return True
    if "implement" in lowered and "plan" in lowered:
        return True
    if "apply" in lowered and any(word in lowered for word in ("structure", "reorganization", "folders", "plan")):
        return True
    if "sync" in lowered and any(word in lowered for word in ("plan", "structure", "folder")):
        return True
    return False


def _normalize_scope_path(folder_path: str) -> str:
    return folder_path.strip().strip("/")


def _resolve_item_path(folder_path: str, item_path: str) -> str:
    cleaned = item_path.strip().strip("/")
    scope = _normalize_scope_path(folder_path)
    if not cleaned:
        return scope
    if scope and (cleaned == scope or cleaned.startswith(f"{scope}/")):
        return cleaned
    return f"{scope}/{cleaned}" if scope else cleaned


def _all_paths_under_scope(workspace: WorkspaceService, folder_path: str) -> set[str]:
    try:
        tree = workspace.list_tree(folder_path, depth=8)
    except NodeNotFoundError:
        return set()
    paths: set[str] = set()
    scope = _normalize_scope_path(folder_path)
    if scope:
        paths.add(scope)
    for entry in flatten_tree_paths(tree.nodes):
        _, path = entry.split(":", 1)
        paths.add(path)
    return paths


def _direct_child_files(existing: set[str], scope: str) -> set[str]:
    prefix = f"{scope}/" if scope else ""
    files: set[str] = set()
    for path in existing:
        if not path.lower().endswith(".md"):
            continue
        if scope and not path.startswith(prefix) and path != scope:
            continue
        relative = path[len(prefix) :] if prefix and path.startswith(prefix) else path
        if "/" in relative.strip("/"):
            continue
        if "/_archive/" in path or relative.startswith("_archive/"):
            continue
        files.add(path)
    return files


def _parse_planned_paths_from_text(folder_path: str, text: str) -> set[str]:
    """Extract planned markdown file paths from target structure or flat plan lists."""
    scope = _normalize_scope_path(folder_path)
    paths: set[str] = set()
    for match in _PLANNED_FILE_RE.finditer(text):
        paths.add(_resolve_item_path(scope, match.group("name")))
    return paths


def _parse_target_structure_creates(
    folder_path: str,
    target_structure: str,
    existing: set[str],
) -> list[FolderReorganizationItem]:
    """Infer create actions from an ASCII target tree when reorg list is empty."""
    planned = _parse_planned_paths_from_text(folder_path, target_structure)
    creates: list[FolderReorganizationItem] = []
    for path in sorted(planned):
        if path in existing:
            continue
        creates.append(
            FolderReorganizationItem(
                action="create",
                path=path,
                rationale="Missing file from target structure",
            )
        )
    return creates


def _build_sync_items(
    *,
    folder_path: str,
    folder_plan: str,
    workspace: WorkspaceService,
) -> list[FolderReorganizationItem]:
    """Diff planned target structure vs on-disk folder; merge explicit reorg directives."""
    scope = _normalize_scope_path(folder_path)
    explicit = [item for item in _parse_reorg_from_draft_plan(folder_plan) if item.action != "keep"]
    explicit_paths = {_resolve_item_path(scope, item.path) for item in explicit}

    target_block = _extract_target_structure_from_plan(folder_plan) or folder_plan
    planned_files = _parse_planned_paths_from_text(scope, target_block)

    items: list[FolderReorganizationItem] = list(explicit)

    if not planned_files:
        return items

    existing = _all_paths_under_scope(workspace, scope)
    existing_files = _direct_child_files(existing, scope)

    for path in sorted(planned_files - existing_files):
        if path in explicit_paths:
            continue
        items.append(
            FolderReorganizationItem(
                action="create",
                path=path,
                rationale="Planned file missing on disk",
            )
        )

    for path in sorted(existing_files - planned_files):
        if path in explicit_paths:
            continue
        items.append(
            FolderReorganizationItem(
                action="archive",
                path=path,
                rationale="File not in planned structure — moved to _archive",
            )
        )

    return items


def _collect_plan_items(
    *,
    folder_path: str,
    folder_plan: str,
    workspace: WorkspaceService,
) -> list[FolderReorganizationItem]:
    return _build_sync_items(
        folder_path=folder_path,
        folder_plan=folder_plan,
        workspace=workspace,
    )


def _is_file_path(path: str) -> bool:
    return path.lower().endswith(".md")


def _sort_for_apply(items: list[FolderReorganizationItem]) -> list[FolderReorganizationItem]:
    def sort_key(item: FolderReorganizationItem) -> tuple[int, int, str]:
        action_order = {
            "create": 0,
            "rename": 1,
            "move": 1,
            "merge": 2,
            "split": 2,
            "archive": 3,
            "delete": 4,
            "keep": 5,
        }
        file_rank = 1 if _is_file_path(item.path) else 0
        return (action_order.get(item.action, 9), file_rank, item.path)

    return sorted(items, key=sort_key)


def apply_folder_plan(
    *,
    folder_path: str,
    folder_plan: str,
    workspace: WorkspaceService,
    settings: ApiSettings,
) -> FolderImplementResult:
    """Execute reorganization items from a folder plan against the corpus."""
    _ = settings
    scope = _normalize_scope_path(folder_path)
    plan_text = folder_plan.strip()
    if not plan_text:
        return FolderImplementResult(
            summary="No folder plan to implement",
            explanation="Add or generate a plan in **Planned structure** first, then switch to Agent mode.",
            applied_count=0,
            skipped_count=0,
            failed_count=0,
            details=["No folder_plan text was provided."],
        )

    items = _collect_plan_items(
        folder_path=scope,
        folder_plan=plan_text,
        workspace=workspace,
    )
    actionable = [item for item in items if item.action != "keep"]
    if not actionable:
        target_block = _extract_target_structure_from_plan(plan_text) or plan_text
        planned = _parse_planned_paths_from_text(scope, target_block)
        return FolderImplementResult(
            summary="Folder already matches the plan",
            explanation=(
                "No creates, moves, or archives needed. "
                f"Planned files ({len(planned)}): "
                + ", ".join(sorted(PurePosixPath(p).name for p in planned)[:12])
                + ("…" if len(planned) > 12 else "")
            ),
            applied_count=0,
            skipped_count=0,
            failed_count=0,
            details=["Structure is in sync with the target structure."],
        )

    applied = 0
    skipped = 0
    failed = 0
    details: list[str] = []

    for item in _sort_for_apply(actionable):
        resolved_path = _resolve_item_path(scope, item.path)
        try:
            if item.action == "create":
                parent = str(PurePosixPath(resolved_path).parent).replace("\\", "/")
                if parent == ".":
                    parent = ""
                name = PurePosixPath(resolved_path).name
                if _is_file_path(resolved_path):
                    workspace.create_document(parent, name)
                    details.append(f"created file: {resolved_path}")
                else:
                    workspace.create_folder(parent, name)
                    details.append(f"created folder: {resolved_path}")
                applied += 1
                continue

            if item.action in {"rename", "move"}:
                if not item.target_path:
                    failed += 1
                    details.append(f"failed {item.action} {resolved_path}: missing target_path")
                    continue
                target_resolved = _resolve_item_path(scope, item.target_path)
                target_parent = str(PurePosixPath(target_resolved).parent).replace("\\", "/")
                if target_parent == ".":
                    target_parent = ""
                new_name = PurePosixPath(target_resolved).name
                workspace.update_node(
                    resolved_path,
                    new_name=new_name,
                    new_parent_path=target_parent,
                )
                details.append(f"{item.action}: {resolved_path} -> {target_resolved}")
                applied += 1
                continue

            if item.action == "delete":
                workspace.delete_node(resolved_path)
                details.append(f"deleted: {resolved_path}")
                applied += 1
                continue

            if item.action == "archive":
                archive_parent = _resolve_item_path(scope, "_archive")
                try:
                    workspace.create_folder(scope, "_archive")
                except NodeAlreadyExistsError:
                    pass
                workspace.update_node(
                    resolved_path,
                    new_parent_path=archive_parent,
                )
                details.append(f"archived: {resolved_path} -> {archive_parent}/")
                applied += 1
                continue

            skipped += 1
            details.append(f"skipped {item.action}: {resolved_path} (not automated)")
        except NodeAlreadyExistsError:
            skipped += 1
            details.append(f"skipped (already exists): {resolved_path}")
        except (NodeNotFoundError, NodeConflictError, InvalidNameError) as exc:
            failed += 1
            details.append(f"failed {item.action} {resolved_path}: {exc}")

    summary = f"Applied {applied} change(s) to match the planned structure"
    if failed:
        summary += f"; {failed} failed"
    if skipped:
        summary += f"; {skipped} skipped"

    explanation = "\n".join(f"- {line}" for line in details[:40])
    if len(details) > 40:
        explanation += f"\n- …and {len(details) - 40} more"

    return FolderImplementResult(
        summary=summary,
        explanation=explanation,
        applied_count=applied,
        skipped_count=skipped,
        failed_count=failed,
        details=details,
    )


def format_folder_implement_message(result: FolderImplementResult) -> str:
    return (
        f"**{result.summary}**\n\n"
        f"{result.explanation}\n\n"
        "The folder now reflects the **Planned structure** (creates missing files, archives unplanned files). "
        "Refresh the doc tree to see updates."
    )
