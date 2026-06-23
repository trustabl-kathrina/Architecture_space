# Fraud Detection Architecture

Fraud detection requires analyzing a transaction against a user's historical behavior and current global threat patterns within milliseconds to block a transaction before it completes.

## Architecture Blueprint

### 1. The Critical Path (Synchronous)
1.  A user swipes a credit card. The Payment Gateway receives the request.
2.  The Gateway publishes an `AuthorizationRequested` event to Kafka and *waits* for a response.

### 2. Real-Time Feature Calculation
*   A Flink job reads the event. It calculates real-time features using stateful windowing:
    *   *Example*: "Distance between current transaction IP and last transaction IP in the last 10 minutes."
    *   *Example*: "Number of transactions by this user in the last hour."

### 3. Model Inference (Scoring)
*   **Option A (Embedded)**: The ML model (e.g., XGBoost, TensorFlow Lite) is loaded directly into the Flink TaskManager's memory. Feature calculation and scoring happen in the same JVM, yielding <10ms latency.
*   **Option B (RPC/API)**: Flink makes an async API call to a dedicated inference server (e.g., Vertex AI, Sagemaker). Easier to manage model lifecycles, but introduces network latency (10-50ms).

### 4. Decision & Response
*   The stream processor evaluates the score. If `score > 0.95`, it publishes an `AuthorizationDeclined` event. Otherwise, `AuthorizationApproved`.
*   The Payment Gateway (from Step 1) consumes this response topic, unblocks, and returns the result to the merchant.

### 5. Model Retraining (Asynchronous)
*   All transactions and their outcomes (including later chargebacks) are streamed to a Data Lakehouse.
*   Data Scientists train updated models on the Lakehouse.
*   The new model is deployed to the inference engine (or broadcast via Kafka to the Flink workers) seamlessly without downtime.
