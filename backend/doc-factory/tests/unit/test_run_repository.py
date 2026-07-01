"""Tests for run repository."""

from doc_factory.services.run_repository import RunRepository, slugify


def test_slugify() -> None:
    assert slugify("Apache Kafka") == "apache_kafka"
    assert slugify("Data Mesh!!!") == "data_mesh"


def test_create_and_list_run(settings) -> None:
    repo = RunRepository(settings)
    run_id, run_dir, store = repo.create_run("Data Mesh")
    assert run_dir.is_dir()
    manifest = repo.load_manifest(run_id)
    assert manifest.topic == "Data Mesh"
    assert manifest.status == "pending"
    store.write_json("probe", {"ok": True})
    runs = repo.list_runs(limit=5)
    assert any(r.run_id == run_id for r in runs)
