# Schema Registry

A Schema Registry provides a centralized repository for managing and validating schemas for Kafka message payloads. It acts as the "Data Contract" for your event-driven architecture.

## Why is it needed?
Without a schema registry, producers and consumers rely on implicit agreements about data formats (e.g., JSON structure). If a producer changes a field name, downstream consumers break silently ("Poison Pills").

## Core Architecture
1.  **Supported Formats**: Avro (most common), Protobuf, and JSON Schema.
2.  **How it Works**: 
    *   The Producer registers the schema with the Registry and receives a Schema ID.
    *   The Producer prepends the payload with a Magic Byte + the Schema ID, then sends the serialized binary data to Kafka.
    *   The Consumer reads the ID, fetches the schema from the Registry (caching it locally), and deserializes the payload.
    *   *Result*: Kafka payloads are much smaller because the schema itself is not sent in every message.

## Schema Evolution & Compatibility Rules
As business requirements change, schemas must evolve. The Schema Registry enforces compatibility checks before allowing a producer to publish with a new schema.
*   **Backward Compatibility** (Default): Consumers using the *new* schema can read data produced with the *old* schema. (e.g., Adding a new optional field, or deleting a field).
*   **Forward Compatibility**: Consumers using the *old* schema can read data produced with the *new* schema. (e.g., Adding a new field, or deleting an optional field).
*   **Full Compatibility**: Both backward and forward compatible.
*   **None**: Schema validation is disabled.

## Best Practices
*   Always use `BACKWARD` or `FULL` compatibility in production.
*   Use a dedicated Schema Registry cluster for high availability.
*   Handle Schema IDs carefully in Dead Letter Queues (DLQ).
