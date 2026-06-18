# Azure Cloud-Native Streaming Architecture

Architecting for streaming on Microsoft Azure heavily leverages their native PaaS ecosystem.

## Blueprint 1: The Modern Azure Data Streaming Stack
Optimal for telemetry, log ingestion, and real-time dashboards.
1.  **Ingestion**: Devices/Microservices -> Azure Event Hubs.
2.  **Processing**: Azure Stream Analytics reads from Event Hubs, performs windowed aggregations, and joins with reference data from Azure SQL.
3.  **Storage / Sink**: 
    *   *Hot Path*: ASA outputs to Power BI natively for real-time dashboards, or to Cosmos DB for low-latency operational serving.
    *   *Cold Path*: Event Hubs Capture automatically writes the raw stream to Azure Data Lake Storage (ADLS Gen 2) in Parquet format for historical batch processing.

## Blueprint 2: Azure Lakehouse Streaming (Databricks)
Optimal for unified batch/stream processing and complex machine learning pipelines.
1.  **Ingestion**: Azure Event Hubs (using the Kafka endpoint).
2.  **Processing**: Azure Databricks running Spark Structured Streaming (or Delta Live Tables). 
3.  **Storage / Sink**: Streaming Upserts into Delta Lake tables residing on ADLS Gen 2. Utilizing the Medallion Architecture (Bronze -> Silver -> Gold).

## Blueprint 3: Serverless Event Routing
Optimal for decoupled microservices and reactive programming.
1.  **Event Router**: Azure Event Grid (A highly scalable, serverless event routing service).
2.  **Producers**: Azure services (e.g., Blob Storage upload event) or custom applications publish events.
3.  **Consumers**: Event Grid pushes the event to Azure Functions (Serverless compute) or Logic Apps to execute a workflow.
