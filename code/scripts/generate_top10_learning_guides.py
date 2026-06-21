#!/usr/bin/env python3
"""Generate Top 10 open-source orchestration learning guides (no cloud PaaS)."""
import os
import shutil

BASE = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "..", "docs",
                 "02_Data_Engineering_Architecture",
                 "02.03_Data_Orchestration_Architecture", "02.03.03_Top_10")
)

# Open-source / self-hosted only — cloud managed services live in 02.03.02_Cloud_Services
TECHS = [
    {"id": "02.03.03.02", "folder": "02.03.03.02_Apache_Airflow_Learning_Guide", "rank": 1,
     "name": "Apache Airflow", "short": "Airflow", "section": "02.03.03.02",
     "tags": "airflow, open-source",
     "desc": "the de facto open source DAG orchestrator for batch data pipelines",
     "prereq": "Python 3.9+, basic DAG concepts",
     "docs": "https://airflow.apache.org/docs/", "pricing": "https://airflow.apache.org/",
     "category": "Open source DAG orchestrator"},
    {"id": "02.03.03.03", "folder": "02.03.03.03_Prefect_Learning_Guide", "rank": 2,
     "name": "Prefect", "short": "Prefect", "section": "02.03.03.03",
     "tags": "prefect, open-source",
     "desc": "a modern Python-native workflow engine with self-hosted agents and optional Prefect Cloud",
     "prereq": "Python 3.9+",
     "docs": "https://docs.prefect.io/", "pricing": "https://www.prefect.io/pricing",
     "category": "Open source Python orchestration"},
    {"id": "02.03.03.04", "folder": "02.03.03.04_Dagster_Learning_Guide", "rank": 3,
     "name": "Dagster", "short": "Dagster", "section": "02.03.03.04",
     "tags": "dagster, open-source, assets",
     "desc": "an asset-centric orchestrator with software-defined assets, partitions, and built-in lineage",
     "prereq": "Python, data pipeline concepts",
     "docs": "https://docs.dagster.io/", "pricing": "https://dagster.io/pricing",
     "category": "Open source asset orchestrator"},
    {"id": "02.03.03.05", "folder": "02.03.03.05_Temporal_Learning_Guide", "rank": 4,
     "name": "Temporal", "short": "Temporal", "section": "02.03.03.05",
     "tags": "temporal, durable-execution, open-source",
     "desc": "a durable execution platform for fault-tolerant, long-running workflows (self-host or Temporal Cloud)",
     "prereq": "Go/Java/Python/TypeScript SDK basics",
     "docs": "https://docs.temporal.io/", "pricing": "https://temporal.io/pricing",
     "category": "Durable execution (open source core)"},
    {"id": "02.03.03.06", "folder": "02.03.03.06_Argo_Workflows_Learning_Guide", "rank": 5,
     "name": "Argo Workflows", "short": "Argo", "section": "02.03.03.06",
     "tags": "argo, kubernetes, cncf, open-source",
     "desc": "a CNCF Kubernetes-native workflow engine for containerized batch and ML pipelines",
     "prereq": "Kubernetes, containers",
     "docs": "https://argo-workflows.readthedocs.io/", "pricing": "https://argo-workflows.readthedocs.io/",
     "category": "Kubernetes-native workflows"},
    {"id": "02.03.03.07", "folder": "02.03.03.07_Kestra_Learning_Guide", "rank": 6,
     "name": "Kestra", "short": "Kestra", "section": "02.03.03.07",
     "tags": "kestra, open-source, yaml",
     "desc": "an open source declarative orchestrator with YAML flows, plugins, and a built-in UI",
     "prereq": "YAML, Docker or Kubernetes",
     "docs": "https://kestra.io/docs/", "pricing": "https://kestra.io/pricing",
     "category": "Declarative open source orchestrator"},
    {"id": "02.03.03.08", "folder": "02.03.03.08_Flyte_Learning_Guide", "rank": 7,
     "name": "Flyte", "short": "Flyte", "section": "02.03.03.08",
     "tags": "flyte, kubernetes, ml, open-source",
     "desc": "a Kubernetes-native workflow platform for data and ML pipelines with strong typing and caching",
     "prereq": "Python, Kubernetes basics",
     "docs": "https://docs.flyte.org/", "pricing": "https://union.ai/pricing",
     "category": "K8s data/ML orchestrator"},
    {"id": "02.03.03.09", "folder": "02.03.03.09_Luigi_Learning_Guide", "rank": 8,
     "name": "Luigi", "short": "Luigi", "section": "02.03.03.09",
     "tags": "luigi, spotify, open-source",
     "desc": "Spotify's lightweight Python batch pipeline framework with dependency graphs and target abstractions",
     "prereq": "Python",
     "docs": "https://luigi.readthedocs.io/", "pricing": "https://luigi.readthedocs.io/",
     "category": "Lightweight Python batch framework"},
    {"id": "02.03.03.10", "folder": "02.03.03.10_Metaflow_Learning_Guide", "rank": 9,
     "name": "Metaflow", "short": "Metaflow", "section": "02.03.03.10",
     "tags": "metaflow, netflix, ml, open-source",
     "desc": "Netflix's human-centric framework for data science and ML workflows with local-to-cloud scaling",
     "prereq": "Python, AWS optional for Metaflow plugins",
     "docs": "https://docs.metaflow.org/", "pricing": "https://docs.metaflow.org/",
     "category": "ML/data workflow framework"},
    {"id": "02.03.03.11", "folder": "02.03.03.11_Mage_Learning_Guide", "rank": 10,
     "name": "Mage", "short": "Mage", "section": "02.03.03.11",
     "tags": "mage, open-source, notebook",
     "desc": "an open source hybrid notebook and pipeline tool with scheduling, observability, and modular blocks",
     "prereq": "Python/SQL, Docker",
     "docs": "https://docs.mage.ai/", "pricing": "https://www.mage.ai/pricing",
     "category": "Notebook-style pipeline orchestrator"},
]

MODULES = [
    ("01", "Overview", "overview"), ("02", "Architecture", "concept"),
    ("03", "How_To_Use", "concept"), ("04", "Scenarios", "concept"),
    ("05", "Limitations_And_Scenarios", "concept"), ("06", "Costing", "evaluation"),
    ("07", "Production_Configuration", "concept"), ("08", "Evaluation_Criteria", "evaluation"),
    ("09", "Benchmarking", "evaluation"),
]
MODULE_FOCUS = {
    "01": "What it is, mental model, when to use", "02": "Components, control vs execution plane",
    "03": "Author, deploy, invoke, operate", "04": "Enterprise pipeline patterns",
    "05": "Quotas, constraints, mitigations", "06": "Self-host and OSS cost models",
    "07": "HA, security, monitoring recipes", "08": "Scorecard vs peer technologies",
    "09": "Reference load and sizing profiles",
}

REMOVE_FOLDERS = [
    "02.03.03.05_Cloud_Composer_Learning_Guide", "02.03.03.06_MWAA_Learning_Guide",
    "02.03.03.07_Azure_Data_Factory_Learning_Guide", "02.03.03.08_Step_Functions_Learning_Guide",
    "02.03.03.09_Cloud_Workflows_Learning_Guide",
    "02.03.03.10_Temporal_Learning_Guide", "02.03.03.11_Argo_Workflows_Learning_Guide",
]

def frontmatter(title, section, template, tags):
    return f"""---
title: {title}
section: "{section}"
status: complete
template: {template}
last_reviewed: 2026-06-20
owner: architecture-team
tags: [{tags}, top-10, learning-guide, open-source]
canonical: true
---
"""

def write_readme(t):
    path = os.path.join(BASE, t["folder"], "README.md")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    mod_rows = "\n".join(
        f"| {n} | [{m.replace('_', ' ')}]({t['id']}.{n}_{m}.md) | {MODULE_FOCUS[n]} |"
        for n, m, _ in MODULES)
    content = (frontmatter(f"{t['name']} Learning Guide", t["section"], "hub", t["tags"])
        + f"# {t['name']} Learning Guide\n\n"
        f"> **Rank #{t['rank']}** in [Top 10 Open Source Orchestration](../02.03.03.01_Overview/02.03.03.01.01_Top_10_Orchestration_Technologies.md).\n\n"
        f"Structured learning path for **{t['desc']}**.\n\n"
        f"For managed cloud orchestrators (Composer, MWAA, ADF, Step Functions, Workflows), see "
        f"[02.03.02 Cloud Services](../../02.03.02_Cloud_Services/README.md).\n\n"
        "## Prerequisites\n\n"
        f"- {t['prereq']}\n"
        "- [Top 10 rankings](../02.03.03.01_Overview/02.03.03.01.01_Top_10_Orchestration_Technologies.md)\n\n"
        "## Modules\n\n| # | Module | Focus |\n| ---: | --- | --- |\n"
        f"{mod_rows}\n\n## Quick links\n\n"
        "- [Top 10 README](../README.md)\n"
        f"- [Official documentation]({t['docs']})\n"
        f"- [Official pricing / OSS license]({t['pricing']})\n")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def module_body(t, num, mod_name, template):
    hnum, prefix = int(num), f"{t['id']}.{num}"
    bodies = {
        "01": f"""# {hnum}. {t['name']} Overview

## What is {t['short']}?

**{t['name']}** is {t['desc']}. Category: **{t['category']}**.

## Why Top 10 rank #{t['rank']}?

Ranked in [Top 10 Open Source Orchestration](../02.03.03.01_Overview/02.03.03.01.01_Top_10_Orchestration_Technologies.md) for adoption in data engineering, OSS community, and production fit — **excluding** hyperscaler managed services covered in [Cloud Services](../../02.03.02_Cloud_Services/README.md).

## When to use {t['short']}

| Use when… | Consider alternatives when… |
| --- | --- |
| {t['category']} matches your platform strategy | Managed cloud-only standard → [Cloud Services](../../02.03.02_Cloud_Services/README.md) |
| Team prefers {t['short']} model | Portable DAG mesh → **Airflow** or **Prefect** |
| Self-host or bring-your-own K8s | Serverless cloud glue only → Step Functions / Workflows in Cloud Services |

## Learning path

Continue to [Architecture]({prefix}_Architecture.md) or [Scenarios]({prefix}_Scenarios.md).
""",
        "02": f"""# {hnum}. Architecture of {t['name']}

## Control plane vs execution plane

| Plane | Responsibility |
| --- | --- |
| **Control plane** | Definitions, scheduling, metadata, APIs |
| **Execution plane** | Task/workflow runs, workers, integrations |

See [official architecture docs]({t['docs']}) and [orchestration reference model](../../02.03.01_Fundamentals/02.03.01.01_Overview/02.03.01.01.03_Orchestration_Reference_Model.md).

## Design principle

**Thin orchestrator, fat compute** — {t['short']} coordinates; Spark, warehouses, and containers execute heavy work.
""",
        "03": f"""# {hnum}. How to Use {t['name']}

## Setup

1. Install or deploy per [{t['name']} docs]({t['docs']}) (Docker, K8s, or pip).
2. Configure secrets via env or vault — never commit credentials.
3. Store definitions in Git; CI validates before promote.

## Operational checklist

- [ ] Least-privilege IAM/RBAC on workers
- [ ] Retry with backoff on external calls
- [ ] Idempotent tasks
- [ ] Run tags: `domain`, `cost_center`, `tier`
""",
        "04": f"""# {hnum}. {t['name']} Scenarios

| # | Scenario | Role |
| ---: | --- | --- |
| 1 | Daily warehouse ELT | Batch dependencies |
| 2 | Incremental partitions | Scheduled backfill |
| 3 | ML training pipeline | Multi-step container chain |
| 4 | Data quality gate | Branch on validation |
| 5 | Multi-tenant platform | Namespaces + RBAC |
| 6 | Hybrid on-prem → cloud | Self-hosted workers |
| 7 | Event-triggered reprocess | Parameterized runs |
| 8 | Finance T0 close | SLA scheduling |
| 9 | Platform golden path | Template repos |
| 10 | DR smoke test | Secondary cluster |

See [Orchestration Strategy](../../02.03.01_Fundamentals/02.03.01.02_Strategy/02.03.01.02.01_Orchestration_Strategy.md).
""",
        "05": f"""# {hnum}. {t['name']} Limitations and Mitigations

| Limitation | Mitigation |
| --- | --- |
| Self-host operational burden | Platform team, Helm charts, managed K8s |
| Smaller ecosystem vs Airflow | Custom plugins; evaluate fit early |
| Scaling limits | Horizontal workers; queue tuning |
| Upgrade drift | Pin versions; automated CI DAG/flow tests |

## When not to use {t['short']}

Compare [Top 10 peers](../README.md) and [Cloud Services](../../02.03.02_Cloud_Services/README.md) for managed alternatives.
""",
        "06": f"""# {hnum}. {t['name']} Costing

> **OSS model:** Infrastructure you operate (VMs, K8s nodes, DB) + optional commercial support/cloud tier.

| Cost driver | Notes |
| --- | --- |
| **Compute** | Worker nodes, task pods, scheduler HA |
| **Metadata store** | Postgres/MySQL/etcd depending on product |
| **Storage** | Logs, artifacts, XCom/IO payloads |
| **Commercial** | Optional SaaS control plane (Prefect Cloud, Temporal Cloud, etc.) |

Self-hosted Airflow on 3-node K8s vs managed Composer — see [Managed Workflows comparison](../../02.03.02_Cloud_Services/02.03.02.01_Overview/02.03.02.01.02_Managed_Workflows.md).
""",
        "07": f"""# {hnum}. {t['name']} Production Configuration

| Goal | Approach |
| --- | --- |
| T0 SLA | HA schedulers, retries, paging |
| Cost-efficient dev | Shared non-prod cluster |
| Regulated | Private network, encryption, audit logs |
| High parallelism | Worker pools / HPA on K8s |

Monitor failure rate, queue depth, duration p99.
""",
        "08": f"""# {hnum}. {t['name']} Evaluation Criteria

Compare **{t['name']}** against other [Top 10](../README.md) entries.

| Dimension | Weight |
| --- | ---: |
| Data engineering fit | High |
| OSS community / plugins | High |
| Self-host complexity | Medium |
| Asset/lineage model | Medium |
| K8s cloud-native fit | Medium |

Managed cloud scorecards: [Cloud Services learning guides](../../02.03.02_Cloud_Services/README.md).
""",
        "09": f"""# {hnum}. {t['name']} Benchmarking

| ID | Profile | Measure |
| ---: | --- | --- |
| B1 | Minimal workflow | Baseline latency |
| B2 | Daily batch chain | SLA window |
| B3 | Parallel fan-out | Concurrency ceiling |
| B4 | Backfill burst | Worker CPU / cost |
| B5 | Retry stress | Reliability under failure |

Run in non-prod; compare to [Costing]({prefix}_Costing.md).
""",
    }
    title = f"{t['name']} {mod_name.replace('_', ' ')}"
    return (frontmatter(title, t["section"], template, t["tags"]) + bodies[num]
            + f"\n## Related\n\n- [Top 10 README](../README.md)\n- [{t['name']} hub](../README.md)\n")

def cleanup():
    for folder in REMOVE_FOLDERS:
        path = os.path.join(BASE, folder)
        if os.path.isdir(path):
            shutil.rmtree(path)

def main():
    cleanup()
    count = 0
    for t in TECHS:
        write_readme(t)
        count += 1
        for num, mod_name, template in MODULES:
            path = os.path.join(BASE, t["folder"], f"{t['id']}.{num}_{mod_name}.md")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8") as f:
                f.write(module_body(t, num, mod_name, template))
            count += 1
    print(f"Wrote {count} guide files; removed cloud duplicate folders")

if __name__ == "__main__":
    main()
