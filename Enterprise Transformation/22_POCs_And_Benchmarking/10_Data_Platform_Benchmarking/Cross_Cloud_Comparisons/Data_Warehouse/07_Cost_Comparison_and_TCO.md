# 7. Cost Comparison & TCO

- **On-Demand / Pay-as-you-go:**
  - *BigQuery:* Per TB of data scanned ($6.25/TB standard). Great for bursty, unpredictable workloads.
  - *Snowflake:* Per-second billing for active compute (Virtual Warehouses). Requires aggressive auto-suspend policies.
- **Provisioned / Reserved:**
  - *Redshift & Synapse:* Provide significant discounts (up to 70%) for 1 or 3-year reserved instances. Best for predictable, 24/7 baseline workloads.
  - *BigQuery (Editions):* Offers slot-based pricing (Standard, Enterprise, Enterprise Plus) with autoscaling for predictable budgeting.
