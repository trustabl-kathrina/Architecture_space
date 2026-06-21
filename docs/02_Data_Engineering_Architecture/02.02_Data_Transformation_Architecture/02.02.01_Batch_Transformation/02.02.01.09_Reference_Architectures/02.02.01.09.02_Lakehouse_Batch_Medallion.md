---
title: Lakehouse Batch Medallion Reference
section: "02.02.01.09"
status: complete
template: overview
last_reviewed: 2026-06-20
owner: architecture-team
tags: [reference, medallion]
canonical: true
---
# Lakehouse Batch Medallion

Bronze (raw Delta) to Silver (conformed MERGE) to Gold (dbt/Spark aggregates). Partition by date; OPTIMIZE/VACUUM schedule.
