# Windowing Strategies

Because streaming data is infinite, you cannot perform aggregations (like "SUM" or "AVERAGE") on the entire stream. You must bound the stream into finite chunks called **Windows**.

## Types of Windows

### 1. Tumbling Windows (Fixed)
*   **Concept**: Fixed-size, non-overlapping time intervals.
*   **Example**: "Count the number of errors every 5 minutes." (00:00-00:05, 00:05-00:10).
*   **Use Case**: Hourly reporting, billing metrics. An event belongs to exactly one window.

### 2. Sliding / Hopping Windows
*   **Concept**: Fixed-size intervals that overlap. Defined by a *window size* and an *advance/slide interval*.
*   **Example**: "Count the number of errors over the last 5 minutes, updated every 1 minute."
*   **Use Case**: Moving averages, real-time trending dashboards. An event can belong to multiple windows.

### 3. Session Windows
*   **Concept**: Dynamic windows defined by periods of activity separated by a gap of inactivity (timeout).
*   **Example**: "Group all user clicks into a session. If the user is inactive for 30 minutes, close the session."
*   **Use Case**: User behavior analytics, cart abandonment tracking. Windows are specific to a particular key (user) and vary in length.

### 4. Global Windows
*   **Concept**: All data with the same key is assigned to a single, infinite global window.
*   **Requirement**: You *must* define custom Triggers to emit data, otherwise, the window will never close and never emit results.

## Triggers
Triggers determine *when* the contents of a window are emitted.
*   **Watermark Triggers**: Emit when the system's watermark (event time tracker) passes the end of the window.
*   **Processing Time Triggers**: Emit periodically based on wall-clock time (e.g., "update the dashboard every 10 seconds with current window progress").
*   **Data-Driven/Count Triggers**: Emit after a certain number of events arrive.
