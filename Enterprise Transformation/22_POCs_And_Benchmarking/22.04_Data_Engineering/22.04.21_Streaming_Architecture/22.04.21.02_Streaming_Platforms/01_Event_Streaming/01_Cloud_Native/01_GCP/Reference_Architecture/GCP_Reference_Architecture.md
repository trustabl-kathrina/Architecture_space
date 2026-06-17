# GCP Cloud-Native Streaming Architecture

Cloud-native streaming on Google Cloud Platform relies entirely on managed, serverless services designed to scale automatically without infrastructure management.

## GCP Reference Architecture
1.  **Ingestion**: Google Cloud Pub/Sub (Serverless message bus).
2.  **Processing**: Google Cloud Dataflow (Apache Beam managed runner). Autoscales based on backlog.
3.  **Storage / Sink**: 
    *   BigQuery (Streaming inserts for analytics via Storage Write API or direct Pub/Sub subscriptions).
    *   Cloud Storage (GCS) for archival and Lakehouse patterns.
4.  **Event-Driven Microservices**: Cloud Run / Cloud Functions triggered by Eventarc or Pub/Sub push subscriptions.

## Design Principles
*   **Zero Ops**: Favor managed services over infrastructure management. Focus engineering effort on business logic, not cluster tuning.
*   **Elasticity**: Systems automatically scale up during traffic spikes and scale to zero (or near zero) during idle times to optimize costs.

## Pros & Cons
*   *Pros*: Fast time to market, true serverless experience (no partitions to manage in Pub/Sub), robust security integration (IAM), unified batch/stream API (Beam).
*   *Cons*: High risk of vendor lock-in, unpredictable costs at massive scale (Pub/Sub and Dataflow can get very expensive if unoptimized), limited low-level tuning capability compared to Kafka/Flink.
