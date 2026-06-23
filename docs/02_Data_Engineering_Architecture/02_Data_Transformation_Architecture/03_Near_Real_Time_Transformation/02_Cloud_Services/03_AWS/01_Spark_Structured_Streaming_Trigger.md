---
title: Spark Structured Streaming Trigger (AWS)
section: "02.02.03.02.03"
status: complete
template: concept
last_reviewed: 2026-06-20
owner: architecture-team
tags: [aws, spark, nrt]
canonical: true
---
# Spark Structured Streaming Trigger on AWS

## Deployment options

| Service | Trigger support | Best for |
| --- | --- | --- |
| **Glue Streaming** | `processingTime` trigger | Managed SS on Kinesis/Kafka |
| **EMR on EKS** | Full SS API | Custom Spark versions |
| **Databricks on AWS** | Delta Live Tables | Lakehouse MERGE silver |

## Glue Streaming trigger

```python
glueContext.forEachBatch(frame=dyf, batch_function=process_batch, options={"windowSize": "60 seconds"})
```

## Checkpointing

- Store checkpoints on **S3** with versioning enabled.
- Separate checkpoint prefix per job/environment.
- Monitor `StructuredStreamingQueryProgress` JSON logs.

## Related

- [Glue Streaming Learning Guide](../../../02_Streaming_Transformation/02_Cloud_Services/03_AWS/03_Glue_Streaming_Learning_Guide/README.md)
