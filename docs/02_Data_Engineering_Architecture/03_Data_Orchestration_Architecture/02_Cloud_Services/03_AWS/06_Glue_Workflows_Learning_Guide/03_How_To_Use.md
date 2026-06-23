---
title: How to Use AWS Glue Workflows
section: "02.03.02.03.06"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, glue, operations]
canonical: true
---
# 3. How to Use AWS Glue Workflows

## Setup prerequisites

1. S3 buckets for raw/curated data and script storage.
2. IAM roles for crawlers and ETL jobs with S3 + catalog permissions.
3. Glue Data Catalog database(s) created.
4. Naming: `wf-{domain}-{layer}-{env}` (e.g., `wf-orders-medallion-prod`).

## Create workflow (AWS CLI)

```bash
aws glue create-workflow \
  --name wf-orders-medallion-prod \
  --description "Bronze to silver orders pipeline" \
  --default-run-properties '{"env":"prod"}'
```

## Add jobs and crawler (existing resources)

```bash
aws glue create-job \
  --name orders-bronze-prod \
  --role GlueETLRole \
  --command Name=glueetl,ScriptLocation=s3://glue-scripts/orders/bronze.py \
  --glue-version 4.0 \
  --number-of-workers 6 \
  --worker-type G.1X \
  --execution-class FLEX

aws glue create-crawler \
  --name orders-raw-crawler-prod \
  --role GlueCrawlerRole \
  --database-name raw_db \
  --targets "S3Targets=[{Path=s3://lake/raw/orders/}]"
```

## Create triggers (dependency chain)

**Starting schedule trigger → crawler:**

```bash
aws glue create-trigger \
  --name wf-orders-start-prod \
  --type SCHEDULED \
  --schedule "cron(0 2 * * ? *)" \
  --workflow-name wf-orders-medallion-prod \
  --actions CrawlerName=orders-raw-crawler-prod
```

**Conditional: crawler succeeded → bronze job:**

```bash
aws glue create-trigger \
  --name wf-orders-crawl-to-bronze-prod \
  --type CONDITIONAL \
  --workflow-name wf-orders-medallion-prod \
  --predicate '{
    "Conditions": [{
      "CrawlerName": "orders-raw-crawler-prod",
      "CrawlState": "SUCCEEDED"
    }]
  }' \
  --actions JobName=orders-bronze-prod
```

**Conditional: bronze succeeded → silver job:**

```bash
aws glue create-trigger \
  --name wf-orders-bronze-to-silver-prod \
  --type CONDITIONAL \
  --workflow-name wf-orders-medallion-prod \
  --predicate '{
    "Conditions": [{
      "JobName": "orders-bronze-prod",
      "State": "SUCCEEDED"
    }]
  }' \
  --actions JobName=orders-silver-prod
```

## Start workflow manually

```bash
aws glue start-workflow-run \
  --name wf-orders-medallion-prod \
  --run-properties '{"partition_date":"2026-06-20"}'
```

## Read run properties in Spark job (Python)

```python
from awsglue.utils import getResolvedOptions
import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext

args = getResolvedOptions(sys.argv, ["WORKFLOW_NAME", "WORKFLOW_RUN_ID"])
# Use boto3 glue.get_workflow_run_properties to fetch partition_date
```

## EventBridge trigger (S3 object created)

Create **EVENT** type trigger with event pattern for S3 `Object Created` — note **max batch 100**, **max window 900 s** per [AWS restrictions](https://docs.aws.amazon.com/glue/latest/dg/blueprint_workflow_restrictions.html).

## IAM patterns

| Role | Permissions |
| --- | --- |
| Glue job role | `s3:GetObject/PutObject` on lake paths; `glue:*` on catalog; KMS decrypt |
| Crawler role | S3 list/read; catalog create/update |
| Operator human/CI | `glue:StartWorkflowRun`, `glue:GetWorkflowRun` |

## Terraform (workflow + trigger sketch)

```hcl
resource "aws_glue_workflow" "orders" {
  name = "wf-orders-medallion-prod"
  default_run_properties = { env = "prod" }
}

resource "aws_glue_trigger" "schedule" {
  name          = "wf-orders-start-prod"
  type          = "SCHEDULED"
  schedule      = "cron(0 2 * * ? *)"
  workflow_name = aws_glue_workflow.orders.name
  actions {
    crawler_name = aws_glue_crawler.raw.name
  }
}
```

## Observability

- **Glue Studio → Workflows → Run details** — graph with per-node status.
- **CloudWatch Logs** — job output under `/aws-glue/jobs/`.
- **CloudWatch metrics** — `glue.driver.aggregate.numCompletedTasks`, DPU hours via Cost Explorer.
- **Glue job run IDs** linked to workflow run in console.

## Operational checklist

- [ ] Job bookmarks enabled for incremental sources
- [ ] Flex execution class on non-T0 jobs where latency allows
- [ ] `MaxConcurrentRuns` set on workflow if needed
- [ ] Crawler schedule aligned with landing SLA (avoid redundant crawls)
- [ ] Run properties documented for downstream jobs
- [ ] Jobs started only via workflow triggers in production

## Related

- [Architecture](02_Architecture.md)
- [Production Configuration](07_Production_Configuration.md)
