# PII Handling & Crypto-Shredding in Streams

Streaming architectures often centralize data, making them prime targets for PII (Personally Identifiable Information) compliance violations under GDPR and CCPA.

## The Right to be Forgotten Problem
If a Kafka topic has infinite retention and contains a user's Social Security Number, and that user invokes their "Right to be Forgotten", you cannot easily run a `DELETE FROM kafka WHERE user_id=123`. The log is immutable.

## Architectural Solutions

### 1. Crypto-Shredding (Best Practice)
*   Instead of storing raw PII, the producer encrypts the PII fields using a unique encryption key specific to that user.
*   The encrypted payload is written to Kafka.
*   A centralized Key Management Service (KMS) stores the mapping of `user_id` to the encryption key.
*   *The Deletion*: When a user requests deletion, you simply delete their key from the KMS. All their historical data currently resting in Kafka (or downstream data lakes) instantly becomes unreadable ciphertext. It has been "crypto-shredded."

### 2. In-Flight Masking / Tokenization
*   Use Kafka Connect Single Message Transforms (SMTs) to detect and mask PII (e.g., replacing a credit card with `XXXX-XXXX-XXXX-1234`) *before* it is written to the sink (like a Data Warehouse or Elasticsearch).
*   Alternatively, use a stream processor (Flink) to replace PII with a token from a Tokenization Vault. Downstream analytical consumers only see the token, while authorized operational services can detokenize it via the Vault API.
