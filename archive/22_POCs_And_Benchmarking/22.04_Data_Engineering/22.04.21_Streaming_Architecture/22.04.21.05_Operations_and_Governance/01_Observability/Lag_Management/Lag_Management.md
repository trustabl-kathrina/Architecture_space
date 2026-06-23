# Lag Management

In stream processing, **Consumer Lag** is the ultimate indicator of system health. It measures the delta between the last message produced to the broker and the last message processed by the consumer.

## The Two Types of Lag
1.  **Offset Lag**: The difference in offset numbers (e.g., Producer is at offset 1000, Consumer is at 900. Lag = 100 messages).
2.  **Time Lag**: The difference in time between when the oldest unprocessed message was produced and the current wall-clock time (e.g., The consumer is processing data that is 5 minutes old). *Time lag is usually the more important business metric.*

## Causes of Lag
*   **Throughput Spike**: A sudden burst of traffic that exceeds the consumer's maximum processing rate.
*   **Poison Pill**: A malformed message causes the consumer to crash and restart repeatedly in a loop, halting progress on that partition.
*   **External Sink Latency**: The stream processor is trying to write to a database (e.g., Postgres), and the database is slow, causing backpressure up into the stream processor.

## Architectural Solutions
*   **Autoscaling based on Lag**: Use KEDA (Kubernetes Event-driven Autoscaling) to dynamically spin up more consumer pods based on the Kafka topic lag metric from Prometheus.
*   **Dead Letter Queues (DLQ)**: Trap poison pills immediately and route them to a DLQ so the consumer can advance its offset and continue processing healthy data.
*   **Async I/O**: If querying external databases, use asynchronous, non-blocking I/O clients to prevent thread starvation in the stream processor.
