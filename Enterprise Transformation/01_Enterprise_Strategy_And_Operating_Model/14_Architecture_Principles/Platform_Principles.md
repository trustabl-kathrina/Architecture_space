# Platform Engineering Principles

## Overview
Guidelines for building internal developer platforms and self-service infrastructure.

## Core Principles

1. **Platform as a Product**: The internal platform must be treated as a product, treating developers and data scientists as the customers.
2. **Paved Roads (Golden Paths)**: Provide highly automated, secure, and compliant default paths for deploying software. Deviations are allowed but unsupported.
3. **Self-Service First**: Capabilities must be provisionable via APIs or portals without requiring manual IT tickets.
4. **Reduce Cognitive Load**: Abstract away infrastructure complexity (e.g., K8s configuration) so domain teams can focus purely on business logic.
