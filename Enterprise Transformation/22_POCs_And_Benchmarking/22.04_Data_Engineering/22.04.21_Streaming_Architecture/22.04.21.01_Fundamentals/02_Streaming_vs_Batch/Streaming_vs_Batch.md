# Streaming vs. Batch Processing

Modern data architectures often involve a mix of streaming and batch processing. Understanding when to use which is a fundamental architectural decision.

## Batch Processing
*   **Data Characteristics**: Bounded data sets (finite size, known start and end).
*   **Execution**: Scheduled at specific intervals (hourly, daily, weekly).
*   **Latency**: High latency (minutes to hours).
*   **Paradigm**: Collect -> Store -> Process.
*   **Use Cases**: End-of-day financial reporting, complex historical aggregations, heavy machine learning model training, bulk data migrations.

## Stream Processing
*   **Data Characteristics**: Unbounded data (infinite continuous streams).
*   **Execution**: Continuous, long-running processes reacting to events as they arrive.
*   **Latency**: Low latency (milliseconds to seconds).
*   **Paradigm**: Collect -> Process -> Store/React.
*   **Execution Engine Types**:
    *   *Micro-batching (Spark Streaming)*: Collects streams into small buckets over a few seconds, processing them as mini-batch jobs.
    *   *Continuous Processing (Flink)*: Processes events one by one as they arrive, maintaining in-memory state. Required for true sub-millisecond latency.
*   **Use Cases**: Real-time fraud detection, dynamic pricing, real-time dashboards, IoT telemetry monitoring, alerting systems.

## Architectural Paradigms

### Lambda Architecture
Maintains separate, parallel batch and streaming pipelines. 
*   **Batch Layer**: For accuracy, heavy joins, and historical data.
*   **Speed Layer**: For real-time approximations.
*   **Serving Layer**: Merges views from both.
*   *Drawback*: Requires maintaining two separate codebases and processing engines.

### Kappa Architecture
A single stream-processing pipeline (e.g., Kafka + Flink) that handles both real-time and historical data.
*   Historical batch processing is treated simply as a stream starting from an older offset.
*   *Advantage*: Single codebase and compute framework.

### The Convergence (Lakehouse Streaming)
Modern frameworks (Spark Structured Streaming, Delta Live Tables, Apache Hudi) blur the lines, allowing unified APIs to handle both batch and streaming on top of object storage, effectively bridging Lambda and Kappa.
