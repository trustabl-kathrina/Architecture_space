#!/usr/bin/env python3
"""Renumber Feature Store Architecture markdown files with sequential prefixes."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs/08_MLOps_Architecture/08.05_Feature_Store_Architecture"

STRUCTURE: dict[str, list[str]] = {
    "01_Fundamentals": [
        "What_Is_Feature_Store",
        "Why_Feature_Store",
        "Online_vs_Offline",
        "Training_Serving_Skew",
    ],
    "02_Core_Concepts": [
        "Entities",
        "Features",
        "Feature_Groups",
        "Feature_Sets",
        "Feature_Views",
        "Feature_Registry",
    ],
    "03_Architectural_Patterns": [
        "Batch_Feature_Store",
        "Realtime_Feature_Store",
        "Hybrid_Feature_Store",
        "Streaming_Feature_Store",
        "Data_Mesh_Feature_Store",
    ],
    "04_Storage_Architecture": [
        "BigQuery",
        "Redis",
        "Cassandra",
        "Bigtable",
        "PostgreSQL",
    ],
    "05_Feature_Engineering": [
        "Batch_Features",
        "Streaming_Features",
        "Aggregation_Patterns",
        "Time_Window_Features",
    ],
    "06_Feature_Governance": [
        "Metadata",
        "Lineage",
        "Quality",
        "Ownership",
        "Cataloging",
    ],
    "07_Cloud_Implementations": [
        "Vertex_AI_Feature_Store",
        "Feast",
        "Tecton",
        "Databricks_Feature_Store",
        "SageMaker_Feature_Store",
    ],
    "08_Enterprise_Patterns": [
        "Telecom_Use_Cases",
        "Recommendation_Engine",
        "Fraud_Detection",
        "Customer_360",
        "Churn_Prediction",
    ],
    "09_POCs_And_Benchmarking": [
        "Feast_on_GCP",
        "Feast_vs_Vertex",
        "Redis_Benchmark",
        "Bigtable_Benchmark",
    ],
    "10_Reference_Architectures": [
        "GCP_Reference",
        "AWS_Reference",
        "Azure_Reference",
        "Multi_Cloud",
    ],
}

MODULE = "08.05"


def build_rename_map() -> dict[str, str]:
    """Map old filename (with .md) to new filename."""
    mapping: dict[str, str] = {}
    for folder, stems in STRUCTURE.items():
        for idx, stem in enumerate(stems, start=1):
            old_name = f"{stem}.md"
            new_name = f"{idx:02d}_{stem}.md"
            mapping[old_name] = new_name
    return mapping


def replace_links(content: str, rename_map: dict[str, str]) -> str:
    def sub_link(match: re.Match[str]) -> str:
        prefix, path, suffix = match.group(1), match.group(2), match.group(3)
        parts = path.split("/")
        filename = parts[-1]
        if filename in rename_map:
            parts[-1] = rename_map[filename]
            path = "/".join(parts)
        return f"{prefix}{path}{suffix}"

    return re.sub(r"(\[.*?\]\()([^)]+?)(\.md\))", sub_link, content)


def main() -> None:
    rename_map = build_rename_map()

    # Rename files (use temp names first to avoid collisions)
    for folder, stems in STRUCTURE.items():
        folder_path = ROOT / folder
        for idx, stem in enumerate(stems, start=1):
            old_path = folder_path / f"{stem}.md"
            new_path = folder_path / f"{idx:02d}_{stem}.md"
            if not old_path.exists():
                if new_path.exists():
                    continue
                raise FileNotFoundError(old_path)
            temp_path = folder_path / f"__tmp_{idx:02d}_{stem}.md"
            old_path.rename(temp_path)

    for folder, stems in STRUCTURE.items():
        folder_path = ROOT / folder
        for idx, stem in enumerate(stems, start=1):
            temp_path = folder_path / f"__tmp_{idx:02d}_{stem}.md"
            new_path = folder_path / f"{idx:02d}_{stem}.md"
            if temp_path.exists():
                temp_path.rename(new_path)

    # Update links and section IDs in all markdown under module
    md_files = list(ROOT.rglob("*.md"))
    parent_readme = ROOT.parent / "README.md"
    if parent_readme.exists():
        md_files.append(parent_readme)

    for path in md_files:
        content = path.read_text(encoding="utf-8")
        updated = replace_links(content, rename_map)
        if path.is_relative_to(ROOT) and path.name != "README.md":
            folder = path.parent.name
            if folder in STRUCTURE:
                stem = path.stem
                if stem.startswith(tuple(f"{i:02d}_" for i in range(1, 100))):
                    base_stem = stem[3:]  # strip NN_
                else:
                    base_stem = stem
                if base_stem in STRUCTURE[folder]:
                    idx = STRUCTURE[folder].index(base_stem) + 1
                    folder_num = folder.split("_")[0]
                    section = f'{MODULE}.{folder_num}.{idx:02d}'
                    updated = re.sub(
                        r'^section: "08\.05\.\d+\.\d+"',
                        f'section: "{section}"',
                        updated,
                        count=1,
                        flags=re.MULTILINE,
                    )
        if updated != content:
            path.write_text(updated, encoding="utf-8")
            print(f"Updated links: {path.relative_to(ROOT.parents[1])}")

    print("\nRenamed files:")
    for folder, stems in STRUCTURE.items():
        for idx, stem in enumerate(stems, start=1):
            print(f"  {folder}/{idx:02d}_{stem}.md")


if __name__ == "__main__":
    main()
