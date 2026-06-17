# Google Cloud Pub/Sub Architecture

Pub/Sub is Google's fully managed, serverless, real-time messaging service that allows you to send and receive messages between independent applications.

## Core Concepts
*   **Topic**: A named resource to which messages are sent by publishers.
*   **Subscription**: A named resource representing the stream of messages from a single, specific topic, to be delivered to the subscribing application.
*   **Message**: The combination of data and (optional) attributes that a publisher sends to a topic.

## Architectural Differentiators (vs. Kafka)
*   **Serverless**: No clusters, no brokers, no partitions to manage. It scales from 0 to millions of messages per second automatically.
*   **Routing**: Kafka uses a partitioned log. Pub/Sub uses a routing model. If 5 consumers attach to a subscription, Pub/Sub load-balances the messages to whichever consumer is available (Compete-Consumer pattern).
*   **Ordering**: Traditionally, Pub/Sub did not guarantee ordering. It now supports *Ordering Keys*, which behave somewhat like Kafka partitions, ensuring strict ordering for messages with the same key.
*   **Exactly-Once Delivery**: Pub/Sub natively supports Exactly-Once Delivery within a region, eliminating the need for complex deduplication logic in the subscriber for most use cases.

## Push vs. Pull Subscriptions
*   **Pull**: The consumer explicitly requests messages. Good for large-scale stream processing (e.g., Dataflow).
*   **Push**: Pub/Sub pushes messages via HTTP POST to a webhook endpoint (e.g., Cloud Run or Cloud Functions). Excellent for lightweight serverless event-driven architectures.

## Performance Tuning
*   **Batching**: Tune `maxMessages`, `maxBytes`, and `maxDelay` in the publisher client to group messages, reducing API calls and improving network efficiency.
*   **Flow Control**: To prevent consumer Out-Of-Memory (OOM) crashes, strictly enforce `maxOutstandingMessages` and `maxOutstandingBytes` in the subscriber client.
*   **Streaming Pull**: Always prefer Streaming Pull over Synchronous Pull for high-throughput consumers to maintain persistent bidirectional connections.
