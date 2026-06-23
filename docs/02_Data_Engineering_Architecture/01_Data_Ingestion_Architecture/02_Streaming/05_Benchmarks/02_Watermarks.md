---
title: Watermarks
section: "02.01"
status: complete
template: concept
last_reviewed: 2026-06-18
owner: architecture-team
tags: []
canonical: true
---
# Watermarks

In distributed stream processing, dealing with time—specifically **Event Time**—is highly complex because events often arrive out of order or with unpredictable delays due to network partitions, offline devices, or distributed processing skew. Watermarks solve this problem.

## Explanation

A **Watermark** is a heuristic mechanism used by stream processing frameworks (like Apache Flink or Google Cloud Dataflow) to measure progress in *Event Time*. 

When the system generates a watermark of time $T$, it is making a declaration to the rest of the streaming pipeline: *"I do not expect to see any more events with an event timestamp less than or equal to $T$."*

Watermarks are what allow the system to know when it is safe to close a **Window** and emit the final results for that window. Without watermarks, the system would wait infinitely, just in case late data arrived.

### The Late Data Problem
If a watermark for 10:00 passes, the 10:00 window is calculated and closed. If an event suddenly arrives with an event time of 09:59, it is considered **Late Data**. Stream processors offer strategies to handle this:
1.  **Discard**: Ignore the late event.
2.  **Allowed Lateness**: Keep the window state around for an extra $N$ minutes and emit an updated (corrected) result.
3.  **Dead Letter Queue**: Route the late event to a side output for manual auditing.

## Examples & Scenarios

### Scenario 1: Mobile Gaming (Offline Synchronization)
*   **Context**: A user plays a mobile game on the subway without an internet connection. They score points at 14:00 and 14:05 (Event Time). They exit the subway at 14:30 and their phone syncs the data to the server (Ingestion Time).
*   **Without Watermarks**: If the system processed based on arrival time, the points would be incorrectly attributed to the 14:30 window. If it used strict event time without delays, the 14:00 window would have already closed empty.
*   **With Watermarks**: The system uses a *Bounded Out-of-Orderness Watermark*. It sets the watermark to track behind the maximum observed event time by a fixed delay (e.g., 35 minutes). 
    *   `Watermark = Max(Event Time) - 35 minutes`.
    *   The system waits until 14:35 (event time progress) to close the 14:00 window, giving the offline user's data time to arrive and be correctly calculated.

### Scenario 2: IoT Sensor Data and Network Skew
*   **Context**: Thousands of temperature sensors stream data to a central broker. Some sensors are on fast 5G networks, others on slow satellite links.
*   **The Issue**: Data for the 10:00:00 timestamp arrives from the 5G sensors at 10:00:01, but the satellite sensors don't deliver their 10:00:00 data until 10:00:15.
*   **The Solution**: A watermark is generated based on the slowest partition or a probabilistic model. The Flink job holds the 10:00 Tumbling Window open until the watermark crosses 10:00, ensuring the satellite data is included in the aggregation before the final average temperature is emitted.

## Expert Concepts

### 1. Watermark Propagation
In a distributed topology (e.g., Kafka -> Flink Operator A -> Flink Operator B), watermarks flow through the pipeline alongside the data. When an operator has multiple input partitions, its internal watermark is always the **MIN()** of the incoming watermarks. It guarantees that the entire pipeline moves forward safely.

### 2. The Idle Partition Problem
If one partition of a Kafka topic stops receiving data, its watermark stops advancing. Because downstream operators take the `MIN()` across all partitions, the entire pipeline's watermark stalls, preventing windows from closing. 
*   *Solution*: Advanced streaming frameworks allow marking a partition as "Idle" after a timeout, excluding it from the `MIN()` calculation so the rest of the stream can continue.
