"""Tests for MVP Pydantic schemas."""

from doc_factory.models.mvp import PlannerAgentOutput, SectionPlan


def test_planner_output_validation() -> None:
    plan = PlannerAgentOutput(
        topic="Data Mesh",
        topic_summary="Decentralized data ownership model.",
        objectives=["Explain principles", "Show architecture"],
        sections=[
            SectionPlan(
                section_id="overview",
                title="Overview",
                description="Intro",
                headings=["Definition", "Scope"],
            ),
            SectionPlan(
                section_id="architecture",
                title="Architecture",
                description="Components",
                headings=["Components", "Data Flow"],
            ),
            SectionPlan(
                section_id="scenarios",
                title="Scenarios",
                description="Use cases",
                headings=["Enterprise", "Patterns"],
            ),
            SectionPlan(
                section_id="implementation",
                title="Implementation",
                description="How to",
                headings=["Steps", "Examples"],
            ),
        ],
        research_queries=["q1", "q2", "q3", "q4"],
        research_plan="Research architecture patterns first.",
    )
    assert plan.topic == "Data Mesh"
    assert len(plan.sections) == 4
