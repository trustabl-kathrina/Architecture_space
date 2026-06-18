"""Shared utilities for Architecture_space documentation tooling."""

from __future__ import annotations

import re
from pathlib import Path

CODE_ROOT = Path(__file__).resolve().parent.parent
REPO_ROOT = CODE_ROOT.parent
DOCS_ROOT = REPO_ROOT / "docs"
TEMPLATES_ROOT = CODE_ROOT / "templates"

FRONT_MATTER_RE = re.compile(r"^---\s*\n.*?\n---\s*\n", re.DOTALL)
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")

VALID_STATUS = {"stub", "draft", "review", "complete", "archived"}
VALID_TEMPLATES = {"evaluation", "concept", "adr", "overview", "hub", "interview", "poc", "redirect"}

SECTION_DESCRIPTIONS: dict[str, str] = {
    "00_Architecture_Governance": "Architecture principles, reference architectures, ADRs, patterns, review checklists, NFRs, blueprints, standards, and strategy alignment.",
    "01_Data_Architecture": "Data architecture fundamentals, enterprise data architecture, mesh, fabric, lakehouse concepts, data products, metadata-driven architecture, and domain-driven design.",
    "02_Data_Engineering_Architecture": "Data ingestion, transformation, orchestration, observability, and reliability architecture.",
    "03_Data_Storage_Architecture": "Data lake, warehouse, lakehouse, marts, ODS, analytical stores, and storage design patterns.",
    "04_Cloud_Data_Platforms": "Cloud data platform services and reference implementations across GCP, AWS, and Azure.",
    "05_Data_Modeling_Architecture": "Conceptual, logical, physical, dimensional, Data Vault, canonical, semantic, TMF SID, and industry modeling.",
    "06_Data_Product_Architecture": "Data product lifecycle, design, SDP/ADP/CDP, marketplace, data contracts, and product governance.",
    "07_Data_Governance_And_Metadata": "Metadata management, catalog, lineage, quality, MDM, reference data, privacy, security, compliance, and governance operating model.",
    "08_Analytics_Architecture": "BI, semantic layer, real-time analytics, self-service analytics, dashboards, and analytics tools.",
    "09_Event_And_Streaming_Architecture": "Event-driven architecture, stream processing, CDC, cloud streaming services, open source engines, patterns, benchmarks, comparisons, and interview questions.",
    "10_Real_Time_Analytics_Architecture": "Real-time analytics engines, streaming analytics stores, serving patterns, and low-latency analytical workloads.",
    "11_AI_Data_Architecture": "AI-ready data platforms, feature stores, RAG, MCP, A2A, vector databases, prompt engineering, AI governance, AI observability, and AI FinOps.",
    "12_Agentic_AI_Architecture": "Agentic AI strategy, agent architecture, MCP/A2A, tool use, orchestration, AgentOps, multi-agent systems, and digital workforce architecture.",
    "13_MLOps_Architecture": "ML lifecycle, feature engineering, training, deployment, monitoring, and model governance.",
    "14_Security_And_Privacy_Architecture": "IAM, encryption, secrets management, RLS/CLS, zero trust, compliance, AI security, and privacy engineering.",
    "15_Industry_Reference_Architectures": "Telecom, banking, insurance, retail, healthcare, manufacturing, government, and other industry reference architectures.",
    "16_Architecture_Interview_Preparation": "Role-based architecture interview preparation, scenario questions, and study guides.",
    "17_Technology_Comparisons": "Technology comparisons, vendor evaluations, selection frameworks, scorecards, and benchmark summaries.",
    "19_Templates_And_Frameworks": "Architecture, HLD, LLD, data product, data contract, ADR, governance, and benchmark templates.",
    "20_Pluto_MIND": "Pluto MIND product architecture, Acquisition AI, Model AI, Transformation AI, Fluid Specification, data product builder, marketplace, governance, FinOps, and data quality.",
}


def section_number(name: str) -> str:
    return name.split("_", 1)[0]


def section_title(name: str) -> str:
    parts = name.split("_", 1)
    return parts[1].replace("_", " ") if len(parts) > 1 else name


def iter_markdown_files(root: Path | None = None) -> list[Path]:
    root = root or DOCS_ROOT
    return sorted(root.rglob("*.md"))


def has_front_matter(text: str) -> bool:
    normalized = text.replace("\r\n", "\n")
    return normalized.startswith("---\n") and "\n---\n" in normalized[4:]


def parse_front_matter(text: str) -> dict[str, str]:
    normalized = text.replace("\r\n", "\n")
    if not has_front_matter(normalized):
        return {}
    end = normalized.index("\n---\n", 4)
    block = normalized[4:end]
    data: dict[str, str] = {}
    for line in block.splitlines():
        if ":" in line:
            key, value = line.split(":", 1)
            data[key.strip()] = value.strip()
    return data


def strip_front_matter(text: str) -> str:
    normalized = text.replace("\r\n", "\n")
    if has_front_matter(normalized):
        return normalized[normalized.index("\n---\n", 4) + 5 :]
    return normalized


def is_complete_content(text: str) -> bool:
    body = strip_front_matter(text)
    if "Vendor A" in body and "Vendor B" in body:
        return False
    if "Use Case 1**: Description of how this is applied" in body:
        return False
    words = len(re.findall(r"\w+", body))
    return words > 400


def detect_template(path: Path, text: str) -> str:
    body = strip_front_matter(text)
    rel = path.as_posix().lower()
    if "/adr/" in rel or path.name.lower().startswith("adr_"):
        return "adr"
    if "what_is" in path.name.lower():
        return "overview"
    if "/hubs/" in rel or path.name.endswith("_Hub.md"):
        return "hub"
    if "## Core Concepts" in body or "## Expert Concepts" in body:
        return "concept"
    if re.search(r"^## \d+\. ", body, re.MULTILINE):
        return "evaluation"
    if "/overview/" in rel or path.parent.name.endswith("_Overview"):
        return "overview"
    if "Vendor A" in body:
        return "evaluation"
    return "overview"


def infer_section_id(path: Path) -> str:
    try:
        parts = path.relative_to(DOCS_ROOT).parts
    except ValueError:
        parts = path.parts
    for part in parts:
        match = re.match(r"^(\d{2}(?:\.\d{2}){0,3})", part)
        if match:
            return match.group(1)
    return section_number(parts[0]) if parts else "00"


def count_statuses(files: list[Path]) -> dict[str, int]:
    counts = {"complete": 0, "draft": 0, "review": 0, "stub": 0, "archived": 0}
    for path in files:
        text = path.read_text(encoding="utf-8")
        meta = parse_front_matter(text)
        status = meta.get("status", "stub")
        counts[status] = counts.get(status, 0) + 1
    return counts
