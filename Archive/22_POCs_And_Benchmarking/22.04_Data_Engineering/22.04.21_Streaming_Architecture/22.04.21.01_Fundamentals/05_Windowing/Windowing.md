# Windowing

Windowing is a core concept in stream processing that allows you to calculate aggregations (like SUM, AVERAGE, MIN, MAX) over an infinite, unbounded stream of data by slicing it into bounded, finite chunks.

## Explanation

Because a data stream never ends, you cannot simply say "give me the total sum of all sales." Instead, you must specify a boundary: "give me the total sum of sales *every hour*." Windowing defines these boundaries. A window conceptually creates a bucket, assigns events to that bucket based on their timestamps (Event Time) or arrival time (Processing Time), and evaluates the bucket's contents once the window closes.

## Types of Windowing

### 1. Tumbling Windows (Fixed Windows)
*   **Definition**: Fixed-size, contiguous, and non-overlapping time intervals.
*   **Behavior**: Every event belongs to exactly one window. Once the time interval expires, the window evaluates and a new one begins.
*   **Examples & Scenarios**:
    *   *Scenario*: Hourly revenue reporting.
    *   *Example*: A window size of 1 hour. Windows are created for `[10:00-11:00)`, `[11:00-12:00)`. An event at 10:45 goes into the first window. An event at 11:05 goes into the second.

### 2. Sliding Windows (Hopping Windows)
*   **Definition**: Fixed-size time intervals that overlap. Defined by two parameters: *window size* and *slide interval* (how often the window starts).
*   **Behavior**: Because the windows overlap, a single event can belong to multiple windows simultaneously.
*   **Examples & Scenarios**:
    *   *Scenario*: Real-time alerting for system monitoring.
    *   *Example*: A window size of 5 minutes, sliding every 1 minute. "Alert if CPU usage averages > 90% over the last 5 minutes, updated every 1 minute." An event at 10:02 belongs to the `[09:58-10:03)`, `[09:59-10:04)`, `[10:00-10:05)`, `[10:01-10:06)`, and `[10:02-10:07)` windows.

### 3. Session Windows
*   **Definition**: Dynamic windows defined by periods of activity followed by a gap of inactivity (timeout).
*   **Behavior**: Unlike fixed windows, session windows do not have a predetermined length. They start when the first event for a key arrives and close when no new events for that key arrive within the specified timeout period.
*   **Examples & Scenarios**:
    *   *Scenario*: User behavior analytics on an e-commerce website.
    *   *Example*: A user starts browsing (Window starts). They click around for 15 minutes, then leave the site. With a session gap of 30 minutes, the system waits. After 30 minutes of no clicks from that user, the session window closes, and the total time spent and pages viewed for that specific session are emitted.

### 4. Global Windows
*   **Definition**: All data belonging to the same key is assigned to a single, infinite window.
*   **Behavior**: Because the window never naturally closes, you *must* specify a custom Trigger mechanism (e.g., "evaluate every time 100 events arrive") to emit results.
*   **Examples & Scenarios**:
    *   *Scenario*: Cumulative transaction counting per user until a specific cancellation event occurs.

## Advanced Windowing Mechanics

### Triggers
Triggers determine *when* the contents of a window are materialized and emitted. A window can fire multiple times:
1.  **Early Firings**: Emitting a speculative/partial result before the watermark passes the window end (e.g., updating a dashboard every 5 seconds for a 1-hour window).
2.  **On-Time Firing**: Emitting the "final" result exactly when the watermark passes the window end.
3.  **Late Firings**: Emitting a corrected result when late data arrives (requiring allowed lateness).

### Eviction Policies
Evictors determine *when data is removed* from the window state. By default, data is kept until the window closes (plus allowed lateness). In highly complex Global windows or long-running sliding windows, explicit Evictors (e.g., "keep only the last 10,000 events" or "remove events older than 24 hours") are required to prevent memory/RocksDB explosions.
