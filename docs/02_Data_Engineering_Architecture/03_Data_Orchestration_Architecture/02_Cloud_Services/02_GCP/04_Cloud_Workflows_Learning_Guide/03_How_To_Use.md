---
title: How to Use Cloud Workflows
section: "02.03.02.02.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, workflows, operations]
canonical: true
---
# 3. How to Use Cloud Workflows

## Setup prerequisites

1. Enable `workflows.googleapis.com` and `workflowexecutions.googleapis.com`.
2. Create **service account** with roles for target APIs (e.g., `bigquery.jobUser`, `run.invoker`).
3. Choose **region** (workflows are regional).
4. Naming: `wf-{domain}-{purpose}-{env}`.

## Deploy workflow (gcloud)

**`workflow.yaml`:**

```yaml
main:
  params: [input]
  steps:
    - init:
        assign:
          - project: ${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
          - dataset: ${input.dataset}
    - run_query:
        call: googleapis.bigquery.v2.jobs.query
        args:
          projectId: ${project}
          body:
            query: ${"SELECT COUNT(*) FROM `" + project + "." + dataset + ".orders`"}
            useLegacySql: false
        result: query_result
    - done:
        return: ${query_result}
```

```bash
gcloud workflows deploy wf-orders-validate-prod \
  --location=us-central1 \
  --source=workflow.yaml \
  --service-account=workflows-runner@PROJECT.iam.gserviceaccount.com
```

## Execute workflow

```bash
# Synchronous wait for result
gcloud workflows run wf-orders-validate-prod \
  --location=us-central1 \
  --data='{"dataset":"analytics"}'

# Async execution
gcloud workflows execute wf-orders-validate-prod \
  --location=us-central1 \
  --data='{"dataset":"analytics"}'
```

**REST API:** `POST https://workflowexecutions.googleapis.com/v1/projects/PROJECT/locations/us-central1/workflows/wf-orders-validate-prod/executions`

## Eventarc trigger (GCS file landed)

```bash
gcloud eventarc triggers create wf-trigger-orders-landing \
  --location=us-central1 \
  --destination-workflow=wf-orders-validate-prod \
  --destination-workflow-location=us-central1 \
  --event-filters="type=google.cloud.storage.object.v1.finalized" \
  --event-filters="bucket=orders-landing-prod" \
  --service-account=eventarc-invoker@PROJECT.iam.gserviceaccount.com
```

Map event payload to workflow input via Eventarc transformation or parse in first step.

## Retry pattern

```yaml
- call_api:
    try:
      call: http.post
      args:
        url: https://api.example.com/process
        auth:
          type: OIDC
        body: ${payload}
    retry:
      predicate: ${http.default_retry_predicate}
      max_retries: 5
      backoff:
        initial_delay: 2
        max_delay: 60
        multiplier: 2
```

## Human callback (approval)

```yaml
- wait_for_approval:
    call: http.post
    args:
      url: https://workflowexecutions.googleapis.com/.../callbacks/WAIT_ID
      auth:
        type: OAuth2
    result: callback_request
- approval_result:
    assign:
      - approved: ${callback_request.http_request.body.approved}
```

External system POSTs to callback URL when human approves.

## IAM patterns

| Role | Use |
| --- | --- |
| `roles/workflows.editor` | Deploy definitions (CI/CD) |
| `roles/workflows.invoker` | Run executions (Eventarc SA, Scheduler) |
| `roles/workflows.admin` | Platform team |
| Target API roles on **workflow SA** | BigQuery, Run, Storage |

## Terraform

```hcl
resource "google_workflows_workflow" "validate" {
  name            = "wf-orders-validate-prod"
  region          = "us-central1"
  service_account = google_service_account.wf.email
  source_contents = file("workflow.yaml")
}
```

## Observability

- **Console:** Execution graph with per-step I/O (redact secrets).
- **Logging:** `workflows.googleapis.com/executions` audit and step logs.
- **Metrics:** Execution count, duration, failure rate — Cloud Monitoring dashboards.

## Operational checklist

- [ ] Workflow SA least privilege
- [ ] Retry policies on external HTTP
- [ ] Idempotent downstream steps
- [ ] Concurrency quota reviewed; backlogging enabled if needed
- [ ] Secrets from Secret Manager, not YAML literals
- [ ] Version control for all workflow YAML

## Related

- [Architecture](02_Architecture.md)
- [Production Configuration](07_Production_Configuration.md)
