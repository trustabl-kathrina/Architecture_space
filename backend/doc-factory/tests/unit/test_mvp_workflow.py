"""Tests for multi-agent pipeline workflow."""

from doc_factory.agents.factory import build_documentation_workflow
from doc_factory.models.state import PIPELINE_AGENT_ORDER


def test_build_pipeline_workflow(settings) -> None:
    workflow = build_documentation_workflow(settings)
    assert workflow.name == "documentation_factory_pipeline"
    assert workflow.graph is not None
    node_names = {node.name for node in workflow.graph.nodes}
    for agent_name in PIPELINE_AGENT_ORDER:
        if agent_name == "markdown_publisher":
            continue
        assert agent_name in node_names
