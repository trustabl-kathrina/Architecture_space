"""Render TechnologyBenchmarkEvaluation as enterprise Markdown tables."""

from __future__ import annotations

from doc_factory.models.benchmark import (
    SCORING_CATEGORIES,
    TechnologyBenchmarkEvaluation,
    normalize_weights,
)
from doc_factory.models.mvp import MarkdownSection


class BenchmarkMarkdownRenderer:
    """Convert structured benchmark evaluation to Markdown documentation."""

    def render_section(self, evaluation: TechnologyBenchmarkEvaluation) -> MarkdownSection:
        body = self.render_markdown(evaluation)
        return MarkdownSection(
            section_id="benchmarks",
            title=f"{evaluation.topic} — Technology Benchmark & Comparison",
            filename="benchmark_evaluation.md",
            content_markdown=body,
        )

    def render_markdown(self, evaluation: TechnologyBenchmarkEvaluation) -> str:
        weights = normalize_weights(evaluation.scoring_weights)
        ranked = sorted(evaluation.technology_scores, key=lambda t: t.rank)
        winner = ranked[0] if ranked else None

        parts: list[str] = [
            f"# {evaluation.topic} — Benchmark & Technology Comparison",
            "",
            "## Executive Summary",
            "",
            evaluation.final_recommendation,
            "",
            f"**Recommended technology:** {evaluation.recommended_technology}  ",
            f"**Confidence:** {evaluation.confidence}",
            "",
            "## Competing Technologies",
            "",
            self._bullet_list(evaluation.competing_technologies),
            "",
            "## Comparison Matrix",
            "",
            self._comparison_matrix_table(evaluation),
            "",
            "## Scoring Framework",
            "",
            "Weighted scoring categories used for enterprise technology selection:",
            "",
            self._scoring_weights_table(evaluation.scoring_weights, weights),
            "",
            "## Weighted Scores",
            "",
            self._weighted_scores_table(ranked),
            "",
            "## Score Detail Matrix",
            "",
            self._score_detail_table(ranked),
            "",
            "## Decision Criteria",
            "",
            self._decision_criteria_table(evaluation),
            "",
            "## Enterprise Adoption Analysis",
            "",
            evaluation.enterprise_adoption_analysis,
            "",
            "## Scalability Analysis",
            "",
            evaluation.scalability_analysis,
            "",
            "## Performance Analysis",
            "",
            evaluation.performance_analysis,
            "",
            "## Operational Complexity Analysis",
            "",
            evaluation.operational_complexity_analysis,
            "",
            "## Cost Analysis",
            "",
            evaluation.cost_analysis,
            "",
            "## Best-Fit Scenarios",
            "",
            self._best_fit_table(evaluation),
            "",
            "## Final Recommendation",
            "",
            evaluation.final_recommendation,
            "",
        ]

        if winner:
            parts.extend(
                [
                    "### Ranking Summary",
                    "",
                    self._ranking_table(ranked),
                    "",
                ]
            )

        return "\n".join(parts)

    @staticmethod
    def _bullet_list(items: list[str]) -> str:
        return "\n".join(f"- {item}" for item in items)

    @staticmethod
    def _escape_cell(value: str) -> str:
        return value.replace("|", "\\|").replace("\n", " ")

    def _comparison_matrix_table(self, evaluation: TechnologyBenchmarkEvaluation) -> str:
        techs = evaluation.competing_technologies
        header = "| Dimension | " + " | ".join(techs) + " |"
        sep = "| --- | " + " | ".join("---" for _ in techs) + " |"
        rows = [header, sep]
        for row in evaluation.comparison_matrix:
            cells = [self._escape_cell(row.dimension)]
            for tech in techs:
                cells.append(self._escape_cell(row.ratings.get(tech, "N/A")))
            rows.append("| " + " | ".join(cells) + " |")
        return "\n".join(rows)

    def _scoring_weights_table(
        self,
        weights: list,
        normalized: dict[str, float],
    ) -> str:
        rows = [
            "| Category | Weight | Normalized | Rationale |",
            "| --- | ---: | ---: | --- |",
        ]
        for item in weights:
            norm = normalized.get(item.category, item.weight)
            rows.append(
                f"| {item.category} | {item.weight:.2f} | {norm:.2f} | "
                f"{self._escape_cell(item.rationale)} |"
            )
        rows.append(f"| **Total** | **{sum(w.weight for w in weights):.2f}** | **1.00** | |")
        return "\n".join(rows)

    def _weighted_scores_table(self, ranked: list) -> str:
        rows = [
            "| Rank | Technology | Weighted Score (0-10) | Summary |",
            "| ---: | --- | ---: | --- |",
        ]
        for tech in ranked:
            rows.append(
                f"| {tech.rank} | {tech.technology} | **{tech.weighted_total:.2f}** | "
                f"{self._escape_cell(tech.summary)} |"
            )
        return "\n".join(rows)

    def _score_detail_table(self, ranked: list) -> str:
        techs = [t.technology for t in ranked]
        header = "| Category | " + " | ".join(techs) + " |"
        sep = "| --- | " + " | ".join("---:" for _ in techs) + " |"
        rows = [header, sep]
        for category in SCORING_CATEGORIES:
            cells = [category]
            for tech in ranked:
                cells.append(f"{tech.scores.get(category, 0.0):.1f}")
            rows.append("| " + " | ".join(cells) + " |")
        return "\n".join(rows)

    def _decision_criteria_table(self, evaluation: TechnologyBenchmarkEvaluation) -> str:
        rows = [
            "| Criterion | Priority | Description |",
            "| --- | --- | --- |",
        ]
        for criterion in evaluation.decision_criteria:
            rows.append(
                f"| {self._escape_cell(criterion.name)} | {criterion.priority} | "
                f"{self._escape_cell(criterion.description)} |"
            )
        return "\n".join(rows)

    def _best_fit_table(self, evaluation: TechnologyBenchmarkEvaluation) -> str:
        rows = [
            "| Scenario | Recommended | Alternatives | Rationale |",
            "| --- | --- | --- | --- |",
        ]
        for scenario in evaluation.best_fit_scenarios:
            alts = ", ".join(scenario.alternatives) if scenario.alternatives else "—"
            rows.append(
                f"| {self._escape_cell(scenario.scenario)} | "
                f"{scenario.recommended_technology} | {self._escape_cell(alts)} | "
                f"{self._escape_cell(scenario.rationale)} |"
            )
        return "\n".join(rows)

    def _ranking_table(self, ranked: list) -> str:
        rows = [
            "| Rank | Technology | Weighted Score |",
            "| ---: | --- | ---: |",
        ]
        for tech in ranked:
            marker = " **(Recommended)**" if tech.rank == 1 else ""
            rows.append(
                f"| {tech.rank} | {tech.technology}{marker} | {tech.weighted_total:.2f} |"
            )
        return "\n".join(rows)
