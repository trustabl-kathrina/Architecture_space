# Capacity Planning for Streaming Infrastructure

Capacity planning for event streams requires calculating disk throughput, network bandwidth, and JVM memory, scaling linearly with data velocity.

## 1. Broker Storage Sizing
Kafka/Event Hubs storage is dictated by retention policies.
*   **Formula**: `(Ingestion Rate per day) * (Retention Days) * (Replication Factor) * (Buffer Margin)`
*   *Example*: 100 GB/day * 7 Days * RF 3 * 1.2 (20% overhead) = **2.52 TB of raw disk space required**.
*   *Optimization*: Use Tiered Storage (S3 offloading) to drastically reduce expensive SSD/EBS volume requirements for long-retention topics.

## 2. Broker Network Sizing
Network is usually the first bottleneck in a streaming cluster.
*   **Inbound**: 100 MB/s producer traffic.
*   **Outbound (Replication)**: 100 MB/s * 2 followers = 200 MB/s internal replication traffic.
*   **Outbound (Consumers)**: If you have 3 independent consumer groups, they draw 100 MB/s * 3 = 300 MB/s.
*   *Total Network Interface Requirement*: 600 MB/s. (Requires a 10 Gigabit network card).

## 3. Partition Sizing
Partitions dictate maximum parallelism.
*   **Rule of Thumb**: Aim for a maximum of 10MB/s throughput per partition. If your topic expects 100MB/s, you need at least 10 partitions.
*   **Broker Limit**: A single Kafka broker can comfortably handle ~4,000 partitions (or up to 50,000 with KRaft). Exceeding this increases the risk of slow leader elections during broker failures.

## 4. Stream Processor (Compute) Sizing
Sizing Flink or Spark involves JVM memory and CPU profiling.
*   **Task Slots (CPU)**: 1 slot = 1 CPU core. Number of slots should equal the number of Kafka partitions to achieve 1:1 parallelism.
*   **State Size (Memory/Disk)**: If processing massive tumbling windows, RocksDB will spill to disk. Ensure TaskManager nodes have fast local NVMe SSDs to prevent I/O blocking during state reads/writes.
