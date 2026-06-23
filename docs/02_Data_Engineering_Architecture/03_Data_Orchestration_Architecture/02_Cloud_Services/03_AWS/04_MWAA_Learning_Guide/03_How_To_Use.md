---
title: How to Use Amazon MWAA
section: "02.03.02.03.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, mwaa, operations, airflow]
canonical: true
---
# 3. How to Use Amazon MWAA

## Setup prerequisites

1. VPC with **two private subnets** in different AZs (+ optional public subnets for public webserver).
2. S3 bucket for DAGs (versioning recommended).
3. **Execution role** IAM role with trust policy for `airflow.amazonaws.com` and `airflow-env.amazonaws.com`.
4. Security groups allowing MWAA ↔ RDS ↔ workers communication.
5. Naming: `mwaa-{domain}-{env}` (e.g., `mwaa-analytics-prod`).

## Create environment (AWS CLI)

```bash
aws mwaa create-environment \
  --name mwaa-analytics-prod \
  --airflow-version 2.10.3 \
  --source-bucket-arn arn:aws:s3:::mwaa-analytics-prod-dags \
  --execution-role-arn arn:aws:iam::ACCOUNT:role/mwaa-analytics-prod-execution \
  --network-configuration '{
    "SubnetIds": ["subnet-aaa","subnet-bbb"],
    "SecurityGroupIds": ["sg-mwaa"]
  }' \
  --webserver-access-mode PRIVATE_ONLY \
  --environment-class mw1.medium \
  --max-workers 10 \
  --min-workers 2 \
  --schedulers 2 \
  --dag-s3-path dags/ \
  --plugins-s3-path plugins/plugins.zip \
  --requirements-s3-path requirements/requirements.txt
```

## Deploy DAGs

### Option A — S3 sync

```bash
aws s3 sync ./dags s3://mwaa-analytics-prod-dags/dags/ --delete
aws s3 cp requirements.txt s3://mwaa-analytics-prod-dags/requirements/requirements.txt
aws s3 cp plugins.zip s3://mwaa-analytics-prod-dags/plugins/plugins.zip
```

MWAA detects changes within ~1–3 minutes.

### Option B — CI/CD (recommended)

1. PR → CI runs `airflow dags list-import-errors` against MWAA-compatible image.
2. Merge → pipeline syncs to S3; optionally triggers environment update for requirements.

### Sample DAG (Glue job trigger)

```python
from airflow import DAG
from airflow.providers.amazon.aws.operators.glue import GlueJobOperator
from datetime import datetime

with DAG(
    dag_id="orders_daily_glue",
    start_date=datetime(2024, 1, 1),
    schedule="0 2 * * *",
    catchup=False,
    tags=["analytics", "tier:T1"],
) as dag:
    run_glue = GlueJobOperator(
        task_id="run_orders_etl",
        job_name="orders-etl-prod",
        script_args={"--partition": "{{ ds }}"},
        region_name="us-east-1",
    )
```

## Trigger DAG via REST API

```bash
# Get CLI token from MWAA web UI or aws mwaa create-cli-token
curl -X POST "https://{webserver}/api/v1/dags/orders_daily_glue/dagRuns" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"conf": {"partition": "2026-06-20"}}'
```

## Secrets Manager connections

**`airflow.cfg` override via MWAA configuration options:**

```json
{
  "secrets.backend": "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend",
  "secrets.backend_kwargs": "{\"connections_prefix\": \"airflow/connections\", \"variables_prefix\": \"airflow/variables\"}"
}
```

Store connection JSON at `airflow/connections/redshift_default`.

## IAM patterns

| Policy area | Example permissions |
| --- | --- |
| S3 DAG bucket | `s3:GetObject`, `s3:ListBucket` on DAG prefix |
| Glue | `glue:StartJobRun`, `glue:GetJobRun` |
| EMR | `elasticmapreduce:AddJobFlowSteps` |
| Secrets Manager | `secretsmanager:GetSecretValue` on `airflow/*` |
| CloudWatch Logs | `logs:CreateLogStream`, `logs:PutLogEvents` |

## Terraform

```hcl
resource "aws_mwaa_environment" "analytics" {
  name              = "mwaa-analytics-prod"
  airflow_version   = "2.10.3"
  environment_class = "mw1.medium"
  execution_role_arn = aws_iam_role.mwaa.arn
  source_bucket_arn  = aws_s3_bucket.dags.arn
  dag_s3_path        = "dags/"
  webserver_access_mode = "PRIVATE_ONLY"
  network_configuration {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.mwaa.id]
  }
  max_workers = 10
  min_workers = 2
}
```

## Observability

- **CloudWatch metrics:** `QueuedTasks`, `RunningTasks`, `SchedulerHeartbeat`, `CPUUtilization`.
- **CloudWatch Logs:** Scheduler, worker, webserver log groups auto-created.
- **Airflow UI:** Task duration, Gantt, log links per task instance.

## Operational checklist

- [ ] Execution role least privilege
- [ ] Requirements.txt pinned; tested in CI
- [ ] `catchup=False` on production DAGs unless backfill intended
- [ ] Pools for warehouse/Glue concurrency
- [ ] DAG import time monitored (&lt; 30s recommended)
- [ ] S3 bucket versioning enabled

## Related

- [Architecture](02_Architecture.md)
- [Production Configuration](07_Production_Configuration.md)
