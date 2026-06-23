---
title: AI Metadata Management
section: "02.03.04.04"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [ai, metadata, orchestration]
canonical: true
---
# AI Metadata Management

## Problem

Catalogs suffer from stale descriptions, missing owners, and inconsistent tags. **AI metadata management** auto-enriches documentation and links orchestrator objects to catalog entities.

## Capabilities

| Capability | Orchestration link |
| --- | --- |
| Auto-description | From DAG docstring → catalog dataset |
| Tag suggestion | domain:finance, 	ier:T0 from path and SLA |
| Owner inference | Git blame → steward assignment |
| Duplicate detection | Merge duplicate dataset URIs affecting triggers |

## Sync loop

On each prod DAG deploy, CI job extracts metadata → LLM enriches → catalog PR for steward approval → approved URI used in [Metadata Orchestration](../02_Metadata_Driven/07_Metadata_Orchestration.md).

## Related

- [Active Metadata](../../01_Fundamentals/06_Active_Metadata/01_Active_Metadata.md)
- [Orchestration Governance](../../01_Fundamentals/04_Governance/01_Orchestration_Governance.md)