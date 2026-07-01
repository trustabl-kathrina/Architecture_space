# Apache Beam and Google Cloud Dataflow

Apache Beam is a unified programming model (API) for defining both batch and streaming data-parallel processing pipelines. Google Cloud Dataflow is a fully managed cloud service for executing Beam pipelines.

## The Beam Philosophy: "Write Once, Run Anywhere"
Beam separates the *definition* of the data pipeline from the *execution* of the pipeline.
*   **SDKs**: You write code using Beam SDKs (Java, Python, Go).
*   **Runners**: You execute the code on a "Runner" of your choice (Google Cloud Dataflow, Apache Flink, Apache Spark, or a direct local runner).

## The Beam Model (The 4 W's)
Beam pioneered many modern streaming concepts, answering four core questions:
1.  **What** results are calculated? (Transformations like Sum, Join, Map).
2.  **Where** in event time are results calculated? (Windowing).
3.  **When** in processing time are results materialized? (Triggers - e.g., output when the watermark passes the window, or output early speculative results).
4.  **How** do refinements of results relate? (Accumulation modes - e.g., discard old results, accumulate and update, or emit retractions).

## Google Cloud Dataflow Architecture
*   **Serverless**: Dataflow provisions and manages the underlying compute instances dynamically.
*   **Liquid Sharding & Autoscaling**: Dataflow dynamically rebalances work between worker nodes mid-flight. If a specific key becomes a hotspot, Dataflow can dynamically split the work, avoiding the severe skew issues that plague static partition-based systems (like Kafka/Flink).
*   **Cost**: Billed per second of CPU/RAM used. Can be expensive for continuous 24/7 streams compared to self-hosted Flink, but saves massively on operational overhead.
