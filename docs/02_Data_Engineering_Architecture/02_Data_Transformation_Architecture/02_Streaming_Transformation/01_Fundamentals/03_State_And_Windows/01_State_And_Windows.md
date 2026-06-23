---
title: State and Windows
section: "02.02.02.01.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [streaming, state, windows]
canonical: true
---
# State and Windows

## Stateful operators

Aggregations, joins, and sessionization require **state** stored in RocksDB (Flink) or memory+checkpoint (Spark SS).

## Window types

| Window | Use case |
| --- | --- |
| Tumbling | Fixed non-overlapping buckets |
| Sliding | Moving averages |
| Session | User activity gaps |
| Global | Single window (careful with unbounded state) |

## Event time vs processing time

- **Event time** - when event occurred (correct for analytics).
- **Processing time** - when processed (simple, non-deterministic under lag).

## Related

- [Watermarks for Transforms](02_Watermarks_For_Transforms.md)
