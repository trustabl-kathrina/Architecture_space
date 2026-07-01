# Apache Flink Architecture

Apache Flink is a framework and distributed processing engine for stateful computations over unbounded and bounded data streams. It is widely considered the gold standard for true real-time, low-latency stream processing.

## Core Architecture
*   **JobManager**: The coordinator. It accepts the application graph (JobGraph), manages checkpoints, coordinates recovery, and schedules tasks.
*   **TaskManager**: The worker nodes. They execute the actual dataflow tasks, buffer streams, and manage local state (usually in RocksDB).
*   **Slots**: TaskManagers are divided into slots, isolating memory for parallel task execution.

## Key Differentiators
1.  **True Continuous Streaming**: Unlike Spark's micro-batching, Flink processes events one-at-a-time (or in small pipelined buffers), achieving sub-millisecond latencies.
2.  **Robust State Management**: Flink treats state as a first-class citizen. It can manage terabytes of state locally on the TaskManagers (using RocksDB) without needing to query an external database (like Redis) during processing.
3.  **Exactly-Once State Consistency**: Uses a variation of the Chandy-Lamport algorithm to inject **Checkpoints** (barriers) into the stream. If a failure occurs, Flink rolls back the entire application state and Kafka offsets to the last successful checkpoint, guaranteeing exactly-once semantics.
4.  **Advanced Event Time Handling**: Deep native support for Event Time and Watermarks, making it uniquely capable of handling out-of-order and late-arriving data correctly.

## Use Cases
*   Fraud detection (low latency CEP).
*   Real-time pricing engines.
*   Continuous ETL and stream enrichment.

## Performance Tuning
*   **State Backend (RocksDB)**: Tune RocksDB write buffers (`state.backend.rocksdb.writebuffer.size`) and enable local SSDs on TaskManagers to handle massive multi-terabyte state without I/O blocking.
*   **Network Buffer Tuning**: Adjust `taskmanager.network.memory.fraction` to optimize how data is shuffled across the network between TaskManagers. Increase buffers for high-throughput, high-parallelism jobs.
*   **Object Reuse**: Enable `pipeline.object-reuse: true` in the Flink environment to prevent the JVM from instantiating new objects for every single event in the stream, drastically reducing Garbage Collection (GC) overhead.
