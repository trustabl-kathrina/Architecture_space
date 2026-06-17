# IoT Streaming Architecture

IoT architectures are designed to handle millions of concurrent device connections, intermittent connectivity, and extremely high-volume, small-payload telemetry.

## Core Components
1.  **Edge / Devices**: Sensors, vehicles, or industrial machines communicating via lightweight protocols (MQTT, CoAP).
2.  **IoT Gateway / Ingestion Hub**:
    *   *AWS IoT Core / Azure IoT Hub*: Managed MQTT brokers that terminate connections, handle device authentication (X.509 certificates), and route rules.
3.  **Stream Buffer**:
    *   Data is routed from the IoT Hub to a highly partitioned stream (Kafka, Kinesis, Event Hubs) to buffer bursts of traffic.
4.  **Real-Time Rules Engine**:
    *   *Apache Flink / Spark Streaming*: Evaluating complex event processing (CEP) rules (e.g., "Alert if temperature > 100 for 5 consecutive minutes").
5.  **Time-Series Storage**:
    *   *InfluxDB, TimescaleDB, or Amazon Timestream*: Optimized databases for storing and querying timestamped metrics.

## Design Principles
*   **Design for Intermittent Connectivity**: Devices will go offline. The architecture must handle massive spikes of backlogged data when devices reconnect, relying heavily on **Event Time** processing rather than Processing Time.
*   **Stateless Edge, Stateful Cloud**: Keep edge devices as dumb as possible; push complex stateful processing to the cloud stream processor.
*   **Data Tiering**: Telemetry data loses value rapidly. Store raw data for 7 days in a hot cache, aggregate to hourly blocks for 30 days, and archive to cold storage (S3/Glacier) indefinitely.

## Pros & Cons
*   *Pros*: Highly scalable, handles millions of connections, robust security models built into cloud IoT hubs.
*   *Cons*: Handling out-of-order data is very complex, high cloud costs for MQTT message routing at scale.
