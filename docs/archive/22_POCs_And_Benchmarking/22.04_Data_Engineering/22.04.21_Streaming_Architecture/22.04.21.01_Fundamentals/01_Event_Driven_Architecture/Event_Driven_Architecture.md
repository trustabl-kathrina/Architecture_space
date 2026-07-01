# Event-Driven Architecture (EDA)

Event-Driven Architecture is a software architecture paradigm promoting the production, detection, consumption of, and reaction to events.

## Core Concepts
*   **Event**: A significant change in state (e.g., `OrderPlaced`, `PaymentProcessed`). Events are immutable facts about the past.
*   **Command vs. Event**: A command is an *intent* to change state (`PlaceOrder`). An event is a *fact* that state has changed (`OrderPlaced`).
*   **Producers/Publishers**: Systems that generate and emit events without knowing who will consume them.
*   **Consumers/Subscribers**: Systems that listen for specific events and react accordingly.
*   **Event Broker**: The intermediary infrastructure (e.g., Kafka, Pub/Sub, EventBridge) that receives, routes, and stores events.

## Key Architectural Benefits
*   **Decoupling**: Producers and consumers scale and deploy independently.
*   **Agility**: New consumers can be added without modifying existing producers.
*   **Resilience**: If a consumer goes down, the broker buffers the events until it recovers.

## Challenges
*   **Eventual Consistency**: State is updated asynchronously across microservices.
*   **Observability**: Tracing an event lifecycle across multiple decoupled services is complex.
*   **Error Handling**: Requires robust Dead Letter Queues (DLQ) and retry mechanisms.

## Expert Concepts: EDA Communication Patterns
1.  **Event Notification**: A system sends a minimalist event (e.g., `Order_ID: 123 Created`). Downstream consumers must call an API back to the source to get the full order details. (High network chatter, strong decoupling).
2.  **Event-Carried State Transfer**: The event contains all necessary data (e.g., the full order JSON). Downstream systems cache this locally to avoid calling APIs. (Lower latency, higher storage overhead).
3.  **Event Choreography vs. Orchestration**:
    *   *Choreography*: Decentralized. Service A fires an event, Service B listens and reacts, firing its own event. (Highly decoupled, hard to trace).
    *   *Orchestration*: Centralized. An orchestrator (e.g., temporal.io, AWS Step Functions) receives events and commands services what to do next. (Easier to trace, introduces a central point of coupling).
4.  **CloudEvents Specification**: A CNCF standard for describing event data in a common way, enabling interoperability across different clouds and tools by standardizing the event envelope (headers).
