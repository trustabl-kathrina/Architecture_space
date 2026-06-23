# Topic Design

Topic design is the foundation of a clean event-driven architecture. Poor topic design leads to governance nightmares and data swamps.

## Naming Conventions
Establish a strict naming convention. A common pattern is:
`<domain>.<environment>.<entity>.<event-type>`
*   *Example*: `sales.prd.order.created`
*   *Example*: `inventory.uat.stock.updated`

## Topic Granularity
*   **Fat Topics (Single Topic, Multiple Event Types)**: Putting all `Order` events (Created, Shipped, Cancelled) in one `orders` topic.
    *   *Pros*: Strict global ordering for the entity lifecycle.
    *   *Cons*: Consumers must filter out event types they don't care about.
*   **Thin Topics (One Topic per Event Type)**: Separate topics for `order-created` and `order-shipped`.
    *   *Pros*: Consumers only subscribe to what they need.
    *   *Cons*: Difficult to guarantee ordering between a "Create" and a "Ship" event if they end up on different partitions.
*   *Recommendation*: Default to Fat Topics based on the aggregate root (Domain-Driven Design), using the Entity ID as the partition key.

## Log Compaction
By default, Kafka deletes data based on time (e.g., 7 days) or size (e.g., 50GB).
*   **Compacted Topics**: Instead of deleting old data, Kafka keeps the *latest* value for each distinct key.
*   *Use Case*: Maintaining current state (e.g., a topic of user profiles where the key is `user_id`). This allows new consumers to bootstrap state by reading the topic from the beginning, getting only the most up-to-date profile for every user without processing years of history.

## Retention Policies
*   **Transient Data (Logs, Telemetry)**: Short retention (hours to days).
*   **Domain Events (Business Facts)**: Long or infinite retention. Storage is cheap, and infinite retention allows for "Event Sourcing" and the ability to rebuild read models or debug historical issues at any time.
