"""Append substantive OSS sections to Top 10 learning guide modules."""
import os
import re

BASE = os.path.normpath(
    os.path.join(
        os.path.dirname(__file__),
        "..", "..",
        "docs", "02_Data_Engineering_Architecture",
        "02.03_Data_Orchestration_Architecture", "02.03.03_Top_10",
    )
)

MARKER = "## Related"

def insert_before_related(path, block):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if block.strip() in text:
        return False
    if MARKER not in text:
        text = text.rstrip() + "\n\n" + block.rstrip() + "\n"
    else:
        text = text.replace(MARKER, block.rstrip() + "\n\n" + MARKER, 1)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return True


AIRFLOW = {
"01": """
## Core objects

| Object | Role |
| --- | --- |
| **DAG** | Directed acyclic graph of tasks with schedule and default args |
| **Task / Operator** | Unit of work (`PythonOperator`, provider hooks, deferrable operators) |
| **DagRun** | One logical execution of a DAG for an interval or manual trigger |
| **TaskInstance** | State machine for a single task in one DagRun |

Airflow 2.x centralizes configuration in `airflow.cfg` (or env vars) and uses a **metadata database** (PostgreSQL recommended) for all runtime state.

## Deployment topologies

| Topology | When |
| --- | --- |
| Single-node (SequentialExecutor) | Local dev only |
| CeleryExecutor + Redis/RabbitMQ | Classic multi-worker |
| KubernetesExecutor / CeleryK8s | Elastic workers per task |
| Managed (Composer, MWAA, Astronomer) | Production without patching Airflow itself |

## Ecosystem

**Provider packages** ship integrations (AWS, GCP, Snowflake, dbt, etc.). Prefer providers over raw `BashOperator` curl for idempotency and testability.
""",
"02": """
## Airflow-specific components

| Component | Function |
| --- | --- |
| **Scheduler** | Parses DAGs, creates DagRuns, queues task instances |
| **DAG processor** | Parses Python DAG files safely in isolated processes |
| **Webserver / UI** | Graph view, logs, admin, REST API (FAB auth) |
| **Workers** | Pull tasks from queue and execute (executor-dependent) |
| **Triggerer** | Runs deferrable (async) operators without blocking worker slots |

## Metadata and lineage

Postgres/MySQL holds DAG definitions, run history, variables, connections (encrypted), and XCom payloads. Large XCom values should live in object storage with references only.

## Executor comparison

| Executor | Isolation | Scale pattern |
| --- | --- | --- |
| Local | Process on scheduler host | Dev |
| Celery | Worker pool | Fixed fleet |
| Kubernetes | Pod per task | Burst-heavy ELT |
| LocalKubernetes | Hybrid | CI and small prod |

## Failure semantics

Tasks move through `queued → running → success|failed|skipped|upstream_failed`. **Trigger rules** (`all_success`, `none_failed_min_one_success`, etc.) define join behavior in fan-in graphs.
""",
"03": """
## Local bootstrap

```bash
pip install "apache-airflow[celery,postgres]==2.10.*"
airflow db migrate
airflow users create ...
airflow standalone   # or docker-compose official image
```

Store DAGs under `dags/` with `AIRFLOW__CORE__DAGS_FOLDER` or Git-sync sidecars in Kubernetes.

## Authoring patterns

- Use **TaskFlow API** (`@dag`, `@task`) for typed Python dependencies.
- Set `catchup=False` on backfill-sensitive pipelines unless historical reprocessing is intended.
- Pin `start_date` in the past only when catchup is required.
- Use **datasets** (Airflow 2.4+) for data-driven scheduling between DAGs.

## CI/CD

1. `airflow dags list-import-errors` in CI on every PR.
2. Run **pytest** with `airflow.utils.state` mocks or `DagBag` load tests.
3. Promote via S3/GCS sync, Helm, or provider-specific deploy hooks.

## Operations

Rotate Fernet keys with a documented procedure; export connections to secret backend (Vault, AWS Secrets Manager, GCP Secret Manager).
""",
"04": """
## Reference patterns

| Pattern | Airflow mechanism |
| --- | --- |
| Medallion ELT | Task groups per layer; dataset outlets on curated tables |
| Dynamic task mapping | `.expand()` over partition list from XCom or object store manifest |
| SLA alerting | `sla` timedelta on tasks + email/Slack callbacks |
| Cross-DAG trigger | `TriggerDagRunOperator` with `wait_for_completion` |
| Backfill | CLI `airflow dags backfill` or UI with date range |
| Pool throttling | `pool` slots for API rate limits |
| Priority lanes | `priority_weight` + separate queues |

## Anti-patterns

Running heavy Spark inside `PythonOperator` on the worker JVM footprint—delegate to `DataprocSubmitJobOperator`, `EmrAddStepsOperator`, or KubernetesPodOperator instead.
""",
"05": """
## Known constraints

| Constraint | Detail |
| --- | --- |
| Schedule granularity | Minimum one minute for cron; use sensors or event triggers for sub-minute |
| Metadata DB pressure | High task count increases scheduler DB churn—partition old data |
| Worker packaging | Python deps must exist on every worker image |
| No native exactly-once | Orchestration is at-least-once; make tasks idempotent |
| UI not multi-tenant alone | RBAC helps but true isolation needs separate deployments |

## Mitigations

Use **deferrable operators** for long polls; **TaskGroups** and **SubDAGs (deprecated)** replaced by task groups; externalize secrets; enable **statsd/OpenTelemetry** for scheduler lag metrics.
""",
"06": """
## Self-hosted cost drivers

| Driver | Typical spend |
| --- | --- |
| Always-on workers | Largest baseline—right-size or use K8sExecutor |
| Metadata DB | RDS/Cloud SQL HA instance |
| Redis/RabbitMQ | Celery broker HA |
| Log storage | S3/GCS lifecycle for task logs |
| Observability | Metrics + log indexing |

Managed Airflow (Composer/MWAA) adds environment fee but removes patch/upgrade toil—see Top 10 cloud entries for calculators.

## Optimization levers

- Autoscale workers on queue depth
- Short-circuit with `@task.short_circuit`
- Avoid excessive XCom serialization
- Use object-store remote logging with retention policies
""",
"07": """
## Production checklist

| Area | Recommendation |
| --- | --- |
| HA | Multi-scheduler (Airflow 2+), redundant webservers behind LB |
| Secrets | `SecretsBackend` integration; disable admin connection UI in prod |
| RBAC | Map SSO groups to Airflow roles |
| DAG integrity | `dagbag_import_timeout`, max active runs per DAG |
| Upgrades | Blue/green metadata migration in staging first |
| Backups | Nightly metadata snapshots; document restore RTO |

## Observability

Export scheduler metrics: `scheduler_heartbeat`, `dag_processing`, `executor_queue`. Alert on p95 task queue time and failed SLA callbacks.
""",
"08": """
## Scorecard (qualitative)

| Criterion | Airflow | Notes |
| --- | ---: | --- |
| Batch DAG maturity | 5/5 | Industry default |
| Asset/lineage native | 3/5 | Datasets improving; Dagster stronger |
| Dynamic UX for ops | 4/5 | Rich UI |
| Self-host ops burden | 2/5 | Requires platform team |
| Portability | 5/5 | Same DAGs on MWAA/Composer |

Peers: **Prefect** (ergonomic Python, hybrid cloud), **Dagster** (assets), **Temporal** (durable micro-workflows).
""",
"09": """
## Sample benchmarks

| Profile | DAG shape | Success criteria |
| --- | --- | --- |
| B1 | 10 tasks serial | Scheduler delay < 30s from tick |
| B2 | 50 tasks fan-out/fan-in | Worker scale-up within 2 min |
| B3 | 500 mapped tasks | Metadata DB CPU < 70% |
| B4 | 24h backfill 1yr | Completes within maintenance window |
| B5 | Deferrable sensor 2h | Worker slot freed within seconds |

Record Airflow version, executor type, worker vCPU/RAM, and metadata DB size with every run for reproducibility.
""",
}

PREFECT = {
"01": """
## Mental model

Prefect treats **flows** as the primary unit (Python functions) rather than static DAG files. A **deployment** binds a flow to infrastructure (work pool, schedule, parameters). **Prefect Cloud** or self-hosted **Prefect server** holds orchestration state; **workers** poll for runs.

## Editions

| Mode | Control plane | Execution |
| --- | --- | --- |
| Prefect Cloud SaaS | Prefect Inc. | Your agents/workers |
| Self-hosted server | Your Postgres + API | Your workers |
| Hybrid | Cloud UI + private workers | Common enterprise pattern |

## Why teams pick Prefect

Native Python typing, dynamic runtime task generation, first-class retries and caching, and simpler local `prefect deploy` ergonomics versus classic Airflow DAG boilerplate.
""",
"02": """
## Component map

| Piece | Role |
| --- | --- |
| **API / UI** | Deployments, run history, automations |
| **Orchestration engine** | Schedules, queues, state transitions |
| **Work pools & workers** | Pull model execution on K8s, ECS, processes |
| **Blocks** | Reusable config for storage, secrets, notifications |
| **Artifacts & variables** | Run-scoped metadata and configuration |

Prefect 2.x uses a **transactional orchestration model**—each flow run is tracked with granular task states without a separate metadata schema you operate directly.

## Execution isolation

Workers are ephemeral; heavy compute should still live in Spark/BQ jobs triggered from `@flow` tasks, mirroring the thin-orchestrator pattern.
""",
"03": """
## Quick start

```bash
pip install -U prefect
prefect cloud login   # or prefect server start
```

Define:

```python
from prefect import flow, task

@task(retries=3, retry_delay_seconds=30)
def extract(): ...

@flow(log_prints=True)
def elt_pipeline():
    extract()
```

Deploy with `prefect deploy` (YAML) or `flow.deploy()` specifying work pool and schedule.

## Best practices

- Use **Secret blocks** instead of env files in repo
- Tag runs (`environment=prod`, `domain=finance`) for cost allocation
- Enable **automation** rules for SLA failures → Slack/PagerDuty
""",
"04": """
## Enterprise scenarios

| Scenario | Prefect approach |
| --- | --- |
| Parametric replays | Deployment parameters + manual custom runs |
| Per-tenant isolation | Separate work pools and IAM roles per tenant |
| Event-driven | Webhooks and automations on block events |
| dbt orchestration | `prefect-dbt` or shell tasks with artifacts |
| ML training | Map over hyperparameter grid with task runners |
| File landing | S3/GCS automation triggers deployment |

Combine with **Concurrency limits** on work pools to protect downstream warehouses.
""",
"05": """
## Limitations

| Topic | Impact |
| --- | --- |
| Batch-first | Not a replacement for Kafka/Flink stream processing |
| Cloud dependency | Full UI/automation easiest with Prefect Cloud |
| Worker packaging | Same dependency sync problem as Airflow on static workers |
| Long-running human tasks | Use pause/resume patterns; compare with Temporal for saga length |

Document **vendor exit**: flows remain plain Python; migrate server to self-hosted Postgres if leaving Cloud.
""",
"06": """
## Pricing dimensions

Prefect Cloud bills on **successful task runs** tiers (see official pricing). Self-hosted server costs are primarily Postgres, API compute, and worker fleet—similar to self-hosted Airflow minus Celery complexity.

| Scenario | Cost tip |
| --- | --- |
| High-frequency micro-tasks | Batch inside one task to reduce run metering |
| Dev/staging | Separate workspace with lower automation |
| Hybrid | Keep workers in your VPC; no data egress through control plane |
""",
"07": """
## Hardening

- TLS everywhere; rotate API keys via CI
- RBAC in Cloud; SSO for enterprise tier
- Work pool **job variables** for K8s resource limits
- Enable **result persistence** to durable storage for replay debugging
- Separate **prod/nonprod** workspaces and block namespaces
""",
"08": """
## Comparison highlights

| Dimension | Prefect | Airflow |
| --- | --- | --- |
| Authoring | Python-first flows | DAG files + operators |
| Scheduling UX | Deployments + automations | Cron in DAG |
| Dynamic tasks | Native `.map` | Dynamic task mapping |
| Maturity | Strong mid-market | Broadest adoption |

Best when team wants **Python-native** orchestration with managed hybrid control plane.
""",
"09": """
## Benchmark ideas

| ID | Load | Metric |
| --- | --- | --- |
| P1 | 1 flow, 100 mapped tasks | End-to-end duration |
| P2 | 5 min schedule, 1k runs/day | Cloud API latency p99 |
| P3 | Worker scale 0→20 | Cold start on K8s work pool |
| P4 | Large result artifact 100MB | Block storage throughput |

Capture Prefect version, work pool type, and worker vCPU with results.
""",
}

DAGSTER = {
"01": """
## Asset-centric paradigm

Dagster models pipelines as **software-defined assets** (tables, files, ML models) with explicit dependencies. **Jobs** select subsets of assets; **schedules** and **sensors** materialize them on cadence or events.

## Key concepts

| Concept | Meaning |
| --- | --- |
| **Asset** | Persistent data product with lineage |
| **Op / graph** | Lower-level compute (legacy style still supported) |
| **Partition** | Time or dimension slice (daily, region) |
| **Resource** | DB connections, Spark, IO managers |

## Deployment options

**Dagster Cloud** (hybrid or serverless agents) or **open-source Dagster webserver + daemon** with user-managed Postgres.
""",
"02": """
## Runtime architecture

| Service | Responsibility |
| --- | --- |
| **Webserver (UI + GraphQL)** | Catalog, launchpad, asset graph |
| **Daemon** | Runs schedules, sensors, backfills |
| **Code locations** | gRPC servers exposing definitions (often one per repo) |
| **Run coordinator / launcher** | Queues runs; K8s, Docker, or external |

**I/O managers** standardize how asset materializations land in Snowflake, S3, or local storage—reducing ad-hoc path logic.
""",
"03": """
## Project layout

Use `dagster project scaffold` (or uv/poetry). Definitions live in Python modules loaded by `Definitions` object merging assets, jobs, schedules, sensors, resources.

Local dev:

```bash
dagster dev
```

Deploy code locations via Helm, Docker, or Dagster Cloud **branch deployments** for PR previews.

## Testing

`materialize` assets in pytest with mock resources; validate **asset checks** for data quality gates before promoting jobs.
""",
"04": """
## Scenario mapping

| Scenario | Dagster feature |
| --- | --- |
| Column-level lineage | Asset dependencies + external metadata sync |
| Incremental models | Partitions + `BackfillPolicy` |
| Quality gates | Asset checks blocking downstream |
| Feature store refresh | Multi-asset job selecting ML assets |
| Monorepo microservices | Multiple code locations in one deployment |
| dbt integration | `dagster-dbt` manifest-driven assets |

Ideal when **data products** and observability matter as much as task success.
""",
"05": """
## Trade-offs

| Limitation | Mitigation |
| --- | --- |
| Learning curve | Training on assets vs raw tasks |
| Operational footprint | Daemon + code locations + DB |
| Real-time | Pair with streaming ingest; Dagster orchestrates batch materialization |
| Non-Python steps | Wrap via ops or external asset sensors |

Less suited to pure JSON state machines (see Step Functions) or ultra-light cron glue.
""",
"06": """
## Cost view

**Dagster Cloud** tiers by seat and run volume; hybrid agents run in your compute—warehouse and Spark costs remain separate. OSS Dagster costs = Postgres + webserver/daemon compute + run workers (K8s).

FinOps: tag runs with `team` **tags** on jobs; use partition backfill scopes to avoid full-table rematerialization spend.
""",
"07": """
## Production patterns

- HA Postgres for event log storage
- Separate **prod/staging** code locations
- **Run coordinators** with concurrency pools per warehouse
- Enable **run monitoring** alerts and Slack on failure
- Store secrets via env or cloud secret managers referenced in resources
- Version definitions with Git SHA visible in UI
""",
"08": """
## Evaluation snapshot

| Dimension | Dagster |
| --- | ---: |
| Lineage / catalog | 5/5 |
| Batch ELT | 5/5 |
| Ad-hoc ops UI | 4/5 |
| Minimal infra path | 3/5 |
| General IT workflows | 2/5 |

Compare **Airflow** for maximal integrators; **Prefect** for lightweight Python flows; **Dagster** when assets are the contract with analytics consumers.
""",
"09": """
## Benchmark profiles

| Profile | Setup | Measure |
| --- | --- | --- |
| D1 | 200 assets linear graph | UI load + daemon tick latency |
| D2 | Daily partition backfill 90d | Warehouse credits vs incremental |
| D3 | Sensor every 60s on S3 prefix | Sensor evaluation CPU |
| D4 | Asset check failure cascade | Time to halt downstream materializations |

Document Dagster version, deployment type (Cloud hybrid vs OSS), and launcher (K8s job vs Celery).
""",
}

TEMPORAL = {
"01": """
## Durable execution

Temporal guarantees **workflow state** survives process crashes and infrastructure failures. Developers write ordinary code; the **Temporal service** records event history and replays deterministically.

## SDKs

Official SDKs for Go, Java, Python, TypeScript, .NET—workflows coordinate **activities** (non-deterministic side effects) with automatic retries and timeouts.
""",
"02": """
## Cluster layout

| Part | Role |
| --- | --- |
| **Frontend service** | gRPC API for workers |
| **History service** | Event sourcing per workflow execution |
| **Matching service** | Task queue routing |
| **Worker** | User code polling task queues |

**Temporal Cloud** hosts the control plane; self-hosted uses Cassandra/MySQL/PostgreSQL persistence stores.
""",
"03": """
## Implementation flow

1. Model business process as workflow functions (deterministic—no random/time without wrappers).
2. Implement activities for DB calls, HTTP, file IO.
3. Run workers scaled independently from frontends.
4. Start executions via client SDK or Temporal Cloud UI.

Use **continue-as-new** for unbounded streams; **signals/queries** for human-in-the-loop approvals.
""",
"04": """
## Data engineering fits

- Long-running ingestion sagas with compensating transactions
- Orchestrating micro-batches waiting on external approvals
- Coordinating multi-step ML pipelines with human gates
- Replacing brittle cron + status table patterns

Less ideal as primary warehouse ELT scheduler—pair with Airflow/Dagster for SQL batches.
""",
"05": """
## Constraints

Workflow code must be **deterministic** (restricted APIs). High fan-out history grows event store—use child workflows judiciously. Operational expertise for self-hosted clusters is non-trivial; Cloud reduces burden.
""",
"06": """
## Cost

Temporal Cloud pricing on actions/history; self-hosted = DB storage + cluster compute. Activity-heavy workflows dominate billing—batch external calls where possible.
""",
"07": """
## Production

Namespace isolation per environment; mTLS between workers and frontend; retention policies on closed workflows; monitor schedule-to-start latency and task backlog.
""",
"08": """
## When Temporal wins

Excellent for **long-lived, failure-prone, procedural** workflows. Ranked #9 in Top 10 for microservice orchestration and sagas, not classic nightly SQL DAGs.
""",
"09": """
## Benchmarks

Measure workflow start latency, activity retry storms, and history size for 10k parallel child workflows—compare Cloud vs self-hosted persistence IOPS.
""",
}

ARGO = {
"01": """
## Kubernetes-native workflows

Argo Workflows executes **DAGs of containers** defined in YAML (or Helm/Hera Python). Each step is a pod; artifacts pass via volumes or S3/GCS artifact repositories.

CNCF graduated project; common in **ML and HPC** pipelines on existing K8s clusters.
""",
"02": """
## Control plane

| Object | Purpose |
| --- | --- |
| **Workflow** | Template + entrypoint |
| **WorkflowTemplate** | Reusable definition |
| **CronWorkflow** | Scheduled runs |
| **Controller** | Reconciles workflow CRDs |
| **Executor** | Docker/container runtime in pod |

Integrates with **Argo Events** for event triggers and **Argo CD** for GitOps delivery of templates.
""",
"03": """
## Authoring

Install controller via Helm. Submit:

```bash
argo submit -n data-workflows my-pipeline.yaml
argo logs @latest
```

Use **WorkflowTaskSet** patterns, **withParam** for fan-out, and **retryStrategy** for transient node failures.

For Python teams, **Hera** generates typed workflow specs.
""",
"04": """
## Scenarios

- GPU training pipelines with step-level resource requests
- Genomic/batch HPC embarrassingly parallel maps
- CI-style data processing when K8s is already standard
- Spark-on-K8s driver steps chained with container prep tasks

Pair with object-store artifact repos for multi-GB intermediates.
""",
"05": """
## Limits

Requires mature K8s ops; UI less business-user friendly than Airflow. No built-in data catalog—lineage is pod-level. Cold-start per step can hurt small fast tasks.
""",
"06": """
## Cost

No per-step SaaS fee—pay cluster node pool, storage, and egress. Cost optimize via spot instances, workflow parallelism limits, and artifact lifecycle rules.
""",
"07": """
## Production

RBAC for workflow SA; artifact repository credentials via K8s secrets; archive logs to S3; set **podGC** strategy; monitor controller metrics and workflow failure rates per namespace.
""",
"08": """
## Top 10 positioning

Rank #10 for teams **already standardized on Kubernetes** wanting container-native batch DAGs without operating Airflow workers.
""",
"09": """
## Benchmarks

Time 100-step fan-out on n nodes; measure pod scheduling latency p99; stress artifact upload/download to GCS with 1GiB files.
""",
}

# Top 10 slot map (see 02.03.03.01.01_Top_10_Orchestration_Technologies.md):
#   .02 Airflow | .03 Prefect | .04 Dagster | .05 Temporal | .06 Argo
#   .07 Kestra  | .08 Flyte   | .09 Luigi   | .10 Metaflow | .11 Mage
# Do NOT point Temporal/Argo at .10/.11 — those folders are Metaflow/Mage.
SPECS = [
    ("02.03.03.02_Apache_Airflow_Learning_Guide", AIRFLOW),
    ("02.03.03.03_Prefect_Learning_Guide", PREFECT),
    ("02.03.03.04_Dagster_Learning_Guide", DAGSTER),
    ("02.03.03.05_Temporal_Learning_Guide", TEMPORAL),
    ("02.03.03.06_Argo_Workflows_Learning_Guide", ARGO),
]

SUFFIX = {
    "01": "01_Overview.md", "02": "02_Architecture.md", "03": "03_How_To_Use.md",
    "04": "04_Scenarios.md", "05": "05_Limitations_And_Scenarios.md",
    "06": "06_Costing.md", "07": "07_Production_Configuration.md",
    "08": "08_Evaluation_Criteria.md", "09": "09_Benchmarking.md",
}

def main():
    updated = 0
    skipped = 0
    for folder, blocks in SPECS:
        sec = folder.split("_")[0]  # e.g. 02.03.03.02 from 02.03.03.02_Apache_Airflow_Learning_Guide
        for num, block in blocks.items():
            mod = SUFFIX[num].split("_", 1)[1].replace(".md", "")
            fname = f"{sec}.{num}_{mod}.md"
            path = os.path.join(BASE, folder, fname)
            if not os.path.isfile(path):
                print(f"ERROR missing guide module: {path}", file=__import__("sys").stderr)
                skipped += 1
                continue
            if insert_before_related(path, block):
                updated += 1
    print(f"Enhanced {updated} module files ({skipped} skipped)")
    if skipped:
        raise SystemExit(1)

if __name__ == "__main__":
    main()
