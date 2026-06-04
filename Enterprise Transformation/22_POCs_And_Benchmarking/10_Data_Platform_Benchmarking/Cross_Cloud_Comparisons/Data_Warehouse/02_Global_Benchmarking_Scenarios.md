# 2. Global Benchmarking Scenarios
Standardized benchmarking relies on industry-accepted workloads (e.g., TPC-DS, TPC-H) adapted for cloud-native architectures.

- **Scenario 1: Massive Scale Ad-Hoc Analytics (TPC-DS 10TB/100TB)**
  - Testing the execution of complex, multi-join analytical queries without prior tuning.
- **Scenario 2: High Concurrency BI Dashboards**
  - Simulating 50, 100, and 500 concurrent users running short sub-second queries typical of Looker, Tableau, or Power BI.
- **Scenario 3: ETL / ELT Data Loading**
  - Measuring ingestion rates of 1TB flat files (CSV/JSON) vs. optimized columnar formats (Parquet) and micro-batch streaming.
- **Scenario 4: Cold Start & Auto-Scaling**
  - Evaluating how quickly compute resources spin up and scale out during sudden spikes in query volume.
