"""Tests for benchmark evaluation models and Markdown renderer."""

from doc_factory.agents.generation.benchmark_agent import finalize_benchmark_output
from doc_factory.models.benchmark import (
    SCORING_CATEGORIES,
    BestFitScenario,
    ComparisonMatrixRow,
    DecisionCriterion,
    ScoringWeight,
    TechnologyBenchmarkEvaluation,
    TechnologyScore,
    apply_computed_rankings,
    compute_weighted_total,
)


def _flink_weights() -> list[ScoringWeight]:
    return [
        ScoringWeight(category=cat, weight=0.10, rationale=f"Weight for {cat}")
        for cat in SCORING_CATEGORIES
    ]


def _flink_scores(tech: str, base: float) -> TechnologyScore:
    scores = {cat: min(10.0, base + (i % 3)) for i, cat in enumerate(SCORING_CATEGORIES)}
    return TechnologyScore(
        technology=tech,
        scores=scores,
        weighted_total=0.0,
        rank=1,
        summary=f"{tech} enterprise stream processing option.",
    )


def _sample_flink_evaluation() -> TechnologyBenchmarkEvaluation:
    techs = [
        "Apache Flink",
        "Apache Spark Structured Streaming",
        "Kafka Streams",
        "Google Cloud Dataflow",
    ]
    return TechnologyBenchmarkEvaluation(
        topic="Apache Flink",
        competing_technologies=techs,
        scoring_weights=_flink_weights(),
        technology_scores=[
            _flink_scores("Apache Flink", 8.5),
            _flink_scores("Apache Spark Structured Streaming", 7.5),
            _flink_scores("Kafka Streams", 7.0),
            _flink_scores("Google Cloud Dataflow", 7.8),
        ],
        comparison_matrix=[
            ComparisonMatrixRow(
                dimension="Exactly-once semantics",
                ratings={t: "Strong" if "Flink" in t else "Moderate" for t in techs},
            ),
            ComparisonMatrixRow(
                dimension="Stateful processing",
                ratings={t: "Native" if t == "Apache Flink" else "Varies" for t in techs},
            ),
            ComparisonMatrixRow(
                dimension="Managed cloud offering",
                ratings={
                    "Apache Flink": "Partial",
                    "Apache Spark Structured Streaming": "Partial",
                    "Kafka Streams": "Self-managed",
                    "Google Cloud Dataflow": "Fully managed",
                },
            ),
            ComparisonMatrixRow(
                dimension="Operational complexity",
                ratings={t: "Medium" for t in techs},
            ),
            ComparisonMatrixRow(
                dimension="Latency profile",
                ratings={t: "Low" if "Flink" in t or "Kafka" in t else "Medium" for t in techs},
            ),
            ComparisonMatrixRow(
                dimension="Ecosystem integrations",
                ratings={t: "Broad" for t in techs},
            ),
            ComparisonMatrixRow(
                dimension="Cost at scale",
                ratings={t: "Medium" for t in techs},
            ),
            ComparisonMatrixRow(
                dimension="Enterprise adoption",
                ratings={t: "High" if "Flink" in t or "Spark" in t else "Medium" for t in techs},
            ),
        ],
        decision_criteria=[
            DecisionCriterion(
                name="Latency SLA",
                description="Sub-second end-to-end processing",
                priority="critical",
            ),
            DecisionCriterion(
                name="State size",
                description="Large keyed state with checkpoint recovery",
                priority="high",
            ),
            DecisionCriterion(
                name="Cloud strategy",
                description="GCP alignment and managed services",
                priority="high",
            ),
            DecisionCriterion(
                name="Team skills",
                description="Java/Scala streaming expertise",
                priority="medium",
            ),
            DecisionCriterion(
                name="TCO",
                description="3-year infrastructure and operations cost",
                priority="high",
            ),
        ],
        enterprise_adoption_analysis="Flink is widely adopted for real-time analytics.",
        scalability_analysis="Flink scales horizontally with task managers.",
        performance_analysis="Low latency with Chandy-Lamport checkpoints.",
        operational_complexity_analysis="Requires cluster operations expertise.",
        cost_analysis="Self-managed Flink has infra + ops TCO.",
        best_fit_scenarios=[
            BestFitScenario(
                scenario="Real-time fraud detection",
                recommended_technology="Apache Flink",
                rationale="Low latency and strong state",
                alternatives=["Kafka Streams"],
            ),
            BestFitScenario(
                scenario="Batch + stream unified lakehouse",
                recommended_technology="Apache Spark Structured Streaming",
                rationale="Unified batch API",
                alternatives=["Apache Flink"],
            ),
            BestFitScenario(
                scenario="Kafka-native microservices",
                recommended_technology="Kafka Streams",
                rationale="No separate cluster",
                alternatives=["Apache Flink"],
            ),
            BestFitScenario(
                scenario="GCP managed streaming",
                recommended_technology="Google Cloud Dataflow",
                rationale="Serverless Beam runner",
                alternatives=["Apache Flink"],
            ),
        ],
        final_recommendation="Apache Flink is the best fit for complex stateful streaming.",
        recommended_technology="Apache Flink",
        confidence="high",
    )


def test_compute_weighted_total() -> None:
    weights = {cat: 0.10 for cat in SCORING_CATEGORIES}
    scores = {cat: 8.0 for cat in SCORING_CATEGORIES}
    assert compute_weighted_total(scores, weights) == 8.0


def test_apply_computed_rankings_orders_flink_first() -> None:
    evaluation = apply_computed_rankings(_sample_flink_evaluation())
    ranked = sorted(evaluation.technology_scores, key=lambda t: t.rank)
    assert ranked[0].technology == "Apache Flink"
    assert ranked[0].weighted_total >= ranked[1].weighted_total


def test_benchmark_renderer_produces_markdown_tables() -> None:
    evaluation = apply_computed_rankings(_sample_flink_evaluation())
    output = finalize_benchmark_output(evaluation)
    md = output.section.content_markdown

    assert "## Comparison Matrix" in md
    assert "## Weighted Scores" in md
    assert "## Scoring Framework" in md
    assert "## Best-Fit Scenarios" in md
    assert "| Apache Flink |" in md
    assert "Scalability" in md
    assert "Security" in md
    assert output.evaluation.recommended_technology == "Apache Flink"


def test_finalize_benchmark_output_section_filename() -> None:
    evaluation = apply_computed_rankings(_sample_flink_evaluation())
    output = finalize_benchmark_output(evaluation)
    assert output.section.filename == "benchmark_evaluation.md"
    assert output.section.section_id == "benchmarks"
