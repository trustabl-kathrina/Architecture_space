---
title: Google Cloud Dataflow Learning Guide
section: "02.01"
status: complete
template: hub
last_reviewed: 2026-06-18
owner: architecture-team
tags: [gcp, dataflow, beam, learning-guide, training]
canonical: true
---
# Google Cloud Dataflow Learning Guide

Structured learning path for architects and engineers implementing Apache Beam pipelines on Google Cloud Dataflow.

## Prerequisites

- GCP project with Dataflow, Compute Engine, and Storage APIs enabled
- Familiarity with [Dataflow Architecture](../02.01.02.02.02.02_Dataflow_Architecture.md)
- Basic understanding of [Pub/Sub](../02.01.02.02.02.01_Pub_Sub_Architecture.md) for streaming ingest patterns
- Optional: [Beam Dataflow Model](../../../03_Open_Source/06_Beam/01_Beam_Dataflow_Model.md)

## Modules

| # | Module | Focus |
| ---: | --- | --- |
| 1 | [Overview](01_Overview.md) | What Dataflow is, Beam model, when to use |
| 2 | [Architecture](02_Architecture.md) | Workers, shuffle, Streaming Engine, fault tolerance |
| 3 | [How to Use](03_How_To_Use.md) | SDKs, pipeline options, templates, deployment |
| 4 | [Scenarios](04_Scenarios.md) | Enterprise streaming and batch patterns |
| 5 | [Limitations and Scenarios](05_Limitations_And_Scenarios.md) | Quotas, constraints, anti-patterns |
| 6 | [Costing](06_Costing.md) | Official GCP pricing and scenario models |
| 7 | [Real-Time Configuration](07_Real_Time_Configuration.md) | Recipes for latency, throughput, reliability |
| 8 | [Evaluation Criteria](08_Evaluation_Criteria.md) | Scorecard vs Flink, Spark, managed alternatives |
| 9 | [Benchmarking](09_Benchmarking.md) | 20 reference scenarios and expected outcomes |

## Quick links

- [Dataflow Architecture reference](../02.01.02.02.02.02_Dataflow_Architecture.md)
- [GCP Dataflow POC](../02.01.02.02.02.06_GCP_Dataflow_POC.md)
- [Official documentation](https://cloud.google.com/dataflow/docs)
- [Official pricing](https://cloud.google.com/dataflow/pricing)
