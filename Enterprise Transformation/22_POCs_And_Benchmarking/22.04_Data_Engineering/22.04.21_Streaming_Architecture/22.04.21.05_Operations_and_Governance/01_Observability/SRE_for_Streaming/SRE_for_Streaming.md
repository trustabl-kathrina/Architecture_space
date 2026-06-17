# SRE (Site Reliability Engineering) for Streaming

Operating a streaming platform requires specific runbooks and incident response protocols, as data is constantly in motion.

## 1. Handling "Poison Pills"
A poison pill is a message that a consumer cannot process (e.g., malformed JSON, schema registry mismatch, business logic exception). It causes the consumer to crash, restart, read the same message, and crash again in an infinite loop.
*   **SRE Runbook**:
    1. Implement a **Dead Letter Queue (DLQ)** pattern natively in the code. Catch all unhandled exceptions, write the original payload + error trace to the `topic_name_dlq`, and `ack` the offset to move forward.
    2. Set up alerts on the DLQ throughput.
    3. SREs inspect the DLQ, fix the consumer code (or schema), and use a script to replay the DLQ back into the main topic.

## 2. Mitigating Extreme Consumer Lag
If an alert fires for "Consumer Lag > 1,000,000 messages":
*   **SRE Runbook**:
    1. Check Consumer CPU/Memory (Is the app crashing?).
    2. Check downstream dependencies (Is the database the app writes to throttling connections?).
    3. *Action*: Scale up consumer pods (up to the partition count limit).
    4. *Action*: If the backlog is too massive to clear, and data loss is acceptable for the specific use case, forcibly reset the consumer group offset to `LATEST` to drop the backlog and restore real-time processing.

## 3. Chaos Engineering
Streaming platforms must be tested for resilience continuously.
*   **Broker Assassination**: Use Chaos Mesh or Gremlin to kill a Kafka broker randomly during peak load.
    *   *Validation*: Producers must not lose data (`acks=all`), and consumers must experience < 5 seconds of latency spike while the controller elects a new partition leader.
*   **TaskManager Kill**: Terminate a Flink TaskManager.
    *   *Validation*: JobManager must detect failure, provision a new pod, download state from S3, and resume processing from the last checkpoint without duplicating output (Exactly-Once Semantics).
