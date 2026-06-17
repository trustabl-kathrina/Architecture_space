# Customer 360 Streaming Architecture

The goal of a Real-Time Customer 360 is to aggregate a user's interactions across all channels (web, mobile, in-store, customer support) into a single, instantly updated profile to drive personalized experiences.

## Architecture Blueprint

### 1. Ingestion (The "Omni-channel" Sources)
*   **Web/Mobile Clickstream**: Trackers send events directly to Kafka via an API Gateway.
*   **Transactional DBs**: Debezium captures purchases, account updates, and returns from legacy RDBMS.
*   **SaaS/CRM**: Kafka Connect pulls support tickets from Zendesk or Salesforce.

### 2. Stream Processing (Identity Resolution & Aggregation)
*   **Flink or Kafka Streams** consumes all source topics.
*   *Identity Resolution*: Events often have different identifiers (a browser cookie ID vs. a logged-in User ID). The stream processor maintains a stateful graph of ID mappings to attribute anonymous web clicks to a known user once they log in.
*   *Profile Aggregation*: The processor updates a massive `StateStore` (RocksDB) keeping the running totals (e.g., `lifetime_value`, `last_viewed_category`, `open_support_tickets`).

### 3. Materialization (Serving the Profile)
*   The stream processor continuously sinks the updated profile to a **Low-Latency Key-Value Store** (e.g., Redis, DynamoDB, Cassandra, or Aerospike).
*   *Key*: `user_id`. *Value*: A JSON blob of the complete profile.

### 4. Consumption
*   When the user browses the website, the recommendation microservice performs a sub-millisecond `GET` against Redis to retrieve their up-to-the-second profile and tailors the UI accordingly.
