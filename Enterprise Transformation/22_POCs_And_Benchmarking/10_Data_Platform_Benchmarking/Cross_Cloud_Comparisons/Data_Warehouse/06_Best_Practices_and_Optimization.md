# 6. Best Practices & Optimization
- **Data Modeling:** Use denormalized structures (Star or Snowflake schemas) and take advantage of nested/repeated fields where supported (BigQuery, Snowflake).
- **Partitioning & Clustering:** Always partition massive tables by date/time and cluster (or sort) by frequently filtered columns to minimize data scanning.
- **Materialized Views:** Use materialized views to pre-compute heavy aggregations and joins for dashboards.
- **Resource Isolation:** Separate ETL/ELT workloads from BI/Reporting workloads using dedicated compute clusters or workload management queues.
- **Cost Controls:** Implement query limits, user-level quotas, and automated alerts to prevent runaway queries on serverless pricing models.
