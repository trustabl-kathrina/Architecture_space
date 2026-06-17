# Security and Governance in Kafka

Securing a Kafka cluster requires layered defenses, as Kafka was originally designed for trusted internal networks.

## The Three Pillars of Kafka Security

### 1. Encryption (Data in Transit)
*   Kafka supports **TLS (Transport Layer Security)** to encrypt data flowing between clients and brokers, and between brokers themselves.
*   *Overhead*: TLS introduces CPU overhead and slight latency, but is mandatory for any enterprise architecture or cloud deployment.

### 2. Authentication (Who are you?)
Verifies the identity of clients connecting to the broker.
*   **mTLS (Mutual TLS)**: Clients provide a certificate. Highly secure, but managing certificate rotation at scale is operationally complex.
*   **SASL/SCRAM**: Username/password mechanisms stored in Zookeeper/KRaft.
*   **SASL/OAUTHBEARER**: Integrates with external Identity Providers (IdP/SSO) using OAuth2 tokens. (Modern Enterprise Standard).
*   **SASL/GSSAPI (Kerberos)**: Common in legacy on-premise Hadoop/Big Data environments.

### 3. Authorization (What can you do?)
Controls what an authenticated user is allowed to do via **ACLs (Access Control Lists)**.
*   Managed via the Authorizer (e.g., `StandardAuthorizer`).
*   Rules are defined as: `Principal P is [Allowed/Denied] Operation O From Host H on Resource R`.
*   *Example*: Service A is allowed to `WRITE` to Topic `orders`, but Service B is only allowed to `READ`.

## Governance & Quotas
To prevent noisy neighbor problems (e.g., a misconfigured consumer issuing millions of requests per second), Kafka enforces **Quotas**.
*   **Network Bandwidth Quotas**: Limit the byte-rate for producers (`produce` quota) and consumers (`fetch` quota).
*   **Request Rate Quotas**: Limit the percentage of CPU time a client can consume on a broker.
