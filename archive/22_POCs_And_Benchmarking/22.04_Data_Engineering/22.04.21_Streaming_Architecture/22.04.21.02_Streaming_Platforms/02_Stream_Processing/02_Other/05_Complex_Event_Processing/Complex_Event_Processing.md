# Complex Event Processing (CEP)

Complex Event Processing is a specific domain of stream processing focused on identifying patterns and correlations across multiple events over time.

## CEP vs. Standard Stream Processing
*   **Standard Stream Processing**: "Sum all transaction amounts for the last 5 minutes." (Aggregations, Transformations).
*   **CEP**: "Detect if a user has 3 failed login attempts followed by a successful login from a different IP address within a 10-minute window." (Pattern Matching).

## Core Concepts
*   **Event Patterns**: Defining sequences of events. Frameworks often use a Regex-like syntax or a fluent API to define these patterns.
    *   `Strict Contiguity`: Events must happen exactly one after another (A -> B).
    *   `Relaxed Contiguity`: Events happen in order, but other events can occur in between (A -> ... -> B).
*   **Condition Evaluation**: Filtering events that match the pattern based on properties (e.g., `event.amount > 1000`).
*   **Within (Time Constraints)**: Patterns must usually complete within a specified Event Time window.

## Architectural Implementations
1.  **Apache Flink CEP**: A powerful library built on top of Flink. It compiles pattern definitions into an NFA (Non-deterministic Finite Automaton) state machine that evaluates the stream continuously.
2.  **Siddhi**: A dedicated, lightweight, SQL-like CEP engine. Often used in WSO2 or embedded in Java applications.
3.  **ksqlDB (Kafka)**: Supports some basic pattern matching capabilities, though less mature than Flink CEP for highly complex state machines.

## Common Use Cases
*   **Fraud Detection**: Detecting "impossible travel" (e.g., a credit card used in New York and London within 30 minutes).
*   **Cybersecurity / SIEM**: Detecting DDoS attack signatures or lateral movement patterns in network logs.
*   **Predictive Maintenance**: Monitoring IoT sensor data for specific sequences of temperature spikes and vibration drops that precede a machine failure.
