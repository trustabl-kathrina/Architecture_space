# Azure Stream Analytics vs. Google Cloud Dataflow

This POC evaluates the managed stream processing offerings of Azure and GCP.

## Comparison Scenarios

### Scenario 1: Developer Experience (Low-Code vs. High-Code)
*   **Requirement**: Business analysts and data analysts need to build real-time dashboards without writing Java or Python.
*   **Azure Stream Analytics**: Uses a simple, familiar SQL dialect. Features a drag-and-drop UI in the Azure Portal. You can have a streaming pipeline from Event Hubs to Power BI running in 10 minutes without touching an IDE.
*   **Google Cloud Dataflow**: Requires writing Apache Beam code (Java, Python, Go). While Dataflow SQL exists, the primary development paradigm is software engineering, requiring IDEs, Maven/Gradle, and CI/CD pipelines.
*   *Winner*: **Azure Stream Analytics**

### Scenario 2: Advanced State and Unified Batch/Stream
*   **Requirement**: The pipeline requires complex, custom ML model inference inside the stream, and the exact same code must be used to backfill 5 years of historical data from object storage.
*   **Azure Stream Analytics**: Limited to what the ASA SQL dialect supports. Cannot easily embed complex custom Python/Java ML models into the real-time flow. Batch processing requires entirely different tools (e.g., Azure Data Factory).
*   **Google Cloud Dataflow**: Apache Beam is the ultimate unified API. The exact same Java/Python code runs the stream and the batch backfill. You can embed TensorFlow/PyTorch models directly into the Beam `DoFn` for inline inference.
*   *Winner*: **Google Cloud Dataflow**

### Scenario 3: Autoscaling
*   **Requirement**: The pipeline must handle sudden 10x traffic spikes automatically.
*   **Azure Stream Analytics**: Traditionally required manual scaling of Streaming Units (SUs). Auto-scaling requires configuring custom Azure Monitor rules or using the newer V2 clusters, but it is less seamless than GCP.
*   **Google Cloud Dataflow**: Features "Liquid Sharding" and Streaming Engine. It automatically detects CPU bottlenecks and backlogs, scales workers up, and dynamically splits hot keys mid-flight without any manual configuration.
*   *Winner*: **Google Cloud Dataflow**

## Head-to-Head Comparison & Validation

### Validation Criteria
1. **Developer Experience**: Validated against the team persona (Business Analysts requiring SQL vs. Software Engineers requiring Java/Python).
2. **Extensibility**: Validated against the requirement to embed custom Machine Learning models directly into the pipeline for inline scoring.
3. **Autoscaling Reactivity**: Validated by measuring the time and manual intervention required to handle a sudden 10x traffic spike.

### Capability Comparison Table
| Criteria | Azure Stream Analytics | Google Cloud Dataflow |
| :--- | :--- | :--- |
| **Target Persona** | Data/Business Analysts (Low-Code/SQL) | Software Engineers (High-Code/Beam) |
| **Language Support** | ASA SQL Dialect | Java, Python, Go, SQL |
| **ML Inference** | Limited / Complex via external endpoints | Excellent (Native embedding in Beam DoFns) |
| **Autoscaling Capability** | Evolving (SU scaling via Azure Monitor rules) | World-Class (Liquid Sharding / Streaming Engine) |
| **Latency** | Seconds | Milliseconds |
| **Throughput** | High | Extremely High |
| **Exactly Once Semantics** | Supported | Supported |
| **Deployment Model** | Fully Managed PaaS | Serverless PaaS |
| **Operational Complexity** | Low (UI/SQL driven) | Medium (Requires CI/CD and programming) |
