# Disaster Recovery (DR) in Streaming

Streaming clusters are stateful, making cross-region DR complex. Unlike stateless microservices, you cannot just redirect traffic via DNS; you must replicate the data.

## DR Architectures

### 1. Active-Passive (Mirroring)
*   **Concept**: Region A is active. All producers and consumers connect here. A replication tool asynchronously copies topics to Region B.
*   **Tools**: Kafka MirrorMaker 2 (MM2), Confluent Cluster Linking.
*   **The Offset Problem**: Offsets are local to a cluster. Message #100 in Region A might be Message #105 in Region B. If you fail over, consumers don't know where to resume.
*   **Solution**: MM2 translates consumer offsets continuously. Upon failover, consumers start in Region B using the translated offsets.

### 2. Active-Active (Stretched Clusters)
*   **Concept**: A single Kafka cluster stretched across multiple regions (e.g., AWS us-east-1 and us-west-2).
*   **Pros**: Zero RPO (Recovery Point Objective). A single logical cluster makes consumer failover trivial.
*   **Cons**: Extremely sensitive to cross-region latency. Synchronous replication (`acks=all`) across regions will severely degrade producer throughput. Only viable if regions are geographically very close (e.g., GCP regions in Europe).

## RTO and RPO
*   **RPO (Recovery Point Objective)**: How much data can you afford to lose? In asynchronous active-passive setups, RPO is strictly greater than 0 (usually seconds of data in flight).
*   **RTO (Recovery Time Objective)**: How fast can you fail over? Requires automated DNS cutovers and pre-warmed stream processing clusters in the DR region.
