# Medallion Architecture Framework

## Overview
A data design pattern used to logically organize data in a Lakehouse, progressively improving structure and quality as data flows through the layers.

## The Layers

### 1. Bronze (Raw)
- **Purpose**: Landing zone for raw data from external systems.
- **Characteristics**: Immutable, append-only, exact replica of source data. History is preserved.

### 2. Silver (Cleansed & Conformed)
- **Purpose**: Filtered, cleaned, and augmented data.
- **Characteristics**: Schema enforcement, deduplication, standardized naming conventions (e.g., snake_case), data type casting. This forms the "Enterprise View" of data.

### 3. Gold (Curated & Business-Level)
- **Purpose**: Highly refined data aggregated for specific business use cases, analytics, and ML.
- **Characteristics**: Star schemas, dimensional models, denormalized tables. Data Products are typically served from the Gold layer.

## Best Practices
- **Data Quality Gates**: Implement automated data quality checks (e.g., Great Expectations) between Bronze -> Silver and Silver -> Gold transitions.
- **Open Table Formats**: Use Delta Lake, Apache Iceberg, or Apache Hudi across all layers for ACID transaction support.
