---
title: Spark Structured Streaming Costing
section: "02.02.02.03.03"
status: complete
template: evaluation
last_reviewed: 2026-06-20
owner: architecture-team
tags: [streaming transformation, learning-guide]
canonical: true
---
# 6. Spark Structured Streaming Costing

## Pricing model

| Component | Billing unit |
| --- | --- |
| Compute | vCPU-hour / DPU / slot-second |
| Storage | GB-month for checkpoints and temp |
| Network | Egress cross-AZ/region |
| Licensing | Enterprise support (if applicable) |

## TCO scenarios (indicative)

| Scenario | Monthly volume | Est. relative cost |
| --- | --- | --- |
| **Small** | 100 GB transform/day | \$ |
| **Medium** | 2 TB/day, 15m NRT | \$\$ |
| **Large** | 20 TB/day, streaming | \$\$\$ |

## Cost optimization

1. Use preemptible/Flex workers for batch tiers.
2. Compress shuffle and enable predicate pushdown.
3. Schedule heavy jobs off-peak.
4. Archive cold checkpoints and logs.

## FinOps checklist

- [ ] Tag jobs by cost center
- [ ] Budget alerts at 80/100%
- [ ] Monthly review of top 10 expensive jobs

## Related

- [Official pricing](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html)
