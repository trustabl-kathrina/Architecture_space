# Kafka Core Concepts

Understanding the core mechanics of Kafka is essential for designing scalable systems on top of it.

## The Append-Only Log
At its heart, Kafka is an append-only, immutable commit log. It does not track which messages have been read by consumers natively; it just retains data for a configured period.

## Core Entities
1.  **Broker**: A single Kafka server. A cluster consists of multiple brokers working together.
2.  **Controller (Zookeeper/KRaft)**: Historically, Zookeeper managed metadata, leader election, and cluster state. Modern Kafka uses **KRaft (Kafka Raft Metadata mode)**, removing the Zookeeper dependency and managing metadata directly within the broker quorum.
3.  **Topic**: A logical category or feed name to which records are published.
4.  **Partition**: The unit of scalability. A topic is split into partitions distributed across brokers.
5.  **Producer**: Applications that publish (write) events to topics.
6.  **Consumer**: Applications that subscribe to (read) topics.
7.  **Consumer Group**: A logical grouping of consumers that cooperate to consume a topic. Each partition is consumed by exactly one consumer in the group, ensuring parallel processing without duplicate reads.
8.  **Offset**: A sequential ID number assigned to messages within a partition. Consumers track their progress by committing their current offset (usually back to an internal Kafka topic `__consumer_offsets`).

## Read/Write Mechanics
*   Kafka uses the OS page cache heavily (Zero-copy network protocols) to achieve massive throughput. It relies on sequential disk I/O, which is incredibly fast even on spinning HDDs.

## Performance Tuning
*   **Producer Tuning**: Optimize `batch.size` (e.g., 64KB - 128KB), `linger.ms` (e.g., 10ms - 50ms), and enable compression (`lz4` or `zstd`) to massively improve throughput and reduce broker disk/network usage.
*   **Consumer Tuning**: Adjust `fetch.min.bytes` to allow the broker to wait and batch data before responding, and tune `max.poll.records` to prevent the consumer processing loop from timing out.
*   **Broker Tuning**: Increase `num.network.threads` and `num.io.threads` on machines with high core counts to parallelize request handling and disk I/O.
