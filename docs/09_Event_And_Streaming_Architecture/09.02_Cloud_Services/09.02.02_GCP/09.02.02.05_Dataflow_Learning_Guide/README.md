---
title: Google Cloud Dataflow Learning Guide
section: "09.02"
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
- Familiarity with [Dataflow Architecture](../09.02.02.02_Dataflow_Architecture.md)
- Basic understanding of [Pub/Sub](../09.02.02.01_Pub_Sub_Architecture.md) for streaming ingest patterns
- Optional: [Beam Dataflow Model](../../../09.03_Open_Source/09.03.06_Beam/09.03.06.01_Beam_Dataflow_Model.md)

## Modules

| # | Module | Focus |
| ---: | --- | --- |
| 1 | [Overview](09.02.02.05.01_Overview.md) | What Dataflow is, Beam model, when to use |
| 2 | [Architecture](09.02.02.05.02_Architecture.md) | Workers, shuffle, Streaming Engine, fault tolerance |
| 3 | [How to Use](09.02.02.05.03_How_To_Use.md) | SDKs, pipeline options, templates, deployment |
| 4 | [Scenarios](09.02.02.05.04_Scenarios.md) | Enterprise streaming and batch patterns |
| 5 | [Limitations and Scenarios](09.02.02.05.05_Limitations_And_Scenarios.md) | Quotas, constraints, anti-patterns |
| 6 | [Costing](09.02.02.05.06_Costing.md) | Official GCP pricing and scenario models |
| 7 | [Real-Time Configuration](09.02.02.05.07_Real_Time_Configuration.md) | Recipes for latency, throughput, reliability |
| 8 | [Evaluation Criteria](09.02.02.05.08_Evaluation_Criteria.md) | Scorecard vs Flink, Spark, managed alternatives |
| 9 | [Benchmarking](09.02.02.05.09_Benchmarking.md) | 20 reference scenarios and expected outcomes |

## Quick links

- [Dataflow Architecture reference](../09.02.02.02_Dataflow_Architecture.md)
- [GCP Dataflow POC](../09.02.02.06_GCP_Dataflow_POC.md)
- [Official documentation](https://cloud.google.com/dataflow/docs)
- [Official pricing](https://cloud.google.com/dataflow/pricing)
