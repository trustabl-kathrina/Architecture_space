---
title: NRT Transformation Interview Questions
section: "02.02.03.07"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [interview, nrt]
canonical: true
---
# NRT Transformation Interview Questions

## Fundamentals

1. **Define near-real-time transformation.** How does it differ from batch and true streaming?
2. **Explain micro-batch vs continuous processing.** Trade-offs in cost and latency?
3. **What is a watermark?** How does it affect windowed NRT aggregations?
4. **Why use MERGE instead of append** for CDC silver tables?
5. **Describe checkpointing** in Spark Structured Streaming micro-batch jobs.

## Architecture

6. **Design an NRT pipeline** from Kafka to Delta silver with 5-minute freshness SLA.
7. **How would you handle late-arriving data** beyond the watermark?
8. **Compare trigger-based orchestration vs engine-native triggers.**
9. **How do you backfill** an NRT table without duplicating rows?
10. **Explain idempotency** in foreachBatch MERGE patterns.

## Operations

11. **What metrics alert you** that NRT SLA is at risk?
12. **How do you right-size trigger interval** vs cost?
13. **Describe failure recovery** when checkpoint corruption occurs.

## Related

- [NRT Reference Architecture](../../09_Reference_Architectures/01_NRT_Lakehouse_Transform_Reference.md)
