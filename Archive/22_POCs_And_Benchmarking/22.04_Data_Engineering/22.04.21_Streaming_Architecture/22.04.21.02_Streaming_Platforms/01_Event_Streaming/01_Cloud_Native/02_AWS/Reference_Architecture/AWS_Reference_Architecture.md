# AWS Cloud-Native Streaming Architecture

AWS provides multiple streaming blueprints depending on whether you prefer "pure serverless" or "managed open-source."

## Blueprint 1: The Pure Serverless Stack (Kinesis)
Optimal for unpredictable workloads, fast time-to-market, and avoiding JVM/cluster management.
1.  **Ingestion**: Amazon API Gateway -> Kinesis Data Streams (On-Demand).
2.  **Processing**:
    *   *Stateless*: AWS Lambda (triggered natively by Kinesis via Event Source Mapping).
    *   *Stateful*: Managed Apache Flink.
3.  **Storage / Sink**: Kinesis Data Firehose micro-batching into Amazon S3 (for Lakehouse) or Amazon Redshift.

## Blueprint 2: The Managed Open-Source Stack (MSK)
Optimal for massive, predictable throughput, high statefulness, and avoiding vendor lock-in.
1.  **Ingestion**: Microservices (EKS/ECS) producing to Amazon MSK. CDC via MSK Connect (Debezium plugin).
2.  **Processing**: Managed Apache Flink (reading from MSK) or Kafka Streams running on EKS.
3.  **Storage / Sink**: MSK Connect (S3 Sink or Redshift Sink). Tiered Storage on MSK for infinite retention.

## Blueprint 3: Event-Driven Serverless (EDA)
Optimal for asynchronous microservice choreography rather than heavy data-pipeline streaming.
1.  **Event Router**: Amazon EventBridge.
2.  **Producers**: Microservices publish domain events (e.g., `OrderCreated`) to EventBridge.
3.  **Consumers**: EventBridge routes events based on rules to AWS Lambda, SQS, or Step Functions for orchestrated workflows.
