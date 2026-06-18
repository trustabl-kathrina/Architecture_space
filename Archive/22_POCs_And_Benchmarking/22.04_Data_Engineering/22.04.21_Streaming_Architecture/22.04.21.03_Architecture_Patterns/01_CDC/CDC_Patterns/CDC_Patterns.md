# CDC Patterns

CDC enables powerful architectural patterns beyond simple data replication.

## 1. The Transactional Outbox Pattern
In a microservices architecture, a service often needs to update its local database and publish an event to Kafka atomically. Two-Phase Commit (2PC) is slow and prone to failure.
*   **The Pattern**: The service writes the business entity update AND inserts an event record into an `Outbox` table within the *same local database transaction*.
*   **The CDC Role**: Debezium monitors the `Outbox` table. As soon as the transaction commits, Debezium captures the outbox row and publishes it to Kafka. This guarantees At-Least-Once delivery of the event without distributed transactions.

## 2. Strangler Fig Pattern (Legacy Modernization)
Used to migrate away from a monolithic legacy database with zero downtime.
*   **The Pattern**: CDC captures all writes to the legacy database and streams them to the new microservice's database. The new service's read paths are tested against live data. Once verified, write traffic is cut over to the new service.

## 3. Cache Invalidation
Maintaining cache consistency is notoriously difficult.
*   **The Pattern**: Instead of the application trying to update the database and the cache (Redis/Memcached) simultaneously, the application only writes to the DB. A CDC pipeline listens to the DB log and asynchronously updates or invalidates the cache entries.

## 4. CQRS Read Model Synchronization
In CQRS, the write database is highly normalized (e.g., Postgres), but the read database is optimized for search (e.g., Elasticsearch).
*   **The Pattern**: CDC streams updates from Postgres, a stream processor (like Flink) joins the data into a denormalized view, and writes the materialized view to Elasticsearch for sub-second querying.
