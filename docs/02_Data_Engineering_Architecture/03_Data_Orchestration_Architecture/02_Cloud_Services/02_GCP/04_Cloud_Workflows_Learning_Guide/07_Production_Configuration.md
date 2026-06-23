---
title: Cloud Workflows Production Configuration
section: "02.03.02.02.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [gcp, workflows, configuration, production]
canonical: true
---
# 7. How to Configure Workflows for Production

## Configuration matrix

| Goal | Workflow design | Platform settings |
| --- | --- | --- |
| **Reliable external calls** | try/retry + backoff | Workflow SA with token refresh |
| **Burst GCS events** | Idempotent steps | Execution backlogging ON |
| **Low latency** | Minimize steps; same region | Co-locate with BQ/Run |
| **Human approval** | Callback step | Secure callback auth |
| **Audit** | Structured return values | Log sinks to locked bucket |

## Recipe 1 — Event-driven file processing

```yaml
# Trigger: Eventarc GCS finalize → workflow
main:
  params: [event]
  steps:
    - parse:
        assign:
          - bucket: ${event.data.bucket}
          - object: ${event.data.name}
    - idempotent_check:
        call: googleapis.storage.v1.objects.get
        args:
          bucket: ${bucket}
          object: ${object}
        result: obj_meta
    - load:
        call: googleapis.bigquery.v2.jobs.insert
        args:
          projectId: ${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
          body: ${load_job_body}
    - return_ok:
        return: ${"loaded:" + object}
```

Platform: enable **Eventarc** trigger; **backlogging**; workflow SA `bigquery.jobUser` + `storage.objectViewer`.

## Recipe 2 — Resilient HTTP integration

```yaml
- call_partner:
    try:
      call: http.post
      args:
        url: ${partner_url}
        timeout: 30
        body: ${payload}
    retry:
      max_retries: 5
      backoff:
        initial_delay: 2
        max_delay: 120
        multiplier: 2
    except:
      as: e
      steps:
        - log_failure:
            call: sys.log
            args:
              data: ${e}
              severity: ERROR
        - publish_dlq:
            call: googleapis.pubsub.v1.projects.topics.publish
            args:
              topic: ${"projects/" + project + "/topics/wf-dlq"}
              body:
                messages:
                  - data: ${base64.encode(json.encode(payload))}
```

## Recipe 3 — Scheduler + anomaly detection

```
Cloud Scheduler → Workflows (hourly)
  → BigQuery jobs.query (anomaly SQL)
  → switch: count > 0 → http.post PagerDuty
```

Set Scheduler **OIDC** auth to invoker SA.

## Recipe 4 — Composer handoff

Final step:

```yaml
- trigger_composer:
    call: http.post
    args:
      url: ${composer_airflow_url + "/api/v1/dags/" + dag_id + "/dagRuns"}
      auth:
        type: OAuth2
      body:
        conf: ${conf_json}
```

Store Composer URL and client creds in Secret Manager; fetch in `init` step.

## Recipe 5 — Concurrency under load

1. Request **quota increase** for `Executions concurrent per region`.
2. Enable **execution backlogging** on workflow.
3. Optional: **Pub/Sub push** buffer in front of Workflows to absorb spikes.

## Monitoring thresholds

| Metric | Warning | Critical |
| --- | --- | --- |
| Execution failure rate | > 1% | > 5% |
| Queued executions duration | > 5 min | > 30 min |
| External step latency p99 | > 10 s | > 30 s |
| DLQ publish rate | > 0 sustained | > 50/hr |

## Related

- [How to Use](03_How_To_Use.md)
- [Limitations](05_Limitations_And_Scenarios.md)
