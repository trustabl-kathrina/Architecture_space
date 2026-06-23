"""Technology benchmark and comparison evaluation models."""

from __future__ import annotations

from typing import Final

from pydantic import BaseModel, Field, field_validator

from doc_factory.models.mvp import MarkdownSection

SCORING_CATEGORIES: Final[tuple[str, ...]] = (
    "Scalability",
    "Performance",
    "Cost",
    "Ecosystem",
    "Learning Curve",
    "Cloud Support",
    "Enterprise Adoption",
    "Governance",
    "Monitoring",
    "Security",
)

DEFAULT_SCORING_WEIGHTS: Final[dict[str, float]] = {
    "Scalability": 0.12,
    "Performance": 0.14,
    "Cost": 0.10,
    "Ecosystem": 0.10,
    "Learning Curve": 0.08,
    "Cloud Support": 0.10,
    "Enterprise Adoption": 0.12,
    "Governance": 0.08,
    "Monitoring": 0.08,
    "Security": 0.08,
}


class ScoringWeight(BaseModel):
    """Weight for one scoring category (must sum to 1.0 across all categories)."""

    category: str
    weight: float = Field(ge=0.0, le=1.0)
    rationale: str = ""


class TechnologyScore(BaseModel):
    """Weighted scores for one competing technology."""

    technology: str
    scores: dict[str, float] = Field(
        description="Category name -> score 0-10",
    )
    weighted_total: float = Field(ge=0.0, le=10.0)
    rank: int = Field(ge=1)
    summary: str = ""

    @field_validator("scores")
    @classmethod
    def validate_categories(cls, value: dict[str, float]) -> dict[str, float]:
        for category in SCORING_CATEGORIES:
            if category not in value:
                raise ValueError(f"Missing score for category: {category}")
        return value


class ComparisonMatrixRow(BaseModel):
    """One row in the capability comparison matrix."""

    dimension: str
    ratings: dict[str, str] = Field(description="technology -> rating label or note")


class DecisionCriterion(BaseModel):
    """Enterprise decision criterion."""

    name: str
    description: str
    priority: str = Field(description="critical, high, medium, or low")


class BestFitScenario(BaseModel):
    """Scenario-based technology recommendation."""

    scenario: str
    recommended_technology: str
    rationale: str
    alternatives: list[str] = Field(default_factory=list)


class TechnologyBenchmarkEvaluation(BaseModel):
    """Full structured benchmark evaluation for a technology topic."""

    topic: str
    competing_technologies: list[str] = Field(min_length=3, max_length=8)
    scoring_weights: list[ScoringWeight] = Field(min_length=10, max_length=10)
    technology_scores: list[TechnologyScore] = Field(min_length=3)
    comparison_matrix: list[ComparisonMatrixRow] = Field(min_length=8)
    decision_criteria: list[DecisionCriterion] = Field(min_length=5)
    enterprise_adoption_analysis: str
    scalability_analysis: str
    performance_analysis: str
    operational_complexity_analysis: str
    cost_analysis: str
    best_fit_scenarios: list[BestFitScenario] = Field(min_length=4)
    final_recommendation: str
    recommended_technology: str
    confidence: str = Field(description="high, medium, or low")


class BenchmarkAgentOutput(BaseModel):
    """Benchmark Agent output with evaluation and rendered Markdown section."""

    topic: str
    evaluation: TechnologyBenchmarkEvaluation
    section: MarkdownSection
    methodology: str = ""
    benchmark_notes: str = ""


def compute_weighted_total(
    scores: dict[str, float],
    weights: dict[str, float],
) -> float:
    """Compute weighted average score on 0-10 scale."""
    total_weight = sum(weights.values())
    if total_weight <= 0:
        return 0.0
    weighted = sum(scores.get(cat, 0.0) * weights.get(cat, 0.0) for cat in SCORING_CATEGORIES)
    return round(weighted / total_weight, 2)


def normalize_weights(weights: list[ScoringWeight]) -> dict[str, float]:
    """Return category -> weight dict normalized to sum 1.0."""
    raw = {w.category: w.weight for w in weights}
    total = sum(raw.values())
    if total <= 0:
        return dict(DEFAULT_SCORING_WEIGHTS)
    return {k: round(v / total, 4) for k, v in raw.items()}


def apply_computed_rankings(
    evaluation: TechnologyBenchmarkEvaluation,
) -> TechnologyBenchmarkEvaluation:
    """Recompute weighted totals and ranks from scores and weights."""
    weight_map = normalize_weights(evaluation.scoring_weights)
    updated_scores: list[TechnologyScore] = []
    for tech in evaluation.technology_scores:
        total = compute_weighted_total(tech.scores, weight_map)
        updated_scores.append(tech.model_copy(update={"weighted_total": total}))
    ranked = sorted(updated_scores, key=lambda t: t.weighted_total, reverse=True)
    ranked_with_rank = [
        tech.model_copy(update={"rank": index}) for index, tech in enumerate(ranked, start=1)
    ]
    return evaluation.model_copy(update={"technology_scores": ranked_with_rank})
