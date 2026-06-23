"""Backward-compatible workflow module — delegates to agents.factory."""

from doc_factory.agents.factory import build_documentation_workflow, root_agent

build_mvp_workflow = build_documentation_workflow

__all__ = ["build_mvp_workflow", "build_documentation_workflow", "root_agent"]
