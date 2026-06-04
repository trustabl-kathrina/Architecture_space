# 4. Feature Comparison Matrix

| Feature | Amazon Redshift | Azure Synapse | Google BigQuery | Snowflake |
|---|---|---|---|---|
| **Architecture** | Provisioned / Serverless | Provisioned / Serverless | Fully Serverless | Decoupled Storage/Compute |
| **Compute Scaling** | Manual / Auto (Concurrency) | Manual / Auto (Serverless) | Automatic (Slots) | Auto (Multi-cluster) |
| **Storage Model** | AWS Managed Storage (RA3) | ADLS Gen2 | Colossus (GCP Storage) | Multi-Cloud Object Storage |
| **Data Sharing** | AWS Data Exchange | Azure Data Share | Analytics Hub | Secure Data Sharing (Native) |
| **AI/ML Integration** | Redshift ML (SageMaker) | Azure ML Integration | BigQuery ML (Native SQL) | Snowpark (Python/Scala/Java) |
| **Maintenance** | Medium (Requires Vacuum/Analyze) | Medium | Zero (Fully Managed) | Near-Zero |
