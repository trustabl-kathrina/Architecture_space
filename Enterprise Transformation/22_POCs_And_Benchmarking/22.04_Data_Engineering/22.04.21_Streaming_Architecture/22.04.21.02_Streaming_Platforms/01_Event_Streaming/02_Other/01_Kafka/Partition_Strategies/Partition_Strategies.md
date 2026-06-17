# Partition Strategies

Partitions are the fundamental unit of parallelism and ordering in Kafka. Choosing the right partitioning strategy is crucial for performance and correctness.

## The Role of Partitions
*   **Parallelism**: You can only have as many active consumers in a group as you have partitions. (If you have 10 partitions and 12 consumers, 2 consumers sit idle).
*   **Ordering**: Kafka *only* guarantees strict ordering of messages **within a single partition**. There is no global ordering across a topic.

## Partitioning Strategies
1.  **Default Partitioner (Round-Robin / Sticky)**
    *   If no key is provided, the producer distributes messages evenly across partitions.
    *   *Pros*: Perfectly balanced load.
    *   *Cons*: No ordering guarantees.
2.  **Key-Based Partitioning (Hash-based)**
    *   Messages with a key (e.g., `user_id`, `device_id`) are hashed (`hash(key) % num_partitions`). All messages with the same key go to the same partition.
    *   *Pros*: Guarantees ordering per entity (e.g., all events for User A are processed sequentially).
    *   *Cons*: Susceptible to **Data Skew** (Hot Partitions) if some keys have massively higher volume than others.
3.  **Custom Partitioning**
    *   Implementing a custom `Partitioner` class.
    *   *Use Case*: Routing specific VIP customer traffic to dedicated, isolated partitions, or handling extreme data skew scenarios.

## Dealing with Hot Partitions (Data Skew)
If "Customer A" generates 80% of traffic, key-based partitioning will overwhelm a single partition/broker.
*   *Solution 1 (Salting)*: Append a random number to the key (`CustomerA-1`, `CustomerA-2`) to spread the load. Consumers must aggregate the results downstream.
*   *Solution 2 (Two-Phase Processing)*: Process the heavy keys without ordering first, aggregate them partially, and then route to a final ordered topic.

## Scaling Partitions
*   You can increase the number of partitions in a topic, but you **cannot decrease them**.
*   *Warning*: Increasing partitions breaks key-based ordering (the hash modulo changes). If ordering is critical, you must create a new topic with the desired partitions and migrate the data.
