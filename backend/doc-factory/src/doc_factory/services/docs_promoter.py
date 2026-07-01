"""Docs promoter — copy staging output to canonical docs/ after review."""

from __future__ import annotations

import logging
import shutil
from dataclasses import dataclass
from pathlib import Path

from doc_factory.config.settings import Settings, get_settings
from doc_factory.services.run_repository import slugify

logger = logging.getLogger(__name__)


@dataclass
class PromotionResult:
    """Result of a docs promotion operation."""

    source: Path
    destination: Path
    files_copied: list[str]
    dry_run: bool


class DocsPromoter:
    """Copy reviewed staging Markdown into canonical docs/ tree."""

    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()

    def resolve_staging(self, run_id: str, topic: str) -> Path:
        """Resolve staging directory for a run."""
        slug = slugify(topic)
        return self._settings.resolved_output_dir / f"{slug}_{run_id[:8]}"

    def resolve_target(self, topic: str, target: str | None = None) -> Path:
        """Resolve promotion target under docs root."""
        if target:
            return self._settings.resolved_docs_root / target
        slug = slugify(topic)
        return self._settings.resolved_docs_root / "_generated" / slug

    def promote(
        self,
        *,
        run_id: str,
        topic: str,
        target: str | None = None,
        dry_run: bool = True,
    ) -> PromotionResult:
        """Copy staging Markdown files to canonical docs location."""
        source = self.resolve_staging(run_id, topic)
        if not source.is_dir():
            raise FileNotFoundError(f"Staging output not found: {source}")

        destination = self.resolve_target(topic, target)
        md_files = sorted(source.rglob("*.md"))
        relative_paths = [str(p.relative_to(source)) for p in md_files]

        if dry_run:
            logger.info("DRY RUN: would copy %s -> %s (%d files)", source, destination, len(md_files))
            return PromotionResult(
                source=source,
                destination=destination,
                files_copied=relative_paths,
                dry_run=True,
            )

        destination.mkdir(parents=True, exist_ok=True)
        copied: list[str] = []
        for path in md_files:
            rel = path.relative_to(source)
            target_path = destination / rel
            target_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target_path)
            copied.append(str(rel))
            logger.info("Promoted %s", rel)

        return PromotionResult(
            source=source,
            destination=destination,
            files_copied=copied,
            dry_run=False,
        )
