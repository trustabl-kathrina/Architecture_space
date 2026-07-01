"""CLI entrypoint for Documentation AI Factory."""

from __future__ import annotations

import asyncio

import click

from doc_factory.config.logging import configure_logging
from doc_factory.config.settings import get_settings
from doc_factory.services.benchmark_runner import run_benchmark
from doc_factory.services.errors import PipelineError
from doc_factory.services.pipeline_runner import run_pipeline as execute_pipeline
from doc_factory.services.run_repository import RunRepository


@click.group()
@click.version_option(package_name="documentation-ai-factory")
def cli() -> None:
    """Local-first AI documentation and research platform for Architecture Space."""


@cli.command("benchmark")
@click.argument("topic")
@click.option(
    "--output",
    "output_dir",
    default=None,
    type=click.Path(),
    help="Output directory for benchmark Markdown and JSON.",
)
def benchmark(topic: str, output_dir: str | None) -> None:
    """Run the Benchmark Agent: weighted scoring and comparison tables."""
    from pathlib import Path

    settings = get_settings()
    configure_logging(settings)

    try:
        result = asyncio.run(
            run_benchmark(topic, output_dir=Path(output_dir) if output_dir else None)
        )
    except PipelineError as exc:
        raise click.ClickException(str(exc)) from exc

    click.echo(f"Topic:        {result.topic}")
    click.echo(f"Recommended:  {result.evaluation.recommended_technology}")
    click.echo(f"Confidence:   {result.evaluation.confidence}")
    click.echo(f"Technologies: {', '.join(result.evaluation.competing_technologies)}")
    click.echo(f"Output file:  {result.section.filename}")
    winner = min(result.evaluation.technology_scores, key=lambda t: t.rank)
    click.echo(f"Top score:    {winner.technology} ({winner.weighted_total:.2f}/10)")


@cli.command("generate")
@click.argument("topic")
@click.option("--run-id", default=None, help="Optional existing run ID to resume/reuse.")
def generate(topic: str, run_id: str | None) -> None:
    """Run the full multi-agent pipeline and publish Markdown."""
    settings = get_settings()
    configure_logging(settings)

    try:
        result = asyncio.run(execute_pipeline(topic, run_id=run_id))
    except PipelineError as exc:
        raise click.ClickException(str(exc)) from exc

    click.echo(f"Run ID:     {result.run_id}")
    click.echo(f"Topic:      {result.topic}")
    click.echo(f"Sections:   {len(result.reviewer_output.final_sections)}")
    click.echo(f"Sources:    {len(result.research_output.sources)}")
    click.echo(f"Approved:   {result.reviewer_output.approved}")
    click.echo(f"Score:      {result.reviewer_output.overall_score:.1f}/100")
    click.echo(f"Files:      {len(result.publish_manifest.files)}")
    click.echo(f"Output dir: {result.output_dir}")


@cli.command("new")
@click.argument("topic")
def new_run(topic: str) -> None:
    """Create a new documentation run (does not execute the pipeline)."""
    repo = RunRepository()
    run_id, run_dir, _ = repo.create_run(topic)
    click.echo(f"Created run {run_id}")
    click.echo(f"Run dir: {run_dir}")
    click.echo(f"Execute: doc-factory run {run_id}")


@cli.command("run")
@click.argument("run_id")
def run_pipeline(run_id: str) -> None:
    """Execute the multi-agent pipeline for an existing run."""
    repo = RunRepository()
    manifest = repo.load_manifest(run_id)
    settings = get_settings()
    configure_logging(settings)

    try:
        result = asyncio.run(execute_pipeline(manifest.topic, run_id=run_id))
    except PipelineError as exc:
        raise click.ClickException(str(exc)) from exc

    click.echo(f"Completed run {result.run_id}")
    click.echo(f"Approved:   {result.reviewer_output.approved}")
    click.echo(f"Output dir: {result.output_dir}")


@cli.command("resume")
@click.argument("run_id")
def resume_run(run_id: str) -> None:
    """Resume/re-run a pipeline for an existing run ID."""
    ctx = click.get_current_context()
    ctx.invoke(run_pipeline, run_id=run_id)


@cli.command("status")
@click.argument("run_id", required=False)
def show_status(run_id: str | None) -> None:
    """Show status for one run or list recent runs."""
    repo = RunRepository()
    if run_id:
        manifest = repo.load_manifest(run_id)
        click.echo(f"run_id:        {manifest.run_id}")
        click.echo(f"topic:         {manifest.topic}")
        click.echo(f"status:        {manifest.status}")
        click.echo(f"current_phase: {manifest.current_phase}")
        click.echo(f"created_at:    {manifest.created_at}")
        click.echo(f"updated_at:    {manifest.updated_at}")
        state_dir = repo.get_run_dir(run_id) / "state"
        if state_dir.is_dir():
            artifacts = sorted(p.name for p in state_dir.glob("*.json"))
            if artifacts:
                click.echo("artifacts:")
                for name in artifacts:
                    click.echo(f"  - {name}")
        return

    runs = repo.list_runs()
    if not runs:
        click.echo("No runs found.")
        return
    for manifest in runs:
        click.echo(
            f"{manifest.run_id[:8]}  {manifest.status:12}  "
            f"{manifest.current_phase:10}  {manifest.topic}"
        )


@cli.command("export")
@click.argument("run_id")
def export_run(run_id: str) -> None:
    """Re-export Markdown from saved reviewer_output artifacts."""
    from doc_factory.models.pipeline import ReviewerAgentOutput
    from doc_factory.services.artifact_store import ArtifactStore
    from doc_factory.services.markdown_publisher import MarkdownPublisher
    from doc_factory.services.run_repository import RunRepository, slugify

    settings = get_settings()
    repo = RunRepository()
    manifest = repo.load_manifest(run_id)
    store = ArtifactStore(repo.get_run_dir(run_id))
    reviewer_output = store.read_model("reviewer", ReviewerAgentOutput)
    slug = slugify(manifest.topic)
    output_dir = settings.resolved_output_dir / f"{slug}_{run_id[:8]}"
    manifest_out = MarkdownPublisher(settings).publish(
        run_id=run_id,
        reviewer_output=reviewer_output,
        output_dir=output_dir,
    )
    click.echo(f"Exported {len(manifest_out.files)} files to {output_dir}")


@cli.command("promote")
@click.argument("run_id")
@click.option(
    "--dry-run",
    is_flag=True,
    default=True,
    help="Preview promotion without writing to docs/.",
)
@click.option("--target", default=None, help="Target directory under docs/ (relative).")
def promote_run(run_id: str, dry_run: bool, target: str | None) -> None:
    """Promote staging output into canonical docs/ (after human review)."""
    settings = get_settings()
    repo = RunRepository()
    manifest = repo.load_manifest(run_id)
    slug = manifest.topic.lower().replace(" ", "_")[:40]
    staging = settings.resolved_output_dir / f"{slug}_{run_id[:8]}"
    if not staging.is_dir():
        raise click.ClickException(f"Staging output not found: {staging}")

    dest = settings.resolved_docs_root / (target or f"_generated/{slug}")
    if dry_run:
        click.echo(f"DRY RUN: would copy {staging} -> {dest}")
        for path in sorted(staging.rglob("*.md")):
            click.echo(f"  {path.relative_to(staging)}")
        return

    import shutil

    dest.mkdir(parents=True, exist_ok=True)
    for path in staging.rglob("*.md"):
        rel = path.relative_to(staging)
        target_path = dest / rel
        target_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target_path)
    click.echo(f"Promoted to {dest}")


if __name__ == "__main__":
    cli()
