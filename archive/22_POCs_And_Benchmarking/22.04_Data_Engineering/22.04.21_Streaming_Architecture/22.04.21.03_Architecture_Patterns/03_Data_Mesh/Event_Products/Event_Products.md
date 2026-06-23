# Event Products (Real-Time Data Products)

In a Data Mesh, a Data Product is the fundamental unit of architecture. While traditionally Data Products are thought of as batch tables (e.g., in Snowflake), in a streaming mesh, **Kafka Topics are Data Products**.

## Characteristics of an Event Product
1.  **Discoverable**: Registered in a central data catalog (e.g., Collibra, Datahub) with metadata indicating it is a real-time stream.
2.  **Addressable**: A stable URl or connection string (e.g., a specific Kafka cluster and topic name).
3.  **Trustworthy**: High SLA, guaranteed uptime, and strict schema validation (Schema Registry).
4.  **Self-Describing**: The schema (Avro/Protobuf) clearly defines every field, its data type, and its business meaning.
5.  **Interoperable**: Adheres to global company standards for event envelopes (e.g., CloudEvents format).

## The Domain Team's Responsibility
*   The "Inventory" team owns the `inventory.stock.updated` topic.
*   They are responsible for the stream's data quality. If they change the schema incompatibly and break a downstream consumer, it is the Inventory team's fault.

## Internal vs. External Streams
*   **Operational Streams (Internal)**: "Raw" events used exclusively within a domain for microservice choreography. Not published to the mesh.
*   **Analytical Streams (External)**: Cleaned, enriched "Data Products" published to the mesh for other domains to consume.
