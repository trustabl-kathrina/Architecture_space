# Google Cloud Dataflow Architecture

Dataflow is a fully managed service for executing Apache Beam data processing pipelines.

## Serverless Execution
*   **Liquid Sharding**: Dataflow dynamically monitors the pipeline's progress. If a specific key or step becomes a bottleneck (straggler), Dataflow dynamically splits the work and redistributes it across available workers.
*   **Autoscaling**: Dataflow Streaming Autoscaling adjusts the number of worker nodes dynamically based on CPU utilization and the backlog of pending messages in Pub/Sub.

## Dataflow Streaming Engine
*   In the standard model, workers hold state and shuffle data among themselves.
*   **Streaming Engine** moves the state storage and data shuffling out of the worker VMs and into Google's backend infrastructure.
*   *Benefits*: Much faster autoscaling, smoother handling of large state, and reduced worker VM sizes.

## Dataflow Prime
An advanced tier of Dataflow that includes Right Fitting (automatically assigning the optimal RAM/CPU ratio to different steps of the pipeline) and advanced diagnostics.

## Best Practices
*   **Use Dataflow Templates**: Avoid deploying pipelines from local developer machines. Compile pipelines into Flex Templates and launch them via Cloud Composer (Airflow) or Cloud Scheduler.
*   **Windowing**: Strictly define windowing and allowed lateness to prevent state explosion in memory.

## Performance Tuning
*   **Streaming Engine**: Always enable Streaming Engine for production workloads. It moves state and shuffle operations off the worker VMs into Google's backend, dramatically improving autoscaling reactivity and reducing OOM errors.
*   **Dataflow Prime / Right Fitting**: Utilize Dataflow Prime to automatically allocate different ratios of memory and CPU to specific steps in the pipeline (e.g., giving memory-intensive grouping steps larger instances).
*   **Preventing Stragglers**: Ensure your data keys are evenly distributed. If using highly skewed keys, rely on Dataflow's Liquid Sharding, but supplement by manually salting/bucketing keys in your Beam code if bottlenecks persist.
