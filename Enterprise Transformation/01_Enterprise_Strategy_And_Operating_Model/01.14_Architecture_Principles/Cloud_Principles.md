# Cloud Architecture Principles

## Overview
Guidelines for leveraging cloud computing to maximize scalability, resilience, and cost-efficiency.

## Core Principles

1. **Cloud-Native by Default**: Design applications specifically for the cloud using microservices, containers, and serverless architectures rather than simply "lifting and shifting."
2. **Design for Failure**: Architect systems to withstand underlying hardware or service failures automatically across multiple availability zones.
3. **Infrastructure as Code (IaC)**: All infrastructure provisioning and configuration must be defined in version-controlled code (e.g., Terraform).
4. **Financial Accountability (FinOps)**: Cloud architecture must incorporate cost visibility, resource optimization, and tagging to ensure efficient spend.
5. **Vendor Portability (Where Practical)**: Utilize abstractions (like Kubernetes or open table formats) to avoid deep lock-in to a specific cloud provider's proprietary stack, balancing portability against the speed of managed services.
