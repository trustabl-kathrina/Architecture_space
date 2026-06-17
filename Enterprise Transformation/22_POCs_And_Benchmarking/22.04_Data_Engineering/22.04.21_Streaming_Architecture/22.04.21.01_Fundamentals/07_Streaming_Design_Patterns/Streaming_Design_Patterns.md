# Streaming Design Patterns

Proven architectural patterns for solving common problems in event-driven and streaming systems.

## Pattern Comparison Summary

| Pattern | Problem Solved | Pros | Cons | Typical Scenario |
| :--- | :--- | :--- | :--- | :--- |
| **Outbox** | Atomically updating DB and publishing an event without 2PC. | Guarantees at-least-once delivery; avoids distributed locking. | Requires CDC or polling process; eventual consistency. | Microservice placing an order and notifying downstream systems. |
| **Event Sourcing** | Losing historical context by only storing current state. | Perfect audit log; ability to rebuild state to any point in time. | High storage costs; complex to query current state without a read model. | Ledger systems, financial transactions, cart history. |
| **CQRS** | Write models and read models have conflicting optimization needs. | Independent scaling of reads/writes; highly optimized querying. | Eventual consistency; increased infrastructure complexity. | High-traffic e-commerce product catalog with complex search. |
| **Saga** | Distributed transactions failing and leaving data in inconsistent states. | Avoids blocking locks (2PC) across microservices; highly resilient. | Complex to trace (Choreography); requires writing compensating logic. | Travel booking (Flight + Hotel + Car) where one failure rolls back all. |
| **DLQ** | Poison pills crashing consumer loops. | Prevents pipeline blocking; preserves data for analysis/replay. | Requires monitoring and manual intervention logic to resolve. | Handling schema mismatches or unparsable JSON payloads. |
| **Stream Joins** | Enriching fast-moving data with reference or other fast data. | Enables real-time enrichment without querying external databases. | Complex state management; requires strict windowing/watermarking. | Enriching a stream of `user_clicks` with `user_profiles`. |

## 1. Outbox Pattern
*   **Problem**: How to atomically update a transactional database and publish a corresponding event to a message broker without distributed two-phase commits.
*   **Solution**: The application writes the business entity and the event to an "Outbox" table in the *same* database transaction. A separate process (typically Change Data Capture like Debezium) reads the Outbox table and publishes to the broker.

## 2. Event Sourcing
*   **Problem**: Storing just the current state of an entity loses historical context and auditability.
*   **Solution**: Store every change to the entity state as a sequence of immutable events in an append-only event store. The current state is derived dynamically by replaying the events.

## 3. CQRS (Command Query Responsibility Segregation)
*   **Problem**: Read and write workloads have drastically different scaling, indexing, and optimization needs.
*   **Solution**: Separate the write model (Commands) from the read model (Queries). Events are used to asynchronously synchronize the write database with one or more highly optimized read databases (e.g., Elasticsearch for text search, Redis for key-value lookups).

## 4. Saga Pattern
*   **Problem**: Implementing distributed transactions across multiple microservices without blocking locks (2PC).
*   **Solution**: A sequence of local transactions where each step updates data within a single service and publishes an event to trigger the next step. If a step fails, **compensating transactions** are triggered to undo previous steps.
    *   *Choreography*: Decentralized event-based triggers between services.
    *   *Orchestration*: Centralized orchestrator service manages the saga state machine.

## 5. Dead Letter Queue (DLQ)
*   **Problem**: Handling "poison pills" (messages that cannot be deserialized or processed due to schema mismatches or unrecoverable business errors).
*   **Solution**: Route unprocessable messages to a separate queue (DLQ) for alerting, manual inspection, schema evolution fixes, and eventual replay.

## 6. Stream Joins
*   **Stream-Stream Joins**: Joining two infinite streams (requires windowing to bound the state).
*   **Stream-Table Joins**: Joining an event stream with a mutating table (e.g., enriching transaction streams with user profile data).
