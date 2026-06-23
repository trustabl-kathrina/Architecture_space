---
title: Stream Processing Overview
section: "02.02.02.01.02"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [streaming, fundamentals]
canonical: true
---
# Stream Processing Overview

## Definition

**Stream processing** applies transformations to unbounded event sequences with low latency, maintaining state across events.

## Core concepts

| Concept | Description |
| --- | --- |
| **Event** | Immutable record with timestamp and payload |
| **Stream** | Ordered sequence of events |
| **Operator** | Map, filter, join, aggregate on streams |
| **Sink** | Materialized output (lake, DB, topic) |

## Processing guarantees

| Guarantee | Meaning |
| --- | --- |
| At-most-once | May lose events |
| At-least-once | May duplicate; idempotent sinks required |
| Exactly-once | End-to-end once (engine + transactional sink) |

## Related

- [State and Windows](../03_State_And_Windows/01_State_And_Windows.md)
