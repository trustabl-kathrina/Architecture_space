---
title: AWS Step Functions Production Configuration
section: "02.03.02.03.05"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, step-functions, configuration, production]
canonical: true
---
# 7. How to Configure Step Functions for Production

## Configuration matrix

| Goal | Workflow design | Platform settings |
| --- | --- | --- |
| **Reliable Glue calls** | `.sync` + Retry on throttling | Scoped execution role |
| **Burst S3 events** | Idempotent Glue job names | EventBridge replay DLQ |
| **Low latency ingress** | Express sync workflow | Regional co-location |
| **Human approval** | `waitForTaskToken` | Secure callback auth |
| **Audit** | Standard workflow | Log level ALL; X-Ray ON |

## Recipe 1 — Event-driven file processing

```json
{
  "StartAt": "StartGlueJob",
  "States": {
    "StartGlueJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "orders-etl-prod",
        "Arguments": {"--input.$": "$.detail.object.key"}
      },
      "Catch": [{
        "ErrorEquals": ["States.ALL"],
        "ResultPath": "$.error",
        "Next": "PublishDLQ"
      }],
      "End": true
    },
    "PublishDLQ": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage",
      "Parameters": {
        "QueueUrl": "https://sqs.us-east-1.amazonaws.com/ACCOUNT/sf-dlq",
        "MessageBody.$": "$"
      },
      "End": true
    }
  }
}
```

Enable **EventBridge** rule with dead-letter queue for failed invocations.

## Recipe 2 — Resilient Lambda integration

```json
"Retry": [{
  "ErrorEquals": ["Lambda.ServiceException", "Lambda.TooManyRequestsException"],
  "IntervalSeconds": 2,
  "MaxAttempts": 6,
  "BackoffRate": 2
}]
```

## Recipe 3 — Scheduled anomaly detection

```
EventBridge Scheduler → Step Functions (hourly Standard)
  → Athena startQueryExecution.sync
  → Choice: count > 0 → SNS PagerDuty
```

## Recipe 4 — MWAA handoff

Task invokes Lambda with MWAA CLI token pattern to POST `/api/v1/dags/{id}/dagRuns`.

Store MWAA hostname and credentials in Secrets Manager; fetch in first Task state.

## Recipe 5 — Express high-volume webhook

- Type: **EXPRESS** (sync or async per API Gateway integration).
- Enable **CloudWatch Logs** (required for Express debugging).
- Keep states &lt; 10; duration &lt; 30 s where possible.

## Monitoring thresholds

| Metric | Warning | Critical |
| --- | --- | --- |
| Execution failure rate | &gt; 1% | &gt; 5% |
| Execution duration p99 | &gt; 2× baseline | &gt; 5× baseline |
| Throttled events (EventBridge) | &gt; 0 sustained | &gt; 100/hr |
| DLQ depth | &gt; 0 sustained | &gt; 50 messages |

## Related

- [How to Use](03_How_To_Use.md)
- [Limitations](05_Limitations_And_Scenarios.md)
