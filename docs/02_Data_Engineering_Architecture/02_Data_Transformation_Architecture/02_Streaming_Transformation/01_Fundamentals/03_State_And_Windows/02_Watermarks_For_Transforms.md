---
title: Watermarks for Transforms
section: "02.02.02.01.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [watermarks, streaming]
canonical: true
---
# Watermarks for Transforms

## Purpose

Watermarks declare **how late** event-time data may arrive; windows close after watermark passes end of window.

## Configuration

``python
.withWatermark('event_ts', '10 minutes')
``n
## Late data strategies

| Strategy | Behavior |
| --- | --- |
| Drop | Ignore late events |
| Side output | Route to quarantine stream |
| Allowed lateness | Update closed windows (Flink) |

## Related

- [Stream-Table Duality](03_Stream_Table_Duality.md)
