# Replication and High Availability (HA)

Kafka's reliability stems from its ability to replicate partitions across multiple brokers.

## Replication Mechanics
*   **Replication Factor (RF)**: The number of copies of a partition. An RF of 3 means there is 1 Leader and 2 Followers. (Industry standard for production is RF=3).
*   **Leader**: All read and write requests for a partition go to the Leader broker.
*   **Followers**: Followers passively replicate data from the Leader.
*   **In-Sync Replicas (ISR)**: The subset of replicas that are fully caught up with the Leader. If a follower falls behind, it is removed from the ISR list.

## Producer Acknowledgements (`acks`)
The producer `acks` setting dictates when a write is considered successful:
*   `acks=0`: Fire and forget. Maximum throughput, high chance of data loss.
*   `acks=1`: Leader acknowledges the write. Risk of data loss if the leader crashes before replication.
*   `acks=all` (or `-1`): The leader waits for **all replicas in the ISR** to acknowledge the write. Highest durability, lowest throughput.

## `min.insync.replicas` Configuration
When using `acks=all`, `min.insync.replicas` specifies the minimum number of replicas that must acknowledge a write.
*   **The Golden Rule**: For highly durable systems, use `RF=3`, `acks=all`, and `min.insync.replicas=2`. This allows the cluster to tolerate the loss of 1 broker while still accepting new writes. If 2 brokers go down, writes will fail (to prevent data loss), but reads can continue.

## Rack Awareness
Kafka can be configured to place replicas on brokers located in different physical racks (or AWS Availability Zones).
*   *Benefit*: If an entire AZ goes offline, the partition remains available because replicas exist in other AZs.
